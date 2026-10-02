import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();

  runApp(const TokoSusilawatiApp());
}

class TokoSusilawatiApp extends StatelessWidget {
  const TokoSusilawatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUSILAWATI TOKO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ApiService.instance.isAuthenticated
          ? const MainNavigation()
          : const LoginScreen(),
    );
  }
}
