import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/player_avatar.dart';

/// Global leaderboard screen.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static final List<Map<String, dynamic>> _mockLeaderboard = [
    {'name': 'PixelPicasso', 'avgScore': 94, 'games': 42, 'wins': 31},
    {'name': 'DrawLord99', 'avgScore': 91, 'games': 38, 'wins': 27},
    {'name': 'ArtMaster42', 'avgScore': 88, 'games': 55, 'wins': 29},
    {'name': 'SketchQueen', 'avgScore': 85, 'games': 33, 'wins': 19},
    {'name': 'InkNinja', 'avgScore': 82, 'games': 47, 'wins': 22},
    {'name': 'BrushBoss', 'avgScore': 79, 'games': 28, 'wins': 14},
    {'name': 'DoodlePro', 'avgScore': 76, 'games': 61, 'wins': 20},
    {'name': 'CanvasKing', 'avgScore': 73, 'games': 22, 'wins': 10},
    {'name': 'PaintWiz', 'avgScore': 71, 'games': 36, 'wins': 12},
    {'name': 'ArtRookie', 'avgScore': 68, 'games': 15, 'wins': 5},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.arrowLeft, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Leaderboard',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top 3 podium
            _buildPodium(primaryColor, textColor, textMuted),
            const SizedBox(height: 24),

            // Remaining rankings
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(top: BorderSide(color: borderColor, width: 1.5)),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: _mockLeaderboard.length - 3,
                  itemBuilder: (context, index) {
                    final player = _mockLeaderboard[index + 3];
                    return _buildRankTile(player, index + 4, cardBg, borderColor, primaryColor, textColor, textMuted);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(Color primaryColor, Color textColor, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (_mockLeaderboard.length > 1)
            _buildPodiumItem(_mockLeaderboard[1], 2, 80, primaryColor, textColor, textMuted),
          const SizedBox(width: 12),
          // 1st place
          if (_mockLeaderboard.isNotEmpty)
            _buildPodiumItem(_mockLeaderboard[0], 1, 100, primaryColor, textColor, textMuted),
          const SizedBox(width: 12),
          // 3rd place
          if (_mockLeaderboard.length > 2)
            _buildPodiumItem(_mockLeaderboard[2], 3, 65, primaryColor, textColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    Map<String, dynamic> player,
    int rank,
    double height,
    Color primaryColor,
    Color textColor,
    Color textMuted,
  ) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    final color = colors[rank] ?? primaryColor;

    return Expanded(
      child: Column(
        children: [
          PlayerAvatar(
            displayName: player['name'],
            rank: rank,
            size: rank == 1 ? 56 : 44,
          ),
          const SizedBox(height: 8),
          Text(
            player['name'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Avg: ${player['avgScore']}',
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                ['🥇', '🥈', '🥉'][rank - 1],
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTile(
    Map<String, dynamic> player,
    int rank,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
          ),
          PlayerAvatar(displayName: player['name'], size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player['games']} games · ${player['wins']} wins',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${player['avgScore']}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
