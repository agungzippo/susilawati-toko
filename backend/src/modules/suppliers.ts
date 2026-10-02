import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";

export const suppliersRouter = new Hono();

suppliersRouter.use("*", requireAuth);

const supplierSchema = z.object({
  name: z.string().min(1, "Nama supplier wajib diisi"),
  phone: z.string().optional(),
  email: z.string().email().optional().or(z.literal("")),
  address: z.string().optional(),
  notes: z.string().optional(),
});

// List suppliers
suppliersRouter.get("/", async (c) => {
  const storeId = c.get("storeId");
  const suppliers = await prisma.supplier.findMany({
    where: { storeId, isActive: true },
    orderBy: { name: "asc" },
  });
  return c.json({ data: suppliers });
});

// Create supplier
suppliersRouter.post("/", zValidator("json", supplierSchema), async (c) => {
  const storeId = c.get("storeId");
  const body = c.req.valid("json");

  const supplier = await prisma.supplier.create({
    data: {
      storeId,
      name: body.name,
      phone: body.phone,
      email: body.email || null,
      address: body.address,
      notes: body.notes,
    },
  });

  return c.json({ data: supplier }, 201);
});

// Update supplier
suppliersRouter.patch("/:id", zValidator("json", supplierSchema.partial()), async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");
  const body = c.req.valid("json");

  const existing = await prisma.supplier.findFirst({
    where: { id, storeId },
  });

  if (!existing) {
    return c.json({ error: "Supplier tidak ditemukan" }, 404);
  }

  const updated = await prisma.supplier.update({
    where: { id },
    data: {
      ...body,
      email: body.email === "" ? null : body.email,
    },
  });

  return c.json({ data: updated });
});
