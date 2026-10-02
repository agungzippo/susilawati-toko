import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _manualBarcodeController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _isProcessing = true;
        await _lookupBarcode(code);
        break;
      }
    }
  }

  Future<void> _lookupBarcode(String barcode) async {
    // Show loading modal or query
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      final variant = await ApiService.instance.getVariantByBarcode(barcode);
      if (mounted) Navigator.pop(context); // Close loading

      if (variant == null) {
        if (mounted) {
          _showNotFoundDialog(barcode);
        }
      } else {
        if (mounted) {
          _showProductBottomSheet(variant);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      // Re-enable scanning after delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) _isProcessing = false;
    }
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search_off, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Barcode Tidak Terdaftar'),
          ],
        ),
        content: Text('Barcode "$barcode" belum terdaftar di sistem SUSILAWATI TOKO.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showProductBottomSheet(Map<String, dynamic> variant) {
    final product = variant['product'] ?? {};
    final balances = variant['stockBalances'] as List? ?? [];
    final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;
    final cost = balances.isNotEmpty ? balances[0]['averageCost'] : 0;
    final minStock = variant['minimumStock'] as int? ?? 5;
    final selling = variant['referenceSellingPrice'];

    Color badgeColor = AppColors.accent;
    String badgeText = 'Stok Aman';
    if (stock <= 0) {
      badgeColor = AppColors.destructive;
      badgeText = 'Stok Habis';
    } else if (stock <= minStock) {
      badgeColor = AppColors.warning;
      badgeText = 'Stok Menipis';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  'Barcode: ${variant['barcode']}',
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              product['name'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Brand: ${product['brand'] ?? '-'} • Kategori: ${product['category']?['name'] ?? '-'}',
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Varian & Ukuran', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      Text(
                        '${variant['color'] ?? 'Default'} / ${variant['size'] ?? 'All Size'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text('SKU: ${variant['sku']}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Stok Saat Ini', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                    Text(
                      '$stock pcs',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                    Text('Batas Min: $minStock pcs', style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Harga Jual Acuan', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      Text(
                        _currency.format(double.tryParse(selling.toString()) ?? 0),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Modal Rata-Rata', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      Text(
                        _currency.format(double.tryParse(cost.toString()) ?? 0),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai / Scan Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode Produk'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Reticle Scanner Overlay
          Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Petunjuk & Input Manual Bawah
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Arahkan kamera ke barcode tas atau masukkan kode secara manual:',
                    style: TextStyle(fontSize: 12, color: AppColors.foreground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualBarcodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: 899123450001',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () {
                          final code = _manualBarcodeController.text.trim();
                          if (code.isNotEmpty) {
                            _lookupBarcode(code);
                          }
                        },
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
