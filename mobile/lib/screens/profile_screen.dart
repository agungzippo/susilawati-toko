import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.instance.getSavedUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sistem SUSILAWATI TOKO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akun & Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu Pengguna
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (_user?['name'] as String? ?? 'S').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?['name'] ?? 'Pengguna',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _user?['email'] ?? '-',
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _user?['role'] == 'OWNER' ? 'PEMILIK TOKO' : 'STAF TOKO',
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info Toko & Sistem
          const Text('Informasi Operasional', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildInfoTile('Nama Toko', 'SUSILAWATI TOKO', Icons.storefront),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile('Lokasi Gudang', 'Gudang Utama Toko', Icons.warehouse_outlined),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile('Zona Waktu', 'WIB (Asia/Jakarta)', Icons.schedule),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile('Mata Uang', 'Rupiah (IDR)', Icons.payments_outlined),
                const Divider(height: 1, color: AppColors.border),
                _buildInfoTile('Versi Aplikasi', '1.0.0 MVP (Lean Edition)', Icons.info_outline),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Tombol Logout
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.destructive,
              side: const BorderSide(color: AppColors.destructive),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Keluar dari Akun'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
      trailing: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      dense: true,
    );
  }
}
