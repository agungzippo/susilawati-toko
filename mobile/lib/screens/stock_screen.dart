import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _products = [];
  String _selectedFilter = 'ALL'; // ALL, SAFE, LOW, EMPTY
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndLoad();
  }

  Future<void> _checkRoleAndLoad() async {
    final user = await ApiService.instance.getSavedUser();
    if (mounted) {
      setState(() {
        _isOwner = user?['role'] == 'OWNER';
      });
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedFilter == 'ALL') return _products;

    return _products.where((p) {
      final variants = (p['variants'] as List? ?? []);
      return variants.any((v) {
        final balances = (v['stockBalances'] as List? ?? []);
        final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;
        final minStock = v['minimumStock'] as int? ?? 5;

        if (_selectedFilter == 'SAFE') return stock > minStock;
        if (_selectedFilter == 'LOW') return stock > 0 && stock <= minStock;
        if (_selectedFilter == 'EMPTY') return stock <= 0;
        return true;
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Katalog & Stok Barang'),
      ),
      body: Column(
        children: [
          // Bar Pencarian & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama tas, brand, SKU, atau barcode...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _loadProducts();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadProducts(),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'ALL'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Stok Aman', 'SAFE'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Stok Menipis', 'LOW'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Habis', 'EMPTY'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Daftar Produk
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: AppColors.accent,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                                const SizedBox(height: 12),
                                Text(_error!),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadProducts, child: const Text('Coba Lagi')),
                              ],
                            ),
                          ),
                        )
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.mutedForeground),
                                  SizedBox(height: 12),
                                  Text(
                                    'Tidak ada produk yang sesuai filter',
                                    style: TextStyle(color: AppColors.mutedForeground),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final variants = product['variants'] as List? ?? [];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Produk
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product['name'] ?? '',
                                                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${product['brand'] ?? 'Tanpa Brand'} • Kategori: ${product['category']?['name'] ?? '-'}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(color: AppColors.border, height: 1),
                                        const SizedBox(height: 8),

                                        // Daftar Varian
                                        ...variants.map((v) {
                                          final balances = v['stockBalances'] as List? ?? [];
                                          final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;
                                          final cost = balances.isNotEmpty ? (balances[0]['averageCost']) : 0;
                                          final minStock = v['minimumStock'] as int? ?? 5;
                                          final selling = v['referenceSellingPrice'];

                                          Color badgeColor = AppColors.accent;
                                          String badgeText = 'Aman';
                                          if (stock <= 0) {
                                            badgeColor = AppColors.destructive;
                                            badgeText = 'Habis';
                                          } else if (stock <= minStock) {
                                            badgeColor = AppColors.warning;
                                            badgeText = 'Menipis';
                                          }

                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '${v['color'] ?? 'Default'} (${v['size'] ?? 'All Size'})',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: badgeColor.withValues(alpha: 0.12),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              badgeText,
                                                              style: TextStyle(
                                                                color: badgeColor,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'SKU: ${v['sku']} • Barcode: ${v['barcode'] ?? '-'}',
                                                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Jual: ${_currency.format(double.tryParse(selling.toString()) ?? 0)}',
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                                          ),
                                                          if (_isOwner) ...[
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              '• Modal: ${_currency.format(double.tryParse(cost.toString()) ?? 0)}',
                                                              style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '$stock pcs',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: badgeColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Min: $minStock',
                                                      style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.foreground,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
