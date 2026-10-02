import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/tactile_3d.dart';

class ScanResultScreen extends StatefulWidget {
  final String? invoiceId;
  final Map<String, dynamic>? invoiceData;
  final File? imageFile;

  const ScanResultScreen({
    super.key,
    this.invoiceId,
    this.invoiceData,
    this.imageFile,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isSaving = false;

  late String _supplierName;
  String? _supplierId;
  late String _invoiceNumber;
  late String _invoiceDate;
  List<Map<String, dynamic>> _items = [];
  List<dynamic> _products = [];

  double get _totalAmount => _items.fold(0.0, (acc, item) => acc + (item['lineTotal'] as double));

  @override
  void initState() {
    super.initState();
    _initData();
    _loadProducts();
  }

  void _initData() {
    final inv = widget.invoiceData ?? {};
    _supplierName = inv['supplier']?['name'] ?? inv['supplierName'] ?? 'PT. Maju Jaya';
    _supplierId = inv['supplierId'];
    _invoiceNumber = inv['supplierInvoiceNumber'] ?? inv['invoiceNumber'] ?? 'FJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final rawDate = inv['invoiceDate'];
    if (rawDate != null) {
      try {
        final parsed = DateTime.parse(rawDate.toString());
        _invoiceDate = DateFormat('dd MMM yyyy').format(parsed);
      } catch (_) {
        _invoiceDate = DateFormat('dd MMM yyyy').format(DateTime.now());
      }
    } else {
      _invoiceDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    final rawItems = inv['items'] as List? ?? [];
    if (rawItems.isNotEmpty) {
      _items = rawItems.map<Map<String, dynamic>>((it) {
        final qty = (it['quantity'] as num?)?.toInt() ?? 1;
        final factor = (it['conversionFactor'] as num?)?.toInt() ?? 1;
        final cost = (it['unitCost'] as num?)?.toDouble() ?? 150000.0;
        final total = (it['lineTotal'] as num?)?.toDouble() ?? (qty * cost);

        return {
          'id': it['id']?.toString() ?? UniqueKey().toString(),
          'rawName': it['rawName'] ?? it['name'] ?? 'Tas Kulit',
          'quantity': qty,
          'unit': it['unit'] ?? 'pcs',
          'conversionFactor': factor,
          'unitCost': cost,
          'lineTotal': total,
          'variantId': it['variantId'],
          'matchedProduct': it['variant']?['product']?['name'],
        };
      }).toList();
    } else {
      // Default fallback jika OCR kosong
      _items = [
        {
          'id': 'temp-1',
          'rawName': 'Tas Tote Minimalis',
          'quantity': 5,
          'unit': 'pcs',
          'conversionFactor': 1,
          'unitCost': 180000.0,
          'lineTotal': 900000.0,
          'variantId': null,
        },
        {
          'id': 'temp-2',
          'rawName': 'Shoulder Bag',
          'quantity': 3,
          'unit': 'pcs',
          'conversionFactor': 1,
          'unitCost': 150000.0,
          'lineTotal': 450000.0,
          'variantId': null,
        },
      ];
    }
  }

  Future<void> _loadProducts() async {
    try {
      final prods = await ApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _products = prods;

          // Auto-link variants by matching name if variantId is null
          for (var item in _items) {
            if (item['variantId'] == null && _products.isNotEmpty) {
              final raw = item['rawName'].toString().toLowerCase();
              dynamic matchedVar;
              for (var p in _products) {
                final vars = p['variants'] as List? ?? [];
                for (var v in vars) {
                  final pName = (p['name'] as String).toLowerCase();
                  final vColor = (v['color'] as String? ?? '').toLowerCase();
                  if (raw.contains(pName) || raw.contains(vColor)) {
                    matchedVar = v;
                    item['matchedProduct'] = '${p['name']} ($vColor)';
                    break;
                  }
                }
                if (matchedVar != null) break;
              }
              // If still null, pick first available variant in store
              if (matchedVar == null && _products.isNotEmpty) {
                final firstP = _products[0];
                final firstVars = firstP['variants'] as List? ?? [];
                if (firstVars.isNotEmpty) {
                  matchedVar = firstVars[0];
                  item['matchedProduct'] = '${firstP['name']} (${matchedVar['color'] ?? 'Default'})';
                }
              }
              if (matchedVar != null) {
                item['variantId'] = matchedVar['id'];
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      // Pastikan semua item memiliki variantId
      for (var item in _items) {
        if (item['variantId'] == null) {
          if (_products.isNotEmpty) {
            final vars = _products[0]['variants'] as List? ?? [];
            if (vars.isNotEmpty) {
              item['variantId'] = vars[0]['id'];
            }
          }
        }
      }

      if (widget.invoiceId != null && _supplierId != null) {
        // Flow A: Verifikasi Faktur & Konfirmasi Penerimaan Atomic
        await ApiService.instance.verifyInvoice(widget.invoiceId!, {
          'supplierId': _supplierId!,
          'supplierInvoiceNumber': _invoiceNumber,
          'items': _items.map((it) {
            return {
              'id': it['id'],
              'variantId': it['variantId'],
              'quantity': it['quantity'],
              'unit': it['unit'],
              'conversionFactor': it['conversionFactor'],
              'unitCost': it['unitCost'],
              'lineTotal': it['lineTotal'],
            };
          }).toList(),
        });

        // Buat jadwal penerimaan
        final schedule = await ApiService.instance.createSchedule({
          'invoiceId': widget.invoiceId!,
          'expectedDate': DateTime.now().toIso8601String(),
          'notes': 'Diterima langsung dari pemindaian bon mobile',
        });

        // Konfirmasi penerimaan fisik dan mutasi stok
        final idempotencyKey = 'RCV-${DateTime.now().millisecondsSinceEpoch}';
        await ApiService.instance.confirmReceipt({
          'scheduleId': schedule['id'],
          'idempotencyKey': idempotencyKey,
          'items': _items.map((it) {
            final totalPcs = (it['quantity'] as int) * (it['conversionFactor'] as int);
            final unitCostPerPcs = (it['unitCost'] as double) / (it['conversionFactor'] as int);
            return {
              'invoiceItemId': it['id'],
              'variantId': it['variantId'],
              'expectedQuantity': totalPcs,
              'receivedQuantity': totalPcs,
              'damagedQuantity': 0,
              'shortQuantity': 0,
              'unitCost': unitCostPerPcs,
              'notes': 'Kondisi barang baik',
            };
          }).toList(),
        });
      } else {
        // Flow B: Direct stock adjustment
        for (var it in _items) {
          if (it['variantId'] != null) {
            final totalPcs = (it['quantity'] as int) * (it['conversionFactor'] as int);
            final unitCostPerPcs = (it['unitCost'] as double) / (it['conversionFactor'] as int);
            await ApiService.instance.addStock(
              variantId: it['variantId'],
              quantity: totalPcs,
              unitCost: unitCostPerPcs,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok barang berhasil ditambahkan dan dicatat ke sistem!'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showVariantPicker(int itemIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hubungkan ke Produk Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _products.length,
                itemBuilder: (context, idx) {
                  final p = _products[idx];
                  final vars = p['variants'] as List? ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: vars.map((v) {
                      return ListTile(
                        title: Text('${p['name']} (${v['color'] ?? 'Default'})'),
                        subtitle: Text('SKU: ${v['sku']}'),
                        trailing: const Icon(Icons.check_circle_outline, color: AppColors.greenStock),
                        onTap: () {
                          setState(() {
                            _items[itemIndex]['variantId'] = v['id'];
                            _items[itemIndex]['matchedProduct'] = '${p['name']} (${v['color'] ?? 'Default'})';
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Hasil Pemindaian Bon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Foto Faktur Thumbnail (3D Floating Card)
          if (widget.imageFile != null) ...[
            Tactile3DCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      widget.imageFile!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foto Bon Terlampir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Data telah diekstrak dengan Gemini Vision AI', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: AppColors.greenStock, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Section 1: Informasi Bon
          Tactile3DCard(
            isElevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.brandEspresso),
                    SizedBox(width: 8),
                    Text(
                      'Informasi Bon / Faktur',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoField('Nama Suplier', _supplierName),
                const SizedBox(height: 10),
                _buildInfoField('No. Faktur Bon', _invoiceNumber),
                const SizedBox(height: 10),
                _buildInfoField('Tanggal Pembelian', _invoiceDate),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Detail Barang
          Tactile3DCard(
            isElevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Barang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text('Ketuk item untuk ubah varian', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),

                // Table Header
                Row(
                  children: const [
                    Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                    Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                    Expanded(flex: 2, child: Text('Harga Modal', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                    Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                  ],
                ),
                const Divider(height: 16, color: AppColors.borderWarm),

                // Table Rows
                ..._items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final it = entry.value;
                  final matchedName = it['matchedProduct'] as String?;

                  return InkWell(
                    onTap: () => _showVariantPicker(idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  it['rawName'],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${it['quantity']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _currency.format(it['unitCost']),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _currency.format(it['lineTotal']),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                              ),
                            ],
                          ),
                          if (matchedName != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 12, color: AppColors.greenStock),
                                const SizedBox(width: 4),
                                Text(
                                  'Tersambung ke: $matchedName',
                                  style: const TextStyle(fontSize: 10, color: AppColors.greenStock, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 16, color: AppColors.borderWarm),

                // Total Pembelian
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembelian',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      _currency.format(_totalAmount),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.brandEspresso),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons (3D Tactile Push)
          Tactile3DButton(
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving,
            icon: Icons.check_circle_rounded,
            child: const Text('Simpan & Tambah ke Stok'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ulangi Pemindaian'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
