import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../services/audio_service.dart';
import '../../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    AudioService().playClick();
    final name = _usernameController.text.trim();
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithUsername(name);

    if (success && mounted) {
      await context.read<ProgressionProvider>().loadProfileForUsername(name);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Stack(
        children: [
          // Sketchpad grid backdrop
          Positioned.fill(
            child: CustomPaint(
              painter: SketchpadBackgroundPainter(
                gridColor: textColor,
                isDark: isDark,
              ),
            ),
          ),

          // Floating background bubbles
          Positioned(
            top: 40,
            left: 50,
            child: _buildBubble(AppTheme.accentYellow.withOpacity(0.08), 80),
          ),
          Positioned(
            bottom: 60,
            right: 40,
            child: _buildBubble(AppTheme.accentCoral.withOpacity(0.08), 120),
          ),
          Positioned(
            top: 250,
            right: 80,
            child: _buildBubble(primaryColor.withOpacity(0.06), 60),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Neobrutalist logo badge
                          Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: AppTheme.gameCardDecoration(
                                    color: primaryColor,
                                    borderColor: borderColor,
                                    shadowColor: borderColor,
                                    radius: 24,
                                  ),
                                  child: const Icon(
                                    LucideIcons.brush,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Icon(LucideIcons.sparkles, color: AppTheme.accentYellow, size: 24),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          Text(
                            'DrawBattle',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            'Sketch fast · Duel friends · Let AI judge',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: textMuted,
                                ),
                          ),
                          const SizedBox(height: AppTheme.space32),

                          // Login form card
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space24),
                            decoration: AppTheme.gameCardDecoration(
                              color: cardBg,
                              borderColor: borderColor,
                              shadowColor: primaryColor,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Choose nickname',
                                    style: Theme.of(context).textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    'Enter a name to join the sketch arena',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space24),
                                  TextFormField(
                                    controller: _usernameController,
                                    textCapitalization: TextCapitalization.words,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. PixelWarrior',
                                      prefixIcon: Icon(LucideIcons.user, color: textMuted, size: 18),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Pick a nickname';
                                      if (v.trim().length < 2) return 'At least 2 characters';
                                      if (v.trim().length > 20) return 'Max 20 characters';
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _handleJoin(),
                                  ),
                                  const SizedBox(height: AppTheme.space24),

                                  // Error Display
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      if (auth.error != null) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: AppTheme.space16),
                                          padding: const EdgeInsets.all(AppTheme.space12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentCoral.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                            border: Border.all(
                                              color: borderColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.alertTriangle, color: AppTheme.accentCoral, size: 16),
                                              const SizedBox(width: AppTheme.space8),
                                              Expanded(
                                                child: Text(
                                                  auth.error!,
                                                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),

                                  // Get Started Button
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      return Container(
                                        height: 56,
                                        decoration: AppTheme.gameCardDecoration(
                                          color: primaryColor,
                                          borderColor: borderColor,
                                          shadowColor: borderColor,
                                          radius: AppTheme.radiusMedium,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: auth.isLoading ? null : _handleJoin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                            ),
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text('Get Started'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
