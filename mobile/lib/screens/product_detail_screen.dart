import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/bag_3d_graphic.dart';
import '../widgets/tactile_3d.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  late Map<String, dynamic> _product;
  int _adjustCount = 0;
  bool _isSavingStock = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _handleStockAdjustment(String variantId, double unitCost) async {
    if (_adjustCount == 0) return;

    setState(() => _isSavingStock = true);
    try {
      if (_adjustCount > 0) {
        // Tambah stok
        await ApiService.instance.addStock(
          variantId: variantId,
          quantity: _adjustCount,
          unitCost: unitCost,
        );
      } else {
        // Kurang stok
        await ApiService.instance.stockOut({
          'customerName': 'Koreksi Fisik Toko',
          'date': DateTime.now().toIso8601String(),
          'items': [
            {
              'variantId': variantId,
              'quantity': _adjustCount.abs(),
            }
          ],
          'notes': 'Penyesuaian stok manual dari detail produk',
        });
      }

      // Reload single product
      final updatedProds = await ApiService.instance.getProducts();
      final updated = updatedProds.firstWhere(
        (p) => p['id'] == _product['id'],
        orElse: () => _product,
      );

      if (mounted) {
        setState(() {
          _product = updated;
          _adjustCount = 0;
          _isSavingStock = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok produk berhasil diperbarui di sistem!'),
            backgroundColor: AppColors.greenStock,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingStock = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.redStock,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final variants = (p['variants'] as List? ?? []);
    final v = variants.isNotEmpty ? variants[0] : {};
    final balances = (v['stockBalances'] as List? ?? []);
    final currentStock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;

    final selling = double.tryParse(v['referenceSellingPrice']?.toString() ?? '0') ?? 0;
    final cost = double.tryParse(balances.isNotEmpty ? balances[0]['averageCost']?.toString() ?? '0' : '0') ?? 0;
    final margin = selling - cost;
    final marginPercent = selling > 0 ? (margin / selling * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Detail Barang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Hero Bag 3D Image Card with Ambient Shadows
          Tactile3DCard(
            isElevated: true,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Bag3DGraphic(
                bagType: p['name'] ?? 'tote',
                width: 220,
                height: 190,
                isHero: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Title & SKU Info Card
          Tactile3DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? 'Nama Produk',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Brand: ${p['brand'] ?? 'Susilawati Exclusive'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentStock > 5 ? AppColors.greenStock.withValues(alpha: 0.12) : AppColors.amberStock.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentStock > 5 ? 'Stok Aman' : (currentStock > 0 ? 'Stok Menipis' : 'Stok Habis'),
                        style: TextStyle(
                          color: currentStock > 5 ? AppColors.greenStock : (currentStock > 0 ? AppColors.amberStock : AppColors.redStock),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Price Breakdown Section
          Tactile3DCard(
            isElevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Harga Jual Acuan', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  _currency.format(selling),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brandEspresso),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Modal Rata-Rata', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          _currency.format(cost),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Potensi Margin', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '${_currency.format(margin)} ($marginPercent%)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.greenStock),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Interactive Stock Counter & Quick Adjust Card
          Tactile3DCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.greenStock.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: AppColors.greenStock, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stok Fisik Tersedia', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            '$currentStock pcs',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                    // Stepper penyesuaian
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderWarm),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (currentStock + (_adjustCount - 1) >= 0) {
                                setState(() => _adjustCount--);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _adjustCount >= 0 ? '+$_adjustCount' : '$_adjustCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _adjustCount == 0 ? AppColors.textDark : (_adjustCount > 0 ? AppColors.greenStock : AppColors.redStock),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _adjustCount++),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_adjustCount != 0) ...[
                  const SizedBox(height: 14),
                  Tactile3DButton(
                    height: 42,
                    isLoading: _isSavingStock,
                    backgroundColor: _adjustCount > 0 ? AppColors.greenStock : AppColors.redStock,
                    onPressed: _isSavingStock
                        ? null
                        : () => _handleStockAdjustment(v['id'], cost),
                    child: Text('Simpan Koreksi Stok (${_adjustCount >= 0 ? '+$_adjustCount' : '$_adjustCount'} pcs)'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Metadata List Riil
          Tactile3DCard(
            child: Column(
              children: [
                _buildMetaRow(Icons.category_outlined, 'Kategori', p['category']?['name'] ?? 'Tas Butik'),
                const Divider(height: 18, color: AppColors.borderWarm),
                _buildMetaRow(Icons.qr_code_2_rounded, 'SKU Produk', v['sku'] ?? '-'),
                const Divider(height: 18, color: AppColors.borderWarm),
                _buildMetaRow(Icons.barcode_reader, 'Barcode', v['barcode'] ?? '-'),
                const Divider(height: 18, color: AppColors.borderWarm),
                _buildMetaRow(Icons.palette_outlined, 'Varian Warna', v['color'] ?? 'Standard'),
                const Divider(height: 18, color: AppColors.borderWarm),
                _buildMetaRow(Icons.warehouse_outlined, 'Lokasi Gudang', 'Gudang Utama Toko'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }
}
