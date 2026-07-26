import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Reusable confetti particle system for celebrations.
class ConfettiPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final int particleCount;
  final List<_ConfettiParticle> _particles;

  ConfettiPainter({
    required this.progress,
    this.particleCount = 80,
  }) : _particles = _generateParticles(particleCount);

  static List<_ConfettiParticle> _generateParticles(int count) {
    final random = math.Random(42);
    return List.generate(count, (i) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        startY: -0.1 - random.nextDouble() * 0.3,
        speed: 0.4 + random.nextDouble() * 0.8,
        size: 4 + random.nextDouble() * 8,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 6,
        drift: (random.nextDouble() - 0.5) * 0.3,
        color: AppColors.confetti[i % AppColors.confetti.length],
        shape: _ConfettiShape.values[random.nextInt(_ConfettiShape.values.length)],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final currentY = p.startY + progress * p.speed * 1.5;
      if (currentY > 1.2) continue;

      final x = (p.x + progress * p.drift) * size.width;
      final y = currentY * size.height;
      final rotation = p.rotation + progress * p.rotationSpeed;
      final opacity = (1.0 - (currentY.clamp(0.8, 1.2) - 0.8) / 0.4).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (p.shape) {
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ConfettiShape.rectangle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
              const Radius.circular(1),
            ),
            paint,
          );
          break;
        case _ConfettiShape.star:
          _drawMiniStar(canvas, p.size / 2, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawMiniStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * math.pi / 180;
      final ox = radius * math.cos(outerAngle);
      final oy = radius * math.sin(outerAngle);
      final ix = radius * 0.4 * math.cos(innerAngle);
      final iy = radius * 0.4 * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

enum _ConfettiShape { circle, rectangle, star }

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double drift;
  final Color color;
  final _ConfettiShape shape;

  const _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.drift,
    required this.color,
    required this.shape,
  });
}

/// Widget that animates confetti falling
class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  final Widget child;

  const ConfettiOverlay({
    super.key,
    required this.trigger,
    required this.child,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.trigger) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.trigger)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: ConfettiPainter(progress: _controller.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
