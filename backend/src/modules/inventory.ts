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

  return c.json({
    data: {
      totalSkus,
      totalUnits,
      totalCostValue: Math.round(totalCostValue),
      totalSellingValue: Math.round(totalSellingValue),
      estimatedPotentialProfit: Math.round(potentialProfit),
      lowStockCount,
      outOfStockCount,
      calculatedAt: new Date().toISOString(),
    },
  });
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

