import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Handcrafted doodle & sketchpad background painter.
/// Renders cute hand-drawn stars, spirals, pencils, crowns, paint drops, and sparkles.
class DoodlePainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;

  DoodlePainter({required this.primaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(isDark ? 0.06 : 0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Draw Corner Stars
    _drawStar(canvas, const Offset(30, 40), 12, paint);
    _drawStar(canvas, Offset(size.width - 40, 50), 16, paint);
    _drawStar(canvas, Offset(40, size.height - 60), 14, paint);
    _drawStar(canvas, Offset(size.width - 50, size.height - 70), 18, paint);

    // 2. Draw Paint Drops
    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(isDark ? 0.05 : 0.04)
      ..style = PaintingStyle.fill;
    _drawPaintDrop(canvas, Offset(size.width * 0.15, size.height * 0.3), 10, fillPaint);
    _drawPaintDrop(canvas, Offset(size.width * 0.85, size.height * 0.4), 14, fillPaint);
    _drawPaintDrop(canvas, Offset(size.width * 0.12, size.height * 0.75), 12, fillPaint);

    // 3. Draw Pencil Doodle Top Right
    _drawPencilDoodle(canvas, Offset(size.width - 90, 120), paint);

    // 4. Draw Spiral Bottom Left
    _drawSpiral(canvas, Offset(80, size.height - 140), 18, paint);

    // 5. Draw Crown Top Left
    _drawCrown(canvas, const Offset(90, 80), paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a1 = (i * 4 * math.pi / 5) - (math.pi / 2);
      final x1 = center.dx + radius * math.cos(a1);
      final y1 = center.dy + radius * math.sin(a1);
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPaintDrop(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.4)
      ..cubicTo(
        center.dx + radius * 1.2, center.dy,
        center.dx + radius, center.dy + radius,
        center.dx, center.dy + radius,
      )
      ..cubicTo(
        center.dx - radius, center.dy + radius,
        center.dx - radius * 1.2, center.dy,
        center.dx, center.dy - radius * 1.4,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPencilDoodle(Canvas canvas, Offset offset, Paint paint) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(0.3);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(25, 0)
      ..lineTo(35, 8)
      ..lineTo(25, 16)
      ..lineTo(0, 16)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawSpiral(Canvas canvas, Offset center, double maxRadius, Paint paint) {
    final path = Path();
    double radius = 2.0;
    double angle = 0.0;
    path.moveTo(center.dx, center.dy);

    while (radius < maxRadius) {
      angle += 0.3;
      radius += 0.6;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawCrown(Canvas canvas, Offset offset, Paint paint) {
    final path = Path()
      ..moveTo(offset.dx, offset.dy + 16)
      ..lineTo(offset.dx, offset.dy)
      ..lineTo(offset.dx + 8, offset.dy + 8)
      ..lineTo(offset.dx + 16, offset.dy)
      ..lineTo(offset.dx + 24, offset.dy + 8)
      ..lineTo(offset.dx + 32, offset.dy)
      ..lineTo(offset.dx + 32, offset.dy + 16)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
