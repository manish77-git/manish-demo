import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Inky — DrawBattle's lovable pencil mascot with a beret.
/// Renders a cute pencil character with eyes, a beret, and optional expressions.
class InkyMascot extends StatelessWidget {
  final double size;
  final InkyExpression expression;

  const InkyMascot({
    super.key,
    this.size = 120,
    this.expression = InkyExpression.happy,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(
        painter: _InkyPainter(expression: expression),
      ),
    );
  }
}

enum InkyExpression { happy, excited, thinking, waving }

class _InkyPainter extends CustomPainter {
  final InkyExpression expression;
  _InkyPainter({required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ─── PENCIL BODY ─────────────────────────────────────
    final bodyTop = h * 0.28;
    final bodyBottom = h * 0.85;
    final bodyWidth = w * 0.38;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.92), width: bodyWidth * 2.2, height: h * 0.08),
      shadowPaint,
    );

    // Main pencil body (warm yellow)
    final bodyPaint = Paint()
      ..color = const Color(0xFFFFD93D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(cx - bodyWidth, bodyTop, cx + bodyWidth, bodyBottom),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Pencil tip (triangle)
    final tipPaint = Paint()
      ..color = const Color(0xFFE8C96F)
      ..style = PaintingStyle.fill;
    final tipPath = Path()
      ..moveTo(cx - bodyWidth, bodyBottom)
      ..lineTo(cx + bodyWidth, bodyBottom)
      ..lineTo(cx, h * 0.98)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Tip point
    final pointPaint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..style = PaintingStyle.fill;
    final pointPath = Path()
      ..moveTo(cx - bodyWidth * 0.3, h * 0.92)
      ..lineTo(cx + bodyWidth * 0.3, h * 0.92)
      ..lineTo(cx, h * 0.98)
      ..close();
    canvas.drawPath(pointPath, pointPaint);

    // Body stripe (orange band)
    final stripePaint = Paint()
      ..color = const Color(0xFFFF922B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(cx - bodyWidth, bodyTop + (bodyBottom - bodyTop) * 0.08, cx + bodyWidth, bodyTop + (bodyBottom - bodyTop) * 0.2),
      stripePaint,
    );

    // ─── BERET ───────────────────────────────────────────
    final beretPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    final beretPath = Path()
      ..moveTo(cx - bodyWidth * 1.3, bodyTop + 2)
      ..quadraticBezierTo(cx - bodyWidth * 0.5, bodyTop - h * 0.18, cx, bodyTop - h * 0.12)
      ..quadraticBezierTo(cx + bodyWidth * 0.8, bodyTop - h * 0.2, cx + bodyWidth * 1.1, bodyTop + 2)
      ..close();
    canvas.drawPath(beretPath, beretPaint);

    // Beret pom-pom
    canvas.drawCircle(
      Offset(cx + bodyWidth * 0.2, bodyTop - h * 0.16),
      w * 0.05,
      Paint()..color = const Color(0xFFFF8A8A),
    );

    // ─── EYES ────────────────────────────────────────────
    final eyeY = bodyTop + (bodyBottom - bodyTop) * 0.38;
    final eyeSpacing = bodyWidth * 0.45;
    final eyeRadius = w * 0.065;

    // White sclera
    final scleraPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeRadius * 1.4, scleraPaint);
    canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeRadius * 1.4, scleraPaint);

    // Pupils
    final pupilPaint = Paint()
      ..color = const Color(0xFF2D3436)
      ..style = PaintingStyle.fill;
    final pupilOffset = expression == InkyExpression.thinking
        ? const Offset(2, -2)
        : const Offset(0, 0);
    canvas.drawCircle(Offset(cx - eyeSpacing + pupilOffset.dx, eyeY + pupilOffset.dy), eyeRadius, pupilPaint);
    canvas.drawCircle(Offset(cx + eyeSpacing + pupilOffset.dx, eyeY + pupilOffset.dy), eyeRadius, pupilPaint);

    // Eye highlights
    final highlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - eyeSpacing - 1.5, eyeY - 2), eyeRadius * 0.35, highlightPaint);
    canvas.drawCircle(Offset(cx + eyeSpacing - 1.5, eyeY - 2), eyeRadius * 0.35, highlightPaint);

    // ─── MOUTH ───────────────────────────────────────────
    final mouthY = bodyTop + (bodyBottom - bodyTop) * 0.58;
    final mouthPaint = Paint()
      ..color = const Color(0xFF2D3436)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (expression == InkyExpression.excited) {
      // Big open smile
      final mouthPath = Path()
        ..moveTo(cx - bodyWidth * 0.3, mouthY - 2)
        ..quadraticBezierTo(cx, mouthY + bodyWidth * 0.5, cx + bodyWidth * 0.3, mouthY - 2);
      canvas.drawPath(mouthPath, mouthPaint);
    } else if (expression == InkyExpression.thinking) {
      // Small O mouth
      canvas.drawCircle(Offset(cx + 2, mouthY + 2), w * 0.03, mouthPaint);
    } else {
      // Happy smile
      final smilePath = Path()
        ..moveTo(cx - bodyWidth * 0.25, mouthY)
        ..quadraticBezierTo(cx, mouthY + bodyWidth * 0.3, cx + bodyWidth * 0.25, mouthY);
      canvas.drawPath(smilePath, mouthPaint);
    }

    // ─── BLUSH ───────────────────────────────────────────
    final blushPaint = Paint()
      ..color = const Color(0xFFFFB4A2).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - bodyWidth * 0.7, eyeY + eyeRadius * 2), width: w * 0.08, height: w * 0.04),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + bodyWidth * 0.7, eyeY + eyeRadius * 2), width: w * 0.08, height: w * 0.04),
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _InkyPainter oldDelegate) =>
      oldDelegate.expression != expression;
}

/// Animated Inky mascot with bouncing/breathing motion
class AnimatedInky extends StatefulWidget {
  final double size;
  final InkyExpression expression;

  const AnimatedInky({
    super.key,
    this.size = 120,
    this.expression = InkyExpression.happy,
  });

  @override
  State<AnimatedInky> createState() => _AnimatedInkyState();
}

class _AnimatedInkyState extends State<AnimatedInky>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = math.sin(_controller.value * math.pi) * 6;
        final tilt = math.sin(_controller.value * math.pi * 2) * 0.03;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: Transform.rotate(
            angle: tilt,
            child: child,
          ),
        );
      },
      child: InkyMascot(
        size: widget.size,
        expression: widget.expression,
      ),
    );
  }
}
