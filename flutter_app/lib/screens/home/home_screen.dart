import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio_service.dart';
import '../../services/prompt_service.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../widgets/doodle_painter.dart';
import '../../widgets/mascot_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _roomCodeController = TextEditingController();
  late AnimationController _entranceController;
  late List<Animation<double>> _staggerAnimations;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Create staggered animations for each element
    _staggerAnimations = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final socket = context.read<SocketProvider>();
      if (auth.uid.isNotEmpty) {
        socket.registerUserOnline(auth.uid);
      }

      // Listen for game invites from friends
      socket.onFriendInviteReceived = (fromUid, hostName, roomCode) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎮 $hostName invited you to room $roomCode!'),
            action: SnackBarAction(
              label: 'JOIN',
              onPressed: () {
                socket.joinRoom(roomCode: roomCode, uid: auth.uid, displayName: auth.displayName);
                Navigator.pushNamed(context, '/lobby', arguments: roomCode);
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      };
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _createRoom() {
    AudioService().playClick();
    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();

    void onUpdate() {
      if (socket.roomCode != null && socket.roomCode!.isNotEmpty) {
        socket.removeListener(onUpdate);
        Navigator.pushNamed(context, '/lobby', arguments: socket.roomCode);
      }
    }

    socket.addListener(onUpdate);
    socket.createRoom(uid: auth.uid, displayName: auth.displayName);
  }

  void _joinRoom() {
    AudioService().playClick();
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();

    socket.joinRoom(
      roomCode: code,
      uid: auth.uid,
      displayName: auth.displayName,
    );
    Navigator.pushNamed(context, '/lobby', arguments: code);
  }

  void _startPractice() {
    AudioService().playClick();
    PromptCategory selectedCategory = PromptCategory.randomFun;
    PromptDifficulty selectedDifficulty = PromptDifficulty.medium;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Text('Quick Solo Game', style: Theme.of(ctx).textTheme.headlineLarge),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Draw solo and get AI feedback',
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
                          'difficulty': selectedDifficulty.label,
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
                          Icon(LucideIcons.paintbrush, size: 18),
                          SizedBox(width: 8),
                          Text('Start Drawing'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                ],
              ),
            );
          },
        );
      },
    );
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
      child: Row(
        children: [
          // Logo with connection indicator
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.coral, AppColors.rose],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(LucideIcons.paintbrush, color: Colors.white, size: 18)),
                Positioned(
                  right: 2, top: 2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: socket.isConnected ? AppColors.mint : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'DrawBattle',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
          const Spacer(),

          // Theme toggle
          IconButton(
            onPressed: () {
              AudioService().playClick();
              context.read<ThemeProvider>().toggleTheme();
            },
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              size: 20,
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
      onTap: _startPractice,
      child: Container(
        height: 64,
        decoration: AppTheme.gradientButton(),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.play, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'PLAY QUICK GAME',
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
            title: 'Single Player Challenge',
            subtitle: 'Beat your high score',
            icon: LucideIcons.target,
            color: AppColors.teal,
            onTap: () {
              AudioService().playClick();
              Navigator.pushNamed(context, '/single_player');
            },
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
    if (horizontal) {
      return GestureDetector(
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: AppTheme.accentCard(context, data.color),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text(data.subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: data.color, size: 20),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: AppTheme.accentCard(context, data.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(data.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 2),
            Text(data.subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRoomCard(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: AppTheme.gameCard(context),
      child: Row(
        children: [
          Icon(LucideIcons.keyRound, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _roomCodeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'ROOM CODE',
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: AppTheme.gradientButton(
              startColor: AppColors.lavender,
              endColor: AppColors.skyBlue,
              radius: AppTheme.radiusSmall,
            ),
            child: ElevatedButton(
              onPressed: _joinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
              child: const Text('Join'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(bool isDark) {
    final color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(LucideIcons.user, 'Profile', () => Navigator.pushNamed(context, '/profile'), color),
        _buildNavItem(LucideIcons.users, 'Friends', () => Navigator.pushNamed(context, '/friends'), color),
        _buildNavItem(LucideIcons.settings, 'Settings', () => Navigator.pushNamed(context, '/settings'), color),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: () {
        AudioService().playClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _GameModeData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameModeData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
