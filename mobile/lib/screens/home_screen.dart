import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _alerts;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ApiService.instance.getSavedUser();
      final summary = await ApiService.instance.getSummary();
      final alerts = await ApiService.instance.getAlerts();

      if (mounted) {
        setState(() {
          _user = user;
          _summary = summary;
          _alerts = alerts;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUSILAWATI TOKO'),
            Text(
              _user?['name'] ?? 'Sistem Monitoring Stok',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _user?['role'] == 'OWNER' ? 'PEMILIK' : 'STAF TOKO',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Ringkasan Utama (4 Kartu Finansial & Operasional)
                      Text(
                        'Ringkasan Persediaan',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Unit Stok',
                              value: '${_summary?['totalUnits'] ?? 0} pcs',
                              subtitle: '${_summary?['totalSkus'] ?? 0} SKU Varian',
                              icon: Icons.inventory_2_outlined,
                              accentColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Estimasi Potensi Laba',
                              value: _currency.format(_summary?['estimatedPotentialProfit'] ?? 0),
                              subtitle: 'Sebelum Biaya Operasional',
                              icon: Icons.trending_up,
                              accentColor: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Nilai Modal Stok',
                              value: _currency.format(_summary?['totalCostValue'] ?? 0),
                              subtitle: 'Metode Rata-Rata Tertimbang',
                              icon: Icons.account_balance_wallet_outlined,
                              accentColor: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Nilai Jual Acuan',
                              value: _currency.format(_summary?['totalSellingValue'] ?? 0),
                              subtitle: 'Potensi Omset Stok',
                              icon: Icons.sell_outlined,
                              accentColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Peringatan Stok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Peringatan Stok', style: theme.textTheme.titleMedium),
                          if ((_alerts?['lowStockCount'] ?? 0) > 0 || (_alerts?['outOfStockCount'] ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(_alerts?['lowStockCount'] ?? 0) + (_alerts?['outOfStockCount'] ?? 0)} Perlu Restok',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if ((_alerts?['lowStock'] as List?)?.isEmpty ?? true)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: AppColors.accent, size: 24),
                                SizedBox(width: 12),
                                Text('Seluruh varian produk dalam batas stok aman.'),
                              ],
                            ),
                          ),
                        )
                      else
                        ...((_alerts?['lowStock'] as List? ?? []).map((item) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                              ),
                              title: Text(
                                item['productName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                'SKU: ${item['sku']} • Warna: ${item['color'] ?? '-'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sisa ${item['currentStock']} pcs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Min: ${item['minimumStock']} pcs',
                                    style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })),

                      const SizedBox(height: 24),

                      // Tombol Aksi Cepat
                      Text('Aksi Operasional', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onNavigateTab?.call(2), // Tab Scan
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              label: const Text('Scan Barcode'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onNavigateTab?.call(1), // Tab Stok
                              icon: const Icon(Icons.list_alt, color: AppColors.primary),
                              label: const Text('Lihat Katalog'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
