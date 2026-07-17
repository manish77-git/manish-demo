/// Drawing submission result data model from AI evaluation.
class DrawingResult {
  final int score;
  final String grade;
  final int confidence;
  final List<String> explanation;
  final List<String> labels;
  final Map<String, dynamic> breakdown;
  final bool allSubmitted;

  // New multi-criteria scores
  final int objectRecognitionScore;
  final int requiredFeaturesScore;
  final int compositionScore;
  final int creativityScore;
  final int strokeQualityScore;
  final List<String> strengths;
  final List<String> weaknesses;

  const DrawingResult({
    required this.score,
    required this.grade,
    required this.confidence,
    this.explanation = const [],
    this.labels = const [],
    this.breakdown = const {},
    this.allSubmitted = false,
    this.objectRecognitionScore = 0,
    this.requiredFeaturesScore = 0,
    this.compositionScore = 0,
    this.creativityScore = 0,
    this.strokeQualityScore = 0,
    this.strengths = const [],
    this.weaknesses = const [],
  });

  factory DrawingResult.fromJson(Map<String, dynamic> json) {
    return DrawingResult(
      score: json['score'] as int? ?? 0,
      grade: json['grade'] as String? ?? 'F',
      confidence: json['confidence'] as int? ?? 0,
      explanation: (json['explanation'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      labels: (json['labels'] as List<dynamic>?)
          ?.map((l) => l.toString())
          .toList() ?? [],
      breakdown: json['breakdown'] as Map<String, dynamic>? ?? {},
      allSubmitted: json['allSubmitted'] as bool? ?? false,
      objectRecognitionScore: json['objectRecognitionScore'] as int? ?? json['breakdown']?['objectRecognitionScore'] as int? ?? 0,
      requiredFeaturesScore: json['requiredFeaturesScore'] as int? ?? json['breakdown']?['requiredFeaturesScore'] as int? ?? 0,
      compositionScore: json['compositionScore'] as int? ?? json['breakdown']?['compositionScore'] as int? ?? 0,
      creativityScore: json['creativityScore'] as int? ?? json['breakdown']?['creativityScore'] as int? ?? 0,
      strokeQualityScore: json['strokeQualityScore'] as int? ?? json['breakdown']?['strokeQualityScore'] as int? ?? 0,
      strengths: (json['strengths'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  String get scoreGrade => grade;

  String get scoreEmoji {
    if (score >= 90) return '🌟';
    if (score >= 80) return '🎨';
    if (score >= 70) return '✨';
    if (score >= 60) return '👍';
    if (score >= 40) return '🤔';
    return '💪';
  }
}
