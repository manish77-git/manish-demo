import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progression = context.watch<ProgressionProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    final winRate = progression.gamesPlayed > 0
        ? ((progression.wins / progression.gamesPlayed) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Profile'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            AudioService().playClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card: Avatar, Name, Title
                Container(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: AppTheme.gameCardDecoration(
                    color: cardBg,
                    borderColor: borderColor,
                    shadowColor: primaryColor,
                    radius: AppTheme.radiusLarge,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 3),
                        ),
                        child: const Icon(LucideIcons.user, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.displayName,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor, width: 1.5),
                              ),
                              child: Text(
                                progression.playerTitle,
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Pure Player Statistics Grid
                Text('MATCH STATISTICS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatTile('Matches Played', '${progression.gamesPlayed}', LucideIcons.gamepad2, primaryColor, cardBg, borderColor, textColor),
                    _buildStatTile('Duels Won', '${progression.wins}', LucideIcons.trophy, AppTheme.accentYellow, cardBg, borderColor, textColor),
                    _buildStatTile('Win Rate', '$winRate%', LucideIcons.percent, AppTheme.accentCyan, cardBg, borderColor, textColor),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // Pure Game Overview Banner
                const EmptyStateWidget(
                  title: 'Pure Drawing & Battle Fun!',
                  message: 'No paywalls, no coins, no fake leaderboards. Every match is 100% pure drawing enjoyment.',
                  icon: LucideIcons.paintbrush,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, Color cardBg, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.gameCardDecoration(
        color: color.withOpacity(0.1),
        borderColor: borderColor,
        shadowColor: color,
        radius: AppTheme.radiusMedium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }
}
