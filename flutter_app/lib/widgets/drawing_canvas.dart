import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/drawing_provider.dart';
import '../config/theme.dart';

/// Custom drawing canvas supporting multiple textured brushes, selections, and live opponents.
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

            if (drawing.currentTool == DrawingToolType.select) {
              final delta = details.delta;
              drawing.moveSelectedStroke(delta);
            } else {
              drawing.addPoint(point);
            }
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
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CanvasPainter(
                  strokes: drawing.strokes,
                  opponentStrokes: drawing.opponentStrokes,
                  opponentCursors: drawing.opponentCursors,
                  opponentNames: drawing.opponentNames,
                  showGrid: drawing.showGrid,
                  isDark: isDark,
                  selectedStrokeIndex: drawing.selectedStrokeIndex,
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

/// Custom painter that renders all drawing strokes with real textured brush engines.
class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final Map<String, List<DrawingStroke>> opponentStrokes;
  final Map<String, Offset> opponentCursors;
  final Map<String, String> opponentNames;
  final bool showGrid;
  final bool isDark;
  final int? selectedStrokeIndex;

  _CanvasPainter({
    required this.strokes,
    required this.opponentStrokes,
    required this.opponentCursors,
    required this.opponentNames,
    required this.showGrid,
    required this.isDark,
    this.selectedStrokeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // ─── GRID LAYER ───────────────────────────────────────
    if (showGrid) {
      final gridPaint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
        ..strokeWidth = 1.0;
      const step = 24.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // ─── STROKES LAYER: OPPONENT DRAWINGS FIRST (BACK) ────
    opponentStrokes.forEach((userId, oStrokes) {
      for (final stroke in oStrokes) {
        _drawStrokeWithBrush(canvas, stroke, isOpponent: true);
      }
    });

    // ─── STROKES LAYER: LOCAL DRAWINGS (FRONT) ─────────────
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      _drawStrokeWithBrush(canvas, stroke, isOpponent: false);

      // Highlight selected stroke
      if (selectedStrokeIndex == i && stroke.points.isNotEmpty) {
        _drawSelectionHighlight(canvas, stroke);
      }
    }

    // ─── OPPONENT CURSORS LAYER ───────────────────────────
    opponentCursors.forEach((userId, cursor) {
      final name = opponentNames[userId] ?? 'Opponent';
      _drawOpponentCursor(canvas, cursor, name);
    });
  }

  void _drawStrokeWithBrush(Canvas canvas, DrawingStroke stroke, {required bool isOpponent}) {
    if (stroke.points.isEmpty) return;

    final basePaint = Paint()
      ..color = stroke.isEraser
          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
          : stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = stroke.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..isAntiAlias = true;

    // Apply different brush styles
    switch (stroke.toolType) {
      case DrawingToolType.pencil:
        // Graphite thin pencil: lower opacity, smaller thickness
        final pencilPaint = basePaint
          ..strokeWidth = math.max(1.5, stroke.strokeWidth * 0.3)
          ..color = stroke.color.withOpacity(stroke.opacity * 0.6);
        _drawStrokePath(canvas, stroke, pencilPaint);
        break;

      case DrawingToolType.marker:
        // Square cap, chisel style semi-transparent
        final markerPaint = basePaint
          ..strokeCap = StrokeCap.square
          ..color = stroke.color.withOpacity(stroke.opacity * 0.45);
        _drawStrokePath(canvas, stroke, markerPaint);
        break;

      case DrawingToolType.pen:
        // Ink pen: very sharp, constant size
        final penPaint = basePaint..strokeWidth = stroke.strokeWidth * 0.8;
        _drawStrokePath(canvas, stroke, penPaint);
        break;

      case DrawingToolType.airbrush:
      case DrawingToolType.softBrush:
        // Soft outer radial blend glow
        for (double w = 2.0; w > 0.5; w -= 0.3) {
          final softPaint = Paint()
            ..color = stroke.color.withOpacity(stroke.opacity * 0.08 * (2.0 - w))
            ..strokeWidth = stroke.strokeWidth * w * 1.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true;
          _drawStrokePath(canvas, stroke, softPaint);
        }
        break;

      case DrawingToolType.watercolor:
        // Layered light washes
        final washPaint = basePaint
          ..strokeWidth = stroke.strokeWidth * 1.6
          ..color = stroke.color.withOpacity(stroke.opacity * 0.18);
        _drawStrokePath(canvas, stroke, washPaint);
        break;

      case DrawingToolType.crayon:
        // Rough wax/dust texture: draw overlapping dots with slight offset jitter
        final random = math.Random(1337);
        final crayonPaint = Paint()
          ..color = stroke.color.withOpacity(stroke.opacity * 0.3)
          ..style = PaintingStyle.fill;

        for (final p in stroke.points) {
          for (int i = 0; i < 6; i++) {
            final offset = Offset(
              random.nextDouble() * stroke.strokeWidth - stroke.strokeWidth / 2,
              random.nextDouble() * stroke.strokeWidth - stroke.strokeWidth / 2,
            );
            canvas.drawCircle(p + offset, random.nextDouble() * 1.8 + 0.5, crayonPaint);
          }
        }
        break;

      case DrawingToolType.pixel:
        // Pixellated block boxes
        final pixelPaint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill;
        const size = 8.0;
        for (final p in stroke.points) {
          final px = (p.dx / size).floor() * size;
          final py = (p.dy / size).floor() * size;
          canvas.drawRect(Rect.fromLTWH(px, py, size, size), pixelPaint);
        }
        break;

      case DrawingToolType.spray:
        // Spray Paint: random splatters around stroke line
        final random = math.Random();
        final sprayPaint = Paint()
          ..color = stroke.color.withOpacity(stroke.opacity * 0.45)
          ..style = PaintingStyle.fill;

        for (final p in stroke.points) {
          for (int i = 0; i < 8; i++) {
            final radius = random.nextDouble() * stroke.strokeWidth * 1.5;
            final angle = random.nextDouble() * 2 * math.pi;
            final offset = Offset(radius * math.cos(angle), radius * math.sin(angle));
            canvas.drawCircle(p + offset, random.nextDouble() * 1.5 + 0.5, sprayPaint);
          }
        }
        break;

      case DrawingToolType.calligraphy:
        // Flat calligraphy nib drawn at a constant 45-degree angle
        final nibPaint = Paint()
          ..color = stroke.color.withOpacity(stroke.opacity)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.fill;

        for (final p in stroke.points) {
          final angle = 45.0 * math.pi / 180;
          final w = stroke.strokeWidth * 0.8;
          final dx = w * math.cos(angle);
          final dy = w * math.sin(angle);
          final p1 = p + Offset(-dx, -dy);
          final p2 = p + Offset(dx, dy);

          final path = Path()
            ..moveTo(p1.dx - 1, p1.dy + 1)
            ..lineTo(p2.dx - 1, p2.dy + 1)
            ..lineTo(p2.dx + 1, p2.dy - 1)
            ..lineTo(p1.dx + 1, p1.dy - 1)
            ..close();
          canvas.drawPath(path, nibPaint);
        }
        break;

      case DrawingToolType.neon:
        // Glow layer
        canvas.drawPath(
          _createPathForStroke(stroke),
          Paint()
            ..color = stroke.color.withOpacity(0.35)
            ..strokeWidth = stroke.strokeWidth * 2.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true,
        );
        // Solid core
        _drawStrokePath(canvas, stroke, basePaint..strokeWidth = stroke.strokeWidth * 0.8);
        break;

      default:
        _drawStrokePath(canvas, stroke, basePaint);
        break;
    }
  }

  void _drawStrokePath(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.isShape) {
      if (stroke.points.length >= 2) {
        _drawShape(canvas, stroke, paint);
      }
    } else {
      canvas.drawPath(_createPathForStroke(stroke), paint);
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
      case DrawingToolType.ellipse:
        canvas.drawOval(rect, paint);
        break;
      case DrawingToolType.triangle:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case DrawingToolType.polygon:
        final path = Path();
        final center = rect.center;
        final radius = rect.width / 2;
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final x = center.dx + radius * math.cos(angle);
          final y = center.dy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
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

  void _drawSelectionHighlight(Canvas canvas, DrawingStroke stroke) {
    // Calculate bounding box
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final p in stroke.points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }

    final bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
    final borderPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Draw dashed outline
    canvas.drawRect(bounds, borderPaint);

    // Draw small anchor corners
    final cornerPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.fill;
    const size = 6.0;
    canvas.drawRect(Rect.fromLTWH(bounds.left - size/2, bounds.top - size/2, size, size), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(bounds.right - size/2, bounds.top - size/2, size, size), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(bounds.left - size/2, bounds.bottom - size/2, size, size), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(bounds.right - size/2, bounds.bottom - size/2, size, size), cornerPaint);
  }

  void _drawOpponentCursor(Canvas canvas, Offset cursor, String name) {
    final fillPaint = Paint()
      ..color = AppTheme.accentCoral
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw cursor brush pointer
    canvas.drawCircle(cursor, 6.0, fillPaint);
    canvas.drawCircle(cursor, 6.0, borderPaint);

    // Render name label text
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: AppTheme.accentCoral,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cursor.dx + 8, cursor.dy - 12));
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
