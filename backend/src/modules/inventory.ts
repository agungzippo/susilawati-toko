import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";

export function calculateAverageCost(
  oldStock: number,
  oldCost: number,
  incomingQty: number,
  incomingCost: number
): number {
  if (oldStock <= 0) return incomingCost;
  if (incomingQty <= 0) return oldCost;
  const totalValue = oldStock * oldCost + incomingQty * incomingCost;
  const totalQty = oldStock + incomingQty;
  return Math.round((totalValue / totalQty) * 100) / 100;
}

export const inventoryRouter = new Hono();

inventoryRouter.use("*", requireAuth);

const initialStockSchema = z.object({
  locationId: z.string().optional(),
  items: z
    .array(
      z.object({
        variantId: z.string().min(1),
        quantity: z.number().int().positive("Jumlah stok awal harus lebih dari 0"),
        unitCost: z.number().nonnegative("Harga modal tidak boleh negatif"),
      })
    )
    .min(1, "Minimal pilih 1 item untuk input stok awal"),
});

// Get stock balances
inventoryRouter.get("/balances", async (c) => {
  const storeId = c.get("storeId");
  const balances = await prisma.stockBalance.findMany({
    where: { storeId },
    include: {
      location: true,
      variant: {
        include: {
          product: {
            include: { category: true },
          },
        },
      },
    },
    orderBy: { variant: { product: { name: "asc" } } },
  });

  return c.json({ data: balances });
});

// Input initial stock
inventoryRouter.post("/initial-stock", zValidator("json", initialStockSchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const body = c.req.valid("json");

  // Get location
  let locationId = body.locationId;
  if (!locationId) {
    const loc = await prisma.location.findFirst({
      where: { storeId, isActive: true },
    });
    if (!loc) return c.json({ error: "Lokasi gudang belum terdaftar" }, 400);
    locationId = loc.id;
  }

  const results = await prisma.$transaction(async (tx) => {
    const updatedBalances = [];

    for (const item of body.items) {
      // Find or create balance
      const existing = await tx.stockBalance.findUnique({
        where: {
          locationId_variantId: {
            locationId,
            variantId: item.variantId,
          },
        },
      });

      let newQty = item.quantity;
      let newCost = item.unitCost;

      if (existing) {
        newQty = existing.quantityOnHand + item.quantity;
        newCost = calculateAverageCost(
          existing.quantityOnHand,
          Number(existing.averageCost),
          item.quantity,
          item.unitCost
        );
      }

      const balance = await tx.stockBalance.upsert({
        where: {
          locationId_variantId: {
            locationId,
            variantId: item.variantId,
          },
        },
        create: {
          storeId,
          locationId,
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

      // Record stock movement
      await tx.stockMovement.create({
        data: {
          storeId,
          locationId,
          variantId: item.variantId,
          type: "INITIAL",
          quantityDelta: item.quantity,
          unitCost: item.unitCost,
          balanceAfter: newQty,
          referenceType: "INITIAL_STOCK",
          notes: "Input stok awal",
          createdBy: user.sub,
        },
      });

      updatedBalances.push(balance);
    }

    return updatedBalances;
  });

  return c.json({ success: true, data: results }, 201);
});

// Stock alerts (low and empty)
inventoryRouter.get("/alerts", async (c) => {
  const storeId = c.get("storeId");

  const balances = await prisma.stockBalance.findMany({
    where: { storeId },
    include: {
      variant: {
        include: { product: true },
      },
      location: true,
    },
  });

  const lowStock = [];
  const outOfStock = [];

  for (const b of balances) {
    if (b.quantityOnHand <= 0) {
      outOfStock.push({
        variantId: b.variantId,
        productName: b.variant.product.name,
        sku: b.variant.sku,
        color: b.variant.color,
        size: b.variant.size,
        currentStock: b.quantityOnHand,
        minimumStock: b.variant.minimumStock,
        status: "OUT_OF_STOCK",
      });
    } else if (b.quantityOnHand <= b.variant.minimumStock) {
      lowStock.push({
        variantId: b.variantId,
        productName: b.variant.product.name,
        sku: b.variant.sku,
        color: b.variant.color,
        size: b.variant.size,
        currentStock: b.quantityOnHand,
        minimumStock: b.variant.minimumStock,
        status: "LOW_STOCK",
      });
    }
  }

  return c.json({
    data: {
      outOfStockCount: outOfStock.length,
      lowStockCount: lowStock.length,
      outOfStock,
      lowStock,
    },
  });
});

// Dashboard summary
inventoryRouter.get("/summary", async (c) => {
  const storeId = c.get("storeId");

  const balances = await prisma.stockBalance.findMany({
    where: { storeId },
    include: {
      variant: true,
    },
  });

  let totalSkus = balances.length;
  let totalUnits = 0;
  let totalCostValue = 0;
  let totalSellingValue = 0;
  let lowStockCount = 0;
  let outOfStockCount = 0;

  for (const b of balances) {
    totalUnits += b.quantityOnHand;
    const cost = Number(b.averageCost);
    const selling = Number(b.variant.referenceSellingPrice);

    totalCostValue += b.quantityOnHand * cost;
    totalSellingValue += b.quantityOnHand * selling;

    if (b.quantityOnHand <= 0) {
      outOfStockCount++;
    } else if (b.quantityOnHand <= b.variant.minimumStock) {
      lowStockCount++;
    }
  }

  const potentialProfit = totalSellingValue - totalCostValue;

  // Hitung aktivitas hari ini
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todayMovements = await prisma.stockMovement.findMany({
    where: {
      storeId,
      createdAt: { gte: todayStart },
    },
  });

  let itemsInToday = 0;
  let itemsOutToday = 0;
  for (const m of todayMovements) {
    if (m.type === "GOODS_RECEIPT" || m.type === "STOCK_ADJUSTMENT_IN" || m.type === "INITIAL") {
      itemsInToday += m.quantityDelta;
    } else if (m.type === "STOCK_ADJUSTMENT_OUT") {
      itemsOutToday += Math.abs(m.quantityDelta);
    }
  }

  return c.json({
    data: {
      totalSkus,
      totalUnits,
      totalCostValue: Math.round(totalCostValue),
      totalSellingValue: Math.round(totalSellingValue),
      estimatedPotentialProfit: Math.round(potentialProfit),
      lowStockCount,
      outOfStockCount,
      itemsInToday,
      itemsOutToday,
      transactionsToday: todayMovements.length,
      calculatedAt: new Date().toISOString(),
    },
  });
});

// Transaksi terbaru untuk dashboard
inventoryRouter.get("/recent-transactions", async (c) => {
  const storeId = c.get("storeId");
  const limit = Number(c.req.query("limit")) || 10;

  const movements = await prisma.stockMovement.findMany({
    where: { storeId },
    include: {
      variant: {
        include: { product: true },
      },
    },
    orderBy: { createdAt: "desc" },
    take: limit,
  });

  const transactions = movements.map((m) => {
    const isIncoming = m.type === "GOODS_RECEIPT" || m.type === "INITIAL" || m.type === "STOCK_ADJUSTMENT_IN";
    const qty = Math.abs(m.quantityDelta);
    const unitPrice = isIncoming ? Number(m.unitCost) : Number(m.variant.referenceSellingPrice);
    const totalAmount = qty * unitPrice;

    return {
      id: m.id,
      type: isIncoming ? "IN" : "OUT",
      title: isIncoming ? "Barang Masuk" : "Barang Keluar",
      productName: m.variant.product.name,
      variantDetail: `${m.variant.color || "Default"} (${qty} pcs)`,
      quantity: qty,
      totalAmount: Math.round(totalAmount),
      date: m.createdAt.toISOString(),
      notes: m.notes,
    };
  });

  return c.json({ data: transactions });
});

// Catat Barang Keluar (Pengurangan Stok / Penjualan Toko)
const stockOutSchema = z.object({
  customerName: z.string().optional(),
  date: z.string().optional(),
  items: z
    .array(
      z.object({
        variantId: z.string().min(1),
        quantity: z.number().int().positive("Jumlah keluar minimal 1 pcs"),
      })
    )
    .min(1, "Minimal pilih 1 item"),
  notes: z.string().optional(),
});

inventoryRouter.post("/stock-out", zValidator("json", stockOutSchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const body = c.req.valid("json");

  // Ambil lokasi default
  const location = await prisma.location.findFirst({
    where: { storeId, isActive: true },
  });
  if (!location) return c.json({ error: "Gudang toko belum terdaftar" }, 400);

  try {
    const result = await prisma.$transaction(async (tx) => {
      let grandTotal = 0;
      const updatedItems = [];

      for (const item of body.items) {
        const balance = await tx.stockBalance.findUnique({
          where: {
            locationId_variantId: {
              locationId: location.id,
              variantId: item.variantId,
            },
          },
          include: { variant: { include: { product: true } } },
        });

        if (!balance || balance.quantityOnHand < item.quantity) {
          throw new Error(
            `Stok untuk ${balance?.variant.product.name || "produk"} tidak mencukupi (Tersedia: ${balance?.quantityOnHand ?? 0} pcs, diminta: ${item.quantity} pcs)`
          );
        }

        const newQty = balance.quantityOnHand - item.quantity;
        const sellingPrice = Number(balance.variant.referenceSellingPrice);
        const lineTotal = item.quantity * sellingPrice;
        grandTotal += lineTotal;

        await tx.stockBalance.update({
          where: { id: balance.id },
          data: {
            quantityOnHand: newQty,
            version: { increment: 1 },
          },
        });

        const movement = await tx.stockMovement.create({
          data: {
            storeId,
            locationId: location.id,
            variantId: item.variantId,
            type: "STOCK_ADJUSTMENT_OUT",
            quantityDelta: -item.quantity,
            unitCost: balance.averageCost,
            balanceAfter: newQty,
            referenceType: "STOCK_OUT",
            notes: body.notes || `Barang keluar ke ${body.customerName || "Pelanggan"}`,
            createdBy: user.sub,
          },
        });

        updatedItems.push({
          variantId: item.variantId,
          productName: balance.variant.product.name,
          color: balance.variant.color,
          quantity: item.quantity,
          sellingPrice,
          lineTotal,
          remainingStock: newQty,
        });
      }

      return {
        customerName: body.customerName,
        totalItems: body.items.reduce((acc, curr) => acc + curr.quantity, 0),
        grandTotal,
        items: updatedItems,
      };
    });

    return c.json({ success: true, data: result }, 201);
  } catch (err: any) {
    return c.json({ error: err.message || "Gagal mencatat barang keluar" }, 400);
  }
});

// Ekspor Saldo Stok ke CSV
inventoryRouter.get("/export-csv", async (c) => {
  const storeId = c.get("storeId");

  const balances = await prisma.stockBalance.findMany({
    where: { storeId },
    include: {
      variant: {
        include: {
          product: {
            include: { category: true },
          },
        },
      },
    },
    orderBy: { variant: { product: { name: "asc" } } },
  });

  const rows = [
    [
      "Kategori",
      "Nama Produk",
      "Brand",
      "SKU",
      "Warna",
      "Ukuran",
      "Barcode",
      "Stok Fisik",
      "Batas Min",
      "Harga Modal",
      "Harga Jual",
      "Total Nilai Modal",
      "Total Nilai Jual",
      "Estimasi Potensi Laba",
      "Status",
    ].join(","),
  ];

  for (const b of balances) {
    const p = b.variant.product;
    const v = b.variant;
    const cost = Number(b.averageCost);
    const selling = Number(v.referenceSellingPrice);
    const totalCost = b.quantityOnHand * cost;
    const totalSelling = b.quantityOnHand * selling;
    const profit = totalSelling - totalCost;

    let status = "AMAN";
    if (b.quantityOnHand <= 0) status = "HABIS";
    else if (b.quantityOnHand <= v.minimumStock) status = "MENIPIS";

    const escapeCsv = (str: string | null | undefined) =>
      `"${(str || "").replace(/"/g, '""')}"`;

    rows.push(
      [
        escapeCsv(p.category?.name),
        escapeCsv(p.name),
        escapeCsv(p.brand),
        escapeCsv(v.sku),
        escapeCsv(v.color),
        escapeCsv(v.size),
        escapeCsv(v.barcode),
        b.quantityOnHand,
        v.minimumStock,
        cost,
        selling,
        totalCost,
        totalSelling,
        profit,
        status,
      ].join(",")
    );
  }

  const csvContent = rows.join("\r\n");
  const filename = `stok-susilawati-${new Date().toISOString().split("T")[0]}.csv`;

  return new Response(csvContent, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
  });
});

