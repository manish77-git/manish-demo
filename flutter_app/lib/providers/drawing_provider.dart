import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';

enum DrawingToolType {
  pencil,
  pen,         // Ink Pen
  brush,       // Paint Brush
  marker,
  airbrush,
  spray,       // Spray Paint
  crayon,
  watercolor,
  oilBrush,    // Thick Oil Impasto
  chalk,       // Dusty Chalk Grain
  neon,
  pixel,
  calligraphy, // Calligraphy Pen
  softBrush,
  hardBrush,
  eraser,
  fill,        // Paint Bucket
  line,
  rectangle,
  circle,
  ellipse,
  triangle,
  polygon,
  arrow,
  star,
  bezier,
  select,      // Selection Tool
}

/// Represents a single stroke, shape, or fill on the canvas.
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingToolType toolType;
  final double opacity;
  final double flow;
  final bool isEraser;
  final bool isShape;
  final bool isFilled;
  final Uint8List? fillImageData;
  final double fillCanvasWidth;
  final double fillCanvasHeight;

  // Cached decoded ui.Image for rendering fill strokes (not serialised)
  ui.Image? _cachedFillImage;
  ui.Image? get cachedFillImage => _cachedFillImage;
  set cachedFillImage(ui.Image? img) => _cachedFillImage = img;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.toolType,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.isEraser = false,
    this.isShape = false,
    this.isFilled = false,
    this.fillImageData,
    this.fillCanvasWidth = 0,
    this.fillCanvasHeight = 0,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'toolType': toolType.name,
      'opacity': opacity,
      'flow': flow,
      'isEraser': isEraser,
      'isShape': isShape,
      'isFilled': isFilled,
    };
    if (fillImageData != null) {
      map['fillImageData'] = base64Encode(fillImageData!);
      map['fillCanvasWidth'] = fillCanvasWidth;
      map['fillCanvasHeight'] = fillCanvasHeight;
    }
    return map;
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final pointsRaw = json['points'] as List;
    final points = pointsRaw
        .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
        .toList();

    final colorVal = json['color'] as int;

    Uint8List? fillData;
    if (json['fillImageData'] != null) {
      fillData = base64Decode(json['fillImageData'] as String);
    }

    return DrawingStroke(
      points: points,
      color: Color(colorVal),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      toolType: DrawingToolType.values.firstWhere(
        (t) => t.name == json['toolType'],
        orElse: () => DrawingToolType.brush,
      ),
      opacity: (json['opacity'] as num).toDouble(),
      flow: (json['flow'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
      isShape: json['isShape'] as bool? ?? false,
      isFilled: json['isFilled'] as bool? ?? false,
      fillImageData: fillData,
      fillCanvasWidth: (json['fillCanvasWidth'] as num?)?.toDouble() ?? 0,
      fillCanvasHeight: (json['fillCanvasHeight'] as num?)?.toDouble() ?? 0,
    );
  }

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DrawingToolType? toolType,
    double? opacity,
    double? flow,
    bool? isEraser,
    bool? isShape,
    bool? isFilled,
    Uint8List? fillImageData,
    double? fillCanvasWidth,
    double? fillCanvasHeight,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      toolType: toolType ?? this.toolType,
      opacity: opacity ?? this.opacity,
      flow: flow ?? this.flow,
      isEraser: isEraser ?? this.isEraser,
      isShape: isShape ?? this.isShape,
      isFilled: isFilled ?? this.isFilled,
      fillImageData: fillImageData ?? this.fillImageData,
      fillCanvasWidth: fillCanvasWidth ?? this.fillCanvasWidth,
      fillCanvasHeight: fillCanvasHeight ?? this.fillCanvasHeight,
    );
  }
}

/// Drawing state management provider.
class DrawingProvider extends ChangeNotifier {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStack = [];

  // Opponent progress states
  final Map<String, List<DrawingStroke>> _opponentStrokes = {};
  final Map<String, Offset> _opponentCursors = {};
  final Map<String, String> _opponentNames = {};

  DrawingToolType _currentTool = DrawingToolType.brush;
  Color _currentColor = const Color(0xFF7C3AED); // brand violet
  double _brushSize = 8.0;
  double _opacity = 1.0;
  double _flow = 1.0;
  double _smoothing = 5.0;
  bool _isSubmitting = false;

  Uint8List? _lastSubmittedBytes;
  String? _lastSubmittedBase64;

  Uint8List? get lastSubmittedBytes => _lastSubmittedBytes;
  String? get lastSubmittedBase64 => _lastSubmittedBase64;

  void cacheLastSubmittedDrawing(Uint8List bytes, String base64) {
    _lastSubmittedBytes = bytes;
    _lastSubmittedBase64 = base64;
    notifyListeners();
  }

  // Tools toggles
  bool _mirrorDrawing = false;
  bool _stabilization = true;
  bool _showGrid = false;
  bool _snapGrid = false;

  // Selection states
  int? _selectedStrokeIndex;

  // External socket trigger
  void Function(List<Map<String, dynamic>> strokesJson)? onLocalStrokesChanged;
  void Function(double x, double y)? onLocalCursorMoved;
  void Function()? onLocalCanvasCleared;

  // Getters
  List<DrawingStroke> get strokes => List.unmodifiable(_strokes);
  List<DrawingStroke> get redoStack => List.unmodifiable(_redoStack);
  Map<String, List<DrawingStroke>> get opponentStrokes => _opponentStrokes;
  Map<String, Offset> get opponentCursors => _opponentCursors;
  Map<String, String> get opponentNames => _opponentNames;

  DrawingToolType get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get brushSize => _brushSize;
  double get opacity => _opacity;
  double get flow => _flow;
  double get smoothing => _smoothing;
  bool get isSubmitting => _isSubmitting;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  bool get mirrorDrawing => _mirrorDrawing;
  bool get stabilization => _stabilization;
  bool get showGrid => _showGrid;
  bool get snapGrid => _snapGrid;
  int? get selectedStrokeIndex => _selectedStrokeIndex;

  // ─── Opponent Drawing Handlers ───────────────────────
  void updateOpponentStrokes(String userId, String name, List<dynamic> strokesList) {
    _opponentNames[userId] = name;
    _opponentStrokes[userId] = strokesList
        .map((s) => DrawingStroke.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
    notifyListeners();
  }

  void updateOpponentCursor(String userId, double x, double y) {
    _opponentCursors[userId] = Offset(x, y);
    notifyListeners();
  }

  void clearOpponent(String userId) {
    _opponentStrokes.remove(userId);
    _opponentCursors.remove(userId);
    _opponentNames.remove(userId);
    notifyListeners();
  }

  // ─── Settings Modifiers ──────────────────────────────
  void setTool(DrawingToolType tool) {
    _currentTool = tool;
    if (tool != DrawingToolType.select) {
      _selectedStrokeIndex = null;
    }
    notifyListeners();
  }

  final List<Color> _recentColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
    const Color(0xFFA78BFA),
    const Color(0xFF2D3436),
  ];
  final List<Color> _favoriteColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
  ];

  List<Color> get recentColors => List.unmodifiable(_recentColors);
  List<Color> get favoriteColors => List.unmodifiable(_favoriteColors);

  void setColor(Color color) {
    _currentColor = color;
    if (!_recentColors.contains(color)) {
      _recentColors.insert(0, color);
      if (_recentColors.length > 8) {
        _recentColors.removeLast();
      }
    }
    notifyListeners();
  }

  void toggleFavoriteColor(Color color) {
    if (_favoriteColors.contains(color)) {
      _favoriteColors.remove(color);
    } else {
      _favoriteColors.add(color);
    }
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

  void toggleMirrorDrawing() {
    _mirrorDrawing = !_mirrorDrawing;
    notifyListeners();
  }

  void toggleStabilization() {
    _stabilization = !_stabilization;
    notifyListeners();
  }

  // ─── Canvas Actions ──────────────────────────────────
  Offset _applyGridSnap(Offset point) {
    if (!_snapGrid) return point;
    const gridSize = 24.0;
    final x = (point.dx / gridSize).round() * gridSize;
    final y = (point.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }

  Offset _applyStabilization(Offset point) {
    if (!_stabilization || _strokes.isEmpty) return point;
    final lastStroke = _strokes.last;
    if (lastStroke.points.isEmpty || lastStroke.isShape) return point;
    final lastPoint = lastStroke.points.last;
    // Exponential Moving Average
    const weight = 0.35;
    return Offset(
      lastPoint.dx + (point.dx - lastPoint.dx) * weight,
      lastPoint.dy + (point.dy - lastPoint.dy) * weight,
    );
  }

  void startStroke(Offset point, {Size? canvasSize}) {
    _redoStack.clear();
    final snappedPoint = _applyGridSnap(point);

    if (_currentTool == DrawingToolType.select) {
      _selectStrokeAt(snappedPoint);
      return;
    }

    if (_currentTool == DrawingToolType.fill) {
      // Real flood-fill: rasterise canvas at actual size, scanline fill at tap point
      _performFloodFill(snappedPoint, canvasSize ?? const Size(400, 400));
      return;
    }

    final isShape = [
      DrawingToolType.line,
      DrawingToolType.rectangle,
      DrawingToolType.circle,
      DrawingToolType.ellipse,
      DrawingToolType.triangle,
      DrawingToolType.polygon,
      DrawingToolType.arrow,
      DrawingToolType.star,
      DrawingToolType.bezier
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

    if (onLocalCursorMoved != null) {
      onLocalCursorMoved!(point.dx, point.dy);
    }
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentTool == DrawingToolType.select && _selectedStrokeIndex != null) {
      if (_strokes.isNotEmpty && _selectedStrokeIndex! < _strokes.length) {
        if (onLocalCursorMoved != null) {
          onLocalCursorMoved!(point.dx, point.dy);
        }
      }
      return;
    }

    if (_strokes.isNotEmpty && _currentTool != DrawingToolType.fill && _currentTool != DrawingToolType.select) {
      final snapped = _applyGridSnap(point);
      final stabilized = _applyStabilization(snapped);
      final currentStroke = _strokes.last;

      if (currentStroke.isShape) {
        if (currentStroke.points.length > 1) {
          currentStroke.points[1] = stabilized;
        } else {
          currentStroke.points.add(stabilized);
        }
      } else {
        currentStroke.points.add(stabilized);
      }

      if (onLocalCursorMoved != null) {
        onLocalCursorMoved!(point.dx, point.dy);
      }
      notifyListeners();
    }
  }

  void endStroke() {
    if (_strokes.isNotEmpty) {
      if (_mirrorDrawing && _currentTool != DrawingToolType.select && _currentTool != DrawingToolType.fill) {
        final last = _strokes.last;
        final mirroredPoints = last.points.map((p) => Offset(800.0 - p.dx, p.dy)).toList();
        _strokes.add(last.copyWith(points: mirroredPoints));
      }
      _triggerSync();
    }
    notifyListeners();
  }

  void _triggerSync() {
    if (onLocalStrokesChanged != null) {
      onLocalStrokesChanged!(_strokes.map((s) => s.toJson()).toList());
    }
  }

  // ─── Selection Manipulation ──────────────────────────
  void _selectStrokeAt(Offset point) {
    _selectedStrokeIndex = null;
    double minDistance = 35.0;

    for (int i = _strokes.length - 1; i >= 0; i--) {
      final stroke = _strokes[i];
      for (final p in stroke.points) {
        final dist = (p - point).distance;
        if (dist < minDistance) {
          minDistance = dist;
          _selectedStrokeIndex = i;
        }
      }
    }
    notifyListeners();
  }

  void moveSelectedStroke(Offset delta) {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _strokes.length) {
      final stroke = _strokes[_selectedStrokeIndex!];
      final newPoints = stroke.points.map((p) => p + delta).toList();
      _strokes[_selectedStrokeIndex!] = stroke.copyWith(points: newPoints);
      _triggerSync();
      notifyListeners();
    }
  }

  void rotateSelectedStroke(double angleDegrees) {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _strokes.length) {
      final stroke = _strokes[_selectedStrokeIndex!];
      if (stroke.points.isEmpty) return;

      double sumX = 0, sumY = 0;
      for (final p in stroke.points) {
        sumX += p.dx;
        sumY += p.dy;
      }
      final center = Offset(sumX / stroke.points.length, sumY / stroke.points.length);
      final rad = angleDegrees * math.pi / 180;

      final newPoints = stroke.points.map((p) {
        final dx = p.dx - center.dx;
        final dy = p.dy - center.dy;
        return Offset(
          center.dx + dx * math.cos(rad) - dy * math.sin(rad),
          center.dy + dx * math.sin(rad) + dy * math.cos(rad),
        );
      }).toList();

      _strokes[_selectedStrokeIndex!] = stroke.copyWith(points: newPoints);
      _triggerSync();
      notifyListeners();
    }
  }

  void scaleSelectedStroke(double factor) {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _strokes.length) {
      final stroke = _strokes[_selectedStrokeIndex!];
      if (stroke.points.isEmpty) return;

      double sumX = 0, sumY = 0;
      for (final p in stroke.points) {
        sumX += p.dx;
        sumY += p.dy;
      }
      final center = Offset(sumX / stroke.points.length, sumY / stroke.points.length);

      final newPoints = stroke.points.map((p) {
        final dx = p.dx - center.dx;
        final dy = p.dy - center.dy;
        return Offset(center.dx + dx * factor, center.dy + dy * factor);
      }).toList();

      _strokes[_selectedStrokeIndex!] = stroke.copyWith(points: newPoints);
      _triggerSync();
      notifyListeners();
    }
  }

  void duplicateSelectedStroke() {
    if (_selectedStrokeIndex != null && _selectedStrokeIndex! < _strokes.length) {
      final stroke = _strokes[_selectedStrokeIndex!];
      final newPoints = stroke.points.map((p) => p + const Offset(15, 15)).toList();
      _strokes.add(stroke.copyWith(points: newPoints));
      _selectedStrokeIndex = _strokes.length - 1;
      _triggerSync();
      notifyListeners();
    }
  }

  // ─── Undo/Redo System ────────────────────────────────
  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      _triggerSync();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      _triggerSync();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _redoStack.clear();
    _selectedStrokeIndex = null;
    _triggerSync();
    if (onLocalCanvasCleared != null) {
      onLocalCanvasCleared!();
    }
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void loadDrawingHistory(Map<String, dynamic> historyMap) {
    _strokes.clear();
    _redoStack.clear();
    historyMap.forEach((uid, strokesList) {
      final list = (strokesList as List)
          .map((s) => DrawingStroke.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      _opponentStrokes[uid] = list;
    });
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
        // Handle fill-image strokes
        if (stroke.fillImageData != null) {
          try {
            final codec = await ui.instantiateImageCodec(stroke.fillImageData!);
            final frame = await codec.getNextFrame();
            final img = frame.image;
            if (stroke.fillCanvasWidth > 0 && stroke.fillCanvasHeight > 0) {
              canvas.drawImageRect(
                img,
                Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
                Rect.fromLTWH(0, 0, stroke.fillCanvasWidth, stroke.fillCanvasHeight),
                Paint(),
              );
            } else {
              canvas.drawImage(img, Offset.zero, Paint());
            }
          } catch (_) {}
          continue;
        }

        final paint = Paint()
          ..color = stroke.isEraser
              ? Colors.white
              : stroke.color.withValues(alpha: stroke.opacity)
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = stroke.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
          ..isAntiAlias = true;

        if (stroke.toolType == DrawingToolType.watercolor) {
          paint.strokeWidth = stroke.strokeWidth * 1.5;
          paint.color = stroke.color.withValues(alpha: stroke.opacity * 0.35);
        } else if (stroke.toolType == DrawingToolType.neon) {
          canvas.drawPath(
            _createPathForStroke(stroke),
            Paint()
              ..color = stroke.color.withValues(alpha: 0.4)
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

  void reset() {
    _strokes.clear();
    _redoStack.clear();
    _opponentStrokes.clear();
    _opponentCursors.clear();
    _opponentNames.clear();
    _currentTool = DrawingToolType.brush;
    _currentColor = const Color(0xFF7C3AED);
    _brushSize = 8.0;
    _opacity = 1.0;
    _flow = 1.0;
    _mirrorDrawing = false;
    _stabilization = true;
    _isSubmitting = false;
    _showGrid = false;
    _snapGrid = false;
    _selectedStrokeIndex = null;
    notifyListeners();
  }

  // ─── FLOOD FILL IMPLEMENTATION ───────────────────────────

  /// Perform a real scanline flood fill on the rasterised canvas at exact dimensions.
  Future<void> _performFloodFill(Offset tapPoint, Size canvasSize) async {
    try {
      // 1. Rasterise current canvas to pixel buffer at actual logical size
      final fillWidth = canvasSize.width.toInt().clamp(50, 2000);
      final fillHeight = canvasSize.height.toInt().clamp(50, 2000);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillWidth.toDouble(), fillHeight.toDouble()),
        Paint()..color = Colors.white,
      );

      // Draw existing strokes at exact 1:1 coordinates
      for (final stroke in _strokes) {
        if (stroke.fillImageData != null) {
          // Draw cached fill images
          try {
            final codec = await ui.instantiateImageCodec(stroke.fillImageData!);
            final frame = await codec.getNextFrame();
            final img = frame.image;
            canvas.drawImageRect(
              img,
              Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
              Rect.fromLTWH(0, 0, stroke.fillCanvasWidth > 0 ? stroke.fillCanvasWidth : fillWidth.toDouble(),
                  stroke.fillCanvasHeight > 0 ? stroke.fillCanvasHeight : fillHeight.toDouble()),
              Paint(),
            );
          } catch (_) {}
          continue;
        }

        final paint = Paint()
          ..color = stroke.isEraser ? Colors.white : stroke.color.withValues(alpha: stroke.opacity)
          ..strokeWidth = stroke.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = stroke.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
          ..isAntiAlias = true;

        if (stroke.isShape && stroke.points.length >= 2) {
          _drawShape(canvas, stroke, paint);
        } else {
          canvas.drawPath(_createPathForStroke(stroke), paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(fillWidth, fillHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final pixels = byteData.buffer.asUint8List();
      final width = fillWidth;
      final height = fillHeight;

      // 2. Get tap pixel coordinates
      final px = tapPoint.dx.round().clamp(0, width - 1);
      final py = tapPoint.dy.round().clamp(0, height - 1);

      // 3. Get target colour at tap point
      final targetIdx = (py * width + px) * 4;
      final targetR = pixels[targetIdx];
      final targetG = pixels[targetIdx + 1];
      final targetB = pixels[targetIdx + 2];
      final targetA = pixels[targetIdx + 3];

      // Fill colour
      final fillR = _currentColor.red;
      final fillG = _currentColor.green;
      final fillB = _currentColor.blue;
      final fillA = (_opacity * 255).round();

      // If target is already the fill colour, skip
      if (_colorDistance(targetR, targetG, targetB, targetA, fillR, fillG, fillB, fillA) < 10) {
        return;
      }

      // 4. Scanline flood fill with adaptive anti-alias tolerance
      const tolerance = 45; // Color distance threshold for outline boundaries
      final filled = Uint8List(width * height); // 0 = unfilled, 1 = filled
      final stack = <int>[];
      stack.add(py * width + px);

      while (stack.isNotEmpty) {
        final pos = stack.removeLast();
        final cx = pos % width;
        final cy = pos ~/ width;

        if (cx < 0 || cx >= width || cy < 0 || cy >= height) continue;
        if (filled[pos] == 1) continue;

        final idx = pos * 4;
        final r = pixels[idx];
        final g = pixels[idx + 1];
        final b = pixels[idx + 2];
        final a = pixels[idx + 3];

        if (_colorDistance(r, g, b, a, targetR, targetG, targetB, targetA) > tolerance) continue;

        filled[pos] = 1;

        // Scanline: fill left
        int left = cx - 1;
        while (left >= 0) {
          final lpos = cy * width + left;
          if (filled[lpos] == 1) break;
          final li = lpos * 4;
          if (_colorDistance(pixels[li], pixels[li + 1], pixels[li + 2], pixels[li + 3],
                  targetR, targetG, targetB, targetA) > tolerance) break;
          filled[lpos] = 1;
          left--;
        }
        left++;

        // Scanline: fill right
        int right = cx + 1;
        while (right < width) {
          final rpos = cy * width + right;
          if (filled[rpos] == 1) break;
          final ri = rpos * 4;
          if (_colorDistance(pixels[ri], pixels[ri + 1], pixels[ri + 2], pixels[ri + 3],
                  targetR, targetG, targetB, targetA) > tolerance) break;
          filled[rpos] = 1;
          right++;
        }
        right--;

        // Push rows above and below
        for (int x = left; x <= right; x++) {
          if (cy > 0) {
            final upPos = (cy - 1) * width + x;
            if (filled[upPos] == 0) stack.add(upPos);
          }
          if (cy < height - 1) {
            final downPos = (cy + 1) * width + x;
            if (filled[downPos] == 0) stack.add(downPos);
          }
        }
      }

      // 5. Anti-aliasing edge expansion (dilate filled area by 1px so edges meet outlines cleanly)
      final dilated = Uint8List.fromList(filled);
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final idx = y * width + x;
          if (filled[idx] == 0) {
            // If any 4-neighbor is filled, dilate into anti-aliased edge
            if (filled[idx - 1] == 1 || filled[idx + 1] == 1 ||
                filled[idx - width] == 1 || filled[idx + width] == 1) {
              final pIdx = idx * 4;
              // Only dilate if it's not a pure contrasting line color
              if (_colorDistance(pixels[pIdx], pixels[pIdx + 1], pixels[pIdx + 2], pixels[pIdx + 3],
                      targetR, targetG, targetB, targetA) <= tolerance + 60) {
                dilated[idx] = 1;
              }
            }
          }
        }
      }

      // 6. Build the fill image: only fill the marked pixels
      final resultPixels = Uint8List(width * height * 4);
      for (int i = 0; i < width * height; i++) {
        if (dilated[i] == 1) {
          resultPixels[i * 4] = fillR;
          resultPixels[i * 4 + 1] = fillG;
          resultPixels[i * 4 + 2] = fillB;
          resultPixels[i * 4 + 3] = fillA;
        } else {
          // Transparent
          resultPixels[i * 4] = 0;
          resultPixels[i * 4 + 1] = 0;
          resultPixels[i * 4 + 2] = 0;
          resultPixels[i * 4 + 3] = 0;
        }
      }

      // 7. Encode as PNG
      final fillRecorder = ui.PictureRecorder();
      final fillCanvas = Canvas(fillRecorder);
      final codec = await ui.ImmutableBuffer.fromUint8List(resultPixels);
      final descriptor = ui.ImageDescriptor.raw(
        codec,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final imgCodec = await descriptor.instantiateCodec();
      final frame = await imgCodec.getNextFrame();
      fillCanvas.drawImage(frame.image, Offset.zero, Paint());
      final fillPicture = fillRecorder.endRecording();
      final fillImage = await fillPicture.toImage(width, height);
      final pngData = await fillImage.toByteData(format: ui.ImageByteFormat.png);

      if (pngData == null) return;

      final pngBytes = pngData.buffer.asUint8List();

      // 8. Add as a fill stroke
      _strokes.add(DrawingStroke(
        points: [tapPoint],
        color: _currentColor,
        strokeWidth: 0,
        toolType: DrawingToolType.fill,
        opacity: _opacity,
        fillImageData: pngBytes,
        fillCanvasWidth: width.toDouble(),
        fillCanvasHeight: height.toDouble(),
      ));

      _triggerSync();
      notifyListeners();
    } catch (e) {
      debugPrint('[DrawingProvider] Flood fill error: $e');
    }
  }

  /// Euclidean colour distance for flood-fill boundary detection.
  static int _colorDistance(int r1, int g1, int b1, int a1, int r2, int g2, int b2, int a2) {
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    final da = a1 - a2;
    return math.sqrt(dr * dr + dg * dg + db * db + da * da).round();
  }
}
