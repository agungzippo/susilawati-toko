import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/tactile_3d.dart';

class SupplierScreen extends StatefulWidget {
  final bool showBackButton;
  const SupplierScreen({super.key, this.showBackButton = false});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _suppliers = [];
  List<dynamic> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((s) {
          final name = (s['name']?.toString() ?? '').toLowerCase();
          final phone = (s['phone']?.toString() ?? '').toLowerCase();
          final email = (s['email']?.toString() ?? '').toLowerCase();
          return name.contains(query) || phone.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final sups = await ApiService.instance.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = sups;
          _filteredSuppliers = sups;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'Tambah Suplier Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Suplier / Vendor',
                    hintText: 'Contoh: PT. Sumber Makmur Tas',
                    prefixIcon: Icon(Icons.business_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon / WhatsApp',
                    hintText: '0812 3456 7890',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Opsional)',
                    hintText: 'kontak@supplier.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alamat / Pusat Grosir',
                    hintText: 'Contoh: Pasar Pagi Mangga Dua Lt. 2',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                Tactile3DButton(
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nama suplier wajib diisi')),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            await ApiService.instance.createSupplier({
                              'name': name,
                              'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                            });

                            if (mounted && ctx.mounted) {
                              Navigator.pop(ctx);
                              _loadSuppliers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Suplier berhasil ditambahkan ke database!'),
                                  backgroundColor: AppColors.greenStock,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: AppColors.redStock,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Simpan Data Suplier'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Suplier Toko'),
        leading: widget.showBackButton
            ? IconButton(
                tooltip: "Kembali",
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            tooltip: "Tambah suplier",
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26, color: AppColors.brandEspresso),
            onPressed: _showAddSupplierDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box with 3D Shadow
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
                  hintText: 'Cari nama suplier atau telepon...',
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
                  : _filteredSuppliers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.business_outlined, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  const Text('Tidak ada data suplier', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _showAddSupplierDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Suplier Pertama'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          children: [
                            ..._filteredSuppliers.map((s) {
                              return Tactile3DCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // 3D Avatar
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

                                    // Details
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
                                          if (s['phone'] != null)
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  s['phone'],
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          if (s['address'] != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    s['address'],
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),

                            // Ringkasan Suplier Riil
                            Tactile3DCard(
                              isElevated: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ringkasan Suplier Toko',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryRow('Total Suplier Terdaftar', '${_suppliers.length} vendor'),
                                  const Divider(height: 16, color: AppColors.borderWarm),
                                  _buildSummaryRow('Status Hubungan Dagang', 'Aktif & Terverifikasi'),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brandEspresso,
        foregroundColor: Colors.white,
        onPressed: _showAddSupplierDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Suplier'),
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
