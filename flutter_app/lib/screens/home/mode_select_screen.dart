import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../services/audio_service.dart';
import '../../widgets/doodle_painter.dart';
import '../../widgets/mascot_painter.dart';

/// Mode Selection screen — choose between Single Player and Multiplayer.
class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  final List<Animation<double>> _staggerAnims = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    for (int i = 0; i < 4; i++) {
      final start = i * 0.18;
      final end = (start + 0.45).clamp(0.0, 1.0);
      _staggerAnims.add(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    }

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    if (index >= _staggerAnims.length) return child;
    return FadeTransition(
      opacity: _staggerAnims[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_staggerAnims[index]),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textMuted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: Stack(
        children: [
          // Doodle background
          Positioned.fill(
            child: CustomPaint(
              painter:
                  DoodlePainter(primaryColor: primary, isDark: isDark, seed: 77),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar with back button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16, vertical: AppTheme.space8),
                  child: Row(
                    children: [
                      _BounceTapWidget(
                        onTap: () {
                          AudioService().playClick();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.cardDark : AppColors.cardLight)
                                .withOpacity(0.9),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(LucideIcons.arrowLeft,
                              size: 20,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mascot + Title
                            _buildAnimated(
                              0,
                              Column(
                                children: [
                                  const AnimatedInky(
                                    size: 80,
                                    expression: InkyExpression.excited,
                                  ),
                                  const SizedBox(height: AppTheme.space16),
                                  Text(
                                    'Choose Your Mode',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 28,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    'How do you want to play today?',
                                    style: TextStyle(
                                        color: textMuted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space32),

                            // Single Player Card
                            _buildAnimated(
                              1,
                              _ModeCard(
                                title: 'Single Player',
                                subtitle:
                                    'Challenge yourself with AI judging.\nPick your category, difficulty & rounds.',
                                icon: LucideIcons.user,
                                emoji: '🎨',
                                gradientStart: AppColors.teal,
                                gradientEnd: AppColors.mint,
                                accentColor: AppColors.teal,
                                onTap: () {
                                  AudioService().playClick();
                                  Navigator.pushNamed(
                                      context, '/single_player');
                                },
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            // Multiplayer Card
                            _buildAnimated(
                              2,
                              _ModeCard(
                                title: 'Multiplayer',
                                subtitle:
                                    'Create or join a room.\nDraw & compete with friends in real-time!',
                                icon: LucideIcons.swords,
                                emoji: '⚔️',
                                gradientStart: AppColors.coral,
                                gradientEnd: AppColors.rose,
                                accentColor: AppColors.coral,
                                onTap: () {
                                  AudioService().playClick();
                                  Navigator.pushNamed(context, '/lobby');
                                },
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),

                            // Quick solo shortcut
                            _buildAnimated(
                              3,
                              _BounceTapWidget(
                                onTap: () {
                                  AudioService().playClick();
                                  Navigator.pushNamed(
                                      context, '/single_player');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppColors.cardDark
                                            : AppColors.cardLight)
                                        .withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.zap,
                                          size: 16, color: AppColors.sunny),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quick Solo — Jump straight in!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A large illustrated mode selection card with gradient accent and bounce-on-tap.
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _BounceTapWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.35 : 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDark ? 0.15 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: gradientStart.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.arrowRight,
                  size: 18, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable widget that scales down on press and bounces back.
class _BounceTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceTapWidget({required this.child, required this.onTap});

  @override
  State<_BounceTapWidget> createState() => _BounceTapWidgetState();
}

class _BounceTapWidgetState extends State<_BounceTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
