import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'stock_screen.dart';
import 'scanner_screen.dart';
import 'incoming_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onNavigateTab: (index) {
        setState(() => _currentIndex = index);
      }),
      const StockScreen(),
      const ScannerScreen(),
      const IncomingScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Stok',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.move_to_inbox_outlined),
              activeIcon: Icon(Icons.move_to_inbox),
              label: 'Masuk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
