import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";

export const categoriesRouter = new Hono();

categoriesRouter.use("*", requireAuth);

const categorySchema = z.object({
  name: z.string().min(1, "Nama kategori wajib diisi"),
});

categoriesRouter.get("/", async (c) => {
  const storeId = c.get("storeId");
  const categories = await prisma.productCategory.findMany({
    where: { storeId },
    orderBy: { name: "asc" },
  });
  return c.json({ data: categories });
});

categoriesRouter.post("/", zValidator("json", categorySchema), async (c) => {
  const storeId = c.get("storeId");
  const { name } = c.req.valid("json");

  const existing = await prisma.productCategory.findFirst({
    where: { storeId, name: { equals: name, mode: "insensitive" } },
  });

  if (existing) {
    return c.json({ error: "Kategori dengan nama ini sudah ada" }, 400);
  }

  const category = await prisma.productCategory.create({
    data: { storeId, name },
  });

  return c.json({ data: category }, 201);
});
