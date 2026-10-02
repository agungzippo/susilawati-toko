import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";

export const productsRouter = new Hono();

productsRouter.use("*", requireAuth);

const createProductSchema = z.object({
  name: z.string().min(1),
  brand: z.string().optional(),
  categoryId: z.string().optional(),
  description: z.string().optional(),
  variants: z
    .array(
      z.object({
        sku: z.string().min(1),
        barcode: z.string().optional(),
        color: z.string().optional(),
        size: z.string().optional(),
        unit: z.string().default("pcs"),
        referenceSellingPrice: z.number().nonnegative().default(0),
        minimumStock: z.number().int().nonnegative().default(5),
      })
    )
    .min(1, "Minimal harus ada 1 varian produk"),
});

// List products with stock
productsRouter.get("/", async (c) => {
  const storeId = c.get("storeId");
  const search = c.req.query("search");
  const categoryId = c.req.query("categoryId");

  const whereClause: any = {
    storeId,
    isActive: true,
  };

  if (categoryId) {
    whereClause.categoryId = categoryId;
  }

  if (search) {
    whereClause.OR = [
      { name: { contains: search, mode: "insensitive" } },
      { brand: { contains: search, mode: "insensitive" } },
      {
        variants: {
          some: {
            OR: [
              { sku: { contains: search, mode: "insensitive" } },
              { barcode: { contains: search, mode: "insensitive" } },
            ],
          },
        },
      },
    ];
  }

  const products = await prisma.product.findMany({
    where: whereClause,
    include: {
      category: true,
      variants: {
        where: { isActive: true },
        include: {
          stockBalances: true,
        },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  return c.json({ data: products });
});

// Get single product
productsRouter.get("/:id", async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");

  const product = await prisma.product.findFirst({
    where: { id, storeId },
    include: {
      category: true,
      variants: {
        where: { isActive: true },
        include: {
          stockBalances: true,
        },
      },
    },
  });

  if (!product) {
    return c.json({ error: "Produk tidak ditemukan" }, 404);
  }

  return c.json({ data: product });
});

// Create product + variants
productsRouter.post("/", zValidator("json", createProductSchema), async (c) => {
  const storeId = c.get("storeId");
  const body = c.req.valid("json");

  // Check SKU uniqueness in store
  const skus = body.variants.map((v) => v.sku);
  const existingVariant = await prisma.productVariant.findFirst({
    where: {
      sku: { in: skus },
      product: { storeId },
    },
  });

  if (existingVariant) {
    return c.json(
      { error: `SKU '${existingVariant.sku}' sudah digunakan pada produk lain` },
      400
    );
  }

  // Get default store location
  const location = await prisma.location.findFirst({
    where: { storeId, isActive: true },
  });

  const product = await prisma.$transaction(async (tx) => {
    const createdProduct = await tx.product.create({
      data: {
        storeId,
        name: body.name,
        brand: body.brand,
        categoryId: body.categoryId,
        description: body.description,
      },
    });

    for (const v of body.variants) {
      const createdVariant = await tx.productVariant.create({
        data: {
          productId: createdProduct.id,
          sku: v.sku,
          barcode: v.barcode,
          color: v.color,
          size: v.size,
          unit: v.unit,
          referenceSellingPrice: v.referenceSellingPrice,
          minimumStock: v.minimumStock,
        },
      });

      // Initialize zero stock balance if default location exists
      if (location) {
        await tx.stockBalance.create({
          data: {
            storeId,
            locationId: location.id,
            variantId: createdVariant.id,
            quantityOnHand: 0,
            averageCost: 0,
          },
        });
      }
    }

    return tx.product.findUnique({
      where: { id: createdProduct.id },
      include: {
        category: true,
        variants: {
          include: { stockBalances: true },
        },
      },
    });
  });

  return c.json({ data: product }, 201);
});

// Find variant by barcode
productsRouter.get("/variants/by-barcode/:barcode", async (c) => {
  const storeId = c.get("storeId");
  const barcode = c.req.param("barcode");

  const variant = await prisma.productVariant.findFirst({
    where: {
      barcode,
      isActive: true,
      product: { storeId },
    },
    include: {
      product: {
        include: { category: true },
      },
      stockBalances: true,
    },
  });

  if (!variant) {
    return c.json({ error: "Varian produk dengan barcode ini tidak ditemukan" }, 404);
  }

  return c.json({ data: variant });
});
