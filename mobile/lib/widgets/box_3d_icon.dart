import 'package:flutter/material.dart';

class Box3DIcon extends StatelessWidget {
  final double size;

  const Box3DIcon({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFEA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _Box3DPainter(),
        ),
      ),
    );
  }
}

class _Box3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Warna isometric box 3D
    const topColor = Color(0xFFDCC8B3);
    const leftColor = Color(0xFFB89E84);
    const rightColor = Color(0xFF9E846B);

    final topPaint = Paint()..color = topColor;
    final leftPaint = Paint()..color = leftColor;
    final rightPaint = Paint()..color = rightColor;

    // Sisi Atas (Top Diamond)
    final topPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.95, h * 0.3)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.05, h * 0.3)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Sisi Kiri
    final leftPath = Path()
      ..moveTo(w * 0.05, h * 0.3)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.5, h * 0.95)
      ..lineTo(w * 0.05, h * 0.7)
      ..close();
    canvas.drawPath(leftPath, leftPaint);

    // Sisi Kanan
    final rightPath = Path()
      ..moveTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.95, h * 0.3)
      ..lineTo(w * 0.95, h * 0.7)
      ..lineTo(w * 0.5, h * 0.95)
      ..close();
    canvas.drawPath(rightPath, rightPaint);

    // Garis lipatan box (Taping)
    final tapePaint = Paint()
      ..color = const Color(0xFF3D2F28).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.5, h * 0.05), Offset(w * 0.5, h * 0.55), tapePaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.55), Offset(w * 0.5, h * 0.95), tapePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
