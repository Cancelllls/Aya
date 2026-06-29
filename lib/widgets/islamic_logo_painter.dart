import 'dart:math';
import 'package:flutter/material.dart';

class IslamicLogoPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final Color color;

  IslamicLogoPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw the 8-pointed star (Rub el Hizb) with rotation
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + (animationValue * pi / 10);
      final x1 = center.dx + radius * cos(angle);
      final y1 = center.dy + radius * sin(angle);

      final innerAngle = angle + pi / 8;
      final innerRadius = radius * 0.73;
      final x2 = center.dx + innerRadius * cos(innerAngle);
      final y2 = center.dy + innerRadius * sin(innerAngle);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner details circle
    final circlePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.6, circlePaint);

    // Glowing core
    final glowPaint = Paint()
      ..color = color.withOpacity(0.12 + 0.12 * sin(animationValue * 2 * pi))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center,
      radius * 0.45 * (0.85 + 0.15 * sin(animationValue * 2 * pi)),
      glowPaint,
    );

    // Crescent Moon in center
    final crescentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crescentPath = Path();
    final cCenter = Offset(center.dx - radius * 0.04, center.dy);
    crescentPath.addOval(
      Rect.fromCircle(center: cCenter, radius: radius * 0.22),
    );

    final subtractPath = Path();
    subtractPath.addOval(
      Rect.fromCircle(
        center: Offset(cCenter.dx + radius * 0.07, cCenter.dy - radius * 0.02),
        radius: radius * 0.21,
      ),
    );

    final finalCrescent = Path.combine(
      PathOperation.difference,
      crescentPath,
      subtractPath,
    );
    canvas.drawPath(finalCrescent, crescentPaint);
  }

  @override
  bool shouldRepaint(covariant IslamicLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
