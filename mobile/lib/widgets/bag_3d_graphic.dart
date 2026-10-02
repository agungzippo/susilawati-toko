import 'package:flutter/material.dart';

class Bag3DGraphic extends StatelessWidget {
  final String bagType;
  final double width;
  final double height;
  final bool isHero;

  const Bag3DGraphic({
    super.key,
    required this.bagType,
    this.width = 60,
    this.height = 60,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F0),
        borderRadius: BorderRadius.circular(isHero ? 20 : 12),
        border: Border.all(color: const Color(0xFFECE6DE), width: 1),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(width * (isHero ? 0.75 : 0.65), height * (isHero ? 0.75 : 0.65)),
          painter: _BagPainter(bagType: bagType),
        ),
      ),
    );
  }
}

class _BagPainter extends CustomPainter {
  final String bagType;

  _BagPainter({required this.bagType});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette per model tas
    Color mainColor;
    Color darkColor;
    Color highlightColor;
    bool isBackpack = false;
    bool isSling = false;

    if (bagType.toLowerCase().contains('tote')) {
      // Beige Tote
      mainColor = const Color(0xFFDCC8B3);
      darkColor = const Color(0xFFBFAF9E);
      highlightColor = const Color(0xFFEDE4D8);
    } else if (bagType.toLowerCase().contains('shoulder')) {
      // Classic Black Shoulder Bag
      mainColor = const Color(0xFF2C2825);
      darkColor = const Color(0xFF191715);
      highlightColor = const Color(0xFF4A4440);
    } else if (bagType.toLowerCase().contains('selempang')) {
      // Olive Green Crossbody
      mainColor = const Color(0xFF6E7860);
      darkColor = const Color(0xFF535C47);
      highlightColor = const Color(0xFF8B967C);
      isSling = true;
    } else if (bagType.toLowerCase().contains('ransel')) {
      // Caramel Brown Ransel
      mainColor = const Color(0xFFB5804C);
      darkColor = const Color(0xFF8F5F31);
      highlightColor = const Color(0xFFD49E6A);
      isBackpack = true;
    } else {
      // Backpack Black
      mainColor = const Color(0xFF33302E);
      darkColor = const Color(0xFF1E1C1A);
      highlightColor = const Color(0xFF524E4B);
      isBackpack = true;
    }

    // 1. Bayangan 3D di bawah tas
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.94), width: w * 0.75, height: h * 0.14),
      shadowPaint,
    );

    if (isBackpack) {
      // Handle atas
      final handlePaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.28), width: w * 0.35, height: h * 0.35),
        3.14,
        3.14,
        false,
        handlePaint,
      );

      // Badan Backpack dengan gradasi 3D
      final bodyRect = Rect.fromLTWH(w * 0.16, h * 0.22, w * 0.68, h * 0.7);
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlightColor, mainColor, darkColor],
        ).createShader(bodyRect);

      final rrect = RRect.fromRectAndCorners(
        bodyRect,
        topLeft: Radius.circular(w * 0.3),
        topRight: Radius.circular(w * 0.3),
        bottomLeft: Radius.circular(w * 0.12),
        bottomRight: Radius.circular(w * 0.12),
      );
      canvas.drawRRect(rrect, bodyPaint);

      // Kantong Depan 3D
      final pocketRect = Rect.fromLTWH(w * 0.25, h * 0.55, w * 0.5, h * 0.32);
      final pocketPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlightColor, mainColor],
        ).createShader(pocketRect);
      canvas.drawRRect(RRect.fromRectAndRadius(pocketRect, Radius.circular(w * 0.08)), pocketPaint);

      // Garis Zipper
      final zipPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(w * 0.3, h * 0.58), Offset(w * 0.7, h * 0.58), zipPaint);
    } else if (isSling) {
      // Tali Selempang
      final strapPaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06;
      final strapPath = Path()
        ..moveTo(w * 0.15, h * 0.45)
        ..cubicTo(w * 0.2, h * 0.05, w * 0.8, h * 0.05, w * 0.85, h * 0.45);
      canvas.drawPath(strapPath, strapPaint);

      // Badan Tas Selempang
      final bodyRect = Rect.fromLTWH(w * 0.15, h * 0.38, w * 0.7, h * 0.54);
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlightColor, mainColor, darkColor],
        ).createShader(bodyRect);
      canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.1)), bodyPaint);

      // Flap penutup atas
      final flapRect = Rect.fromLTWH(w * 0.15, h * 0.38, w * 0.7, h * 0.3);
      final flapPaint = Paint()
        ..color = darkColor.withValues(alpha: 0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(flapRect, Radius.circular(w * 0.1)), flapPaint);

      // Kancing pengait emas
      final bucklePaint = Paint()..color = const Color(0xFFD4AF37);
      canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.04, bucklePaint);
    } else {
      // Tas Tote / Shoulder Bag dengan Handle Melengkung Elegan
      final handlePaint = Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round;

      // Handle Depan & Belakang
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.32), width: w * 0.44, height: h * 0.5),
        3.14,
        3.14,
        false,
        handlePaint,
      );

      // Badan Tas Tote (Trapezoid halus dengan pinggul melengkung)
      final bodyPath = Path()
        ..moveTo(w * 0.22, h * 0.36)
        ..lineTo(w * 0.78, h * 0.36)
        ..lineTo(w * 0.84, h * 0.88)
        ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.16, h * 0.88)
        ..close();

      final bodyRect = Rect.fromLTWH(w * 0.16, h * 0.36, w * 0.68, h * 0.54);
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlightColor, mainColor, darkColor],
        ).createShader(bodyRect);

      canvas.drawPath(bodyPath, bodyPaint);

      // Garis jahitan kulit (Stitching detail)
      final stitchPaint = Paint()
        ..color = darkColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.38, h * 0.38), Offset(w * 0.38, h * 0.86), stitchPaint);
      canvas.drawLine(Offset(w * 0.62, h * 0.38), Offset(w * 0.62, h * 0.86), stitchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
