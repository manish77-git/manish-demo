import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/drawing_provider.dart';

/// Custom drawing canvas using CustomPainter.
class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        return GestureDetector(
          onTapDown: (details) {
            drawing.startStroke(details.localPosition);
            drawing.endStroke();
          },
          onPanStart: (details) {
            final box = context.findRenderObject() as RenderBox;
            final point = box.globalToLocal(details.globalPosition);
            drawing.startStroke(point);
          },
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final point = box.globalToLocal(details.globalPosition);
            drawing.addPoint(point);
          },
          onPanEnd: (_) => drawing.endStroke(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: drawing.strokes,
                  showGrid: drawing.showGrid,
                  isDark: isDark,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter that renders all drawing strokes and helper elements.
class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final bool showGrid;
  final bool isDark;

  _CanvasPainter({
    required this.strokes,
    required this.showGrid,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // ─── GRID LAYER ───────────────────────────────────────
    if (showGrid) {
      final gridPaint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
        ..strokeWidth = 1.0;
      const step = 20.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // ─── STROKES LAYER ────────────────────────────────────
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.isEraser
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : stroke.color.withOpacity(stroke.opacity)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // Brush specific styles
      if (stroke.toolType == DrawingToolType.watercolor) {
        paint.strokeWidth = stroke.strokeWidth * 1.5;
        paint.color = stroke.color.withOpacity(stroke.opacity * 0.35);
      } else if (stroke.toolType == DrawingToolType.neon) {
        // Outer Glow for Neon brush
        canvas.drawPath(
          _createPathForStroke(stroke),
          Paint()
            ..color = stroke.color.withOpacity(0.4)
            ..strokeWidth = stroke.strokeWidth * 2.2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true,
        );
      }

      if (stroke.isShape) {
        if (stroke.points.length >= 2) {
          _drawShape(canvas, stroke, paint);
        }
      } else {
        canvas.drawPath(_createPathForStroke(stroke), paint);
      }
    }
  }

  Path _createPathForStroke(DrawingStroke stroke) {
    final path = Path();
    if (stroke.points.isEmpty) return path;

    if (stroke.points.length == 1) {
      path.addOval(Rect.fromCircle(center: stroke.points[0], radius: stroke.strokeWidth / 2));
    } else {
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (int i = 1; i < stroke.points.length - 1; i++) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
    }
    return path;
  }

  void _drawShape(Canvas canvas, DrawingStroke stroke, Paint paint) {
    final p1 = stroke.points[0];
    final p2 = stroke.points[1];
    final rect = Rect.fromPoints(p1, p2);

    switch (stroke.toolType) {
      case DrawingToolType.line:
        canvas.drawLine(p1, p2, paint);
        break;
      case DrawingToolType.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case DrawingToolType.circle:
        final radius = rect.width / 2;
        canvas.drawCircle(rect.center, radius.abs(), paint);
        break;
      case DrawingToolType.triangle:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case DrawingToolType.arrow:
        canvas.drawLine(p1, p2, paint);
        final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
        const arrowSize = 15.0;
        final arrowPath = Path()
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(
            p2.dx - arrowSize * math.cos(angle - math.pi / 6),
            p2.dy - arrowSize * math.sin(angle - math.pi / 6),
          )
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(
            p2.dx - arrowSize * math.cos(angle + math.pi / 6),
            p2.dy - arrowSize * math.sin(angle + math.pi / 6),
          );
        canvas.drawPath(arrowPath, paint);
        break;
      case DrawingToolType.star:
        final path = Path();
        final center = rect.center;
        final outerRadius = rect.width / 2;
        final innerRadius = outerRadius / 2.5;
        const points = 5;
        const angle = 2 * math.pi / points;

        for (int i = 0; i < points * 2; i++) {
          final isEven = i % 2 == 0;
          final r = isEven ? outerRadius : innerRadius;
          final currAngle = i * angle / 2 - math.pi / 2;
          final x = center.dx + r * math.cos(currAngle);
          final y = center.dy + r * math.sin(currAngle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
