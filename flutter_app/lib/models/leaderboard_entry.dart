/// Leaderboard entry data model.
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int averageScore;
  final int bestScore;
  final int currentWinStreak;
  final String lastPlayedAt;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.totalScore,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.averageScore,
    this.bestScore = 0,
    this.currentWinStreak = 0,
    this.lastPlayedAt = '',
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Anonymous',
      photoUrl: json['photoUrl'] as String?,
      totalScore: json['totalScore'] as int? ?? 0,
      gamesPlayed: json['totalGames'] as int? ?? json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['totalWins'] as int? ?? json['gamesWon'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] as String? ?? json['lastPlayed'] as String? ?? '',
    );
  }

  int get wins => gamesWon;
  int get losses => gamesPlayed - gamesWon;
  int get winRate => gamesPlayed > 0 ? ((gamesWon / gamesPlayed) * 100).round() : 0;

  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
