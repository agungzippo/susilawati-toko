# Rencana Kerja Implementasi: SUSILAWATI TOKO

Dokumen kerja teknis untuk pembangunan Sistem Manajemen Stok SUSILAWATI TOKO. Dokumen ini memangkas arsitektur berlebih (ponytail), menerapkan standar desain mobile ritel (UI/UX Pro Max), dan memprioritaskan fungsi operasional langsung toko tas.

---

## 1. Ringkasan Evaluasi PRD-toko.md

Terdapat 5 poin utama yang disesuaikan dari draf awal `PRD-toko.md`:

1. **Identitas Toko**:
   - Nama produk diselaraskan menjadi **SUSILAWATI TOKO**.
   - Model bisnis adalah toko tas fisik tunggal dengan gudang di lokasi toko.

2. **Pemangkasan Infrastruktur (Ponytail)**:
   - PRD awal memuat Redis, MinIO, dan daemon worker terpisah.
   - Penyesuaian: Gunakan Docker Compose untuk PostgreSQL saja. Bun API menangani background task langsung via async handler native. Penyimpanan foto menggunakan folder lokal `./uploads` di server, beralih ke Cloudflare R2 / S3 saat produksi.
   - *Skipped*: Redis, BullMQ, MinIO. Ditambahkan saat antrean melebihi 100 job serentak.

3. **Penyederhanaan Ekstraksi Bon Faktur**:
   - Bon supplier tas lokal di Indonesia didominasi nota karbon tulisan tangan atau printer dot-matrix. OCR tradisional (Tesseract) tidak akurat dan memerlukan parser regex rumit.
   - Penyesuaian: Gunakan 1 panggilan Multimodal Vision AI (Gemini Flash Vision) yang langsung menghasilkan format JSON terstruktur.
   - *Skipped*: Pipeline OCR multi-tahap dan parser regex manual.

4. **Satuan Grosir Tas (Kodi, Lusin, Pcs)**:
   - Supplier tas menjual per kodi (20 pcs) atau lusin (12 pcs), sedangkan toko menjual per pcs.
   - Penyesuaian: Tambahkan konversi otomatis pada faktur dan barang masuk (1 kodi = 20 pcs; modal per pcs = harga per kodi / 20).

5. **Penyederhanaan Multi-Lokasi di UI**:
   - Database tetap memuat `location_id` dengan nilai default `GUDANG_UTAMA`, namun UI disederhanakan tanpa dropdown pemilihan gudang untuk mempercepat input harian.

---

## 2. Standar Desain UI/UX (UI/UX Pro Max)

Rujukan detail tersimpan pada `design-system/susilawati-toko/MASTER.md`.

### 2.1 Token Warna & Tampilan
- **Gaya**: Flat design fungsional, bersih, bebas bayangan berlebih atau efek 3D.
- **Primary**: `#334155` (Slate 700) untuk navbar, appbar, dan tombol sekunder.
- **Accent / Sukses**: `#059669` (Emerald 600) untuk tombol simpan, scan, dan stok aman.
- **Peringatan**: `#D97706` (Amber 600) untuk stok menipis dan jadwal tertunda.
- **Bahaya**: `#DC2626` (Red 600) untuk barang rusak, stok habis, dan hapus data.
- **Background**: `#F8FAFC` (Slate 50), Kartu: `#FFFFFF`, Border: `#E2E8F0`.
- **Kontras Teks**: Rasio minimal 4.5:1 terhadap latar.

### 2.2 Tipografi & Angka
- **Font Judul**: Rubik.
- **Font Teks**: Nunito Sans.
- **Angka & Kode**: Gunakan *tabular figures* (`FontFeature.tabularFigures()`) untuk SKU, stok, dan nominal Rupiah (`Rp 150.000`) agar tata letak tabel stabil tanpa getar visual.

### 2.3 Ergonomi Antarmuka Kasir & Gudang
- **Ukuran Sentuh**: Minimal 48×48 dp untuk seluruh elemen sentuh.
- **Zona Jempol (Thumb-zone)**: Tombol aksi utama (Scan Barcode, Tambah Faktur, Konfirmasi) berada di sepertiga bawah layar.
- **Verifikasi Faktur**: Split panel horizontal pada tablet atau bottom-sheet swipe pada ponsel untuk melihat foto faktur dan tabel item secara bersamaan.
- **Ikon**: Menggunakan Lucide atau Material Icons SVG outline. Dilarang memakai emoji sebagai ikon tombol.

---

## 3. Rencana Kerja Bertahap (Sprint Execution)

### Fase 1: Fondasi Backend & Database (Target: 3 Hari)
Fokus: Menyiapkan API inti, autentikasi, dan skema data stok tanpa layer berlebih.

- [ ] Jalankan PostgreSQL melalui Docker Compose minimal.
- [ ] Inisialisasi backend Bun + Hono + Prisma ORM.
- [ ] Terapkan skema database:
  - `Store`, `User` (Pemilik & Admin/Staf).
  - `Supplier`.
  - `Product` & `ProductVariant` (SKU, barcode, warna, ukuran, harga modal, harga jual acuan, minimum stok).
  - `StockBalance` & `StockMovement`.
- [ ] Buat modul autentikasi JWT (access token + secure refresh token).
- [ ] Buat endpoint CRUD master produk, supplier, dan stok awal (`POST /inventory/initial-stock`).
- [ ] Tambahkan tes unit perhitungan average cost saat stok bertambah.

### Fase 2: Aplikasi Mobile Flutter - Master Produk & Barcode (Target: 4 Hari)
Fokus: Antarmuka pengelolaan produk, scan barcode, dan pemantauan stok real-time.

- [ ] Inisialisasi proyek Flutter Android dengan arsitektur fitur sederhana (Riverpod/Bloc lean).
- [ ] Konfigurasi tema aplikasi sesuai token `MASTER.md` (Slate, Emerald, Rubik, Nunito Sans).
- [ ] Buat layar Autentikasi (Login & Logout).
- [ ] Buat navigasi bawah (Beranda, Stok, Scan, Barang Masuk, Lainnya).
- [ ] Buat layar Daftar Stok dengan filter status (Aman, Menipis, Habis).
- [ ] Integrasikan scanner kamera menggunakan pustaka `mobile_scanner` (respons scan < 500 ms).
- [ ] Buat form Tambah & Ubah Produk dengan varian warna dan ukuran.

### Fase 3: Modul Faktur & Ekstraksi Cerdas (Target: 4 Hari)
Fokus: Foto bon supplier, ekstraksi cepat, verifikasi item, dan konversi satuan grosir.

- [ ] Buat endpoint upload gambar faktur ke penyimpanan lokal `./uploads`.
- [ ] Hubungkan API ekstraksi faktur dengan Vision AI (Gemini Flash Vision) untuk menghasilkan JSON otomatis.
- [ ] Buat antarmuka Flutter ambil foto bon dari kamera / galeri dengan kompresi lokal.
- [ ] Buat antarmuka Verifikasi Faktur:
  - Preview foto bon di sisi kiri/atas.
  - Form tabel item hasil bacaan di sisi kanan/bawah.
  - Dropdown konversi satuan grosir: kodi (×20), lusin (×12), pcs (×1).
  - Pencocokan nama barang faktur ke SKU produk yang ada.
- [ ] Simpan faktur terverifikasi dengan status `VERIFIED`.

### Fase 4: Jadwal & Penerimaan Barang Masuk (Target: 3 Hari)
Fokus: Eksekusi penerimaan fisik, pencatatan barang rusak/kurang, dan pembaruan stok atomic.

- [ ] Buat endpoint penjadwalan kedatangan barang dari faktur terverifikasi.
- [ ] Buat layar Jadwal Barang Masuk dengan penanda terlambat otomatis.
- [ ] Buat form Terima Barang di Flutter:
  - Input jumlah diterima, rusak, dan kurang per SKU.
  - Keypad numerik besar untuk kecepatan staf gudang.
- [ ] Terapkan mutasi stok atomic di backend dalam 1 database transaction:
  - Tambah saldo stok tersedia sesuai jumlah barang baik.
  - Pisahkan barang rusak ke catatan retur / rusak (tidak menambah stok aktif).
  - Hitung ulang nilai *average cost* otomatis.
  - Gunakan `idempotency_key` untuk mencegah input ganda.

### Fase 5: Stok Opname, Dashboard Nilai Modal & Potensi Laba (Target: 3 Hari)
Fokus: Kontrol selisih stok fisik, visualisasi nilai bisnis, dan laporan pemilik.

- [ ] Buat modul Stok Opname:
  - Mulai sesi opname (ambil snapshot saldo sistem).
  - Hitung fisik via scan barcode atau pencarian nama.
  - Catat selisih beserta alasan.
  - Layar persetujuan pemilik untuk menerbitkan penyesuaian stok otomatis.
- [ ] Bangun Beranda Dashboard:
  - Kartu ringkasan: Total SKU, Stok Tersedia, Stok Menipis/Habis.
  - Nilai modal persediaan (Σ stok × average cost).
  - Nilai jual potensial (Σ stok × harga jual acuan).
  - Estimasi potensi laba (Nilai jual potensial - Nilai modal).
- [ ] Ekspor data laporan saldo stok dan riwayat mutasi ke format CSV sederhana.

---

## 4. Matriks Checklist Verifikasi Sebelum Rilis (Pre-Launch)

- [ ] **Akurasi Modal**: Uji hitung average cost dengan transaksi bertingkat (contoh: 20 pcs @ Rp 50.000 + 10 pcs @ Rp 65.000 = 30 pcs @ Rp 55.000).
- [ ] **Anti-Duplikasi**: Uji pengiriman konfirmasi penerimaan ganda saat sinyal terputus (wajib idempotent).
- [ ] **Audit Perubahan**: Setiap mutasi stok tercatat aktor, jenis mutasi, dan waktu perubahan.
- [ ] **Ergonomi**: Seluruh tombol aksi utama lolos uji sentuh 48 dp pada layar ponsel Android 6 inci.
- [ ] **Visibilitas Teks**: Kontras warna lolos audit WCAG 4.5:1. Angka menggunakan font tabular.
- [ ] **Penyimpanan Lokal**: Backup otomatis database PostgreSQL berjalan setiap hari.
