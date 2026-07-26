import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_service.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../widgets/mascot_painter.dart';

const List<String> _emojiAvatars = [
  '🎨', '🐱', '🐶', '🦊', '🦁', '🐼', '🦄', '🤖',
  '🧙‍♂️', '👑', '🚀', '⭐', '🔥', '🌈', '🍕', '🎸',
  '⚽', '🏆', '👾', '🎯', '🥑', '🌮', '🐉', '🦉',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    AudioService().playClick();
    final auth = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Avatar', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: AppTheme.space16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _emojiAvatars.length,
                itemBuilder: (ctx, idx) {
                  final emoji = _emojiAvatars[idx];
                  final isSelected = auth.avatar == emoji;
                  return GestureDetector(
                    onTap: () {
                      AudioService().playClick();
                      auth.updateProfile(avatar: emoji);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.coral.withValues(alpha: 0.2)
                            : (isDark ? AppColors.bgDark : AppColors.bgLight),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.coral : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.space16),
            ],
          ),
        );
      },
    );
  }

  void _saveName() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      context.read<AuthProvider>().updateProfile(displayName: text);
    }
    setState(() => _isEditingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

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
      body: RefreshIndicator(
        onRefresh: () => auth.refreshProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    decoration: AppTheme.gameCard(context),
                    child: Row(
                      children: [
                        // Avatar (tappable to edit)
                        GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Stack(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primary, AppColors.lavender],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(auth.avatar, style: const TextStyle(fontSize: 40)),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.coral,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.pencil, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isEditingName
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _nameController,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                                            decoration: const InputDecoration(isDense: true),
                                            onSubmitted: (_) => _saveName(),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.check, color: AppColors.mint),
                                          onPressed: _saveName,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            auth.displayName,
                                            style: Theme.of(context).textTheme.headlineLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(LucideIcons.pencil, size: 16, color: textMuted),
                                          onPressed: () => setState(() => _isEditingName = true),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                '@${auth.username}',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Personal Best Highlight Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: AppTheme.accentCard(context, AppColors.sunny),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.sunny,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.trophy, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PERSONAL HIGH SCORE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${auth.highestScore} pts',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primary),
                              ),
                            ],
                          ),
                        ),
                        const AnimatedInky(size: 50, expression: InkyExpression.excited),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Stats grid
                  Text(
                    'CAREER STATISTICS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textMuted, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatTile(label: 'Games Played', value: '${auth.gamesPlayed}', icon: LucideIcons.gamepad2, color: AppColors.teal),
                      _StatTile(label: 'Wins', value: '${auth.gamesWon}', icon: LucideIcons.crown, color: AppColors.sunny),
                      _StatTile(label: 'Win Rate', value: '${auth.winRate}%', icon: LucideIcons.percent, color: AppColors.lavender),
                      _StatTile(label: 'Avg Score', value: '${auth.averageScore}', icon: LucideIcons.target, color: AppColors.coral),
                      _StatTile(label: 'Total Drawings', value: '${auth.totalDrawings}', icon: LucideIcons.paintbrush, color: AppColors.skyBlue),
                      _StatTile(label: 'Friends', value: '${auth.friendsCount}', icon: LucideIcons.users, color: AppColors.rose),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Recent Match History
                  Text(
                    'RECENT MATCHES',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: textMuted, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (auth.matchHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: AppTheme.gameCard(context),
                      child: Center(
                        child: Text(
                          'No matches played yet. Start a Single Player Challenge or Multiplayer game!',
                          style: TextStyle(color: textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: AppTheme.gameCard(context),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: auth.matchHistory.length.clamp(0, 10),
                        separatorBuilder: (ctx, idx) => Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final match = auth.matchHistory[idx];
                          final isSingle = match['mode'] == 'single_player';
                          final score = match['totalScore'] as int? ?? 0;
                          final dateStr = match['date'] as String? ?? '';
                          String formattedDate = '';
                          if (dateStr.isNotEmpty) {
                            try {
                              final d = DateTime.parse(dateStr);
                              formattedDate = '${d.day}/${d.month}/${d.year}';
                            } catch (_) {}
                          }

                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isSingle ? AppColors.teal : AppColors.coral).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSingle ? LucideIcons.target : LucideIcons.swords,
                                color: isSingle ? AppColors.teal : AppColors.coral,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isSingle ? 'Single Player Challenge' : 'Multiplayer Duel',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                            ),
                            subtitle: Text(
                              '$formattedDate · ${match['roundsCount'] ?? 1} rounds',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            trailing: Text(
                              '$score pts',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: primary),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.accentCard(context, color, radius: AppTheme.radiusMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
