import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../services/prompt_service.dart';
import '../../services/audio_service.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../widgets/doodle_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _roomCodeController = TextEditingController();
  late AnimationController _staggerController;
  final List<Animation<double>> _staggerAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 5; i++) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      _staggerAnimations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }

    _staggerController.forward();

    // Register user on socket when home loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final socket = context.read<SocketProvider>();
      if (auth.isAuthenticated) {
        socket.registerUserOnline(auth.uid);
      }
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _startPractice() {
    AudioService().playClick();
    PromptCategory selectedCategory = PromptCategory.randomFun;
    PromptDifficulty selectedDifficulty = PromptDifficulty.medium;
    int selectedRounds = 5; // 3, 5, 10, 15, -1 for Endless
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roundOptions = [3, 5, 10, 15, -1];
    String roundsLabel(int r) => r == -1 ? 'Endless ♾️' : '$r Rounds';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  Text('Quick Solo Challenge', style: Theme.of(ctx).textTheme.headlineLarge),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Draw solo, choose rounds, and record your high scores!',
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Category
                  Text('Category', style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: AppTheme.space8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: PromptCategory.values.take(8).map((c) {
                      final isSelected = selectedCategory == c;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedCategory = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.coral.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isSelected ? AppColors.coral : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${c.emoji} ${c.label}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected ? AppColors.coral : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  // Number of Rounds Selector
                  Text('Number of Rounds', style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: AppTheme.space8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: roundOptions.map((r) {
                      final isSelected = selectedRounds == r;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedRounds = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.sunny.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: isSelected ? AppColors.sunny : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            roundsLabel(r),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected ? AppColors.sunny : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  // Difficulty
                  Text('Difficulty', style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    children: PromptDifficulty.values.map((d) {
                      final isSelected = selectedDifficulty == d;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedDifficulty = d),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.teal.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: isSelected ? AppColors.teal : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '${d.emoji} ${d.label}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                                color: isSelected ? AppColors.teal : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Start button
                  Container(
                    height: 54,
                    decoration: AppTheme.gradientButton(
                      startColor: AppColors.teal,
                      endColor: AppColors.mint,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final prompt = PromptService().getRandomPrompt(
                          category: selectedCategory,
                          difficulty: selectedDifficulty,
                        );
                        Navigator.pushNamed(context, '/drawing', arguments: {
                          'prompt': prompt.text,
                          'category': selectedCategory.label,
                          'difficulty': selectedDifficulty.label.toLowerCase(),
                          'isSinglePlayerChallenge': true,
                          'currentRound': 1,
                          'totalRounds': selectedRounds,
                          'cumulativeScore': 0,
                          'isMultiplayer': false,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.play, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'START DRAWING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _createRoom() {
    AudioService().playClick();
    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();

    if (!socket.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting to server... Please try again in a moment.')),
      );
      return;
    }

    socket.createRoom(
      uid: auth.uid,
      displayName: auth.displayName,
    );

    Navigator.pushNamed(context, '/lobby');
  }

  void _joinRoom() {
    AudioService().playClick();
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character room code.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();

    socket.joinRoom(
      roomCode: code,
      uid: auth.uid,
      displayName: auth.displayName,
    );

    Navigator.pushNamed(context, '/lobby');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final socket = context.watch<SocketProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: Stack(
        children: [
          // Background doodles
          Positioned.fill(
            child: CustomPaint(
              painter: DoodlePainter(primaryColor: primary, isDark: isDark),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(auth, socket, isDark, primary, textMuted),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero section with mascot
                            _buildAnimated(0, _buildHeroSection(auth, isDark, primary, textMuted)),
                            const SizedBox(height: AppTheme.space32),

                            // PLAY button (primary CTA)
                            _buildAnimated(1, _buildPlayButton(isDark)),
                            const SizedBox(height: AppTheme.space24),

                            // Game mode cards
                            _buildAnimated(2, _buildGameModes(isDark, primary)),
                            const SizedBox(height: AppTheme.space24),

                            // Join room input
                            _buildAnimated(3, _buildJoinRoomCard(isDark, primary)),
                            const SizedBox(height: AppTheme.space32),

                            // Navigation row
                            _buildAnimated(4, _buildNavRow(isDark)),
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

  Widget _buildAnimated(int index, Widget child) {
    if (index >= _staggerAnimations.length) return child;
    return FadeTransition(
      opacity: _staggerAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_staggerAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth, SocketProvider socket, bool isDark, Color primary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cardDark : AppColors.cardLight).withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.paintbrush, color: AppColors.coral, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'DrawBattle',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Socket Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: socket.isConnected
                  ? AppColors.mint.withValues(alpha: 0.15)
                  : AppColors.coral.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: socket.isConnected ? AppColors.mint : AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  socket.isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: socket.isConnected ? AppColors.mint : AppColors.coral,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Profile Avatar Button
          GestureDetector(
            onTap: () {
              AudioService().playClick();
              Navigator.pushNamed(context, '/profile');
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text(auth.avatar, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AuthProvider auth, bool isDark, Color primary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCard(context),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(auth.avatar, style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, ${auth.displayName}! 👋',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'High Score: ${auth.highestScore} pts · ${auth.gamesWon} Wins',
                  style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        AudioService().playClick();
        Navigator.pushNamed(context, '/single_player');
      },
      child: Container(
        height: 64,
        decoration: AppTheme.gradientButton(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.play, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'PLAY SINGLE PLAYER CHALLENGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModes(bool isDark, Color primary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final cards = [
          _GameModeData(
            title: 'Multiplayer Lobby',
            subtitle: 'Challenge friends in a room',
            icon: LucideIcons.swords,
            color: AppColors.coral,
            onTap: () {
              AudioService().playClick();
              Navigator.pushNamed(context, '/lobby');
            },
          ),
          _GameModeData(
            title: 'Create Room',
            subtitle: 'Host up to 10 players',
            icon: LucideIcons.plusCircle,
            color: AppColors.lavender,
            onTap: _createRoom,
          ),
          _GameModeData(
            title: 'Quick Solo Setup',
            subtitle: 'Customize rounds & category',
            icon: LucideIcons.sliders,
            color: AppColors.teal,
            onTap: _startPractice,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards.map((data) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: data == cards.last ? 0 : 12),
                  child: _buildModeCard(data, isDark),
                ),
              );
            }).toList(),
          );
        }

        return Column(
          children: cards.map((data) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildModeCard(data, isDark, horizontal: true),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildModeCard(_GameModeData data, bool isDark, {bool horizontal = false}) {
    final card = Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: AppTheme.accentCard(context, data.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(data.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppTheme.space16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: card,
    );
  }

  Widget _buildJoinRoomCard(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: AppTheme.gameCard(context),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _roomCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontSize: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ROOM CODE',
                hintStyle: TextStyle(
                  letterSpacing: 2,
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _NavButton(
            label: 'Profile',
            icon: LucideIcons.user,
            color: AppColors.teal,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NavButton(
            label: 'Friends',
            icon: LucideIcons.users,
            color: AppColors.rose,
            onTap: () => Navigator.pushNamed(context, '/friends'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NavButton(
            label: 'Settings',
            icon: LucideIcons.settings,
            color: AppColors.lavender,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
      ],
    );
  }
}

class _GameModeData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _GameModeData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      decoration: AppTheme.gameCard(context),
      child: InkWell(
        onTap: () {
          AudioService().playClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
