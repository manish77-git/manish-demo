import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/player_avatar.dart';
import '../../services/api_service.dart';

/// Global leaderboard screen querying real database entries.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final service = LeaderboardService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => auth.idToken,
      );

      final list = await service.getLeaderboard(limit: 50);
      setState(() {
        _entries = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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
      body: Stack(
        children: [
          // Sketchpad background grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: SketchpadBackgroundPainter(
                gridColor: textColor,
                isDark: isDark,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.space16),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.arrowLeft, color: textColor),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: 2.5),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Leaderboard',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Main body wrapper
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.alertTriangle, color: AppTheme.accentCoral, size: 36),
                                  const SizedBox(height: AppTheme.space8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppTheme.space16),
                                  ElevatedButton(
                                    onPressed: _fetchLeaderboard,
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            )
                          : _entries.isEmpty
                              ? _buildEmptyState(cardBg, borderColor, textColor)
                              : Column(
                                  children: [
                                    // Top 3 Podium
                                    _buildPodium(primaryColor, textColor, textMuted),
                                    const SizedBox(height: AppTheme.space24),

                                    // Lower Rankings
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                          border: Border(top: BorderSide(color: borderColor, width: 2.5)),
                                        ),
                                        child: RefreshIndicator(
                                          onRefresh: _fetchLeaderboard,
                                          color: primaryColor,
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                            itemCount: _entries.length > 3 ? _entries.length - 3 : 0,
                                            itemBuilder: (context, index) {
                                              final player = _entries[index + 3];
                                              return _buildRankTile(
                                                player,
                                                index + 4,
                                                cardBg,
                                                borderColor,
                                                primaryColor,
                                                textColor,
                                                textMuted,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color cardBg, Color borderColor, Color textColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
        padding: const EdgeInsets.all(AppTheme.space32),
        decoration: AppTheme.gameCardDecoration(
          color: cardBg,
          borderColor: borderColor,
          shadowColor: AppTheme.accentYellow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users, size: 48, color: AppTheme.accentYellow),
            const SizedBox(height: AppTheme.space16),
            Text(
              'No players yet. Be the first to play!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
              textAlign: TextAlign.center,
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
          if (_entries.length > 1)
            _buildPodiumItem(_entries[1], 2, 80, primaryColor, textColor, textMuted),
          const SizedBox(width: 12),
          // 1st place
          if (_entries.isNotEmpty)
            _buildPodiumItem(_entries[0], 1, 100, primaryColor, textColor, textMuted),
          const SizedBox(width: 12),
          // 3rd place
          if (_entries.length > 2)
            _buildPodiumItem(_entries[2], 3, 65, primaryColor, textColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardEntry player,
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
            displayName: player.displayName,
            rank: rank,
            size: rank == 1 ? 56 : 44,
          ),
          const SizedBox(height: 8),
          Text(
            player.displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Avg: ${player.averageScore}',
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height,
            decoration: AppTheme.gameCardDecoration(
              color: color.withOpacity(0.08),
              borderColor: color,
              shadowColor: color.withOpacity(0.2),
              radius: AppTheme.radiusMedium,
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
    LeaderboardEntry player,
    int rank,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textColor,
    Color textMuted,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor.withOpacity(0.15),
        radius: AppTheme.radiusMedium,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: textMuted,
              ),
            ),
          ),
          PlayerAvatar(displayName: player.displayName, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.gamesPlayed} games · ${player.wins}W - ${player.losses}L · WR: ${player.winRate}% · Streak: ${player.currentWinStreak}🔥 · Best: ${player.bestScore}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Text(
              '${player.averageScore}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
