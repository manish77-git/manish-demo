import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Player avatar widget with optional rank badge.
class PlayerAvatar extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final int? rank;
  final double size;

  const PlayerAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.rank,
    this.size = 48,
  });

  Color get _avatarColor {
    // Generate consistent color from display name
    final hash = displayName.hashCode;
    final colors = [
      AppTheme.accentPrimary,
      AppTheme.accentSecondary,
      AppTheme.accentWarm,
      AppTheme.accentGold,
      const Color(0xFF9B59B6),
      const Color(0xFF45B7D1),
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _avatarColor,
                _avatarColor.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _avatarColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitial(),
                  ),
                )
              : _buildInitial(),
        ),
        // Rank badge
        if (rank != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rankColor,
                border: Border.all(color: AppTheme.surfaceLight, width: 2),
              ),
              child: Center(
                child: Text(
                  rank! <= 3 ? _rankEmoji : '$rank',
                  style: TextStyle(
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.surfaceLight;
    }
  }

  String get _rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }
}
