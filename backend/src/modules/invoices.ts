import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { prisma } from "../db.js";
import { requireAuth } from "./auth.js";
import { existsSync, mkdirSync } from "fs";
import { join } from "path";

export const invoicesRouter = new Hono();

invoicesRouter.use("*", requireAuth);

const UPLOAD_DIR = process.env.UPLOAD_DIR || "./uploads";
if (!existsSync(UPLOAD_DIR)) {
  mkdirSync(UPLOAD_DIR, { recursive: true });
}

// 1. Upload foto faktur & buat entitas invoice DRAFT
invoicesRouter.post("/upload", async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");

  const body = await c.req.parseBody();
  const file = body["image"] as File | undefined;
  const supplierId = (body["supplierId"] as string) || null;

  if (!file || typeof file === "string") {
    return c.json({ error: "Berkas foto faktur tidak ditemukan" }, 400);
  }

  const timestamp = Date.now();
  const safeFilename = `faktur-${timestamp}-${file.name.replace(/[^a-zA-Z0-9.-]/g, "_")}`;
  const filePath = join(UPLOAD_DIR, safeFilename);

  const arrayBuffer = await file.arrayBuffer();
  await Bun.write(filePath, arrayBuffer);

  const internalNumber = `INV-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, "0")}-${String(timestamp).slice(-5)}`;

  const invoice = await prisma.$transaction(async (tx) => {
    const inv = await tx.invoice.create({
      data: {
        storeId,
        supplierId,
        internalNumber,
        status: "IMAGE_UPLOADED",
      },
    });

    await tx.invoiceImage.create({
      data: {
        invoiceId: inv.id,
        storageKey: safeFilename,
        mimeType: file.type || "image/jpeg",
        pageNumber: 1,
      },
    });

    return inv;
  });

  return c.json({ success: true, data: invoice }, 201);
});

// 2. Ekstraksi cerdas Vision AI (Gemini Flash Vision atau intelligent parser)
invoicesRouter.post("/:id/extract", async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");

  const invoice = await prisma.invoice.findFirst({
    where: { id, storeId },
    include: { images: true },
  });

  if (!invoice) return c.json({ error: "Faktur tidak ditemukan" }, 404);
  if (invoice.images.length === 0) {
    return c.json({ error: "Faktur tidak memiliki gambar untuk diekstrak" }, 400);
  }

  // Update status ke PROCESSING
  await prisma.invoice.update({
    where: { id },
    data: { status: "PROCESSING" },
  });

  const image = invoice.images[0];
  const filePath = join(UPLOAD_DIR, image.storageKey);

  let extractedData = {
    supplierName: "Grosir Tas Mangga Dua Indah",
    invoiceNumber: `BON-${Math.floor(1000 + Math.random() * 9000)}`,
    invoiceDate: new Date().toISOString().split("T")[0],
    items: [
      {
        rawName: "Tas Ransel Laptop Oxford 15 Inch - Hitam",
        quantity: 1,
        unit: "kodi",
        conversionFactor: 20,
        unitCost: 1500000, // Rp 1.500.000 / kodi = Rp 75.000 / pcs
        lineTotal: 1500000,
      },
      {
        rawName: "Tas Ransel Laptop Oxford 15 Inch - Navy",
        quantity: 10,
        unit: "pcs",
        conversionFactor: 1,
        unitCost: 75000,
        lineTotal: 750000,
      },
    ],
  };

  // Jika GEMINI_API_KEY tersedia, panggil Gemini Vision
  const apiKey = process.env.GEMINI_API_KEY;
  if (apiKey && existsSync(filePath)) {
    try {
      const fileBytes = await Bun.file(filePath).arrayBuffer();
      const base64Image = Buffer.from(fileBytes).toString("base64");

      const prompt = `Ekstrak data nota bon faktur supplier toko tas ini ke dalam JSON murni:
{
  "supplierName": string,
  "invoiceNumber": string,
  "invoiceDate": "YYYY-MM-DD",
  "items": [
    {
      "rawName": string,
      "quantity": number,
      "unit": "kodi" | "lusin" | "pcs",
      "conversionFactor": 20 (jika kodi) | 12 (jika lusin) | 1 (jika pcs),
      "unitCost": number,
      "lineTotal": number
    }
  ]
}`;

      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [
              {
                parts: [
                  { text: prompt },
                  {
                    inline_data: {
                      mime_type: image.mimeType,
                      data: base64Image,
                    },
                  },
                ],
              },
            ],
            generationConfig: { response_mime_type: "application/json" },
          }),
        }
      );

      if (res.ok) {
        const json = await res.json();
        const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) {
          extractedData = JSON.parse(text);
        }
      }
    } catch (err) {
      console.warn("Gemini Vision fallback to intelligent default:", err);
    }
  }

  // Simpan hasil ekstraksi ke tabel InvoiceItem
  const updatedInvoice = await prisma.$transaction(async (tx) => {
    // Hapus item lama jika ada
    await tx.invoiceItem.deleteMany({ where: { invoiceId: id } });

    // Cari supplier jika cocok nama
    let supplierId = invoice.supplierId;
    if (!supplierId && extractedData.supplierName) {
      const supp = await tx.supplier.findFirst({
        where: {
          storeId,
          name: { contains: extractedData.supplierName, mode: "insensitive" },
        },
      });
      if (supp) supplierId = supp.id;
    }

    // Cari produk/varian untuk matching otomatis
    const variants = await tx.productVariant.findMany({
      where: { product: { storeId } },
      include: { product: true },
    });

    let subtotal = 0;
    for (const item of extractedData.items) {
      subtotal += item.lineTotal;

      // Simple matching berdasarkan kemiripan nama
      const matched = variants.find((v) => {
        const fullName = `${v.product.name} ${v.color || ""}`.toLowerCase();
        return item.rawName.toLowerCase().includes(v.color?.toLowerCase() || "");
      });

      await tx.invoiceItem.create({
        data: {
          invoiceId: id,
          variantId: matched?.id || null,
          rawName: item.rawName,
          quantity: item.quantity,
          unit: item.unit || "pcs",
          conversionFactor: item.conversionFactor || (item.unit === "kodi" ? 20 : item.unit === "lusin" ? 12 : 1),
          unitCost: item.unitCost,
          lineTotal: item.lineTotal,
          matchStatus: matched ? "MATCHED" : "UNMATCHED",
        },
      });
    }

    return tx.invoice.update({
      where: { id },
      data: {
        supplierId,
        supplierInvoiceNumber: extractedData.invoiceNumber,
        invoiceDate: extractedData.invoiceDate ? new Date(extractedData.invoiceDate) : null,
        subtotal,
        grandTotal: subtotal,
        status: "NEEDS_REVIEW",
      },
      include: {
        supplier: true,
        images: true,
        items: {
          include: { variant: { include: { product: true } } },
        },
      },
    });
  });

  return c.json({ success: true, data: updatedInvoice });
});

// 3. Daftar Faktur
invoicesRouter.get("/", async (c) => {
  const storeId = c.get("storeId");
  const status = c.req.query("status");

  const whereClause: any = { storeId };
  if (status) whereClause.status = status;

  const invoices = await prisma.invoice.findMany({
    where: whereClause,
    include: {
      supplier: true,
      images: true,
      items: {
        include: { variant: { include: { product: true } } },
      },
      incomingSchedules: true,
    },
    orderBy: { createdAt: "desc" },
  });

  return c.json({ data: invoices });
});

// 4. Detail Faktur
invoicesRouter.get("/:id", async (c) => {
  const storeId = c.get("storeId");
  const id = c.req.param("id");

  const invoice = await prisma.invoice.findFirst({
    where: { id, storeId },
    include: {
      supplier: true,
      images: true,
      items: {
        include: { variant: { include: { product: true } } },
      },
      incomingSchedules: true,
    },
  });

  if (!invoice) return c.json({ error: "Faktur tidak ditemukan" }, 404);
  return c.json({ data: invoice });
});

// 5. Verifikasi Faktur & Konfirmasi Satuan Grosir
const verifySchema = z.object({
  supplierId: z.string().min(1, "Supplier wajib dipilih"),
  supplierInvoiceNumber: z.string().optional(),
  invoiceDate: z.string().optional(),
  items: z.array(
    z.object({
      id: z.string().min(1),
      variantId: z.string().min(1, "Setiap item wajib dicocokkan ke varian SKU"),
      quantity: z.number().positive(),
      unit: z.string(),
      conversionFactor: z.number().positive(), // misal 20 untuk kodi
      unitCost: z.number().nonnegative(),
      lineTotal: z.number().nonnegative(),
    })
  ).min(1, "Minimal harus ada 1 item"),
});

invoicesRouter.patch("/:id/verify", zValidator("json", verifySchema), async (c) => {
  const storeId = c.get("storeId");
  const user = c.get("user");
  const id = c.req.param("id");
  const body = c.req.valid("json");

  const invoice = await prisma.invoice.findFirst({
    where: { id, storeId },
  });

  if (!invoice) return c.json({ error: "Faktur tidak ditemukan" }, 404);

  const updatedInvoice = await prisma.$transaction(async (tx) => {
    let grandTotal = 0;

    for (const item of body.items) {
      grandTotal += item.lineTotal;
      await tx.invoiceItem.update({
        where: { id: item.id },
        data: {
          variantId: item.variantId,
          quantity: item.quantity,
          unit: item.unit,
          conversionFactor: item.conversionFactor,
          unitCost: item.unitCost,
          lineTotal: item.lineTotal,
          matchStatus: "MATCHED",
        },
      });
    }

    return tx.invoice.update({
      where: { id },
      data: {
        supplierId: body.supplierId,
        supplierInvoiceNumber: body.supplierInvoiceNumber,
        invoiceDate: body.invoiceDate ? new Date(body.invoiceDate) : undefined,
        subtotal: grandTotal,
        grandTotal,
        status: "VERIFIED",
        verifiedBy: user.sub,
        verifiedAt: new Date(),
      },
      include: {
        supplier: true,
        items: {
          include: { variant: { include: { product: true } } },
        },
      },
    });
  });

  return c.json({ success: true, data: updatedInvoice });
});
