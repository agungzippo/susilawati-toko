import { prisma } from "./db.js";

async function main() {
  console.log("🌱 Menyiapkan data SUSILAWATI TOKO sesuai desain...");

  // 1. Toko
  const store = await prisma.store.upsert({
    where: { id: "store-susilawati-001" },
    create: {
      id: "store-susilawati-001",
      name: "susilawati toko .",
      timezone: "Asia/Jakarta",
      currency: "IDR",
    },
    update: {
      name: "susilawati toko .",
    },
  });

  // 2. Lokasi Gudang
  const location = await prisma.location.upsert({
    where: { id: "loc-gudang-utama-001" },
    create: {
      id: "loc-gudang-utama-001",
      storeId: store.id,
      name: "Rak A1",
      type: "WAREHOUSE",
      address: "Lantai 1 Area Toko",
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
  const categories = ["Tas Tote", "Shoulder Bag", "Backpack", "Tas Selempang", "Tas Ransel"];
  const catMap: Record<string, string> = {};
  for (const catName of categories) {
    const cat = await prisma.productCategory.upsert({
      where: { storeId_name: { storeId: store.id, name: catName } },
      create: { storeId: store.id, name: catName },
      update: {},
    });
    catMap[catName] = cat.id;
  }

  // 5. Supplier
  const s1 = await prisma.supplier.upsert({
    where: { id: "supp-001" },
    create: {
      id: "supp-001",
      storeId: store.id,
      name: "PT. Maju Jaya",
      phone: "0812 3456 7890",
      email: "mjujaya@supplier.co.id",
      address: "Sentra Tas Mangga Dua",
    },
    update: {},
  });

  const s2 = await prisma.supplier.upsert({
    where: { id: "supp-002" },
    create: {
      id: "supp-002",
      storeId: store.id,
      name: "CV. Sejahtera Abadi",
      phone: "0813 2222 3333",
      email: "sejahtera@supplier.co.id",
      address: "Kawasan Industri Pulo Gadung",
    },
    update: {},
  });

  const s3 = await prisma.supplier.upsert({
    where: { id: "supp-003" },
    create: {
      id: "supp-003",
      storeId: store.id,
      name: "UD. Lestari",
      phone: "0817 8888 9999",
      email: "lestari@supplier.co.id",
      address: "Pusat Grosir Pasar Baru",
    },
    update: {},
  });

  // 6. Produk Sesuai Mockup UI
  const mockProducts = [
    {
      name: "Tas Tote Minimalis",
      category: "Tas Tote",
      sku: "TT001",
      barcode: "89920250001",
      color: "Beige Cream",
      size: "Medium",
      selling: 285000,
      cost: 185000,
      stock: 15,
      supplierId: s1.id,
    },
    {
      name: "Shoulder Bag",
      category: "Shoulder Bag",
      sku: "SB002",
      barcode: "89920250002",
      color: "Classic Black",
      size: "One Size",
      selling: 260000,
      cost: 160000,
      stock: 8,
      supplierId: s2.id,
    },
    {
      name: "Backpack",
      category: "Backpack",
      sku: "BP003",
      barcode: "89920250003",
      color: "Matte Black",
      size: "Large",
      selling: 350000,
      cost: 230000,
      stock: 5,
      supplierId: s1.id,
    },
    {
      name: "Tas Selempang",
      category: "Tas Selempang",
      sku: "SL004",
      barcode: "89920250004",
      color: "Olive Green",
      size: "Compact",
      selling: 220000,
      cost: 140000,
      stock: 12,
      supplierId: s3.id,
    },
    {
      name: "Tas Ransel",
      category: "Tas Ransel",
      sku: "RS005",
      barcode: "89920250005",
      color: "Caramel Brown",
      size: "Large",
      selling: 420000,
      cost: 280000,
      stock: 6,
      supplierId: s1.id,
    },
  ];

  for (const item of mockProducts) {
    let p = await prisma.product.findFirst({
      where: { storeId: store.id, name: item.name },
      include: { variants: true },
    });

    if (!p) {
      p = await prisma.product.create({
        data: {
          storeId: store.id,
          categoryId: catMap[item.category],
          brand: "Susilawati Exclusive",
          name: item.name,
          description: `Koleksi tas ${item.name} dengan material kulit sintetis premium`,
          variants: {
            create: [
              {
                sku: item.sku,
                barcode: item.barcode,
                color: item.color,
                size: item.size,
                referenceSellingPrice: item.selling,
                minimumStock: 3,
              },
            ],
          },
        },
        include: { variants: true },
      });
    }

    const variant = p.variants[0];

    await prisma.stockBalance.upsert({
      where: {
        locationId_variantId: {
          locationId: location.id,
          variantId: variant.id,
        },
      },
      create: {
        storeId: store.id,
        locationId: location.id,
        variantId: variant.id,
        quantityOnHand: item.stock,
        averageCost: item.cost,
      },
      update: {
        quantityOnHand: item.stock,
        averageCost: item.cost,
      },
    });

    await prisma.stockMovement.create({
      data: {
        storeId: store.id,
        locationId: location.id,
        variantId: variant.id,
        type: "INITIAL",
        quantityDelta: item.stock,
        unitCost: item.cost,
        balanceAfter: item.stock,
        referenceType: "INITIAL_STOCK",
        notes: "Stok awal etalase toko",
        createdBy: owner.id,
      },
    });
  }

  // Buat contoh transaksi terbaru
  // 1. Barang Masuk
  const pSelempang = await prisma.product.findFirst({ where: { name: "Tas Selempang" }, include: { variants: true } });
  if (pSelempang) {
    await prisma.stockMovement.create({
      data: {
        storeId: store.id,
        locationId: location.id,
        variantId: pSelempang.variants[0].id,
        type: "GOODS_RECEIPT",
        quantityDelta: 3,
        unitCost: 150000,
        balanceAfter: 12,
        referenceType: "GOODS_RECEIPT",
        notes: "Barang Masuk dari UD. Lestari",
        createdBy: owner.id,
      },
    });
  }

  // 2. Barang Keluar
  const pTote = await prisma.product.findFirst({ where: { name: "Tas Tote Minimalis" }, include: { variants: true } });
  if (pTote) {
    await prisma.stockMovement.create({
      data: {
        storeId: store.id,
        locationId: location.id,
        variantId: pTote.variants[0].id,
        type: "STOCK_ADJUSTMENT_OUT",
        quantityDelta: -1,
        unitCost: 185000,
        balanceAfter: 15,
        referenceType: "STOCK_OUT",
        notes: "Barang Keluar ke Pelanggan Toko",
        createdBy: owner.id,
      },
    });
  }

  console.log("✅ Seeding selesai! Data katalog sesuai mockup UI telah siap.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
