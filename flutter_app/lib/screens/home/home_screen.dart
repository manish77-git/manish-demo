import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio_service.dart';
import '../../services/prompt_service.dart';
import '../../widgets/doodle_painter.dart';
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

  void _showPracticeConfigDialog() {
    AudioService().playClick();
    PromptCategory selectedCategory = PromptCategory.randomFun;
    PromptDifficulty selectedDifficulty = PromptDifficulty.medium;

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
                  DropdownButtonFormField<PromptCategory>(
                    dropdownColor: cardBg,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    ),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    items: PromptCategory.values.map((c) {
                      return DropdownMenuItem<PromptCategory>(
                        value: c,
                        child: Text('${c.emoji} ${c.label}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PromptDifficulty>(
                    dropdownColor: cardBg,
                    value: selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                    ),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    items: PromptDifficulty.values.map((d) {
                      return DropdownMenuItem<PromptDifficulty>(
                        value: d,
                        child: Text('${d.emoji} ${d.label}'),
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
    final socket = context.watch<SocketProvider>();
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
          // Handcrafted Doodle & Paper background
          Positioned.fill(
            child: CustomPaint(
              painter: DoodlePainter(primaryColor: primaryColor, isDark: isDark),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopAppBar(auth, socket, isDark, primaryColor, cardBg, borderColor, textColor, textMuted),

                // Dashboard Scroll Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mascot Hero Banner
                            _buildMascotHeroSection(auth, primaryColor, cardBg, borderColor, textColor, textMuted),
                            const SizedBox(height: AppTheme.space24),

                            // Main Game Mode Cards
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
                                  childAspectRatio: isWide ? 1.3 : 2.4,
                                  children: [
                                    _buildModeCard(
                                      title: '1v1 Duel',
                                      subtitle: 'Strict 2-player match',
                                      icon: LucideIcons.swords,
                                      color: AppTheme.accentCoral,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: () {
                                        AudioService().playClick();
                                        Navigator.pushNamed(context, '/lobby');
                                      },
                                    ),
                                    _buildModeCard(
                                      title: 'Create Room',
                                      subtitle: 'Host up to 10 players',
                                      icon: LucideIcons.plusCircle,
                                      color: primaryColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _createRoom,
                                    ),
                                    _buildModeCard(
                                      title: 'Practice vs AI',
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

                            // Join Code Input Card
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space16),
                              decoration: AppTheme.gameCardDecoration(
                                color: cardBg,
                                borderColor: borderColor,
                                shadowColor: primaryColor,
                                radius: AppTheme.radiusLarge,
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.keyRound, size: 20, color: primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _roomCodeController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0),
                                      decoration: const InputDecoration(
                                        hintText: 'ENTER 4-DIGIT ROOM CODE',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _joinRoom,
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                    child: const Text('Join Room'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space24),

                            // Navigation Buttons Toolbar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildNavButton(LucideIcons.user, 'Profile', () => Navigator.pushNamed(context, '/profile'), textColor),
                                _buildNavButton(LucideIcons.settings, 'Settings', () => Navigator.pushNamed(context, '/settings'), textColor),
                              ],
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

  Widget _buildTopAppBar(
    AuthProvider auth,
    SocketProvider socket,
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
          // Logo & Mascot Name
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: const Center(child: Icon(LucideIcons.paintbrush, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 10),
              Text(
                'DrawBattle',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: textColor),
              ),
            ],
          ),
          const Spacer(),

          // Real Online Players Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.accentLight, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${socket.isConnected ? 1 : 0} Online',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Theme Toggle Button
          IconButton(
            onPressed: () {
              AudioService().playClick();
              context.read<ThemeProvider>().toggleTheme();
            },
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotHeroSection(
    AuthProvider auth,
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
          AnimatedBuilder(
            animation: _mascotAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * _mascotAnim.value),
                child: child,
              );
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 2.5),
              ),
              child: const Icon(LucideIcons.sparkles, size: 38, color: Colors.white),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${auth.displayName}! 🎨',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sketch fast, duel friends in real-time, and test your creativity!',
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

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: () {
        AudioService().playClick();
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
