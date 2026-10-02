import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class IncomingScreen extends StatefulWidget {
  const IncomingScreen({super.key});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  String? _error;
  List<dynamic> _invoices = [];
  List<dynamic> _schedules = [];

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
      final invoices = await ApiService.instance.getInvoices();
      final schedules = await ApiService.instance.getSchedules();

      if (mounted) {
        setState(() {
          _invoices = invoices;
          _schedules = schedules;
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

  void _showReceiptDialog(Map<String, dynamic> schedule) {
    final invoice = schedule['invoice'] ?? {};
    final items = (invoice['items'] as List? ?? []);

    final qtyControllers = <String, TextEditingController>{};
    for (final it in items) {
      final variantId = it['variantId'] ?? it['id'];
      final conv = (it['conversionFactor'] as num? ?? 1).toDouble();
      final expectedPcs = ((it['quantity'] as num? ?? 1) * conv).toInt();
      qtyControllers[variantId] = TextEditingController(text: expectedPcs.toString());
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_outlined, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Terima Barang: ${invoice['internalNumber'] ?? ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Supplier: ${invoice['supplier']?['name'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Periksa jumlah fisik barang (dalam pcs):',
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 12),
              ...items.map((it) {
                final variantId = it['variantId'] ?? it['id'];
                final variant = it['variant'] ?? {};
                final product = variant['product'] ?? {};
                final conv = (it['conversionFactor'] as num? ?? 1).toDouble();
                final expectedPcs = ((it['quantity'] as num? ?? 1) * conv).toInt();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it['rawName'] ?? product['name'] ?? 'Item',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Dipesan: ${it['quantity']} ${it['unit']} (≈ $expectedPcs pcs)',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Jumlah Baik (pcs):', style: TextStyle(fontSize: 12)),
                          const Spacer(),
                          SizedBox(
                            width: 80,
                            height: 40,
                            child: TextField(
                              controller: qtyControllers[variantId],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(110, 42),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Buat payload
              final receiptItems = items.map((it) {
                final variantId = it['variantId'] ?? it['id'];
                final conv = (it['conversionFactor'] as num? ?? 1).toDouble();
                final expectedPcs = ((it['quantity'] as num? ?? 1) * conv).toInt();
                final receivedPcs = int.tryParse(qtyControllers[variantId]?.text ?? '') ?? expectedPcs;
                final unitCost = (it['unitCost'] as num? ?? 0).toDouble() / conv;

                return {
                  'invoiceItemId': it['id'],
                  'variantId': variantId,
                  'expectedQuantity': expectedPcs,
                  'receivedQuantity': receivedPcs,
                  'damagedQuantity': 0,
                  'shortQuantity': expectedPcs > receivedPcs ? expectedPcs - receivedPcs : 0,
                  'unitCost': unitCost,
                };
              }).toList();

              final idempotencyKey = 'RECEIPT-${schedule['id']}-${DateTime.now().millisecondsSinceEpoch}';

              try {
                await ApiService.instance.confirmReceipt({
                  'scheduleId': schedule['id'],
                  'idempotencyKey': idempotencyKey,
                  'items': receiptItems,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Penerimaan barang berhasil dicatat! Stok otomatis bertambah.'),
                      backgroundColor: AppColors.accent,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.destructive,
                    ),
                  );
                }
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RECEIVED':
      case 'CONFIRMED':
      case 'VERIFIED':
        return AppColors.accent;
      case 'SCHEDULED':
      case 'NEEDS_REVIEW':
        return AppColors.warning;
      case 'LATE':
      case 'CANCELLED':
        return AppColors.destructive;
      default:
        return AppColors.secondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'IMAGE_UPLOADED':
        return 'Foto Diunggah';
      case 'PROCESSING':
        return 'Ekstraksi AI...';
      case 'NEEDS_REVIEW':
        return 'Perlu Diperiksa';
      case 'VERIFIED':
        return 'Terverifikasi';
      case 'SCHEDULED':
        return 'Dijadwalkan';
      case 'RECEIVED':
        return 'Diterima Lengkap';
      case 'PARTIALLY_RECEIVED':
        return 'Sebagian Diterima';
      case 'LATE':
        return 'Terlambat';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barang Masuk & Faktur'),
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
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Jadwal Kedatangan Aktif
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jadwal Kedatangan Barang', style: theme.textTheme.titleMedium),
                          Text('${_schedules.length} Jadwal', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_schedules.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: const [
                                Icon(Icons.local_shipping_outlined, color: AppColors.mutedForeground, size: 36),
                                SizedBox(height: 8),
                                Text('Tidak ada jadwal pengiriman aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._schedules.map((s) {
                          final inv = s['invoice'] ?? {};
                          final status = s['status'] as String? ?? 'SCHEDULED';
                          final statusColor = _getStatusColor(status);
                          final isPending = status == 'SCHEDULED' || status == 'LATE' || status == 'PARTIALLY_RECEIVED';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getStatusLabel(status),
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      Text(
                                        inv['internalNumber'] ?? '',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    inv['supplier']?['name'] ?? 'Supplier Grosir',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estimasi Sampai: ${DateFormat('dd MMM yyyy').format(DateTime.parse(s['expectedDate']))}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                  if (isPending) ...[
                                    const SizedBox(height: 14),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        minimumSize: const Size.fromHeight(42),
                                      ),
                                      onPressed: () => _showReceiptDialog(s),
                                      icon: const Icon(Icons.done_all, size: 18),
                                      label: const Text('Terima & Hitung Fisik'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Daftar Faktur Supplier
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Faktur & Bon Pembelian', style: theme.textTheme.titleMedium),
                          Text('${_invoices.length} Faktur', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._invoices.map((inv) {
                        final status = inv['status'] as String? ?? 'DRAFT';
                        final statusColor = _getStatusColor(status);
                        final total = double.tryParse(inv['grandTotal'].toString()) ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.receipt_long, color: AppColors.primary),
                            ),
                            title: Text(
                              inv['internalNumber'] ?? 'Faktur',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${inv['supplier']?['name'] ?? 'Supplier'} • Total: ${_currency.format(total)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }
}
