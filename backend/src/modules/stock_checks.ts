import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";

export const stockChecksRouter = new Hono();

stockChecksRouter.use("*", requireAuth);

// 1. Mulai Sesi Stok Opname (Ambil Snapshot Sistem Otomatis)
const startCheckSchema = z.object({
  locationId: z.string().optional(),
});

stockChecksRouter.post("/", zValidator("json", startCheckSchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const body = c.req.valid("json");

  let locationId = body.locationId;
  if (!locationId) {
    const loc = await prisma.location.findFirst({ where: { storeId, isActive: true } });
    if (!loc) return c.json({ error: "Gudang belum terdaftar" }, 400);
    locationId = loc.id;
  }

  // Ambil seluruh saldo stok saat ini untuk snapshot
  const balances = await prisma.stockBalance.findMany({
    where: { storeId, locationId },
  });

  const check = await prisma.$transaction(async (tx) => {
    const sc = await tx.stockCheck.create({
      data: {
        storeId,
        locationId: locationId!,
        status: "IN_PROGRESS",
        createdBy: user.sub,
      },
    });

    for (const b of balances) {
      await tx.stockCheckItem.create({
        data: {
          stockCheckId: sc.id,
          variantId: b.variantId,
          systemQuantitySnapshot: b.quantityOnHand,
          physicalQuantity: b.quantityOnHand, // Default ke jumlah sistem sebelum dihitung ulang
          difference: 0,
        },
      });
    }

    return tx.stockCheck.findUnique({
      where: { id: sc.id },
      include: {
        items: {
          include: { variant: { include: { product: true } } },
        },
      },
    });
  });

  return c.json({ success: true, data: check }, 201);
});

// 2. Daftar Sesi Stok Opname
stockChecksRouter.get("/", async (c) => {
  const storeId = c.get("storeId");
  const checks = await prisma.stockCheck.findMany({
    where: { storeId },
    include: {
      location: true,
      items: {
        include: { variant: { include: { product: true } } },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  return c.json({ data: checks });
});

// 3. Detail Sesi Opname
stockChecksRouter.get("/:id", async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");

  const check = await prisma.stockCheck.findFirst({
    where: { id, storeId },
    include: {
      location: true,
      items: {
        include: { variant: { include: { product: true } } },
      },
    },
  });

  if (!check) return c.json({ error: "Sesi opname tidak ditemukan" }, 404);
  return c.json({ data: check });
});

// 4. Input Hitungan Fisik Item
const updateItemSchema = z.object({
  variantId: z.string().min(1),
  physicalQuantity: z.number().int().nonnegative(),
  reason: z.string().optional(),
});

stockChecksRouter.put("/:id/items", zValidator("json", updateItemSchema), async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");
  const body = c.req.valid("json");

  const check = await prisma.stockCheck.findFirst({
    where: { id, storeId },
  });

  if (!check) return c.json({ error: "Sesi opname tidak ditemukan" }, 404);
  if (check.status !== "IN_PROGRESS" && check.status !== "DRAFT") {
    return c.json({ error: "Sesi opname yang sudah diajukan/disetujui tidak dapat diedit" }, 400);
  }

  const existingItem = await prisma.stockCheckItem.findFirst({
    where: { stockCheckId: id, variantId: body.variantId },
  });

  if (!existingItem) {
    return c.json({ error: "Item varian tidak terdaftar dalam sesi opname" }, 404);
  }

  const difference = body.physicalQuantity - existingItem.systemQuantitySnapshot;

  const updatedItem = await prisma.stockCheckItem.update({
    where: { id: existingItem.id },
    data: {
      physicalQuantity: body.physicalQuantity,
      difference,
      reason: body.reason,
    },
    include: { variant: { include: { product: true } } },
  });

  return c.json({ success: true, data: updatedItem });
});

// 5. Ajukan Hasil Opname (Staf ke Pemilik)
stockChecksRouter.post("/:id/submit", async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");

  const check = await prisma.stockCheck.findFirst({
    where: { id, storeId },
  });

  if (!check) return c.json({ error: "Sesi opname tidak ditemukan" }, 404);

  const updated = await prisma.stockCheck.update({
    where: { id },
    data: {
      status: "SUBMITTED",
      submittedAt: new Date(),
    },
  });

  return c.json({ success: true, data: updated });
});

// 6. Persetujuan Pemilik (Otomatis Buat Mutasi Penyesuaian Stok)
stockChecksRouter.post("/:id/approve", async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const id = c.req.param("id");

  if (user.role !== "OWNER") {
    return c.json({ error: "Hanya akun Pemilik yang berwenang menyetujui penyesuaian stok" }, 403);
  }

  const check = await prisma.stockCheck.findFirst({
    where: { id, storeId },
    include: { items: true },
  });

  if (!check) return c.json({ error: "Sesi opname tidak ditemukan" }, 404);
  if (check.status !== "SUBMITTED") {
    return c.json({ error: "Hanya sesi opname berstatus SUBMITTED yang dapat disetujui" }, 400);
  }

  const result = await prisma.$transaction(async (tx) => {
    for (const item of check.items) {
      if (item.difference !== 0) {
        const movementType = item.difference > 0 ? "STOCK_ADJUSTMENT_IN" : "STOCK_ADJUSTMENT_OUT";

        // Update saldo stok fisik
        await tx.stockBalance.update({
          where: {
            locationId_variantId: {
              locationId: check.locationId,
              variantId: item.variantId,
            },
          },
          data: {
            quantityOnHand: item.physicalQuantity,
            version: { increment: 1 },
          },
        });

        // Catat mutasi penyesuaian
        await tx.stockMovement.create({
          data: {
            storeId,
            locationId: check.locationId,
            variantId: item.variantId,
            type: movementType,
            quantityDelta: item.difference,
            balanceAfter: item.physicalQuantity,
            referenceType: "STOCK_CHECK",
            referenceId: check.id,
            notes: item.reason || `Penyesuaian stok opname (${item.difference > 0 ? '+' : ''}${item.difference} pcs)`,
            createdBy: user.sub,
          },
        });
      }
    }

    return tx.stockCheck.update({
      where: { id },
      data: {
        status: "APPROVED",
        approvedBy: user.sub,
        approvedAt: new Date(),
      },
      include: {
        items: {
          include: { variant: { include: { product: true } } },
        },
      },
    });
  });

  return c.json({ success: true, data: result });
});
