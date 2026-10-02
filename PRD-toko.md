# Product Requirements Document (PRD)

## SUSILAWATI TOKO - Sistem Monitoring Stok

| Informasi | Nilai |
|---|---|
| Nama toko | SUSILAWATI TOKO |
| Nama produk | Sistem Monitoring Stok SUSILAWATI TOKO |
| Dokumen | Product Requirements Document |
| Versi | 1.1 |
| Status | Siap Implementasi (Ponytail Lean MVP) |
| Platform MVP | Flutter Android (ponsel dan tablet) |
| Backend | Bun + Hono |
| ORM | Prisma ORM |
| Database | PostgreSQL |
| Ekstraksi Faktur | Vision AI (Gemini Flash Vision) |
| Infrastruktur lokal | Docker Compose (PostgreSQL) |
| Tanggal | 2 Oktober 2026 |

---

## 1. Ringkasan Eksekutif

Sistem Monitoring Stok SUSILAWATI TOKO adalah aplikasi internal berbasis Flutter untuk membantu pemilik dan staf toko tas SUSILAWATI TOKO memantau persediaan barang, memasukkan data barang dari foto bon atau faktur supplier grosir, menjadwalkan barang masuk, mencatat penerimaan barang fisik, melakukan stok opname, dan menghitung nilai modal serta estimasi potensi laba dari stok yang tersedia.

Produk ini bukan toko online, bukan aplikasi kasir/POS, dan tidak menangani pembayaran pelanggan. MVP difokuskan pada kebutuhan operasional harian SUSILAWATI TOKO dengan jumlah pengguna (1-5 orang), satu lokasi toko/gudang utama, dan volume data yang ringkas.

Aplikasi menggunakan pendekatan API-first. Flutter menjadi antarmuka utama pada MVP, sedangkan backend Bun/Hono menyediakan seluruh aturan bisnis. Arsitektur ini memungkinkan dashboard web ditambahkan kemudian tanpa menulis ulang logika inti.

---

## 2. Latar Belakang

Pada tahap awal operasional toko, pencatatan stok sering dilakukan melalui buku, pesan, foto bon, atau spreadsheet. Cara tersebut menimbulkan beberapa masalah:

- Jumlah stok aktual sulit diketahui dengan cepat.
- Produk dengan stok menipis atau habis mudah terlewat.
- Informasi harga beli tersebar di berbagai bon dan faktur.
- Foto faktur tidak terhubung dengan data barang yang diterima.
- Jadwal kedatangan barang tidak terdokumentasi dengan baik.
- Selisih antara barang pada faktur dan barang yang diterima sulit ditelusuri.
- Nilai modal persediaan dan potensi laba harus dihitung manual.
- Tidak tersedia riwayat yang jelas tentang siapa yang mengubah stok.

Aplikasi ini dibangun untuk menjadikan data persediaan sebagai sumber informasi utama yang rapi, mudah diperiksa, dan dapat diaudit.

---

## 3. Tujuan Produk

### 3.1 Tujuan utama

1. Menyediakan informasi jumlah stok per produk dan varian secara cepat.
2. Mempermudah input faktur supplier melalui foto dan OCR.
3. Memastikan hasil OCR diperiksa manusia sebelum memengaruhi data operasional.
4. Mencatat jadwal barang masuk dan realisasi penerimaan barang.
5. Menyediakan proses stok opname dan penanganan selisih stok.
6. Menghitung nilai modal persediaan dan estimasi potensi laba.
7. Menyimpan riwayat perubahan stok dan aktivitas penting.
8. Menyediakan pengalaman mobile yang praktis untuk operasional di toko.

### 3.2 Sasaran keberhasilan awal

Dalam tiga bulan pertama penggunaan:

- Minimal 95% produk aktif tercatat di aplikasi.
- Minimal 90% penerimaan barang dicatat melalui aplikasi.
- Minimal 80% faktur supplier disimpan sebagai foto dan diverifikasi.
- Waktu pencarian informasi stok satu produk kurang dari 10 detik.
- Selisih stok dapat diketahui melalui stok opname berkala.
- Pemilik dapat melihat nilai modal dan potensi laba tanpa perhitungan manual.

### 3.3 Non-goals

MVP tidak bertujuan untuk:

- Menjadi toko online.
- Menyediakan katalog publik.
- Menyediakan keranjang dan checkout.
- Menjadi aplikasi kasir/POS.
- Memproses pembayaran pelanggan.
- Mengelola piutang pelanggan.
- Mengelola transaksi penjualan per pelanggan.
- Terintegrasi dengan marketplace.
- Menggantikan sistem akuntansi penuh.
- Menghasilkan laba aktual tanpa data penjualan.
- Menyediakan dashboard web Remix pada tahap awal.
- Mendukung iOS pada peluncuran awal.

---

## 4. Definisi Laba pada MVP

Karena MVP tidak mencatat transaksi penjualan, aplikasi tidak dapat menghitung laba aktual. Istilah **hasil laba** pada MVP didefinisikan sebagai **estimasi potensi laba persediaan**.

### 4.1 Rumus utama

```text
Modal unit = Harga modal rata-rata tertimbang
Potensi laba unit = Harga jual acuan - Modal unit
Nilai modal stok = Stok tersedia × Modal unit
Nilai jual potensial = Stok tersedia × Harga jual acuan
Potensi laba stok = Nilai jual potensial - Nilai modal stok
Margin potensial (%) = Potensi laba unit / Harga jual acuan × 100%
```

### 4.2 Ketentuan

- Harga jual acuan dimasukkan secara manual pada produk atau varian.
- Harga modal diperbarui ketika barang diterima.
- Metode modal awal menggunakan weighted average/average cost.
- Potensi laba bukan pengakuan pendapatan dan bukan laporan laba rugi.
- Aplikasi harus menampilkan label **Estimasi Potensi Laba**, bukan **Laba Bersih**.
- Produk tanpa harga jual acuan tidak dimasukkan ke total potensi laba dan ditandai sebagai data belum lengkap.
- Produk tanpa harga modal tidak dimasukkan ke total nilai modal dan ditandai untuk diperbaiki.

### 4.3 Fase lanjutan

Laba aktual hanya dapat ditambahkan apabila tersedia salah satu sumber berikut:

- Rekap penjualan harian.
- Impor data penjualan.
- Integrasi sistem POS.
- Integrasi marketplace.

---

## 5. Pengguna dan Hak Akses

### 5.1 Pemilik

Kebutuhan:

- Melihat ringkasan seluruh stok.
- Mengetahui nilai modal dan potensi laba.
- Memantau barang yang akan masuk dan terlambat.
- Menyetujui penyesuaian stok.
- Melihat riwayat aktivitas.
- Mengelola pengguna dan pengaturan toko.

### 5.2 Admin/Staf

Kebutuhan:

- Menambah dan mengubah data produk.
- Mengunggah foto faktur.
- Memeriksa hasil OCR.
- Membuat jadwal barang masuk.
- Menerima barang.
- Melakukan stok opname.

### 5.3 Hak akses awal

| Fitur | Pemilik | Admin/Staf |
|---|---:|---:|
| Melihat dashboard | Ya | Ya |
| Melihat stok | Ya | Ya |
| Mengelola produk | Ya | Ya |
| Mengunggah faktur | Ya | Ya |
| Memverifikasi OCR | Ya | Ya |
| Membuat jadwal barang masuk | Ya | Ya |
| Mencatat penerimaan | Ya | Ya |
| Melakukan stok opname | Ya | Ya |
| Menyetujui penyesuaian stok | Ya | Tidak |
| Mengelola pengguna | Ya | Tidak |
| Melihat audit log | Ya | Terbatas |
| Mengubah pengaturan toko | Ya | Tidak |

MVP menggunakan Role-Based Access Control (RBAC). Hak akses harus diperiksa di backend, bukan hanya disembunyikan pada Flutter.

---

## 6. Asumsi Produk

- MVP digunakan oleh satu toko dan satu lokasi penyimpanan utama.
- Struktur data tetap menyertakan `store_id` dan `location_id` agar siap dikembangkan.
- Pengguna awal maksimal 5 akun.
- Produk dapat memiliki varian warna dan ukuran.
- Satu SKU mewakili satu varian yang dapat dihitung stoknya.
- Bahasa aplikasi adalah Bahasa Indonesia.
- Mata uang adalah Rupiah (IDR).
- Zona waktu operasional adalah Asia/Jakarta.
- Foto faktur dapat berasal dari kamera atau galeri.
- Koneksi internet diperlukan untuk sinkronisasi dan OCR.
- Mode offline penuh tidak termasuk MVP.
- Aplikasi tetap dapat menyimpan draft lokal saat unggahan terganggu.

---

## 7. Ruang Lingkup MVP

### 7.1 Termasuk

1. Autentikasi dan manajemen sesi.
2. Pengguna dan peran.
3. Profil toko dan lokasi.
4. Supplier.
5. Kategori produk.
6. Produk dan varian/SKU.
7. Foto produk.
8. Saldo dan mutasi stok.
9. Peringatan stok minimum.
10. Stok opname.
11. Penyesuaian stok dengan persetujuan.
12. Unggah foto bon/faktur.
13. Pemrosesan OCR secara asynchronous.
14. Verifikasi dan koreksi hasil OCR.
15. Pencocokan item faktur dengan SKU.
16. Jadwal barang masuk.
17. Penerimaan sebagian atau lengkap.
18. Pencatatan barang kurang, lebih, atau rusak.
19. Perhitungan average cost.
20. Nilai modal, nilai jual potensial, dan potensi laba.
21. Dashboard mobile.
22. Pencarian dan filter.
23. Audit log.
24. Ekspor laporan CSV dan PDF sederhana.
25. Backup database dan berkas.

### 7.2 Di luar MVP

- Web dashboard Remix.
- Aplikasi iOS.
- Mode offline penuh dan conflict resolution lintas perangkat.
- Penjualan dan pembayaran.
- Integrasi barcode printer.
- Integrasi marketplace/POS.
- Notifikasi WhatsApp.
- Akuntansi double-entry.
- Prediksi permintaan berbasis AI.
- Multi-cabang aktif.
- Approval bertingkat.

---

## 8. Alur Utama Pengguna

### 8.1 Menambahkan produk secara manual

1. Pengguna membuka menu Produk.
2. Pengguna memilih Tambah Produk.
3. Pengguna mengisi nama, kategori, merek, foto, dan deskripsi.
4. Pengguna menambahkan satu atau lebih varian.
5. Setiap varian memiliki SKU, warna, ukuran, harga jual acuan, dan batas minimum stok.
6. Backend memeriksa keunikan SKU.
7. Produk tersimpan tanpa otomatis menambah stok.

### 8.2 Mengunggah faktur

1. Pengguna membuka menu Faktur.
2. Pengguna memilih Ambil Foto atau Pilih dari Galeri.
3. Pengguna dapat mengunggah satu atau beberapa halaman.
4. Aplikasi melakukan kompresi aman tanpa membuat teks tidak terbaca.
5. File dikirim ke object storage.
6. Backend membuat dokumen faktur berstatus `IMAGE_UPLOADED`.
7. OCR job diproses di background.
8. Status berubah menjadi `NEEDS_REVIEW` ketika hasil tersedia.
9. Pengguna menerima indikator bahwa faktur siap diperiksa.

### 8.3 Memverifikasi hasil OCR

1. Pengguna membuka faktur berstatus Perlu Diperiksa.
2. Aplikasi menampilkan foto dan hasil ekstraksi.
3. Pengguna memeriksa supplier, nomor faktur, tanggal, total, dan item.
4. Setiap item dicocokkan dengan SKU yang sudah ada.
5. Sistem menawarkan kandidat berdasarkan kode dan kemiripan nama.
6. Pengguna dapat memilih SKU, membuat draft produk baru, atau menandai belum dikenali.
7. Pengguna memperbaiki jumlah dan harga jika salah.
8. Sistem memvalidasi subtotal dan total.
9. Pengguna menyimpan hasil verifikasi.
10. Status berubah menjadi `VERIFIED`.
11. Stok belum berubah pada tahap ini.

### 8.4 Menjadwalkan barang masuk

1. Pengguna membuka faktur terverifikasi.
2. Pengguna memasukkan estimasi tanggal kedatangan.
3. Pengguna memilih lokasi tujuan dan penanggung jawab.
4. Sistem membuat jadwal barang masuk.
5. Jadwal muncul pada kalender dan dashboard.
6. Jika melewati tanggal tanpa penerimaan lengkap, status otomatis menjadi Terlambat.

### 8.5 Menerima barang

1. Pengguna membuka jadwal barang masuk.
2. Pengguna memilih Terima Barang.
3. Aplikasi menampilkan jumlah yang diharapkan dan yang sudah diterima.
4. Pengguna mengisi jumlah diterima, rusak, dan kurang untuk setiap SKU.
5. Pengguna dapat melampirkan foto kondisi barang.
6. Backend memvalidasi jumlah.
7. Setelah dikonfirmasi, backend membuat penerimaan dan mutasi stok dalam satu database transaction.
8. Average cost diperbarui.
9. Jika masih ada kekurangan, status menjadi `PARTIALLY_RECEIVED`.
10. Jika seluruh barang terpenuhi atau ditutup manual, status menjadi `RECEIVED` atau `CLOSED`.

### 8.6 Melakukan stok opname

1. Pengguna membuat sesi stok opname.
2. Pengguna memilih lokasi dan cakupan produk.
3. Sistem menyimpan snapshot stok sistem.
4. Pengguna memindai barcode atau mencari SKU.
5. Pengguna memasukkan jumlah fisik.
6. Sistem menampilkan selisih setelah item dihitung.
7. Pengguna memberikan alasan dan bukti untuk selisih.
8. Staf mengirim hasil pemeriksaan.
9. Pemilik menyetujui atau menolak penyesuaian.
10. Jika disetujui, backend membuat mutasi penyesuaian; saldo tidak diedit langsung.

---

## 9. Kebutuhan Fungsional

### FR-001 Autentikasi

- Pengguna dapat login menggunakan email dan kata sandi.
- Pengguna dapat logout dari perangkat aktif.
- Access token berumur pendek.
- Refresh token disimpan secara aman dan dapat dicabut.
- Akun nonaktif tidak dapat membuat sesi baru.
- Percobaan login berulang harus dibatasi.

**Acceptance criteria:**

- Kredensial valid menghasilkan sesi aktif.
- Kredensial salah tidak mengungkap apakah email terdaftar.
- Pengguna nonaktif menerima pesan bahwa akses tidak tersedia.
- Logout mencabut refresh token terkait.

### FR-002 Dashboard

Dashboard menampilkan:

- Total SKU aktif.
- Total unit stok tersedia.
- Jumlah produk stok menipis.
- Jumlah produk habis.
- Nilai modal persediaan.
- Nilai jual potensial.
- Estimasi potensi laba.
- Faktur yang perlu diperiksa.
- Jadwal barang masuk hari ini.
- Jadwal barang terlambat.
- Penerimaan terbaru.
- Selisih stok opname yang menunggu persetujuan.

Filter periode tidak mengubah saldo stok saat ini, tetapi berlaku pada aktivitas dan penerimaan.

### FR-003 Supplier

- Membuat, melihat, mengubah, dan menonaktifkan supplier.
- Menyimpan nama, kontak, alamat, catatan, dan status.
- Supplier yang sudah digunakan tidak boleh dihapus permanen.
- Supplier nonaktif tetap tampil pada riwayat dokumen.

### FR-004 Produk dan varian

- Produk memiliki nama, kategori, merek, deskripsi, foto, dan status.
- Produk dapat memiliki beberapa varian.
- Varian memiliki SKU unik, barcode opsional, warna, ukuran, harga jual acuan, dan minimum stok.
- SKU tidak boleh digunakan ulang pada varian lain.
- Produk yang pernah memiliki mutasi stok tidak boleh dihapus permanen.
- Produk dapat dinonaktifkan.

### FR-005 Stok

- Sistem menyimpan saldo per SKU dan lokasi.
- Saldo stok tidak boleh diubah langsung dari UI.
- Semua perubahan berasal dari mutasi yang valid.
- Jenis mutasi MVP: `INITIAL`, `GOODS_RECEIPT`, `STOCK_ADJUSTMENT_IN`, `STOCK_ADJUSTMENT_OUT`, dan `DAMAGED`.
- Pengguna dapat melihat riwayat mutasi per SKU.
- Sistem menampilkan stok tersedia dan status stok.

### FR-006 Stok awal

- Pemilik dapat membuat sesi input stok awal.
- Satu SKU hanya boleh memiliki satu sumber stok awal per lokasi, kecuali dikoreksi melalui penyesuaian.
- Stok awal harus menyertakan jumlah dan harga modal.
- Konfirmasi stok awal membuat mutasi `INITIAL`.

### FR-007 Stok opname

- Pengguna dapat membuat draft sesi opname.
- Sesi menyimpan lokasi, tanggal, pemeriksa, dan cakupan.
- Item dapat dihitung melalui scan barcode atau pencarian.
- Sistem menyimpan jumlah sistem saat sesi dimulai.
- Selisih harus memiliki alasan jika tidak nol.
- Sesi yang sudah diajukan tidak dapat diubah staf.
- Persetujuan menghasilkan mutasi penyesuaian.

### FR-008 Unggah faktur

- Mendukung JPG, JPEG, PNG, HEIC, dan PDF.
- Maksimal 10 halaman per faktur.
- Maksimal 10 MB per file setelah kompresi.
- File harus divalidasi berdasarkan MIME type dan signature.
- Pengguna dapat mengambil ulang foto.
- Faktur dapat disimpan sebagai draft sebelum diproses.

### FR-009 Ekstraksi Faktur (Vision AI / OCR)

Aplikasi mengekstrak informasi faktur/bon supplier menggunakan Vision AI multimodal (seperti Gemini Flash) atau OCR engine:

- Nomor faktur / nomor nota.
- Nama supplier.
- Tanggal faktur.
- Mata uang.
- Nama/kode item.
- Jumlah dan satuan beli (kodi, lusin, pcs).
- Harga satuan.
- Diskon.
- Subtotal.
- Total.

Ketentuan:

- Pemrosesan asynchronous via background task backend.
- Format bon supplier toko tas fisik umumnya berupa nota karbon tulisan tangan atau cetakan dot-matrix; Vision AI menjadi opsi utama karena mampu mengekstrak teks non-standar langsung menjadi JSON terstruktur.
- Ekstraksi timeout atau gagal dapat dicoba ulang dengan sekali klik.
- Hasil ekstraksi mentah disimpan terpisah dari hasil terverifikasi.
- Hasil ekstraksi tidak pernah langsung membuat mutasi stok.

// ponytail: 1 panggilan Vision AI langsung menghasilkan structured JSON, memangkas kompleksitas regex parsing multi-tahap.

### FR-010 Verifikasi faktur dan Konversi Satuan Grosir

- Foto faktur dan form hasil ekstraksi ditampilkan berdampingan (tablet) atau via expandable bottom-sheet (ponsel).
- Pengguna dapat mengoreksi seluruh field hasil ekstraksi.
- **Konversi Satuan Grosir Tas**: Mendukung satuan beli grosir khas supplier tas:
  - 1 Kodi = 20 pcs
  - 1 Lusin = 12 pcs
  - 1 Pcs = 1 pcs
  Sistem otomatis mengalikan jumlah kodi/lusin ke dalam kuantitas `pcs` stok masuk dan membagi harga modal per unit `pcs`.
- Setiap baris item dicocokkan ke SKU produk yang ada atau dibuatkan draf produk baru.
- Sistem memberi peringatan jika nomor faktur supplier terindikasi duplikat.
- Faktur berstatus `VERIFIED` setelah seluruh item terhubung ke SKU dan nilai subtotal valid.

### FR-011 Jadwal barang masuk

- Jadwal dapat dibuat dari faktur terverifikasi.
- Menyimpan tanggal estimasi, lokasi tujuan, PIC, dan catatan.
- Jumlah yang diharapkan berasal dari item faktur, tetapi dapat dikoreksi sebelum penerimaan dengan audit log.
- Status: `SCHEDULED`, `IN_TRANSIT`, `LATE`, `PARTIALLY_RECEIVED`, `RECEIVED`, `CANCELLED`, `CLOSED`.
- Status terlambat dihitung jika tanggal estimasi lewat dan belum selesai.

### FR-012 Penerimaan barang

- Mendukung penerimaan sebagian.
- Pengguna mengisi jumlah diterima, rusak, dan kurang.
- Jumlah diterima kumulatif tidak boleh melebihi jumlah yang diharapkan tanpa konfirmasi khusus.
- Barang rusak tidak menambah stok tersedia.
- Foto bukti bersifat opsional, tetapi wajib jika ada barang rusak.
- Konfirmasi penerimaan bersifat atomic.
- Penerimaan yang sudah dikonfirmasi tidak dapat diedit langsung; koreksi menggunakan dokumen koreksi.

### FR-013 Average cost

Saat penerimaan barang valid:

```text
Average cost baru =
((stok lama × average cost lama) + (jumlah masuk × harga modal masuk))
/ (stok lama + jumlah masuk)
```

Ketentuan:

- Gunakan tipe Decimal.
- Pembulatan hanya untuk tampilan; nilai presisi disimpan.
- Jika stok lama nol, average cost baru sama dengan harga modal masuk.
- Harga modal dapat mencakup alokasi biaya tambahan pada fase lanjutan; tidak termasuk MVP.

### FR-014 Estimasi potensi laba

- Ditampilkan per SKU, produk, kategori, dan total toko.
- Produk dengan data harga tidak lengkap dipisahkan.
- Pengguna dapat melihat modal unit, harga jual acuan, potensi laba unit, dan margin.
- Total dashboard harus menampilkan waktu terakhir perhitungan.

### FR-015 Pencarian, filter, dan sortir

- Pencarian berdasarkan nama, SKU, barcode, supplier, dan nomor faktur.
- Filter produk berdasarkan kategori, status, stok, dan kelengkapan harga.
- Filter faktur berdasarkan supplier, status, dan rentang tanggal.
- Filter jadwal berdasarkan status dan tanggal kedatangan.
- Daftar mendukung pagination/cursor.

### FR-016 Notifikasi dalam aplikasi

- Faktur selesai diproses OCR.
- OCR gagal.
- Barang dijadwalkan masuk hari ini.
- Jadwal terlambat.
- Stok di bawah batas minimum.
- Stok opname menunggu persetujuan.

Push notification dapat ditambahkan setelah notifikasi dalam aplikasi stabil.

### FR-017 Laporan dan ekspor

MVP menyediakan:

- Laporan saldo stok.
- Laporan mutasi stok.
- Laporan barang masuk.
- Laporan selisih stok opname.
- Laporan nilai modal persediaan.
- Laporan estimasi potensi laba.
- Daftar stok menipis dan habis.

Format ekspor:

- CSV untuk data tabel.
- PDF sederhana untuk ringkasan.

### FR-018 Audit log

Aktivitas yang dicatat:

- Login penting dan pencabutan sesi.
- Membuat/mengubah produk dan SKU.
- Verifikasi faktur.
- Perubahan pencocokan item.
- Konfirmasi penerimaan.
- Pengajuan, persetujuan, dan penolakan stok opname.
- Perubahan harga jual acuan.
- Perubahan minimum stok.
- Pengelolaan pengguna.

Audit log minimal menyimpan aktor, aksi, waktu, entitas, ID entitas, nilai sebelum/sesudah yang relevan, dan metadata perangkat/IP jika tersedia.

---

## 10. Aturan Bisnis

1. Stok hanya berubah melalui `stock_movements`.
2. Mengunggah atau memverifikasi faktur tidak menambah stok.
3. Stok bertambah ketika penerimaan barang dikonfirmasi.
4. Barang rusak tidak masuk stok tersedia.
5. Dokumen operasional yang sudah dikonfirmasi tidak dihapus permanen.
6. Koreksi dilakukan melalui dokumen/mutasi pembalik.
7. SKU harus unik dalam satu toko.
8. Nomor faktur harus diperiksa duplikasinya dalam kombinasi supplier dan tanggal/nomor.
9. Faktur tanpa nomor tetap dapat disimpan, tetapi memerlukan identitas dokumen internal.
10. Item faktur harus terhubung ke SKU sebelum dapat diterima.
11. Penyesuaian stok oleh staf harus disetujui pemilik.
12. Saldo stok negatif tidak diizinkan pada MVP.
13. Semua operasi penerimaan dan penyesuaian menggunakan database transaction.
14. Permintaan konfirmasi penerimaan menggunakan idempotency key.
15. Nilai uang menggunakan Decimal, bukan floating point.
16. Timestamp disimpan dalam UTC dan ditampilkan dalam Asia/Jakarta.
17. Dokumen yang sudah ditutup bersifat read-only.
18. Potensi laba selalu diberi label sebagai estimasi.
19. Produk nonaktif tidak dapat dipilih pada dokumen baru, tetapi tetap terlihat di riwayat.
20. Semua query data dibatasi berdasarkan toko pengguna.

---

## 11. Status dan State Machine

### 11.1 Faktur

```text
DRAFT
  → IMAGE_UPLOADED
  → OCR_PROCESSING
  → NEEDS_REVIEW
  → VERIFIED
  → SCHEDULED
  → PARTIALLY_RECEIVED
  → RECEIVED
  → CLOSED
```

Jalur alternatif:

```text
OCR_PROCESSING → OCR_FAILED → OCR_PROCESSING
DRAFT/NEEDS_REVIEW/VERIFIED → CANCELLED
```

### 11.2 Stok opname

```text
DRAFT → IN_PROGRESS → SUBMITTED → APPROVED → APPLIED
                              └→ REJECTED → IN_PROGRESS
```

### 11.3 Penerimaan barang

```text
DRAFT → CONFIRMED
      → CANCELLED
```

Penerimaan `CONFIRMED` tidak diubah langsung.

---

## 12. Model Data Konseptual

### 12.1 Entitas inti

#### Store

- `id`
- `name`
- `timezone`
- `currency`
- `created_at`
- `updated_at`

#### Location

- `id`
- `store_id`
- `name`
- `type`
- `address`
- `is_active`

#### User

- `id`
- `store_id`
- `name`
- `email`
- `password_hash`
- `role_id`
- `is_active`
- `last_login_at`

#### Supplier

- `id`
- `store_id`
- `name`
- `phone`
- `email`
- `address`
- `notes`
- `is_active`

#### Product

- `id`
- `store_id`
- `category_id`
- `brand`
- `name`
- `description`
- `image_key`
- `is_active`

#### ProductVariant

- `id`
- `product_id`
- `sku`
- `barcode`
- `color`
- `size`
- `unit`
- `reference_selling_price`
- `minimum_stock`
- `is_active`

#### StockBalance

- `id`
- `store_id`
- `location_id`
- `variant_id`
- `quantity_on_hand`
- `average_cost`
- `version`
- `updated_at`

Unique constraint: `(location_id, variant_id)`.

#### StockMovement

- `id`
- `store_id`
- `location_id`
- `variant_id`
- `type`
- `quantity_delta`
- `unit_cost`
- `balance_after`
- `reference_type`
- `reference_id`
- `notes`
- `created_by`
- `created_at`

#### Invoice

- `id`
- `store_id`
- `supplier_id`
- `internal_number`
- `supplier_invoice_number`
- `invoice_date`
- `currency`
- `subtotal`
- `discount_total`
- `grand_total`
- `status`
- `ocr_provider`
- `verified_by`
- `verified_at`

#### InvoiceImage

- `id`
- `invoice_id`
- `storage_key`
- `mime_type`
- `page_number`
- `checksum`
- `uploaded_by`

#### OcrExtraction

- `id`
- `invoice_id`
- `provider`
- `status`
- `raw_response`
- `normalized_result`
- `error_code`
- `attempt_count`
- `started_at`
- `completed_at`

#### InvoiceItem

- `id`
- `invoice_id`
- `variant_id`
- `raw_name`
- `raw_code`
- `quantity`
- `unit`
- `unit_cost`
- `discount`
- `line_total`
- `match_status`
- `confidence_score`

#### IncomingSchedule

- `id`
- `invoice_id`
- `location_id`
- `expected_date`
- `status`
- `pic_user_id`
- `notes`

#### GoodsReceipt

- `id`
- `schedule_id`
- `receipt_number`
- `received_at`
- `status`
- `received_by`
- `confirmed_at`
- `idempotency_key`

#### GoodsReceiptItem

- `id`
- `goods_receipt_id`
- `invoice_item_id`
- `variant_id`
- `expected_quantity`
- `received_quantity`
- `damaged_quantity`
- `short_quantity`
- `unit_cost`
- `notes`

#### StockCheck

- `id`
- `store_id`
- `location_id`
- `status`
- `started_at`
- `submitted_at`
- `approved_at`
- `created_by`
- `approved_by`

#### StockCheckItem

- `id`
- `stock_check_id`
- `variant_id`
- `system_quantity_snapshot`
- `physical_quantity`
- `difference`
- `reason`
- `evidence_key`

#### AuditLog

- `id`
- `store_id`
- `actor_user_id`
- `action`
- `entity_type`
- `entity_id`
- `before_data`
- `after_data`
- `ip_address`
- `device_info`
- `created_at`

### 12.2 Prinsip database

- Gunakan UUID/UUIDv7 atau CUID2 secara konsisten.
- Gunakan foreign key untuk integritas referensial.
- Gunakan soft delete/status nonaktif pada master data yang sudah dipakai.
- Gunakan indeks pada SKU, barcode, status, tanggal, supplier, dan foreign key.
- Gunakan optimistic locking pada `StockBalance.version` bila diperlukan.
- Buat unique constraint untuk idempotency key.

---

## 13. Arsitektur Sistem

```text
Flutter Android
      │ HTTPS/JSON
      ▼
Bun Runtime + Hono API
      │
      ├── Application Services
      ├── Domain Rules
      ├── Prisma Repositories
      ├── PostgreSQL
      ├── Object Storage
      ├── Job Queue / Worker
      └── OCR Provider
```

### 13.1 Prinsip arsitektur

- API-first.
- Modular monolith untuk MVP.
- Business logic tidak diletakkan di route atau UI.
- OCR menggunakan provider-neutral interface.
- Object storage tidak diakses langsung tanpa signed URL/otorisasi.
- Proses berat dijalankan di worker.
- Transaksi stok bersifat atomic dan idempotent.

### 13.2 Struktur backend yang disarankan

```text
apps/api/src/
├── modules/
│   ├── auth/
│   ├── users/
│   ├── suppliers/
│   ├── products/
│   ├── inventory/
│   ├── invoices/
│   ├── ocr/
│   ├── incoming-schedules/
│   ├── goods-receipts/
│   ├── stock-checks/
│   ├── reports/
│   └── audit/
├── shared/
│   ├── errors/
│   ├── validation/
│   ├── auth/
│   └── observability/
├── infrastructure/
│   ├── prisma/
│   ├── storage/
│   ├── queue/
│   └── ocr-providers/
└── app.ts
```

### 13.3 Lapisan modul

```text
Hono Route
→ Controller/Handler
→ Application Service/Use Case
→ Domain Rules
→ Repository Interface
→ Prisma Repository
```

### 13.4 Interface OCR

```ts
interface InvoiceRecognitionProvider {
  extractInvoice(input: {
    invoiceId: string;
    files: Array<{ url: string; mimeType: string }>;
    locale: "id-ID";
  }): Promise<{
    providerRequestId?: string;
    supplierName?: string;
    invoiceNumber?: string;
    invoiceDate?: string;
    subtotal?: string;
    discountTotal?: string;
    grandTotal?: string;
    items: Array<{
      name: string;
      code?: string;
      quantity?: string;
      unit?: string;
      unitCost?: string;
      lineTotal?: string;
      confidence?: number;
    }>;
    raw: unknown;
  }>;
}
```

---

## 14. API Awal

Prefix: `/api/v1`

### Authentication

- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /auth/me`

### Products

- `GET /products`
- `POST /products`
- `GET /products/:id`
- `PATCH /products/:id`
- `POST /products/:id/variants`
- `PATCH /variants/:id`
- `GET /variants/by-barcode/:barcode`

### Suppliers

- `GET /suppliers`
- `POST /suppliers`
- `PATCH /suppliers/:id`

### Inventory

- `GET /inventory/balances`
- `GET /inventory/variants/:variantId/movements`
- `POST /inventory/initial-stock`
- `GET /inventory/alerts`

### Invoices

- `GET /invoices`
- `POST /invoices`
- `GET /invoices/:id`
- `POST /invoices/:id/images`
- `POST /invoices/:id/process-ocr`
- `GET /invoices/:id/ocr-status`
- `PATCH /invoices/:id/verified-data`
- `POST /invoices/:id/verify`
- `POST /invoices/:id/cancel`

### Incoming schedules

- `GET /incoming-schedules`
- `POST /incoming-schedules`
- `GET /incoming-schedules/:id`
- `PATCH /incoming-schedules/:id`
- `POST /incoming-schedules/:id/cancel`

### Goods receipts

- `POST /incoming-schedules/:id/receipts`
- `GET /goods-receipts/:id`
- `POST /goods-receipts/:id/confirm`

### Stock checks

- `GET /stock-checks`
- `POST /stock-checks`
- `GET /stock-checks/:id`
- `PUT /stock-checks/:id/items/:variantId`
- `POST /stock-checks/:id/submit`
- `POST /stock-checks/:id/approve`
- `POST /stock-checks/:id/reject`

### Dashboard and reports

- `GET /dashboard/summary`
- `GET /reports/stock-balance`
- `GET /reports/stock-movements`
- `GET /reports/incoming-goods`
- `GET /reports/stock-valuation`
- `GET /reports/potential-profit`
- `POST /exports`
- `GET /exports/:id`

API harus didokumentasikan menggunakan OpenAPI dan menghasilkan kontrak yang dapat digunakan Flutter.

---

## 15. Struktur Navigasi Flutter

Bottom navigation MVP:

1. **Beranda**
2. **Stok**
3. **Scan/Foto**
4. **Barang Masuk**
5. **Lainnya**

### Beranda

- Ringkasan stok.
- Nilai persediaan.
- Potensi laba.
- Peringatan.
- Agenda barang masuk.

### Stok

- Daftar produk.
- Pencarian dan filter.
- Detail produk/SKU.
- Riwayat mutasi.
- Stok opname.

### Scan/Foto

- Scan barcode.
- Foto faktur.
- Pilih dari galeri.
- Draft unggahan.

### Barang Masuk

- Faktur perlu diperiksa.
- Jadwal barang masuk.
- Barang terlambat.
- Riwayat penerimaan.

### Lainnya

- Supplier.
- Produk dan kategori.
- Laporan.
- Pengguna.
- Audit log.
- Pengaturan.
- Logout.

---

## 16. Kebutuhan UI/UX (UI/UX Pro Max)

Desain mengikuti sistem desain resmi pada `design-system/susilawati-toko/MASTER.md`:

### 16.1 Desain Visual dan Token Warna
- **Gaya visual**: Flat design fungsional, garis bersih, tanpa bayangan berlebihan atau efek 3D dekoratif.
- **Warna Utama**: Slate 700 (`#334155`) untuk header, navigasi, dan tombol sekunder.
- **Warna Aksen / Sukses**: Emerald 600 (`#059669`) untuk tombol aksi utama (CTA), status stok aman, dan konfirmasi.
- **Warna Peringatan**: Amber 600 (`#D97706`) untuk stok menipis dan faktur menunggu review.
- **Warna Bahaya**: Red 600 (`#DC2626`) untuk barang rusak, stok habis, dan aksi destruktif.
- **Latar Belakang**: Slate 50 (`#F8FAFC`), Kartu/Surface: Putih murni (`#FFFFFF`), Border: Slate 200 (`#E2E8F0`).
- **Kontras Teks**: Rasio kontras minimal 4.5:1 untuk teks normal agar terbaca jelas di bawah lampu toko.

### 16.2 Tipografi dan Format Angka
- **Font Utama**: Rubik (judul) dan Nunito Sans (teks isi).
- **Format Angka**: Menggunakan *tabular figures* (`FontFeature.tabularFigures()`) pada nominal Rupiah, kuantitas stok, dan kode SKU untuk mencegah teks bergeser saat nilai berubah.
- **Mata Uang**: Format Rupiah standar Indonesia (`Rp 150.000`).

### 16.3 Ergonomi Mobile
- **Ukuran Sentuh (Touch Target)**: Minimal 48×48 dp pada seluruh tombol aksi dan input form.
- **Zona Jempol (Thumb Zone)**: Aksi utama (Scan Barcode, Tambah Faktur, Terima Barang) diletakkan di area bawah layar yang terjangkau satu tangan.
- **Layar Verifikasi Faktur**: Menggunakan expandable bottom-sheet atau split-panel horizontal (pada tablet) agar staf dapat memeriksa foto faktur tanpa kehilangan posisi form isian.
- **Input Angka Cepat**: Menggunakan keypad numerik besar saat memasukkan jumlah penerimaan barang.
- **Ikon**: Dilarang menggunakan emoji sebagai ikon antarmuka. Gunakan pustaka ikon SVG konsisten (Lucide atau Material Icons outline).
- **Status Ganda**: Status barang dan stok wajib menggunakan kombinasi teks dan ikon, bukan warna saja (ramah buta warna).

---

## 17. Kebutuhan Non-Fungsional

### 17.1 Performa

- P95 API read sederhana kurang dari 500 ms pada beban MVP, di luar jaringan pengguna.
- P95 API write kurang dari 800 ms, di luar unggahan file dan OCR.
- Dashboard tampil dengan skeleton dan data utama tersedia kurang dari 3 detik pada koneksi stabil.
- Pencarian SKU merespons kurang dari 1 detik untuk 10.000 SKU.
- OCR diproses asynchronous; target 90% dokumen selesai kurang dari 60 detik, bergantung provider.

### 17.2 Reliabilitas

- Target availability backend MVP: 99,5% per bulan.
- Mutasi stok tidak boleh tercatat sebagian.
- Worker mendukung retry dengan exponential backoff.
- Job OCR harus idempotent.
- Kegagalan OCR tidak menghapus foto atau data faktur.

### 17.3 Skalabilitas awal

MVP dirancang untuk:

- 1 toko aktif.
- 5 pengguna.
- 10.000 SKU.
- 100.000 mutasi stok.
- 5.000 faktur per tahun.
- 10 halaman per faktur.

### 17.4 Kompatibilitas

- Android 9 atau lebih baru.
- Layout ponsel dan tablet.
- Kamera dan galeri Android.
- Barcode scanner menggunakan kamera perangkat.

### 17.5 Maintainability

- TypeScript strict mode.
- Validasi request menggunakan Zod.
- Prisma migration masuk version control.
- Modul memiliki batas dependensi yang jelas.
- Minimal linting, formatting, unit test, dan integration test pada CI.

---

## 18. Keamanan dan Privasi

- Semua koneksi production menggunakan HTTPS.
- Kata sandi di-hash dengan Argon2id atau algoritma aman setara.
- Refresh token disimpan dalam secure storage pada Flutter.
- Secret tidak disimpan di source code atau image Docker.
- Signed URL digunakan untuk akses berkas privat.
- File upload divalidasi berdasarkan ukuran, MIME, dan signature.
- Metadata EXIF yang tidak dibutuhkan dapat dihapus.
- Query wajib dibatasi berdasarkan `store_id`.
- Endpoint sensitif memerlukan pemeriksaan role/permission.
- Rate limiting diterapkan pada login, upload, dan OCR trigger.
- Audit log tidak dapat diedit melalui aplikasi.
- Data sensitif tidak boleh masuk log aplikasi.
- Backup dienkripsi saat disimpan.
- Retensi foto faktur dapat dikonfigurasi; default disimpan selama data faktur aktif.
- Provider OCR hanya menerima data yang diperlukan untuk ekstraksi.

---

## 19. Strategi Offline dan Koneksi Buruk

Offline penuh tidak termasuk MVP. Namun aplikasi harus tahan terhadap koneksi tidak stabil:

- Cache daftar produk terakhir untuk pencarian cepat.
- Simpan draft form dan metadata foto secara lokal sebelum upload selesai.
- Tampilkan progress upload.
- Upload dapat dicoba ulang.
- Jangan mengirim konfirmasi penerimaan dua kali.
- Gunakan idempotency key untuk operasi kritis.
- Tampilkan waktu sinkronisasi terakhir.
- Pengguna tidak boleh melihat draft lokal sebagai data yang sudah tersimpan di server.

---

## 20. Observability dan Operasional

### Logging

- Structured JSON log.
- Request ID untuk setiap request.
- Correlation ID untuk API, job, dan OCR provider.
- Jangan mencatat password, token, atau signed URL lengkap.

### Metrics

- Request rate, latency, dan error rate.
- Jumlah job OCR berhasil/gagal.
- Durasi OCR.
- Upload gagal.
- Penerimaan gagal dikonfirmasi.
- Perbedaan stok opname.
- Database connection pool.

### Alerting

- Error rate API tinggi.
- Worker berhenti.
- Queue menumpuk.
- Database hampir penuh.
- Backup gagal.
- Object storage tidak tersedia.

---

## 21. Backup dan Pemulihan

- Backup PostgreSQL otomatis setiap hari.
- Retensi harian minimal 14 hari untuk MVP.
- Object storage memiliki backup atau versioning.
- Uji restore dilakukan sebelum peluncuran dan secara berkala.
- Target awal RPO maksimal 24 jam.
- Target awal RTO maksimal 8 jam.
- Prosedur restore harus terdokumentasi.

---

## 22. Pengujian

### 22.1 Unit test

- Perhitungan average cost.
- Perhitungan nilai stok dan potensi laba.
- Validasi status transition.
- Validasi penerimaan sebagian.
- Validasi stok tidak negatif.
- Pencocokan dan normalisasi data OCR.

### 22.2 Integration test

- Prisma dengan PostgreSQL test container/database.
- Konfirmasi penerimaan membuat receipt, movement, dan balance secara atomic.
- Retry dengan idempotency key tidak menggandakan stok.
- Approval stok opname membuat penyesuaian yang benar.
- Tenant/store isolation.

### 22.3 API test

- Authentication dan authorization.
- Validasi request.
- Pagination dan filter.
- Upload dan callback/job OCR.
- Error contract konsisten.

### 22.4 Flutter test

- Widget test untuk form penting.
- State management test.
- Navigation test.
- Upload retry.
- Barcode scan flow.
- Golden test untuk layar utama bila diperlukan.

### 22.5 UAT

Skenario minimum:

1. Membuat produk dengan tiga varian warna.
2. Menginput stok awal.
3. Mengunggah faktur dua halaman.
4. Memperbaiki hasil OCR yang salah.
5. Mencocokkan item ke SKU.
6. Menjadwalkan kedatangan barang.
7. Menerima sebagian barang.
8. Menerima sisa barang pada hari berikutnya.
9. Memastikan average cost berubah benar.
10. Melakukan stok opname dengan selisih.
11. Menyetujui penyesuaian.
12. Mengekspor laporan stok dan potensi laba.

---

## 23. Analytics Produk

Event internal yang perlu dicatat tanpa merekam data sensitif:

- `login_succeeded`
- `product_created`
- `invoice_uploaded`
- `ocr_completed`
- `ocr_failed`
- `invoice_verified`
- `incoming_schedule_created`
- `goods_receipt_confirmed`
- `stock_check_started`
- `stock_check_submitted`
- `stock_adjustment_approved`
- `report_exported`

Metric produk:

- Persentase faktur yang berhasil diproses OCR.
- Rata-rata field yang dikoreksi setelah OCR.
- Waktu dari upload sampai verifikasi.
- Waktu dari jadwal sampai penerimaan.
- Persentase SKU yang memiliki harga lengkap.
- Persentase penerimaan yang memiliki selisih.
- Frekuensi stok opname.

---

## 24. Infrastruktur Development (Lean / Ponytail)

Docker Compose minimal:

```text
services:
  postgres
```

Komponen:

- `postgres`: database PostgreSQL utama (port 5432).
- `api`: Bun + Hono berjalan langsung di host via `bun run dev` (cepat, reload instan, hemat memori).
- `storage`: berkas foto disimpan di direktori lokal `./uploads` pada mode development. Produksi menggunakan Cloudflare R2 / S3. Tidak memerlukan MinIO lokal.
- `queue`: antrean background (ekstraksi faktur & ekspor) diproses menggunakan async worker native Bun atau antrean berbasis PostgreSQL. Tidak memerlukan Redis pada tahap MVP (5 pengguna, 1 toko).

// ponytail: Redis dan MinIO diskip. Tambahkan Redis jika antrean melebihi 100 job bersamaan.
// ponytail: Standalone worker process diskip. Tambahkan proses terpisah jika beban ekstraksi mengganggu API utama.

---

## 25. Rencana Implementasi

### Fase 0 — Discovery dan finalisasi PRD

Deliverables:

- Validasi alur toko.
- Contoh faktur supplier.
- Daftar kategori dan atribut produk.
- Keputusan provider OCR.
- Wireframe inti.
- Finalisasi acceptance criteria.

### Fase 1 — Fondasi teknis

Deliverables:

- Repository dan CI.
- Docker Compose.
- Hono API.
- Prisma dan PostgreSQL.
- Auth dan RBAC.
- Profil toko, lokasi, dan pengguna.
- Logging serta error contract.

### Fase 2 — Produk dan stok

Deliverables:

- Supplier.
- Kategori.
- Produk dan varian.
- Stok awal.
- Saldo dan mutasi stok.
- Peringatan stok minimum.
- Scan barcode dasar.

### Fase 3 — Faktur dan OCR

Deliverables:

- Kamera/galeri.
- Multi-page upload.
- Object storage.
- OCR worker.
- Review dan koreksi hasil.
- Pencocokan SKU.
- Deteksi duplikasi.

### Fase 4 — Jadwal dan penerimaan

Deliverables:

- Jadwal barang masuk.
- Status keterlambatan.
- Penerimaan sebagian/lengkap.
- Barang rusak dan kurang.
- Average cost.
- Mutasi stok atomic.

### Fase 5 — Opname, dashboard, dan laporan

Deliverables:

- Stok opname.
- Approval penyesuaian.
- Dashboard.
- Nilai persediaan.
- Estimasi potensi laba.
- Ekspor CSV/PDF.

### Fase 6 — Hardening dan peluncuran

Deliverables:

- UAT.
- Security review.
- Performance test.
- Backup/restore test.
- Import data awal.
- Pelatihan singkat.
- Peluncuran Android.

---

## 26. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Foto faktur buram | OCR tidak akurat | Panduan kamera, quality check, retake, input manual |
| Format faktur supplier berbeda | Field tidak terbaca konsisten | Provider-neutral OCR, review wajib, simpan hasil mentah |
| Produk OCR tidak cocok ke SKU | Penerimaan tertunda | Kandidat matching, pencarian manual, draft produk |
| Pengguna menganggap OCR selalu benar | Stok salah | Tidak ada auto-posting, verifikasi wajib |
| Penerimaan dikirim dua kali | Stok ganda | Idempotency key dan unique constraint |
| Koreksi stok tanpa kontrol | Data tidak dapat dipercaya | Approval pemilik dan audit log |
| Tidak ada data penjualan | Laba aktual tidak tersedia | Label jelas sebagai estimasi potensi laba |
| Koneksi toko tidak stabil | Upload gagal | Draft lokal, retry, progress, resumable upload bila diperlukan |
| Biaya OCR meningkat | Biaya operasional | Kompresi, batas halaman, monitoring pemakaian, provider abstraction |
| Kehilangan perangkat | Akses tidak sah | Secure storage, token revocation, screen lock recommendation |

---

## 27. Kriteria Peluncuran MVP

MVP dapat diluncurkan jika:

- Seluruh alur kritis lulus UAT.
- Tidak ada bug severity critical atau high yang belum ditangani.
- Konfirmasi penerimaan terbukti idempotent.
- Perhitungan average cost tervalidasi dengan contoh manual.
- Isolasi data toko dan RBAC lulus pengujian.
- Backup dan restore berhasil diuji.
- OCR gagal tidak menyebabkan kehilangan dokumen.
- Audit log tersedia untuk perubahan stok.
- Dashboard memberi label jelas pada estimasi potensi laba.
- Crash-free rate selama beta memenuhi target minimal 99%.
- Dokumentasi penggunaan dasar tersedia.

---

## 28. Definition of Done

Sebuah fitur dinyatakan selesai apabila:

- Requirement dan acceptance criteria terpenuhi.
- UI menangani loading, empty, error, dan success state.
- Authorization backend diterapkan.
- Validasi input diterapkan di API.
- Audit log ditambahkan jika relevan.
- Unit/integration test kritis tersedia.
- Dokumentasi API diperbarui.
- Migration database dapat dijalankan dan di-rollback sesuai prosedur.
- Sudah diuji pada ponsel Android target.
- Tidak menampilkan data sensitif pada log.
- Sudah diterima pada UAT jika fitur termasuk alur bisnis utama.

---

## 29. Keputusan yang Masih Perlu Dikonfirmasi

1. Apakah satu model tas selalu memiliki varian warna dan ukuran?
2. Apakah produk sudah memiliki barcode dari supplier?
3. Jika tidak ada barcode, apakah aplikasi perlu membuat kode/barcode internal?
4. Berapa perkiraan jumlah produk dan SKU pada tahun pertama?
5. Apakah hanya ada satu gudang/ruang penyimpanan?
6. Siapa yang boleh menyetujui selisih stok?
7. Apakah harga pada faktur sudah termasuk pajak dan ongkos kirim?
8. Apakah ongkos kirim perlu dialokasikan ke harga modal pada fase berikutnya?
9. Apakah faktur paling sering berupa nota cetak, tulisan tangan, PDF, atau foto WhatsApp?
10. Apakah supplier menggunakan kode barang yang konsisten?
11. Apakah diperlukan satuan selain `pcs`, misalnya lusin atau koli?
12. Berapa lama foto faktur harus disimpan?
13. Apakah laporan perlu dikirim otomatis ke email/WhatsApp pada fase berikutnya?
14. Apakah Android-only dapat diterima untuk seluruh pengguna awal?

---

## 30. Roadmap Setelah MVP

Prioritas dievaluasi berdasarkan pemakaian nyata selama 2–3 bulan.

### Kandidat fase berikutnya

- Dashboard admin Remix untuk input massal dan laporan kompleks.
- Impor dan ekspor Excel yang lebih lengkap.
- Multi-lokasi dan transfer stok.
- Mode offline penuh.
- Push notification.
- Integrasi printer barcode/label.
- Alokasi ongkos kirim ke harga modal.
- Integrasi POS atau rekap penjualan untuk laba aktual.
- Integrasi marketplace.
- Prediksi reorder.
- Analisis umur stok dan slow-moving items.
- Aplikasi iOS.

---

## 31. Ringkasan Keputusan Produk

- MVP menggunakan Flutter Android tanpa dashboard web.
- Backend tetap API-first agar Remix dapat ditambahkan nanti.
- Fokus produk adalah stok, faktur, jadwal, penerimaan, dan opname.
- Tidak ada penjualan, checkout, atau pembayaran.
- OCR membantu input, tetapi manusia selalu melakukan verifikasi.
- Stok hanya bertambah setelah penerimaan dikonfirmasi.
- Semua perubahan stok memiliki mutasi dan audit trail.
- Hasil laba pada MVP adalah estimasi potensi laba, bukan laba aktual.
- Arsitektur awal adalah modular monolith agar sederhana namun tetap terstruktur.
