import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class ScanResultScreen extends StatefulWidget {
  final Map<String, dynamic>? invoiceData;
  const ScanResultScreen({super.key, this.invoiceData});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isSaving = false;

  late String _supplierName;
  late String _invoiceNumber;
  late String _invoiceDate;
  late List<Map<String, dynamic>> _items;
  late double _totalAmount;

  @override
  void initState() {
    super.initState();
    _supplierName = widget.invoiceData?['supplierName'] ?? 'PT. Maju Jaya';
    _invoiceNumber = widget.invoiceData?['invoiceNumber'] ?? 'FJ-2025-0612-001';
    _invoiceDate = widget.invoiceData?['invoiceDate'] ?? '12 Jun 2025';

    _items = [
      {
        'name': 'Tas Tote Minimalis',
        'qty': 5,
        'unitPrice': 180000.0,
        'subtotal': 900000.0,
      },
      {
        'name': 'Shoulder Bag',
        'qty': 3,
        'unitPrice': 150000.0,
        'subtotal': 450000.0,
      },
    ];

    _totalAmount = _items.fold(0.0, (acc, item) => acc + (item['subtotal'] as double));
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // Refresh summary / trigger update in background
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok berhasil diperbarui dari bon faktur!'),
            backgroundColor: AppColors.greenStock,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.redStock,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Hasil Pemindaian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Section 1: Informasi dari Bon / Faktur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppColors.shadow3D,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi dari Bon / Faktur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                _buildInfoField('Nama Suplier', _supplierName),
                const SizedBox(height: 10),
                _buildInfoField('No. Faktur', _invoiceNumber),
                const SizedBox(height: 10),
                _buildInfoField('Tanggal', _invoiceDate),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Detail Barang
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppColors.shadow3D,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Barang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('Harga Beli', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderWarm),

                // Table Rows
                ..._items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            it['name'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${it['qty']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _currency.format(it['unitPrice']),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _currency.format(it['subtotal']),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 1, color: AppColors.borderWarm),
                const SizedBox(height: 12),

                // Total Pembelian
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembelian',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      _currency.format(_totalAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Simpan & Tambah ke Stok'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ulangi Scan'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
