import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  void _createRoom() {
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
    String selectedCategory = 'all';
    String selectedDifficulty = 'all';

    final List<String> categories = [
      'all', 'Animals', 'Food', 'Nature', 'Objects', 'Vehicles',
      'Sports', 'Buildings', 'Fantasy', 'Space', 'Technology',
      'Jobs', 'Holidays', 'Emotions', 'Mythology', 'Abstract Concepts'
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
                'SELECT RULES',
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
                        child: Text(c == 'all' ? 'Mixed Categories' : c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCategory = val;
                        });
                      }
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
                        child: Text(d == 'all' ? 'Mixed Difficulties' : d.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedDifficulty = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/drawing',
                      arguments: {
                        'isMultiplayer': false,
                        'category': selectedCategory,
                        'difficulty': selectedDifficulty,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: const Text('Start Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            top: -50,
            right: 40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentYellow.withOpacity(0.06),
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Navigation Bar
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: AppTheme.gameCardDecoration(
                              color: primaryColor,
                              borderColor: borderColor,
                              shadowColor: borderColor,
                              radius: AppTheme.radiusSmall,
                            ),
                            child: const Icon(LucideIcons.brush, size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DrawBattle',
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                Text(
                                  'Artist: ${auth.displayName}',
                                  style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                            icon: Icon(LucideIcons.settings, size: 18, color: textColor),
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                side: BorderSide(color: borderColor, width: 2.5),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space48),

                      // Game Hero Callout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'FREE DOODLE AI GAME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                              children: [
                                const TextSpan(text: 'Sketch fast. '),
                                const TextSpan(text: 'Duel friends.\n'),
                                TextSpan(
                                  text: 'Let AI judge.',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Text(
                            'The free multiplayer drawing duel. No downloads, no accounts. Create a room instantly, sketch with friends, and let AI evaluate the winner.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space48),

                      // Action Grid
                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.5 : 3.0,
                        crossAxisSpacing: AppTheme.space16,
                        mainAxisSpacing: AppTheme.space16,
                        children: [
                          _buildMenuCard(
                            title: 'Practice Solo',
                            subtitle: 'Draw at your own pace with AI feedback',
                            icon: LucideIcons.palette,
                            color: primaryColor,
                            statusText: 'AI FEEDBACK',
                            statusColor: AppTheme.accentLight,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            shadowColor: primaryColor,
                            textMuted: textMuted,
                            onTap: _showPracticeConfigDialog,
                          ),
                          _buildMenuCard(
                            title: 'Create Room',
                            subtitle: 'Host a drawing lobby with codes',
                            icon: LucideIcons.plus,
                            color: AppTheme.accentCyan,
                            statusText: 'MULTIPLAYER',
                            statusColor: AppTheme.accentCyan,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            shadowColor: AppTheme.accentCyan,
                            textMuted: textMuted,
                            onTap: _createRoom,
                          ),
                          _buildMenuCard(
                            title: 'Daily Challenge',
                            subtitle: 'Compete globally on today\'s prompt',
                            icon: LucideIcons.calendar,
                            color: AppTheme.accentCoral,
                            statusText: 'DAILY COMING SOON',
                            statusColor: AppTheme.accentCoral,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            shadowColor: AppTheme.accentCoral,
                            textMuted: textMuted,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Daily challenges are coming soon!')),
                              );
                            },
                          ),
                          _buildMenuCard(
                            title: 'Leaderboard',
                            subtitle: 'See top ranks and draw streaks',
                            icon: LucideIcons.trophy,
                            color: AppTheme.accentYellow,
                            statusText: 'GLOBAL RANKS',
                            statusColor: AppTheme.accentYellow,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            shadowColor: AppTheme.accentYellow,
                            textMuted: textMuted,
                            onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Join Room Box
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space24),
                        decoration: AppTheme.gameCardDecoration(
                          color: cardBg,
                          borderColor: borderColor,
                          shadowColor: primaryColor,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.users, size: 18, color: primaryColor),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  'Join with Code',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _roomCodeController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter room code',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    onSubmitted: (_) => _joinRoom(),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Container(
                                  decoration: AppTheme.gameCardDecoration(
                                    color: primaryColor,
                                    borderColor: borderColor,
                                    shadowColor: borderColor,
                                    radius: AppTheme.radiusSmall,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _joinRoom,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                      ),
                                    ),
                                    child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Sign out button
                      const SizedBox(height: AppTheme.space48),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            context.read<AuthProvider>().signOut();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: Icon(LucideIcons.logOut, size: 16, color: textMuted),
                          label: Text(
                            'Sign out',
                            style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String statusText,
    required Color statusColor,
    required Color cardBg,
    required Color borderColor,
    required Color shadowColor,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: AppTheme.gameCardDecoration(
            color: cardBg,
            borderColor: borderColor,
            shadowColor: shadowColor,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppTheme.space16),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(LucideIcons.chevronRight, size: 16, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
