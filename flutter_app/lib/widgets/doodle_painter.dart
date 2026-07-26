import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative background painter with paint splashes, brushes, stars, and doodles.
/// Creates a playful, artistic atmosphere on every screen.
class DoodlePainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;
  final int seed;

  DoodlePainter({
    required this.primaryColor,
    required this.isDark,
    this.seed = 42,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final opacity = isDark ? 0.04 : 0.06;

    // Soft dot pattern background
    _drawDotPattern(canvas, size, opacity * 0.5);

    // Paint splashes
    _drawPaintSplashes(canvas, size, random, opacity);

    // Small floating doodles
    _drawFloatingDoodles(canvas, size, random, opacity);
  }

  void _drawDotPattern(Canvas canvas, Size size, double opacity) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(opacity)
      ..style = PaintingStyle.fill;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
  }

  void _drawPaintSplashes(Canvas canvas, Size size, math.Random random, double opacity) {
    final colors = [
      const Color(0xFFFF6B6B), // Coral
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFFE66D), // Yellow
      const Color(0xFFA78BFA), // Lavender
      const Color(0xFF6BCB77), // Mint
      const Color(0xFFFF85A1), // Pink
    ];

    for (int i = 0; i < 6; i++) {
      final color = colors[i % colors.length];
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final r = 20 + random.nextDouble() * 50;

      final paint = Paint()
        ..color = color.withOpacity(opacity * 1.2)
        ..style = PaintingStyle.fill;

      // Blob shape using quadratic curves
      final path = Path();
      const segments = 8;
      for (int s = 0; s <= segments; s++) {
        final angle = (s / segments) * 2 * math.pi;
        final variation = r * (0.7 + random.nextDouble() * 0.6);
        final x = cx + variation * math.cos(angle);
        final y = cy + variation * math.sin(angle);
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          final prevAngle = ((s - 0.5) / segments) * 2 * math.pi;
          final ctrlR = r * (0.8 + random.nextDouble() * 0.4);
          final ctrlX = cx + ctrlR * math.cos(prevAngle);
          final ctrlY = cy + ctrlR * math.sin(prevAngle);
          path.quadraticBezierTo(ctrlX, ctrlY, x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawFloatingDoodles(Canvas canvas, Size size, math.Random random, double opacity) {
    final doodlePaint = Paint()
      ..color = primaryColor.withOpacity(opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw small stars
    for (int i = 0; i < 5; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      _drawStar(canvas, Offset(cx, cy), 6 + random.nextDouble() * 8, doodlePaint);
    }

    // Draw small circles
    for (int i = 0; i < 4; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(cx, cy), 3 + random.nextDouble() * 6, doodlePaint);
    }

    // Draw tiny pencil icons
    for (int i = 0; i < 3; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      _drawTinyPencil(canvas, Offset(cx, cy), 12 + random.nextDouble() * 8, doodlePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      final outerX = center.dx + radius * math.cos(outerAngle);
      final outerY = center.dy + radius * math.sin(outerAngle);
      final innerX = center.dx + radius * 0.4 * math.cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawTinyPencil(Canvas canvas, Offset pos, double length, Paint paint) {
    // Simple pencil doodle: body + tip
    final angle = -math.pi / 4;
    final endX = pos.dx + length * math.cos(angle);
    final endY = pos.dy + length * math.sin(angle);
    canvas.drawLine(pos, Offset(endX, endY), paint);

    // Tip triangle
    final tipLength = length * 0.25;
    final tipX = endX + tipLength * math.cos(angle);
    final tipY = endY + tipLength * math.sin(angle);
    canvas.drawLine(Offset(endX, endY), Offset(tipX, tipY), paint);
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.seed != seed;
}

/// Animated background widget using DoodlePainter
class AnimatedDoodleBackground extends StatelessWidget {
  const AnimatedDoodleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);
    return CustomPaint(
      painter: DoodlePainter(primaryColor: primary, isDark: isDark),
    );
  }
}
