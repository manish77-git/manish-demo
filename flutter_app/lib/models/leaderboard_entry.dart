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
      rank: (json['rank'] as num? ?? 0).toInt(),
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Anonymous',
      photoUrl: json['photoUrl']?.toString(),
      totalScore: (json['totalScore'] as num? ?? 0).toInt(),
      gamesPlayed: ((json['totalGames'] ?? json['gamesPlayed'] ?? json['gamesCount'] ?? 0) as num? ?? 0).toInt(),
      gamesWon: ((json['totalWins'] ?? json['gamesWon'] ?? json['winsCount'] ?? 0) as num? ?? 0).toInt(),
      averageScore: (json['averageScore'] as num? ?? 0).toInt(),
      bestScore: (json['bestScore'] as num? ?? 0).toInt(),
      currentWinStreak: ((json['currentWinStreak'] ?? json['winStreak'] ?? 0) as num? ?? 0).toInt(),
      lastPlayedAt: json['lastPlayedAt']?.toString() ?? json['lastPlayed']?.toString() ?? '',
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
