-- CreateEnum
CREATE TYPE "Role" AS ENUM ('OWNER', 'STAFF');

-- CreateEnum
CREATE TYPE "MovementType" AS ENUM ('INITIAL', 'GOODS_RECEIPT', 'STOCK_ADJUSTMENT_IN', 'STOCK_ADJUSTMENT_OUT', 'DAMAGED');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('DRAFT', 'IMAGE_UPLOADED', 'PROCESSING', 'NEEDS_REVIEW', 'VERIFIED', 'SCHEDULED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CLOSED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ScheduleStatus" AS ENUM ('SCHEDULED', 'IN_TRANSIT', 'LATE', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED', 'CLOSED');

-- CreateEnum
CREATE TYPE "ReceiptStatus" AS ENUM ('DRAFT', 'CONFIRMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "StockCheckStatus" AS ENUM ('DRAFT', 'IN_PROGRESS', 'SUBMITTED', 'APPROVED', 'REJECTED', 'APPLIED');

-- CreateTable
CREATE TABLE "stores" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL DEFAULT 'SUSILAWATI TOKO',
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    "currency" TEXT NOT NULL DEFAULT 'IDR',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "locations" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "name" TEXT NOT NULL DEFAULT 'Gudang Utama',
    "type" TEXT NOT NULL DEFAULT 'WAREHOUSE',
    "address" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'STAFF',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "suppliers" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "email" TEXT,
    "address" TEXT,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_categories" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "category_id" TEXT,
    "brand" TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "image_key" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_variants" (
    "id" TEXT NOT NULL,
    "product_id" TEXT NOT NULL,
    "sku" TEXT NOT NULL,
    "barcode" TEXT,
    "color" TEXT,
    "size" TEXT,
    "unit" TEXT NOT NULL DEFAULT 'pcs',
    "reference_selling_price" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "minimum_stock" INTEGER NOT NULL DEFAULT 5,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "product_variants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_balances" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "variant_id" TEXT NOT NULL,
    "quantity_on_hand" INTEGER NOT NULL DEFAULT 0,
    "average_cost" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "version" INTEGER NOT NULL DEFAULT 1,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stock_balances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_movements" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "variant_id" TEXT NOT NULL,
    "type" "MovementType" NOT NULL,
    "quantity_delta" INTEGER NOT NULL,
    "unit_cost" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "balance_after" INTEGER NOT NULL,
    "reference_type" TEXT,
    "reference_id" TEXT,
    "notes" TEXT,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "supplier_id" TEXT,
    "internal_number" TEXT NOT NULL,
    "supplier_invoice_number" TEXT,
    "invoice_date" TIMESTAMP(3),
    "currency" TEXT NOT NULL DEFAULT 'IDR',
    "subtotal" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "discount_total" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "grand_total" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "status" "InvoiceStatus" NOT NULL DEFAULT 'DRAFT',
    "verified_by" TEXT,
    "verified_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_images" (
    "id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "storage_key" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "page_number" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoice_items" (
    "id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "variant_id" TEXT,
    "raw_name" TEXT NOT NULL,
    "raw_code" TEXT,
    "quantity" DECIMAL(10,2) NOT NULL DEFAULT 1,
    "unit" TEXT NOT NULL DEFAULT 'pcs',
    "conversion_factor" DECIMAL(10,2) NOT NULL DEFAULT 1,
    "unit_cost" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "discount" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "line_total" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "match_status" TEXT NOT NULL DEFAULT 'UNMATCHED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "incoming_schedules" (
    "id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "expected_date" TIMESTAMP(3) NOT NULL,
    "status" "ScheduleStatus" NOT NULL DEFAULT 'SCHEDULED',
    "pic_user_id" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "incoming_schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goods_receipts" (
    "id" TEXT NOT NULL,
    "schedule_id" TEXT NOT NULL,
    "receipt_number" TEXT NOT NULL,
    "received_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "ReceiptStatus" NOT NULL DEFAULT 'DRAFT',
    "received_by" TEXT,
    "confirmed_at" TIMESTAMP(3),
    "idempotency_key" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "goods_receipts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goods_receipt_items" (
    "id" TEXT NOT NULL,
    "goods_receipt_id" TEXT NOT NULL,
    "invoice_item_id" TEXT,
    "variant_id" TEXT NOT NULL,
    "expected_quantity" INTEGER NOT NULL DEFAULT 0,
    "received_quantity" INTEGER NOT NULL DEFAULT 0,
    "damaged_quantity" INTEGER NOT NULL DEFAULT 0,
    "short_quantity" INTEGER NOT NULL DEFAULT 0,
    "unit_cost" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "notes" TEXT,

    CONSTRAINT "goods_receipt_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_checks" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "status" "StockCheckStatus" NOT NULL DEFAULT 'DRAFT',
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "submitted_at" TIMESTAMP(3),
    "approved_at" TIMESTAMP(3),
    "created_by" TEXT NOT NULL,
    "approved_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stock_checks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_check_items" (
    "id" TEXT NOT NULL,
    "stock_check_id" TEXT NOT NULL,
    "variant_id" TEXT NOT NULL,
    "system_quantity_snapshot" INTEGER NOT NULL,
    "physical_quantity" INTEGER NOT NULL,
    "difference" INTEGER NOT NULL DEFAULT 0,
    "reason" TEXT,
    "evidence_key" TEXT,

    CONSTRAINT "stock_check_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "store_id" TEXT NOT NULL,
    "actor_user_id" TEXT,
    "action" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "before_data" JSONB,
    "after_data" JSONB,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "product_categories_store_id_name_key" ON "product_categories"("store_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "product_variants_sku_key" ON "product_variants"("sku");

-- CreateIndex
CREATE UNIQUE INDEX "product_variants_barcode_key" ON "product_variants"("barcode");

-- CreateIndex
CREATE UNIQUE INDEX "stock_balances_location_id_variant_id_key" ON "stock_balances"("location_id", "variant_id");

-- CreateIndex
CREATE INDEX "stock_movements_variant_id_created_at_idx" ON "stock_movements"("variant_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_internal_number_key" ON "invoices"("internal_number");

-- CreateIndex
CREATE UNIQUE INDEX "goods_receipts_receipt_number_key" ON "goods_receipts"("receipt_number");

-- CreateIndex
CREATE UNIQUE INDEX "goods_receipts_idempotency_key_key" ON "goods_receipts"("idempotency_key");

-- AddForeignKey
ALTER TABLE "locations" ADD CONSTRAINT "locations_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_categories" ADD CONSTRAINT "product_categories_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "product_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_variants" ADD CONSTRAINT "product_variants_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_balances" ADD CONSTRAINT "stock_balances_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_balances" ADD CONSTRAINT "stock_balances_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_balances" ADD CONSTRAINT "stock_balances_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "suppliers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_images" ADD CONSTRAINT "invoice_images_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_items" ADD CONSTRAINT "invoice_items_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incoming_schedules" ADD CONSTRAINT "incoming_schedules_invoice_id_fkey" FOREIGN KEY ("invoice_id") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incoming_schedules" ADD CONSTRAINT "incoming_schedules_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incoming_schedules" ADD CONSTRAINT "incoming_schedules_pic_user_id_fkey" FOREIGN KEY ("pic_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goods_receipts" ADD CONSTRAINT "goods_receipts_schedule_id_fkey" FOREIGN KEY ("schedule_id") REFERENCES "incoming_schedules"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goods_receipt_items" ADD CONSTRAINT "goods_receipt_items_goods_receipt_id_fkey" FOREIGN KEY ("goods_receipt_id") REFERENCES "goods_receipts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goods_receipt_items" ADD CONSTRAINT "goods_receipt_items_invoice_item_id_fkey" FOREIGN KEY ("invoice_item_id") REFERENCES "invoice_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goods_receipt_items" ADD CONSTRAINT "goods_receipt_items_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_checks" ADD CONSTRAINT "stock_checks_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_checks" ADD CONSTRAINT "stock_checks_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_check_items" ADD CONSTRAINT "stock_check_items_stock_check_id_fkey" FOREIGN KEY ("stock_check_id") REFERENCES "stock_checks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_check_items" ADD CONSTRAINT "stock_check_items_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "product_variants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "stores"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
