import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarPulsePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final Color primaryColor;
  final Color accentColor;

  RadarPulsePainter({
    required this.animationValue,
    this.primaryColor = const Color(0xFFFF6B00),
    this.accentColor = const Color(0xFFFFB800),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;

    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw static concentric reference rings
    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4.0);
      canvas.drawCircle(center, r, basePaint);
    }

    // Draw crosshair grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), gridPaint);
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), gridPaint);

    // Dynamic animated pulsing wave rings (3 phased waves)
    for (int wave = 0; wave < 3; wave++) {
      final waveProgress = (animationValue + (wave / 3.0)) % 1.0;
      final currentRadius = maxRadius * waveProgress;
      final opacity = (1.0 - waveProgress) * 0.45;

      final wavePaint = Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, currentRadius, wavePaint);

      // Subtle radial fill inside wave
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withOpacity(opacity * 0.25),
            primaryColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, currentRadius, fillPaint);
    }

    // Rotating radar beam sweep
    final sweepAngle = animationValue * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          accentColor.withOpacity(0.28),
          accentColor.withOpacity(0.0),
        ],
        transform: GradientRotation(sweepAngle - math.pi / 4),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Glowing center beacon dot
    final centerGlow = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 16, centerGlow);

    final centerDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, centerDot);

    final centerInnerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, centerInnerDot);
  }

  @override
  bool shouldRepaint(covariant RadarPulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
