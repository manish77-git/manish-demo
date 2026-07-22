import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../services/audio_service.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _roomCodeController = TextEditingController();
  late AnimationController _mascotAnim;

  @override
  void initState() {
    super.initState();
    _mascotAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _mascotAnim.dispose();
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

  void _showDailyRewardModal() {
    AudioService().playClick();
    final progression = context.read<ProgressionProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: const BorderSide(color: AppTheme.borderLight, width: 2.5),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.gift, color: AppTheme.accentYellow, size: 28),
            SizedBox(width: 10),
            Text('Daily Reward!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, size: 48, color: AppTheme.accentCoral),
            const SizedBox(height: 12),
            const Text(
              'Claim your daily bonus:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.coins, color: AppTheme.accentYellow, size: 20),
                SizedBox(width: 6),
                Text('+100 Coins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 16),
                Icon(LucideIcons.zap, color: AppTheme.primaryLight, size: 20),
                SizedBox(width: 6),
                Text('+150 XP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final claimed = progression.claimDailyReward();
              Navigator.pop(context);
              if (claimed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Claimed +100 Coins and +150 XP!')),
                );
              }
            },
            child: const Text('Claim Reward'),
          ),
        ],
      ),
    );
  }

  void _showPracticeConfigDialog() {
    AudioService().playClick();
    String selectedCategory = 'all';
    String selectedDifficulty = 'all';

    final List<String> categories = [
      'all', 'Animals', 'Food', 'Nature', 'Objects', 'Vehicles',
      'Sports', 'Buildings', 'Fantasy', 'Space', 'Technology',
    ];

    final List<String> difficulties = ['all', 'easy', 'medium', 'hard'];

    final isDark = context.read<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                side: BorderSide(color: borderColor, width: 2.5),
              ),
              title: Text(
                'PRACTICE RULES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor: cardBg,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    ),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    items: categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c == 'all' ? '🎲 Random Category' : c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: cardBg,
                    value: selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    ),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    items: difficulties.map((d) {
                      return DropdownMenuItem<String>(
                        value: d,
                        child: Text(d == 'all' ? '⚡ Mixed Difficulty' : d.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedDifficulty = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textColor)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/drawing', arguments: {
                      'category': selectedCategory,
                      'difficulty': selectedDifficulty,
                      'isMultiplayer': false,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: const Text('Start Solo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progression = context.watch<ProgressionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      body: Stack(
        children: [
          // Sketchpad background
          Positioned.fill(
            child: CustomPaint(
              painter: SketchpadBackgroundPainter(gridColor: textColor, isDark: isDark),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Player Stats Header Bar
                _buildTopPlayerHeader(auth, progression, isDark, primaryColor, cardBg, borderColor, textColor, textMuted),

                // Scrollable Dashboard Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mascot Greeting Hero Section
                            _buildMascotHeroSection(auth, progression, primaryColor, cardBg, borderColor, textColor, textMuted),
                            const SizedBox(height: AppTheme.space24),

                            // Action Mode Grid
                            Text(
                              'GAME MODES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: textMuted,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space12),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 600;
                                return GridView.count(
                                  crossAxisCount: isWide ? 3 : 1,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: AppTheme.space16,
                                  mainAxisSpacing: AppTheme.space16,
                                  childAspectRatio: isWide ? 1.3 : 2.5,
                                  children: [
                                    // 1. Find 1v1 Duel
                                    _buildModeCard(
                                      title: 'Find 1v1 Duel',
                                      subtitle: 'Ranked matchmaking',
                                      icon: LucideIcons.swords,
                                      color: AppTheme.accentCoral,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: () {
                                        AudioService().playClick();
                                        Navigator.pushNamed(context, '/lobby');
                                      },
                                    ),

                                    // 2. Custom Room
                                    _buildModeCard(
                                      title: 'Create Room',
                                      subtitle: 'Host private duel',
                                      icon: LucideIcons.plusCircle,
                                      color: primaryColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _createRoom,
                                    ),

                                    // 3. Practice vs AI
                                    _buildModeCard(
                                      title: 'Solo Practice',
                                      subtitle: 'Draw & get AI score',
                                      icon: LucideIcons.bot,
                                      color: AppTheme.accentCyan,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _showPracticeConfigDialog,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: AppTheme.space24),

                            // Join Code Section & Daily Quests Card
                            Row(
                              children: [
                                // Join Code Input Card
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(AppTheme.space16),
                                    decoration: AppTheme.gameCardDecoration(
                                      color: cardBg,
                                      borderColor: borderColor,
                                      shadowColor: primaryColor,
                                      radius: AppTheme.radiusLarge,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(LucideIcons.keyRound, size: 18, color: primaryColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'JOIN WITH CODE',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _roomCodeController,
                                                textCapitalization: TextCapitalization.characters,
                                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0),
                                                decoration: const InputDecoration(
                                                  hintText: '4-DIGIT CODE',
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: _joinRoom,
                                              icon: const Icon(LucideIcons.arrowRight),
                                              style: IconButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space24),

                            // Bottom Toolbar Navigation Buttons
                            _buildBottomNavBar(cardBg, borderColor, textColor, primaryColor),
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

  Widget _buildTopPlayerHeader(
    AuthProvider auth,
    ProgressionProvider progression,
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 2.5)),
      ),
      child: Row(
        children: [
          // Avatar & Level Badge
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.user, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.displayName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            'LVL ${progression.level}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          height: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progression.levelProgress,
                              backgroundColor: borderColor.withOpacity(0.15),
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),

          // Coin Balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.coins, color: AppTheme.accentYellow, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${progression.coins}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Daily Reward Button
          IconButton(
            onPressed: _showDailyRewardModal,
            icon: Icon(
              LucideIcons.gift,
              color: progression.dailyRewardClaimed ? textMuted : AppTheme.accentCoral,
            ),
            tooltip: 'Daily Reward',
          ),

          // Theme Mode Toggle
          IconButton(
            onPressed: () {
              AudioService().playClick();
              context.read<ThemeProvider>().toggleTheme();
            },
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, color: textColor),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }

  Widget _buildMascotHeroSection(
    AuthProvider auth,
    ProgressionProvider progression,
    Color primaryColor,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
        radius: AppTheme.radiusLarge,
      ),
      child: Row(
        children: [
          // Bouncing Mascot Graphic
          AnimatedBuilder(
            animation: _mascotAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * _mascotAnim.value),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 2.5),
              ),
              child: const Icon(LucideIcons.paintbrush, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back, ${auth.displayName}! 🎨',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sketch fast, battle friends in real-time, and let AI rank your masterpieces!',
                  style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.gameCardDecoration(
        color: color.withOpacity(0.12),
        borderColor: borderColor,
        shadowColor: color,
        radius: AppTheme.radiusLarge,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const Spacer(),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(Color cardBg, Color borderColor, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
        radius: AppTheme.radiusLarge,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(LucideIcons.trophy, 'Leaderboard', () => Navigator.pushNamed(context, '/leaderboard'), textColor),
          _buildNavButton(LucideIcons.shoppingBag, 'Shop', () => Navigator.pushNamed(context, '/shop'), textColor),
          _buildNavButton(LucideIcons.user, 'Profile', () => Navigator.pushNamed(context, '/profile'), textColor),
          _buildNavButton(LucideIcons.settings, 'Settings', () => Navigator.pushNamed(context, '/settings'), textColor),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: () {
        AudioService().playClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
