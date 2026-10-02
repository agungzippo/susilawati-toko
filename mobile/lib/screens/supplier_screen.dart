import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class SupplierScreen extends StatefulWidget {
  final bool showBackButton;
  const SupplierScreen({super.key, this.showBackButton = false});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final sups = await ApiService.instance.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = sups;
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
      appBar: AppBar(
        title: const Text('Suplier'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Form tambah suplier')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  hintText: 'Cari nama suplier...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Supplier List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSuppliers,
              color: AppColors.brandEspresso,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandEspresso))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        ..._suppliers.map((s) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderWarm),
                              boxShadow: AppColors.shadow3D,
                            ),
                            child: Row(
                              children: [
                                // 3D Building Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3EFEA),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.borderWarm),
                                  ),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: AppColors.brandEspresso,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Supplier Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s['name'] ?? 'Nama Suplier',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            s['phone'] ?? '-',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.mail_outline_rounded, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            s['email'] ?? '-',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // 3. Ringkasan Finansial Suplier Card (Sesuai Mockup)
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
                              const Text(
                                'Ringkasan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Total Suplier', '${_suppliers.length}'),
                              const Divider(height: 16, color: AppColors.borderWarm),
                              _buildSummaryRow('Total Hutang', _currency.format(4250000)),
                              const Divider(height: 16, color: AppColors.borderWarm),
                              _buildSummaryRow('Jatuh Tempo Terdekat', '20 Jun 2025'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
