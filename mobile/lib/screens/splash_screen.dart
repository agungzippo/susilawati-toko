import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (ApiService.instance.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLightBeige,
      body: Stack(
        children: [
          // Bottom Organic Wave Accent
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: CustomPaint(
              painter: _SplashWavePainter(),
            ),
          ),

          // Main Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minimalist Bag Vector Logo matching mockup
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.shadow3D,
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(40, 36),
                        painter: _MinimalistBagPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Brand Title
                  const Text(
                    'susilawati',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    't o k o  .',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Subtitle
                  const Text(
                    'Lebih mudah mengelola\nstok dan transaksi toko tas Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalistBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.brandEspresso
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Bag Handle
    final handlePath = Path();
    handlePath.moveTo(size.width * 0.35, size.height * 0.45);
    handlePath.cubicTo(
      size.width * 0.35, size.height * 0.05,
      size.width * 0.65, size.height * 0.05,
      size.width * 0.65, size.height * 0.45,
    );
    canvas.drawPath(handlePath, strokePaint);

    // Bag Body
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.18, size.height * 0.45);
    bodyPath.lineTo(size.width * 0.82, size.height * 0.45);
    bodyPath.cubicTo(
      size.width * 0.88, size.height * 0.70,
      size.width * 0.90, size.height * 0.88,
      size.width * 0.78, size.height * 0.94,
    );
    bodyPath.lineTo(size.width * 0.22, size.height * 0.94);
    bodyPath.cubicTo(
      size.width * 0.10, size.height * 0.88,
      size.width * 0.12, size.height * 0.70,
      size.width * 0.18, size.height * 0.45,
    );
    canvas.drawPath(bodyPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Back subtle wave
    final backPaint = Paint()
      ..color = const Color(0xFFECE4D8).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, size.height * 0.5);
    backPath.cubicTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.7, size.height * 0.8,
      size.width, size.height * 0.4,
    );
    backPath.lineTo(size.width, size.height);
    backPath.lineTo(0, size.height);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front subtle wave
    final frontPaint = Paint()
      ..color = const Color(0xFFE4DAD0).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, size.height * 0.7);
    frontPath.cubicTo(
      size.width * 0.4, size.height * 0.45,
      size.width * 0.6, size.height * 0.85,
      size.width, size.height * 0.6,
    );
    frontPath.lineTo(size.width, size.height);
    frontPath.lineTo(0, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
