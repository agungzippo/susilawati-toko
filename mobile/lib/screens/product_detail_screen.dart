import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/bag_3d_graphic.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  int _adjustCount = 2;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final variants = (p['variants'] as List? ?? []);
    final v = variants.isNotEmpty ? variants[0] : {};
    final balances = (v['stockBalances'] as List? ?? []);
    final currentStock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 15;

    final selling = double.tryParse(v['referenceSellingPrice']?.toString() ?? '285000') ?? 285000;
    final cost = double.tryParse(balances.isNotEmpty ? balances[0]['averageCost']?.toString() ?? '185000' : '185000') ?? 185000;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Hero Bag 3D Image
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppColors.shadow3D,
            ),
            child: Center(
              child: Bag3DGraphic(
                bagType: p['name'] ?? 'tote',
                width: 200,
                height: 180,
                isHero: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Title & Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] ?? 'Tas Tote Minimalis',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${v['sku'] ?? 'TT001'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: AppColors.borderWarm),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur edit detail produk terbuka')),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textDark),
                label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Price Breakdown Section
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
                const Text('Harga Jual', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  _currency.format(selling),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Harga Modal', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                        const Text('Margin', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

          // 4. Interactive Stock Counter Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppColors.shadow3D,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.greenStock.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.greenStock, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok Tersedia', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        '$currentStock pcs',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                // Stepper
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderWarm),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_adjustCount > 1) setState(() => _adjustCount--);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_adjustCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _adjustCount++);
                        },
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
          ),
          const SizedBox(height: 20),

          // 5. Metadata List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppColors.shadow3D,
            ),
            child: Column(
              children: [
                _buildMetaRow(Icons.category_outlined, 'Kategori', p['category']?['name'] ?? 'Tas Tote'),
                const Divider(height: 20, color: AppColors.borderWarm),
                _buildMetaRow(Icons.person_outline, 'Suplier', 'PT. Maju Jaya'),
                const Divider(height: 20, color: AppColors.borderWarm),
                _buildMetaRow(Icons.location_on_outlined, 'Lokasi Penyimpanan', 'Rak A1'),
                const Divider(height: 20, color: AppColors.borderWarm),
                _buildMetaRow(Icons.calendar_today_outlined, 'Tanggal Input', '10 Jun 2025'),
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
