import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_service.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../widgets/mascot_painter.dart';
import '../../widgets/doodle_painter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative background
          Positioned.fill(
            child: CustomPaint(
              painter: DoodlePainter(
                primaryColor: primary,
                isDark: isDark,
                seed: 99,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space24,
                  vertical: AppTheme.space32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Inky mascot waving
                          const AnimatedInky(
                            size: 100,
                            expression: InkyExpression.waving,
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // App title
                          Text(
                            'DrawBattle',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            'Draw. Battle. Laugh. Win.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space32),

                          // Login card
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space24),
                            decoration: AppTheme.gameCard(context),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Choose your name',
                                    style: Theme.of(context).textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    'Enter a nickname to join the arena',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                      fontWeight: FontWeight.w500,
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
                                  const SizedBox(height: AppTheme.space20),

                                  // Error
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      if (auth.error != null) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: AppTheme.space16),
                                          padding: const EdgeInsets.all(AppTheme.space12),
                                          decoration: BoxDecoration(
                                            color: AppColors.coral.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                            border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.alertTriangle, color: AppColors.coral, size: 16),
                                              const SizedBox(width: AppTheme.space8),
                                              Expanded(
                                                child: Text(
                                                  auth.error!,
                                                  style: const TextStyle(
                                                    color: AppColors.coral,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),

                                  // Join button
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      return Container(
                                        height: 54,
                                        decoration: AppTheme.gradientButton(),
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
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(LucideIcons.sparkles, size: 18),
                                                    SizedBox(width: 8),
                                                    Text("Let's Draw!"),
                                                  ],
                                                ),
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
}
