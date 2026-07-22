/// Extended User data model for DrawBattle progression & profile system.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int level;
  final int xp;
  final int coins;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int averageScore;
  final int currentWinStreak;
  final String favoriteBrush;
  final List<String> unlockedBrushes;
  final List<String> unlockedThemes;
  final List<String> badges;
  final List<String> friends;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 100,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageScore = 0,
    this.currentWinStreak = 0,
    this.favoriteBrush = 'pencil',
    this.unlockedBrushes = const ['pencil', 'paintbrush', 'marker', 'eraser'],
    this.unlockedThemes = const ['classic', 'sketchpad'],
    this.badges = const ['first_sketch'],
    this.friends = const [],
    required this.createdAt,
  });

  /// XP needed for next level
  int get xpForNextLevel => level * 250;

  /// Level completion progress percentage (0.0 - 1.0)
  double get levelProgress => (xp % 250) / 250.0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Player',
      photoUrl: json['photoUrl']?.toString(),
      level: _parseInt(json['level'], defaultVal: 1),
      xp: _parseInt(json['xp']),
      coins: _parseInt(json['coins'], defaultVal: 100),
      totalScore: _parseInt(json['totalScore']),
      gamesPlayed: _parseInt(json['gamesPlayed'] ?? json['totalGames']),
      gamesWon: _parseInt(json['gamesWon'] ?? json['totalWins']),
      averageScore: _parseInt(json['averageScore']),
      currentWinStreak: _parseInt(json['currentWinStreak'] ?? json['winStreak']),
      favoriteBrush: json['favoriteBrush']?.toString() ?? 'pencil',
      unlockedBrushes: _parseList(json['unlockedBrushes'], fallback: ['pencil', 'paintbrush', 'marker', 'eraser']),
      unlockedThemes: _parseList(json['unlockedThemes'], fallback: ['classic', 'sketchpad']),
      badges: _parseList(json['badges'], fallback: ['first_sketch']),
      friends: _parseList(json['friends']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'level': level,
    'xp': xp,
    'coins': coins,
    'totalScore': totalScore,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'averageScore': averageScore,
    'currentWinStreak': currentWinStreak,
    'favoriteBrush': favoriteBrush,
    'unlockedBrushes': unlockedBrushes,
    'unlockedThemes': unlockedThemes,
    'badges': badges,
    'friends': friends,
    'createdAt': createdAt.toIso8601String(),
  };

  double get winRate => gamesPlayed > 0 ? (gamesWon / gamesPlayed) : 0.0;
}

int _parseInt(dynamic value, {int defaultVal = 0}) {
  if (value == null) return defaultVal;
  if (value is num) return value.toInt();
  if (value is String) {
    return double.tryParse(value)?.toInt() ?? int.tryParse(value) ?? defaultVal;
  }
  return defaultVal;
}

List<String> _parseList(dynamic value, {List<String> fallback = const []}) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return List.from(fallback);
}
