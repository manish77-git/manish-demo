import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio_service.dart';
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
                // Header Card: Avatar, Name, Level, XP
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentYellow,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor, width: 1.5),
                                  ),
                                  child: Text(
                                    'LEVEL ${progression.level}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'XP ${progression.xp} / ${progression.xpForNextLevel}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                                      ),
                                      const SizedBox(height: 3),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progression.levelProgress,
                                          backgroundColor: borderColor.withOpacity(0.15),
                                          color: primaryColor,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Player Stats Grid
                Text('STATISTICS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatTile('Coins', '${progression.coins}', LucideIcons.coins, AppTheme.accentYellow, cardBg, borderColor, textColor),
                    _buildStatTile('Level', '${progression.level}', LucideIcons.zap, primaryColor, cardBg, borderColor, textColor),
                    _buildStatTile('Unlocks', '${progression.unlockedBrushes.length} Brushes', LucideIcons.brush, AppTheme.accentCyan, cardBg, borderColor, textColor),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // Badges Section
                Text('ACHIEVEMENT BADGES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: AppTheme.gameCardDecoration(
                    color: cardBg,
                    borderColor: borderColor,
                    shadowColor: primaryColor,
                    radius: AppTheme.radiusLarge,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildBadgeChip('🎨 First Sketch', 'Created first drawing', true, primaryColor, borderColor),
                      _buildBadgeChip('⚡ Speed Demon', 'Submitted in < 30s', true, AppTheme.accentYellow, borderColor),
                      _buildBadgeChip('🏆 Match Winner', 'Won a 1v1 duel', true, AppTheme.accentCoral, borderColor),
                      _buildBadgeChip('🌟 Master Artist', 'Scored 90+ points', false, textMuted, borderColor),
                    ],
                  ),
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
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String title, String desc, bool isUnlocked, Color color, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? borderColor : Colors.grey.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUnlocked ? LucideIcons.award : LucideIcons.lock, size: 16, color: isUnlocked ? color : Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isUnlocked ? Colors.black : Colors.grey)),
              Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
