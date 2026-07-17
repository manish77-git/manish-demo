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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final secColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final accentColor = isDark ? AppTheme.accentDark : AppTheme.accentLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Hero Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(LucideIcons.brush, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DrawBattle AI',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-Powered Drawing Battles',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Artist: ${auth.displayName}',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Core Actions Grid
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      // Solo Practice
                      _buildMenuCard(
                        title: 'Practice Solo',
                        subtitle: 'Draw at your own pace with real-time AI feedback',
                        icon: LucideIcons.palette,
                        color: primaryColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        onTap: () => Navigator.pushNamed(context, '/drawing'),
                      ),
                      // Create Room
                      _buildMenuCard(
                        title: 'Create Private Room',
                        subtitle: 'Host an invite-only drawing lobby with room codes',
                        icon: LucideIcons.key,
                        color: secColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        onTap: _createRoom,
                      ),
                      // Daily Challenge
                      _buildMenuCard(
                        title: 'Daily Challenge',
                        subtitle: 'Compete globally on today\'s curated drawing topic',
                        icon: LucideIcons.calendar,
                        color: accentColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Daily challenges unlock soon!')),
                          );
                        },
                      ),
                      // Leaderboard
                      _buildMenuCard(
                        title: 'Leaderboard',
                        subtitle: 'Browse top sketching ranks and active draw streaks',
                        icon: LucideIcons.trophy,
                        color: Colors.orangeAccent,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        onTap: () => Navigator.pushNamed(context, '/leaderboard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Join Room Card Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.users, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Join Lobby',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roomCodeController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter Room Code',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                onSubmitted: (_) => _joinRoom(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _joinRoom,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: Icon(LucideIcons.arrowRight, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Settings Launcher
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                        icon: Icon(LucideIcons.settings, size: 18, color: textMuted),
                        label: Text('Settings', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 24),
                      TextButton.icon(
                        onPressed: () {
                          context.read<AuthProvider>().signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: Icon(LucideIcons.logOut, size: 18, color: textMuted),
                        label: Text('Logout', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
