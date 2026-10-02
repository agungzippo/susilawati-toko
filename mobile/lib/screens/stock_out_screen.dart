import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/bag_3d_graphic.dart';
import '../widgets/tactile_3d.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _customerController = TextEditingController(text: 'Toko Sumber Rezeki');
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  
  // Selected items to stock-out: Map of variantId -> { variant, product, quantity }
  final Map<String, Map<String, dynamic>> _selectedItems = {};

  double get _totalPenjualan {
    double total = 0;
    _selectedItems.forEach((_, item) {
      final v = item['variant'];
      final price = double.tryParse(v['referenceSellingPrice']?.toString() ?? '0') ?? 0;
      final qty = item['quantity'] as int;
      total += (price * qty);
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final prods = await ApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _allProducts = prods;
          _filteredProducts = prods;
          _isLoading = false;

          // Auto-select first 1 or 2 products with available stock
          for (var p in _allProducts) {
            final vars = p['variants'] as List? ?? [];
            for (var v in vars) {
              final balances = v['stockBalances'] as List? ?? [];
              final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;
              if (stock > 0 && _selectedItems.length < 2) {
                _selectedItems[v['id']] = {
                  'product': p,
                  'variant': v,
                  'stock': stock,
                  'quantity': 1,
                };
              }
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) {
          final name = (p['name']?.toString() ?? '').toLowerCase();
          final brand = (p['brand']?.toString() ?? '').toLowerCase();
          final vars = (p['variants'] as List? ?? []);
          final matchesSku = vars.any((v) => (v['sku']?.toString() ?? '').toLowerCase().contains(query));
          return name.contains(query) || brand.contains(query) || matchesSku;
        }).toList();
      }
    });
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.borderWarm, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pilih Barang Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama produk / SKU...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, idx) {
                      final p = _filteredProducts[idx];
                      final vars = p['variants'] as List? ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: vars.map((v) {
                          final balances = v['stockBalances'] as List? ?? [];
                          final stock = balances.isNotEmpty ? (balances[0]['quantityOnHand'] as int? ?? 0) : 0;
                          final isSelected = _selectedItems.containsKey(v['id']);
                          final price = double.tryParse(v['referenceSellingPrice']?.toString() ?? '0') ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.brandEspresso.withValues(alpha: 0.05) : AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.brandEspresso : AppColors.borderWarm),
                            ),
                            child: ListTile(
                              leading: Bag3DGraphic(bagType: p['name'] ?? 'tote', width: 44, height: 44),
                              title: Text('${p['name']} (${v['color'] ?? 'Default'})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Stok: $stock pcs | ${_currency.format(price)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              trailing: IconButton(
                                icon: Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: isSelected ? AppColors.greenStock : AppColors.brandEspresso,
                                ),
                                onPressed: stock <= 0
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedItems.remove(v['id']);
                                          } else {
                                            _selectedItems[v['id']] = {
                                              'product': p,
                                              'variant': v,
                                              'stock': stock,
                                              'quantity': 1,
                                            };
                                          }
                                        });
                                        Navigator.pop(context);
                                      },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSaveTransaction() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 barang untuk dicatat keluar')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsPayload = _selectedItems.entries.map((entry) {
        return {
          'variantId': entry.key,
          'quantity': entry.value['quantity'],
        };
      }).toList();

      await ApiService.instance.stockOut({
        'customerName': _customerController.text.trim().isEmpty ? 'Pelanggan Toko' : _customerController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'items': itemsPayload,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Barang Keluar berhasil disimpan ke sistem!'),
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
        title: const Text('Barang Keluar (Penjualan)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandEspresso))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Kartu Tanggal & Pelanggan (3D Tactile Card)
                Tactile3DCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tanggal Transaksi
                      const Text('Tanggal Transaksi', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
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
                                DateFormat('dd MMMM yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nama Pelanggan
                      const Text('Nama Pelanggan / Tujuan', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Toko Sumber Rezeki / Pembeli Langsung',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Header Daftar Barang & Tombol Tambah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barang yang Dikeluarkan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    TextButton.icon(
                      onPressed: _showAddProductModal,
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.brandEspresso),
                      label: const Text('Tambah Barang', style: TextStyle(color: AppColors.brandEspresso, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Selected Items List with 3D Cards & Steppers
                if (_selectedItems.isEmpty)
                  Tactile3DCard(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          const Text('Belum ada barang yang dipilih', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _showAddProductModal,
                            child: const Text('Pilih dari Daftar Barang'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._selectedItems.entries.map((entry) {
                    final item = entry.value;
                    final p = item['product'];
                    final v = item['variant'];
                    final int stock = item['stock'];
                    final int qty = item['quantity'];
                    final price = double.tryParse(v['referenceSellingPrice']?.toString() ?? '0') ?? 0;

                    return Tactile3DCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Bag3DGraphic(bagType: p['name'] ?? 'tote', width: 48, height: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['name']} (${v['color'] ?? 'Default'})',
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
                          // Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              border: Border.all(color: AppColors.borderWarm),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (qty > 1) {
                                        item['quantity'] = qty - 1;
                                      } else {
                                        _selectedItems.remove(entry.key);
                                      }
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                  onTap: () {
                                    if (qty < stock) {
                                      setState(() => item['quantity'] = qty + 1);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Jumlah melebihi stok yang tersedia ($stock pcs)')),
                                      );
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    child: Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 20),

                // 4. Catatan Opsional
                Tactile3DCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catatan Transaksi (Opsional)', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Pembayaran tunai lunas di toko',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Total Penjualan Card
                Tactile3DCard(
                  isElevated: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Penjualan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        _currency.format(_totalPenjualan),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandEspresso),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Tombol Simpan Transaksi (3D Tactile Push)
                Tactile3DButton(
                  onPressed: _isSubmitting ? null : _handleSaveTransaction,
                  isLoading: _isSubmitting,
                  icon: Icons.check_circle_rounded,
                  child: const Text('Simpan Transaksi Barang Keluar'),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
