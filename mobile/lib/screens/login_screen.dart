import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'owner@susilawati.com');
  final _passwordController = TextEditingController(text: 'admin123');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 44,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'SUSILAWATI TOKO',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistem Monitoring & Manajemen Stok Tas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.destructive),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.destructive, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.destructive, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Email Pengguna',
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'nama@susilawati.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Kata Sandi',
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan kata sandi',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk ke Sistem'),
                    ),
                    const SizedBox(height: 16),

                    // Quick demo switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _emailController.text = 'owner@susilawati.com';
                              _passwordController.text = 'admin123';
                            });
                          },
                          child: const Text('Akun Pemilik'),
                        ),
                        const Text('•', style: TextStyle(color: AppColors.mutedForeground)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _emailController.text = 'staf@susilawati.com';
                              _passwordController.text = 'staf123';
                            });
                          },
                          child: const Text('Akun Staf'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
