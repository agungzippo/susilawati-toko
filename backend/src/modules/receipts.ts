import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";
import { calculateAverageCost } from "./inventory.js";

export const receiptsRouter = new Hono();

receiptsRouter.use("*", requireAuth);

// 1. Buat Jadwal Kedatangan dari Faktur Terverifikasi
const createScheduleSchema = z.object({
  invoiceId: z.string().min(1),
  locationId: z.string().optional(),
  expectedDate: z.string(), // ISO date
  notes: z.string().optional(),
});

receiptsRouter.post("/schedules", zValidator("json", createScheduleSchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const body = c.req.valid("json");

  const invoice = await prisma.invoice.findFirst({
    where: { id: body.invoiceId, storeId },
    include: { items: true },
  });

  if (!invoice) return c.json({ error: "Faktur tidak ditemukan" }, 404);
  if (invoice.status !== "VERIFIED") {
    return c.json({ error: "Faktur harus berstatus VERIFIED sebelum dapat dijadwalkan" }, 400);
  }

  let locationId = body.locationId;
  if (!locationId) {
    const loc = await prisma.location.findFirst({ where: { storeId, isActive: true } });
    if (!loc) return c.json({ error: "Lokasi gudang belum terdaftar" }, 400);
    locationId = loc.id;
  }

  const schedule = await prisma.$transaction(async (tx) => {
    const s = await tx.incomingSchedule.create({
      data: {
        invoiceId: invoice.id,
        locationId: locationId!,
        expectedDate: new Date(body.expectedDate),
        status: "SCHEDULED",
        picUserId: user.sub,
        notes: body.notes,
      },
    });

    await tx.invoice.update({
      where: { id: invoice.id },
      data: { status: "SCHEDULED" },
    });

    return s;
  });

  return c.json({ success: true, data: schedule }, 201);
});

// 2. Daftar Jadwal Kedatangan
receiptsRouter.get("/schedules", async (c) => {
  const storeId = c.get("storeId");
  const status = c.req.query("status");

  const whereClause: any = {
    invoice: { storeId },
  };
  if (status) whereClause.status = status;

  const schedules = await prisma.incomingSchedule.findMany({
    where: whereClause,
    include: {
      location: true,
      pic: true,
      invoice: {
        include: {
          supplier: true,
          items: {
            include: { variant: { include: { product: true } } },
          },
        },
      },
      goodsReceipts: {
        include: { items: true },
      },
    },
    orderBy: { expectedDate: "asc" },
  });

  // Tandai LATE otomatis jika tanggal estimasi lewat dan belum diterima
  const now = new Date();
  const schedulesWithLateStatus = schedules.map((s) => {
    let computedStatus = s.status;
    if (s.status === "SCHEDULED" && new Date(s.expectedDate) < now) {
      computedStatus = "LATE";
    }
    return { ...s, status: computedStatus };
  });

  return c.json({ data: schedulesWithLateStatus });
});

// 3. Konfirmasi Penerimaan Barang Fisik (Atomic Stock Mutation & Idempotent)
const confirmReceiptSchema = z.object({
  scheduleId: z.string().min(1),
  idempotencyKey: z.string().min(1),
  items: z.array(
    z.object({
      invoiceItemId: z.string().optional(),
      variantId: z.string().min(1),
      expectedQuantity: z.number().int().nonnegative(),
      receivedQuantity: z.number().int().nonnegative(),
      damagedQuantity: z.number().int().nonnegative().default(0),
      shortQuantity: z.number().int().nonnegative().default(0),
      unitCost: z.number().nonnegative(), // modal per pcs
      notes: z.string().optional(),
    })
  ).min(1, "Minimal harus ada 1 item yang diterima"),
});

receiptsRouter.post("/confirm", zValidator("json", confirmReceiptSchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const body = c.req.valid("json");

  // Idempotency check: Jika key sudah ada, kembalikan data yang sama
  const existingReceipt = await prisma.goodsReceipt.findUnique({
    where: { idempotencyKey: body.idempotencyKey },
    include: { items: true },
  });

  if (existingReceipt) {
    return c.json({
      success: true,
      data: existingReceipt,
      message: "Transaksi telah diproses sebelumnya (Idempotent)",
    });
  }

  const schedule = await prisma.incomingSchedule.findFirst({
    where: { id: body.scheduleId, invoice: { storeId } },
    include: { invoice: true, location: true },
  });

  if (!schedule) return c.json({ error: "Jadwal barang masuk tidak ditemukan" }, 404);

  const receiptNumber = `RCV-${Date.now().toString().slice(-6)}`;

  const result = await prisma.$transaction(async (tx) => {
    const receipt = await tx.goodsReceipt.create({
      data: {
        scheduleId: schedule.id,
        receiptNumber,
        status: "CONFIRMED",
        receivedBy: user.sub,
        confirmedAt: new Date(),
        idempotencyKey: body.idempotencyKey,
      },
    });

    let allFulfilled = true;

    for (const item of body.items) {
      await tx.goodsReceiptItem.create({
        data: {
          goodsReceiptId: receipt.id,
          invoiceItemId: item.invoiceItemId,
          variantId: item.variantId,
          expectedQuantity: item.expectedQuantity,
          receivedQuantity: item.receivedQuantity,
          damagedQuantity: item.damagedQuantity,
          shortQuantity: item.shortQuantity,
          unitCost: item.unitCost,
          notes: item.notes,
        },
      });

      if (item.shortQuantity > 0) {
        allFulfilled = false;
      }

      // 1. Mutasi Stok Barang Diterima (Kondisi Baik)
      if (item.receivedQuantity > 0) {
        const balance = await tx.stockBalance.findUnique({
          where: {
            locationId_variantId: {
              locationId: schedule.locationId,
              variantId: item.variantId,
            },
          },
        });

        const oldQty = balance?.quantityOnHand ?? 0;
        const oldCost = Number(balance?.averageCost ?? 0);

        const newQty = oldQty + item.receivedQuantity;
        const newCost = calculateAverageCost(oldQty, oldCost, item.receivedQuantity, item.unitCost);

        await tx.stockBalance.upsert({
          where: {
            locationId_variantId: {
              locationId: schedule.locationId,
              variantId: item.variantId,
            },
          },
          create: {
            storeId,
            locationId: schedule.locationId,
            variantId: item.variantId,
            quantityOnHand: newQty,
            averageCost: newCost,
          },
          update: {
            quantityOnHand: newQty,
            averageCost: newCost,
            version: { increment: 1 },
          },
        });

        await tx.stockMovement.create({
          data: {
            storeId,
            locationId: schedule.locationId,
            variantId: item.variantId,
            type: "GOODS_RECEIPT",
            quantityDelta: item.receivedQuantity,
            unitCost: item.unitCost,
            balanceAfter: newQty,
            referenceType: "GOODS_RECEIPT",
            referenceId: receipt.id,
            notes: `Penerimaan barang dari faktur ${schedule.invoice.internalNumber}`,
            createdBy: user.sub,
          },
        });
      }

      // 2. Catatan Barang Rusak (tidak menambah stok aktif)
      if (item.damagedQuantity > 0) {
        await tx.stockMovement.create({
          data: {
            storeId,
            locationId: schedule.locationId,
            variantId: item.variantId,
            type: "DAMAGED",
            quantityDelta: 0, // Tidak menambah saldo fisik yang bisa dijual
            unitCost: item.unitCost,
            balanceAfter: 0,
            referenceType: "GOODS_RECEIPT_DAMAGED",
            referenceId: receipt.id,
            notes: `Barang rusak saat penerimaan (${item.damagedQuantity} pcs)`,
            createdBy: user.sub,
          },
        });
      }
    }

    // Update status jadwal & faktur
    const finalScheduleStatus = allFulfilled ? "RECEIVED" : "PARTIALLY_RECEIVED";
    await tx.incomingSchedule.update({
      where: { id: schedule.id },
      data: { status: finalScheduleStatus },
    });

    await tx.invoice.update({
      where: { id: schedule.invoiceId },
      data: { status: finalScheduleStatus },
    });

    return tx.goodsReceipt.findUnique({
      where: { id: receipt.id },
      include: {
        items: {
          include: { variant: { include: { product: true } } },
        },
      },
    });
  });

  return c.json({ success: true, data: result }, 201);
});
