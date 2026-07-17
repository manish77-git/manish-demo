/// Game session data model.
class GameSession {
  final String id;
  final String status; // waiting, drawing, evaluating, results
  final String? prompt;
  final String? promptDifficulty;
  final String hostId;
  final List<GamePlayer> players;
  final int maxPlayers;
  final int drawingTimeSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, DrawingSubmission>? submissions;

  const GameSession({
    required this.id,
    required this.status,
    this.prompt,
    this.promptDifficulty,
    required this.hostId,
    required this.players,
    this.maxPlayers = 6,
    this.drawingTimeSeconds = 60,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.submissions,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      status: json['status'] as String,
      prompt: json['prompt'] as String?,
      promptDifficulty: json['promptDifficulty'] as String?,
      hostId: json['hostId'] as String,
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      maxPlayers: json['maxPlayers'] as int? ?? 6,
      drawingTimeSeconds: json['drawingTimeSeconds'] as int? ?? 60,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      submissions: json['submissions'] != null
          ? (json['submissions'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, DrawingSubmission.fromJson(v as Map<String, dynamic>)),
            )
          : null,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isDrawing => status == 'drawing';
  bool get isEvaluating => status == 'evaluating';
  bool get isResults => status == 'results';
  bool get isFull => players.length >= maxPlayers;
  int get playerCount => players.length;
}

/// A player in a game session.
class GamePlayer {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String status;
  final DateTime joinedAt;

  const GamePlayer({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.status,
    required this.joinedAt,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Anonymous',
      photoUrl: json['photoUrl'] as String?,
      status: json['status'] as String? ?? 'waiting',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isReady => status == 'ready';
  bool get isDrawing => status == 'drawing';
  bool get hasSubmitted => status == 'submitted';
}

/// A drawing submission within a game session.
class DrawingSubmission {
  final String? drawingUrl;
  final int? score;
  final List<String> aiLabels;
  final DateTime? submittedAt;
  final DateTime? evaluatedAt;

  const DrawingSubmission({
    this.drawingUrl,
    this.score,
    this.aiLabels = const [],
    this.submittedAt,
    this.evaluatedAt,
  });

  factory DrawingSubmission.fromJson(Map<String, dynamic> json) {
    return DrawingSubmission(
      drawingUrl: json['drawingUrl'] as String?,
      score: json['score'] as int?,
      aiLabels: (json['aiLabels'] as List<dynamic>?)
          ?.map((l) => l.toString())
          .toList() ?? [],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.parse(json['evaluatedAt'] as String)
          : null,
    );
  }
}
