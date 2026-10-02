import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'incoming_screen.dart';
import 'stock_out_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String _selectedFilter = 'Semua'; // 'Semua', 'Barang Masuk', 'Barang Keluar'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await ApiService.instance.getRecentTransactions(limit: 50);
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'Semua') return _transactions;
    if (_selectedFilter == 'Barang Masuk') {
      return _transactions.where((tx) => tx['type'] == 'IN').toList();
    }
    return _transactions.where((tx) => tx['type'] == 'OUT').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Quick Action Cards (Barang Masuk & Barang Keluar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncomingScreen()),
                      );
                      _loadTransactions();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                              color: AppColors.greenStock.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: AppColors.greenStock,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barang Masuk',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Scan Bon Faktur',
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StockOutScreen()),
                      );
                      _loadTransactions();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                              color: AppColors.redStock.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.redStock,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barang Keluar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Catat Penjualan',
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Filter Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: ['Semua', 'Barang Masuk', 'Barang Keluar'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandEspresso : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.brandEspresso : AppColors.borderWarm,
                        ),
                        boxShadow: AppColors.shadow3D,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              color: AppColors.brandEspresso,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandEspresso))
                  : _filteredTransactions.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            const Center(
                              child: Text(
                                'Belum ada data transaksi',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _filteredTransactions[index];
                            final isIncoming = tx['type'] == 'IN';
                            final iconBg = isIncoming ? AppColors.greenStock : AppColors.redStock;
                            final icon = isIncoming ? Icons.add : Icons.remove;
                            final formattedDate = tx['date'] != null
                                ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(tx['date']))
                                : '-';

                            final totalVal = double.tryParse(tx['totalValue']?.toString() ?? '0') ?? 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderWarm),
                                boxShadow: AppColors.shadow3D,
                              ),
                              child: Row(
                                children: [
                                  // Circle Icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
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
                                        const SizedBox(height: 2),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Total Value
                                  if (totalVal > 0)
                                    Text(
                                      _currency.format(totalVal),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                ],
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
