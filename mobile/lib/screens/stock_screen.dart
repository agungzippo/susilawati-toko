import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/bag_3d_graphic.dart';
import 'product_detail_screen.dart';

class StockScreen extends StatefulWidget {
  final bool showBackButton;
  const StockScreen({super.key, this.showBackButton = false});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _products = [];
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Tas Tote',
    'Shoulder Bag',
    'Backpack',
    'Tas Selempang',
    'Tas Ransel',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.instance.getProducts(
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedCategory == 'Semua') return _products;
    return _products.where((p) {
      final catName = p['category']?['name']?.toString().toLowerCase() ?? '';
      final prodName = p['name']?.toString().toLowerCase() ?? '';
      final filter = _selectedCategory.toLowerCase();
      return catName.contains(filter) || prodName.contains(filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Stok Barang'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          // 1. Search Box + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderWarm),
                      boxShadow: AppColors.shadow3D,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari nama barang...',
                        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _loadProducts(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderWarm),
                    boxShadow: AppColors.shadow3D,
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.textDark, size: 20),
                ),
              ],
            ),
          ),

          // 2. Horizontal Filter Pills
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandEspresso : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.brandEspresso : AppColors.borderWarm,
                      ),
                      boxShadow: isSelected ? AppColors.buttonShadow3D : AppColors.shadow3D,
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 3. Product Cards List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: AppColors.brandEspresso,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandEspresso))
                  : _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada barang ditemukan',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProducts[index];
                            final variants = (p['variants'] as List? ?? []);
                            final v = variants.isNotEmpty ? variants[0] : {};
                            final balances = (v['stockBalances'] as List? ?? []);
                            final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 15;
                            final cost = double.tryParse(balances.isNotEmpty ? balances[0]['averageCost']?.toString() ?? '185000' : '185000') ?? 185000;
                            final selling = double.tryParse(v['referenceSellingPrice']?.toString() ?? '285000') ?? 285000;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: p),
                                  ),
                                ).then((_) => _loadProducts());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderWarm),
                                  boxShadow: AppColors.shadow3D,
                                ),
                                child: Row(
                                  children: [
                                    // 3D Bag Thumbnail
                                    Bag3DGraphic(
                                      bagType: p['name'] ?? 'tote',
                                      width: 60,
                                      height: 60,
                                    ),
                                    const SizedBox(width: 12),

                                    // Title, SKU, Green Stock Dot
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] ?? 'Nama Produk',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'SKU: ${v['sku'] ?? 'TT001'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.greenStock,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Stok $stock pcs',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.greenStock,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Pricing & Chevron
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Jual ${_currency.format(selling)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Modal ${_currency.format(cost)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
