import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Animated countdown timer widget with circular progress indicator.
class TimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onTimeUp;

  const TimerWidget({
    super.key,
    required this.totalSeconds,
    required this.onTimeUp,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
          widget.onTimeUp();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.totalSeconds;
    final isUrgent = _remainingSeconds <= 10;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppTheme.accentCoral.withOpacity(0.15)
                : AppTheme.cardDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUrgent
                  ? AppTheme.accentCoral.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpacerWidgetWrapper(
                progress: progress,
                isUrgent: isUrgent,
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isUrgent ? 1.15 : 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: isUrgent && _remainingSeconds % 2 == 0 ? scale : 1.0,
                    child: Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isUrgent ? AppTheme.accentCoral : AppTheme.textDark,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class SpacerWidgetWrapper extends StatelessWidget {
  final double progress;
  final bool isUrgent;

  const SpacerWidgetWrapper({
    super.key,
    required this.progress,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isUrgent ? AppTheme.accentCoral : AppTheme.accentLight,
            ),
          ),
          Center(
            child: Icon(
              Icons.timer_outlined,
              size: 14,
              color: isUrgent ? AppTheme.accentCoral : AppTheme.textSecDark,
            ),
          ),
        ],
      ),
    );
  }
}
