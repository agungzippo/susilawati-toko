import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/box_3d_icon.dart';
import 'incoming_screen.dart';
import 'stock_out_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await ApiService.instance.getSummary();
      final txs = await ApiService.instance.getRecentTransactions(limit: 5);

      if (mounted) {
        setState(() {
          _summary = summary;
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.brandEspresso,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandEspresso))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // 1. Header (susilawati toko .)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'susilawati',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              't o k o  .',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderWarm),
                                boxShadow: AppColors.shadow3D,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.textDark,
                                size: 22,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.greenStock,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Kartu Highlight Utama (Total Stok & Nilai Persediaan)
                    Row(
                      children: [
                        // Card 1: Total Stok
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderWarm),
                              boxShadow: AppColors.shadow3D,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Box3DIcon(size: 38),
                                const SizedBox(height: 12),
                                const Text(
                                  'Total Stok',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${_summary?['totalUnits'] ?? 248}',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'item',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Card 2: Nilai Persediaan
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderWarm),
                              boxShadow: AppColors.shadow3D,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Nilai Persediaan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _currency.format(_summary?['totalCostValue'] ?? 18750000),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Potensi Omset: ${_currency.format(_summary?['totalSellingValue'] ?? 0)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Stat Ticker (Barang Masuk, Barang Keluar, Total Transaksi)
                    Row(
                      children: [
                        _buildMiniTicker(
                          title: 'Barang Masuk',
                          icon: Icons.arrow_upward_rounded,
                          iconColor: AppColors.greenStock,
                          value: '${_summary?['itemsInToday'] ?? 12}',
                          suffix: 'item',
                        ),
                        const SizedBox(width: 10),
                        _buildMiniTicker(
                          title: 'Barang Keluar',
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.redStock,
                          value: '${_summary?['itemsOutToday'] ?? 8}',
                          suffix: 'item',
                        ),
                        const SizedBox(width: 10),
                        _buildMiniTicker(
                          title: 'Total Transaksi',
                          icon: Icons.receipt_long_outlined,
                          iconColor: AppColors.brandWarm,
                          value: '${_summary?['transactionsToday'] ?? 5}',
                          suffix: 'hari ini',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Grid Menu Cepat (6 Tombol 3D Bersegi)
                    Row(
                      children: [
                        _buildActionTile(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stok Barang',
                          onTap: () => widget.onNavigateTab?.call(1),
                        ),
                        const SizedBox(width: 12),
                        _buildActionTile(
                          icon: Icons.input_rounded,
                          label: 'Barang Masuk',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const IncomingScreen()),
                          ).then((_) => _loadData()),
                        ),
                        const SizedBox(width: 12),
                        _buildActionTile(
                          icon: Icons.output_rounded,
                          label: 'Barang Keluar',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StockOutScreen()),
                          ).then((_) => _loadData()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Suplier',
                          onTap: () => widget.onNavigateTab?.call(3),
                        ),
                        const SizedBox(width: 12),
                        _buildActionTile(
                          icon: Icons.monetization_on_outlined,
                          label: 'Harga & Modal',
                          onTap: _showFinancialModal,
                        ),
                        const SizedBox(width: 12),
                        _buildActionTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Laporan',
                          onTap: _showReportDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 5. Transaksi Terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Terbaru',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigateTab?.call(1),
                          child: const Text(
                            'Lihat Semua >',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderWarm),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada transaksi terbaru hari ini',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._transactions.map((tx) {
                        final isIncoming = tx['type'] == 'IN';
                        final iconBg = isIncoming ? AppColors.greenStock : AppColors.redStock;
                        final icon = isIncoming ? Icons.add : Icons.remove;
                        final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(tx['date']));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderWarm),
                            boxShadow: AppColors.shadow3D,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['title'] ?? (isIncoming ? 'Barang Masuk' : 'Barang Keluar'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx['productName']} (${tx['quantity']} pcs)',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _currency.format(tx['totalAmount'] ?? 0),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMiniTicker({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String suffix,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderWarm),
          boxShadow: AppColors.shadow3D,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(width: 2),
                Text(
                  suffix,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.tileBeige,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: AppColors.shadow3D,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderWarm),
                ),
                child: Icon(icon, color: AppColors.brandEspresso, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinancialModal() {
    showModalBottomSheet(
      context: context,
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
                  color: AppColors.borderWarm,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rincian Finansial Stok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _buildFinancialRow('Nilai Modal Persediaan', _currency.format(_summary?['totalCostValue'] ?? 0)),
            const Divider(color: AppColors.borderWarm),
            _buildFinancialRow('Potensi Omset Penjualan', _currency.format(_summary?['totalSellingValue'] ?? 0)),
            const Divider(color: AppColors.borderWarm),
            _buildFinancialRow(
              'Estimasi Potensi Laba',
              _currency.format(_summary?['estimatedPotentialProfit'] ?? 0),
              highlight: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.greenStock : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ekspor Laporan'),
        content: const Text('Unduh laporan stok toko terkini dalam format CSV untuk pembukuan Excel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandEspresso),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan CSV siap diunduh dari server via /api/v1/inventory/export-csv'),
                  backgroundColor: AppColors.greenStock,
                ),
              );
            },
            child: const Text('Ekspor CSV'),
          ),
        ],
      ),
    );
  }
}
