import { describe, expect, test } from "bun:test";
import { calculateAverageCost } from "../src/modules/inventory.js";

describe("Kalkulasi Weighted Average Cost Persediaan", () => {
  test("Menghitung modal rata-rata tertimbang saat stok lama ada", () => {
    // Stok lama: 20 pcs @ Rp 50.000 (nilai: 1.000.000)
    // Masuk baru: 10 pcs @ Rp 65.000 (nilai: 650.000)
    // Total stok: 30 pcs, Total nilai: 1.650.000 -> Rata-rata: Rp 55.000
    const result = calculateAverageCost(20, 50000, 10, 65000);
    expect(result).toBe(55000);
  });

  test("Menggunakan harga masuk jika stok lama nol", () => {
    const result = calculateAverageCost(0, 0, 15, 75000);
    expect(result).toBe(75000);
  });

  test("Mempertahankan harga lama jika barang masuk nol", () => {
    const result = calculateAverageCost(10, 80000, 0, 0);
    expect(result).toBe(80000);
  });

  test("Menangani desimal dengan pembulatan 2 angka", () => {
    // Stok lama: 3 pcs @ Rp 10.000 = 30.000
    // Masuk baru: 4 pcs @ Rp 11.000 = 44.000
    // Total: 74.000 / 7 = 10571.428... -> 10571.43
    const result = calculateAverageCost(3, 10000, 4, 11000);
    expect(result).toBe(10571.43);
  });
});
