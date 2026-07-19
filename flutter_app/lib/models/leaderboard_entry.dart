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
      rank: _parseInt(json['rank']),
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Anonymous',
      photoUrl: json['photoUrl']?.toString(),
      totalScore: _parseInt(json['totalScore']),
      gamesPlayed: _parseInt(json['totalGames'] ?? json['gamesPlayed'] ?? json['gamesCount']),
      gamesWon: _parseInt(json['totalWins'] ?? json['gamesWon'] ?? json['winsCount']),
      averageScore: _parseInt(json['averageScore']),
      bestScore: _parseInt(json['bestScore']),
      currentWinStreak: _parseInt(json['currentWinStreak'] ?? json['winStreak']),
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

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) {
    return double.tryParse(value)?.toInt() ?? int.tryParse(value) ?? 0;
  }
  return 0;
}
