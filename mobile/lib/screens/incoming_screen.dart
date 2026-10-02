import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../widgets/tactile_3d.dart';
import 'scan_result_screen.dart';

class IncomingScreen extends StatefulWidget {
  final bool showBackButton;
  const IncomingScreen({super.key, this.showBackButton = true});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> with SingleTickerProviderStateMixin {
  int _selectedMode = 1; // 0 = Manual, 1 = Scan Bon / Faktur
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  String _statusText = '';

  late AnimationController _animController;

  // Manual Mode State
  List<dynamic> _suppliers = [];
  String? _manualSupplierId;
  final _manualInvoiceController = TextEditingController();
  List<dynamic> _products = [];
  String? _selectedVariantId;
  final _manualQtyController = TextEditingController(text: '10');
  final _manualCostController = TextEditingController(text: '150000');
  bool _isManualSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadInitialData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualInvoiceController.dispose();
    _manualQtyController.dispose();
    _manualCostController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final sups = await ApiService.instance.getSuppliers();
      final prods = await ApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _suppliers = sups;
          if (_suppliers.isNotEmpty) _manualSupplierId = _suppliers[0]['id'];
          _products = prods;
          if (_products.isNotEmpty) {
            final vars = _products[0]['variants'] as List? ?? [];
            if (vars.isNotEmpty) _selectedVariantId = vars[0]['id'];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _isProcessing = true;
        _statusText = 'Mengunggah foto faktur ke server...';
      });

      // 1. Upload foto ke backend
      final uploadRes = await ApiService.instance.uploadInvoiceImage(picked.path);
      final invoiceId = uploadRes['id'] as String;

      setState(() {
        _statusText = 'Mengekstrak data bon dengan AI...';
      });

      // 2. Panggil Vision AI extraction
      final extractRes = await ApiService.instance.extractInvoice(invoiceId);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusText = '';
      });

      // 3. Arahkan ke hasil pemindaian riil
      final bool? refreshed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            invoiceId: invoiceId,
            invoiceData: extractRes,
            imageFile: _selectedImage,
          ),
        ),
      );

      if (refreshed == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.redStock,
          ),
        );
      }
    }
  }

  Future<void> _handleManualSubmit() async {
    if (_selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih barang terlebih dahulu')),
      );
      return;
    }

    final qty = int.tryParse(_manualQtyController.text) ?? 0;
    final cost = double.tryParse(_manualCostController.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah barang masuk harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isManualSubmitting = true);
    try {
      await ApiService.instance.addStock(
        variantId: _selectedVariantId!,
        quantity: qty,
        unitCost: cost,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang masuk berhasil dicatat ke stok!'),
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
      if (mounted) setState(() => _isManualSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      appBar: AppBar(
        title: const Text('Barang Masuk'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Segmented 3D Pill Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE5DC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 0 ? AppColors.brandEspresso : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedMode == 0 ? AppColors.buttonShadow3D : null,
                      ),
                      child: Text(
                        'Input Manual',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 0 ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMode = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 1 ? AppColors.brandEspresso : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedMode == 1 ? AppColors.buttonShadow3D : null,
                      ),
                      child: Text(
                        'Scan Bon / Faktur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 1 ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedMode == 1) ...[
            // 2. Camera Viewfinder Card with 3D Depth
            Tactile3DCard(
              padding: EdgeInsets.zero,
              isElevated: true,
              backgroundColor: const Color(0xFF1F1B18),
              customBorder: Border.all(color: const Color(0xFF38312B), width: 1.5),
              child: SizedBox(
                height: 360,
                child: Stack(
                  children: [
                    // Preview image or viewfinder background
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 360,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: const Icon(
                                Icons.document_scanner_outlined,
                                color: Colors.white70,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Posisikan Bon / Faktur di Sini',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'AI otomatis mendeteksi nama barang,\njumlah, dan harga modal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Laser Scanning Bar (active when processing)
                    if (_isProcessing)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Positioned(
                            top: 20 + (_animController.value * 320),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.greenStock,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.greenStock.withValues(alpha: 0.8),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Corner Brackets for 3D Viewfinder
                    Positioned(top: 18, left: 18, child: _buildCorner(isTop: true, isLeft: true)),
                    Positioned(top: 18, right: 18, child: _buildCorner(isTop: true, isLeft: false)),
                    Positioned(bottom: 18, left: 18, child: _buildCorner(isTop: false, isLeft: true)),
                    Positioned(bottom: 18, right: 18, child: _buildCorner(isTop: false, isLeft: false)),

                    // Loading overlay
                    if (_isProcessing)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              const SizedBox(height: 16),
                              Text(
                                _statusText,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (3D Tactile)
            Tactile3DButton(
              onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
              icon: Icons.camera_alt_rounded,
              child: const Text('Ambil Foto Bon (Kamera)'),
            ),
            const SizedBox(height: 12),
            Tactile3DButton(
              onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
              backgroundColor: AppColors.brandWarm,
              icon: Icons.photo_library_outlined,
              child: const Text('Pilih dari Galeri Foto'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pastikan tulisan pada nota/faktur tidak blur dan pencahayaan terang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ] else ...[
            // MANUAL MODE FORM
            Tactile3DCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Suplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderWarm),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _manualSupplierId,
                        isExpanded: true,
                        hint: const Text('Pilih suplier'),
                        items: _suppliers.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(s['name']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _manualSupplierId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Pilih Produk & Varian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderWarm),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVariantId,
                        isExpanded: true,
                        hint: const Text('Pilih produk'),
                        items: _products.expand<DropdownMenuItem<String>>((p) {
                          final vars = p['variants'] as List? ?? [];
                          return vars.map<DropdownMenuItem<String>>((v) {
                            return DropdownMenuItem<String>(
                              value: v['id'],
                              child: Text('${p['name']} (${v['color'] ?? 'Default'})'),
                            );
                          });
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedVariantId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jumlah (Pcs)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _manualQtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '10'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Harga Modal / Pcs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _manualCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '150000', prefixText: 'Rp '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Tactile3DButton(
                    onPressed: _isManualSubmitting ? null : _handleManualSubmit,
                    isLoading: _isManualSubmitting,
                    icon: Icons.check_circle_outline,
                    child: const Text('Simpan Barang Masuk'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.greenStock, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.greenStock, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.greenStock, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.greenStock, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
