import { prisma } from "./db.js";

async function main() {
  console.log("🌱 Memulai seeding SUSILAWATI TOKO...");

  // 1. Toko
  const store = await prisma.store.upsert({
    where: { id: "store-susilawati-001" },
    create: {
      id: "store-susilawati-001",
      name: "SUSILAWATI TOKO",
      timezone: "Asia/Jakarta",
      currency: "IDR",
    },
    update: {
      name: "SUSILAWATI TOKO",
    },
  });

  // 2. Lokasi Gudang
  const location = await prisma.location.upsert({
    where: { id: "loc-gudang-utama-001" },
    create: {
      id: "loc-gudang-utama-001",
      storeId: store.id,
      name: "Gudang Utama Toko",
      type: "WAREHOUSE",
      address: "Lantai 1 Area Belakang Toko",
    },
    update: {},
  });

  // 3. Pengguna
  const ownerPasswordHash = await Bun.password.hash("admin123", { algorithm: "argon2id" });
  const staffPasswordHash = await Bun.password.hash("staf123", { algorithm: "argon2id" });

  const owner = await prisma.user.upsert({
    where: { email: "owner@susilawati.com" },
    create: {
      storeId: store.id,
      name: "Ibu Susilawati",
      email: "owner@susilawati.com",
      passwordHash: ownerPasswordHash,
      role: "OWNER",
    },
    update: { passwordHash: ownerPasswordHash },
  });

  await prisma.user.upsert({
    where: { email: "staf@susilawati.com" },
    create: {
      storeId: store.id,
      name: "Staf Toko",
      email: "staf@susilawati.com",
      passwordHash: staffPasswordHash,
      role: "STAFF",
    },
    update: { passwordHash: staffPasswordHash },
  });

  // 4. Kategori Produk
  const catRansel = await prisma.productCategory.upsert({
    where: { storeId_name: { storeId: store.id, name: "Tas Ransel" } },
    create: { storeId: store.id, name: "Tas Ransel" },
    update: {},
  });

  const catSelempang = await prisma.productCategory.upsert({
    where: { storeId_name: { storeId: store.id, name: "Tas Selempang" } },
    create: { storeId: store.id, name: "Tas Selempang" },
    update: {},
  });

  await prisma.productCategory.upsert({
    where: { storeId_name: { storeId: store.id, name: "Totebag" } },
    create: { storeId: store.id, name: "Totebag" },
    update: {},
  });

  // 5. Supplier
  const supplierManggaDua = await prisma.supplier.create({
    data: {
      storeId: store.id,
      name: "Grosir Tas Mangga Dua Indah",
      phone: "081234567890",
      address: "Pasar Pagi Mangga Dua Lt. 2 Blok B No. 15",
      notes: "Supplier utama tas ransel dan sling bag",
    },
  });

  // 6. Produk & Varian Contoh
  const p1 = await prisma.product.create({
    data: {
      storeId: store.id,
      categoryId: catRansel.id,
      brand: "Polo Paris",
      name: "Tas Ransel Laptop Oxford 15 Inch",
      description: "Bahan waterproof, kompartemen laptop busa tebal",
      variants: {
        create: [
          {
            sku: "TR-OXF-BLK",
            barcode: "899123450001",
            color: "Hitam",
            size: "15 Inch",
            referenceSellingPrice: 135000,
            minimumStock: 5,
          },
          {
            sku: "TR-OXF-NVY",
            barcode: "899123450002",
            color: "Navy",
            size: "15 Inch",
            referenceSellingPrice: 135000,
            minimumStock: 5,
          },
          {
            sku: "TR-OXF-GRY",
            barcode: "899123450003",
            color: "Abu-abu",
            size: "15 Inch",
            referenceSellingPrice: 135000,
            minimumStock: 5,
          },
        ],
      },
    },
    include: { variants: true },
  });

  // Isi stok awal untuk varian
  const initialStocks = [
    { variant: p1.variants[0], qty: 15, cost: 75000 },
    { variant: p1.variants[1], qty: 8, cost: 75000 },
    { variant: p1.variants[2], qty: 2, cost: 75000 }, // Stok menipis
  ];

  for (const item of initialStocks) {
    await prisma.stockBalance.create({
      data: {
        storeId: store.id,
        locationId: location.id,
        variantId: item.variant.id,
        quantityOnHand: item.qty,
        averageCost: item.cost,
      },
    });

    await prisma.stockMovement.create({
      data: {
        storeId: store.id,
        locationId: location.id,
        variantId: item.variant.id,
        type: "INITIAL",
        quantityDelta: item.qty,
        unitCost: item.cost,
        balanceAfter: item.qty,
        referenceType: "INITIAL_STOCK",
        notes: "Saldo stok pembukaan toko",
        createdBy: owner.id,
      },
    });
  }

  console.log("✅ Seeding SUSILAWATI TOKO selesai!");
  console.log(`- Toko: ${store.name}`);
  console.log(`- Login Owner: ${owner.email} / admin123`);
  console.log(`- Login Staf: staf@susilawati.com / staf123`);
  console.log(`- Supplier: ${supplierManggaDua.name}`);
  console.log(`- Produk terdaftar: ${p1.name} (3 varian)`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
