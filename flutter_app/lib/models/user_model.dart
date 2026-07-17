/// User data model for DrawBattle.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int averageScore;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageScore = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Anonymous',
      photoUrl: json['photoUrl'] as String?,
      totalScore: json['totalScore'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'totalScore': totalScore,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'averageScore': averageScore,
    'createdAt': createdAt.toIso8601String(),
  };

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0;
}
