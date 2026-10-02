import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'scan_result_screen.dart';

class IncomingScreen extends StatefulWidget {
  final bool showBackButton;
  const IncomingScreen({super.key, this.showBackButton = true});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  int _selectedMode = 1; // 0 = Manual, 1 = Scan Bon / Faktur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Barang Masuk'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Segmented Pill Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7DF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 0 ? AppColors.brandEspresso : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Manual',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 0 ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 1 ? AppColors.brandEspresso : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Scan Bon / Faktur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 1 ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Camera Viewfinder Card with Corner Brackets
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: const Color(0xFF26211E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadow3D,
            ),
            child: Stack(
              children: [
                // Bon Faktur Image Mockup inside viewfinder
                Center(
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F8F6),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TOKO MAJU JAYA',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('FAKTUR PEMBELIAN', style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                        const Divider(thickness: 1, color: Colors.black45),
                        const SizedBox(height: 6),
                        _buildReceiptRow('Tas Tote', '5 x 180.000', '900.000'),
                        const SizedBox(height: 4),
                        _buildReceiptRow('Shoulder Bag', '3 x 150.000', '450.000'),
                        const SizedBox(height: 8),
                        const Divider(thickness: 1, color: Colors.black45),
                        _buildReceiptRow('Total', '', '1.350.000', isBold: true),
                        const SizedBox(height: 12),
                        const Text('Terima Kasih', style: TextStyle(fontFamily: 'Courier', fontSize: 9)),
                      ],
                    ),
                  ),
                ),

                // Corner Brackets
                Positioned(
                  top: 24,
                  left: 24,
                  child: _buildCorner(isTop: true, isLeft: true),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: _buildCorner(isTop: true, isLeft: false),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: _buildCorner(isTop: false, isLeft: true),
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: _buildCorner(isTop: false, isLeft: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Action Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanResultScreen()),
              );
            },
            child: const Text('Ambil Foto Bon / Faktur'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pastikan seluruh informasi pada bon terlihat jelas dan tidak blur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String item, String qtyPrice, String total, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (qtyPrice.isNotEmpty)
                Text(
                  qtyPrice,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black54),
                ),
            ],
          ),
        ),
        Text(
          total,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
