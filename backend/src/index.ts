import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { authRouter } from "./modules/auth.js";
import { productsRouter } from "./modules/products.js";
import { suppliersRouter } from "./modules/suppliers.js";
import { categoriesRouter } from "./modules/categories.js";
import { inventoryRouter } from "./modules/inventory.js";
import { invoicesRouter } from "./modules/invoices.js";
import { receiptsRouter } from "./modules/receipts.js";
import { stockChecksRouter } from "./modules/stock_checks.js";
import { join } from "path";

const app = new Hono();

// Global Middlewares
app.use("*", logger());
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  })
);

// Health check
app.get("/health", (c) => {
  return c.json({
    status: "ok",
    app: "SUSILAWATI TOKO API",
    time: new Date().toISOString(),
  });
});

// Static uploads serving (pure native Bun)
app.get("/uploads/:filename", async (c) => {
  const filename = c.req.param("filename");
  const file = Bun.file(join("./uploads", filename));
  if (!(await file.exists())) return c.notFound();
  return new Response(file);
});

// API v1 routes
app.route("/api/v1/auth", authRouter);
app.route("/api/v1/products", productsRouter);
app.route("/api/v1/suppliers", suppliersRouter);
app.route("/api/v1/categories", categoriesRouter);
app.route("/api/v1/inventory", inventoryRouter);
app.route("/api/v1/invoices", invoicesRouter);
app.route("/api/v1/receipts", receiptsRouter);
app.route("/api/v1/stock-checks", stockChecksRouter);

// Global Error Handler
app.onError((err, c) => {
  console.error("Unhandled error:", err);
  return c.json(
    {
      error: err.message || "Terjadi kesalahan internal server",
    },
    500
  );
});

// 404 Handler
app.notFound((c) => {
  return c.json({ error: "Endpoint tidak ditemukan" }, 404);
});

const port = Number(process.env.PORT) || 3000;
console.log(`🚀 SUSILAWATI TOKO API berjalan di port ${port}`);

export default {
  port,
  fetch: app.fetch,
};
