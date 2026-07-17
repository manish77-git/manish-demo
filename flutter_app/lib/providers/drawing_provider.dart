import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DrawingToolType {
  pencil,
  pen,
  brush,
  marker,
  airbrush,
  spray,
  crayon,
  watercolor,
  neon,
  pixel,
  eraser,
  fill,
  line,
  rectangle,
  circle,
  triangle,
  arrow,
  star,
}

/// Represents a single stroke or shape on the canvas.
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingToolType toolType;
  final double opacity;
  final double flow;
  final bool isEraser;
  final bool isShape;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.toolType,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.isEraser = false,
    this.isShape = false,
  });
}

/// Drawing state management provider.
class DrawingProvider extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStack = [];

  DrawingToolType _currentTool = DrawingToolType.brush;
  Color _currentColor = const Color(0xFF4F7CFF);
  double _brushSize = 8.0;
  double _opacity = 1.0;
  double _flow = 1.0;
  double _smoothing = 5.0;
  bool _isSubmitting = false;

  // Zoom and Pan states
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  bool _showGrid = false;
  bool _snapGrid = false;

  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  List<DrawingStroke> get redoStack => List.unmodifiable(_redoStack);

  DrawingToolType get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get brushSize => _brushSize;
  double get opacity => _opacity;
  double get flow => _flow;
  double get smoothing => _smoothing;
  bool get isSubmitting => _isSubmitting;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  double get zoomScale => _zoomScale;
  Offset get panOffset => _panOffset;
  bool get showGrid => _showGrid;
  bool get snapGrid => _snapGrid;

  void setTool(DrawingToolType tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setBrushSize(double size) {
    _brushSize = size;
    notifyListeners();
  }

  void setOpacity(double value) {
    _opacity = value;
    notifyListeners();
  }

  void setFlow(double value) {
    _flow = value;
    notifyListeners();
  }

  void setSmoothing(double value) {
    _smoothing = value;
    notifyListeners();
  }

  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void toggleSnapGrid() {
    _snapGrid = !_snapGrid;
    notifyListeners();
  }

  void setZoomAndPan(double scale, Offset offset) {
    _zoomScale = scale;
    _panOffset = offset;
    notifyListeners();
  }

  void centerCanvas() {
    _zoomScale = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  Offset _applyGridSnap(Offset point) {
    if (!_snapGrid) return point;
    const gridSize = 20.0;
    final x = (point.dx / gridSize).round() * gridSize;
    final y = (point.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }

  void startStroke(Offset point) {
    _redoStack.clear();
    final snappedPoint = _applyGridSnap(point);

    final isShape = [
      DrawingToolType.line,
      DrawingToolType.rectangle,
      DrawingToolType.circle,
      DrawingToolType.triangle,
      DrawingToolType.arrow,
      DrawingToolType.star
    ].contains(_currentTool);

    _strokes.add(DrawingStroke(
      points: [snappedPoint],
      color: _currentColor,
      strokeWidth: _brushSize,
      toolType: _currentTool,
      opacity: _opacity,
      flow: _flow,
      isEraser: _currentTool == DrawingToolType.eraser,
      isShape: isShape,
    ));
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_strokes.isNotEmpty) {
      final snappedPoint = _applyGridSnap(point);
      final currentStroke = _strokes.last;

      if (currentStroke.isShape) {
        // Shapes only track start (index 0) and current end (index 1)
        if (currentStroke.points.length > 1) {
          currentStroke.points[1] = snappedPoint;
        } else {
          currentStroke.points.add(snappedPoint);
        }
      } else {
        currentStroke.points.add(snappedPoint);
      }
      notifyListeners();
    }
  }

  void endStroke() {
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  /// Export the canvas to a PNG image.
  Future<Uint8List?> exportToPng(Size canvasSize) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      // Draw all strokes
      for (final stroke in _strokes) {
        final paint = Paint()
          ..color = stroke.isEraser
              ? Colors.white
              : stroke.color.withOpacity(stroke.opacity)
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        if (stroke.toolType == DrawingToolType.watercolor) {
          paint.strokeWidth = stroke.strokeWidth * 1.5;
          paint.color = stroke.color.withOpacity(stroke.opacity * 0.3);
        } else if (stroke.toolType == DrawingToolType.neon) {
          paint.color = stroke.color;
          // Neon outer glow simulation for vector export
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

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error exporting canvas: $e');
      return null;
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

  void reset() {
    _strokes.clear();
    _redoStack.clear();
    _currentTool = DrawingToolType.brush;
    _currentColor = const Color(0xFF4F7CFF);
    _brushSize = 8.0;
    _opacity = 1.0;
    _flow = 1.0;
    _isSubmitting = false;
    _zoomScale = 1.0;
    _panOffset = Offset.zero;
    _showGrid = false;
    _snapGrid = false;
    notifyListeners();
  }
}
