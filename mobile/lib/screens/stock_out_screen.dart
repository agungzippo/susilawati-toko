import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/bag_3d_graphic.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int _selectedMode = 0; // 0 = Manual, 1 = Scan Bon / Nota
  String _selectedCustomer = 'Toko Sumber Rezeki';
  DateTime _selectedDate = DateTime.now();

  int _qtyTote = 2;
  int _qtyShoulder = 1;

  final double _priceTote = 285000;
  final double _priceShoulder = 260000;

  bool _isSubmitting = false;

  double get _totalPenjualan => (_qtyTote * _priceTote) + (_qtyShoulder * _priceShoulder);

  Future<void> _handleSaveTransaction() async {
    setState(() => _isSubmitting = true);

    try {
      // Find variant IDs from backend
      final products = await ApiService.instance.getProducts();
      final pTote = products.firstWhere((p) => p['name'] == 'Tas Tote Minimalis', orElse: () => null);
      final pShoulder = products.firstWhere((p) => p['name'] == 'Shoulder Bag', orElse: () => null);

      if (pTote != null && pShoulder != null) {
        final varToteId = pTote['variants'][0]['id'];
        final varShoulderId = pShoulder['variants'][0]['id'];

        await ApiService.instance.stockOut({
          'customerName': _selectedCustomer,
          'date': _selectedDate.toIso8601String(),
          'items': [
            {'variantId': varToteId, 'quantity': _qtyTote},
            {'variantId': varShoulderId, 'quantity': _qtyShoulder},
          ],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Barang Keluar berhasil disimpan!'),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Barang Keluar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
                        'Scan Bon / Nota',
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

          // 2. Form Tanggal
          const Text('Tanggal', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Form Pelanggan
          const Text('Pelanggan', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCustomer,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                items: const [
                  DropdownMenuItem(value: 'Toko Sumber Rezeki', child: Text('Toko Sumber Rezeki')),
                  DropdownMenuItem(value: 'Boutique Cantik Bandung', child: Text('Boutique Cantik Bandung')),
                  DropdownMenuItem(value: 'Pelanggan Langsung', child: Text('Pelanggan Langsung')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCustomer = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Barang Search
          const Text('Barang', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 18, color: AppColors.textMuted),
                SizedBox(width: 10),
                Text('Cari barang...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Selected Items with Steppers
          _buildItemCard(
            name: 'Tas Tote Minimalis',
            stock: 15,
            price: _priceTote,
            qty: _qtyTote,
            onDecrement: () {
              if (_qtyTote > 1) setState(() => _qtyTote--);
            },
            onIncrement: () => setState(() => _qtyTote++),
          ),
          const SizedBox(height: 10),
          _buildItemCard(
            name: 'Shoulder Bag',
            stock: 8,
            price: _priceShoulder,
            qty: _qtyShoulder,
            onDecrement: () {
              if (_qtyShoulder > 1) setState(() => _qtyShoulder--);
            },
            onIncrement: () => setState(() => _qtyShoulder++),
          ),
          const SizedBox(height: 24),

          // 6. Total Penjualan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Penjualan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              Text(
                _currency.format(_totalPenjualan),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7. Simpan Transaksi Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSaveTransaction,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Transaksi'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String name,
    required int stock,
    required double price,
    required int qty,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: AppColors.shadow3D,
      ),
      child: Row(
        children: [
          Bag3DGraphic(bagType: name, width: 50, height: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok $stock pcs  |  ${_currency.format(price)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderWarm),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onDecrement,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.remove, size: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$qty',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                InkWell(
                  onTap: onIncrement,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
