import 'level_assessment_data.dart';

enum LevelAssessmentStatus { completed, skipped, incomplete }

/// Assessment outcome. Kept apart from `LearningProfile.currentLevel`, which
/// remains the learner's own declaration.
class LevelAssessmentResult {
  const LevelAssessmentResult({
    required this.status,
    required this.selfReportedLevel,
    required this.recordedAt,
    this.assessedLevel,
    this.score = 0,
    this.confidence = 0,
    this.answeredCount = 0,
    this.skillScores = const <String, double>{},
  });

  factory LevelAssessmentResult.skipped({
    required String selfReportedLevel,
    DateTime? at,
  }) {
    return LevelAssessmentResult(
      status: LevelAssessmentStatus.skipped,
      selfReportedLevel: selfReportedLevel,
      recordedAt: (at ?? DateTime.now()).toUtc(),
    );
  }

  final LevelAssessmentStatus status;
  final String selfReportedLevel;
  final DateTime recordedAt;

  /// CEFR level estimated from answers; null unless enough were given.
  final String? assessedLevel;

  /// Difficulty-weighted accuracy, 0..100.
  final double score;

  /// Fit of the estimate to the answers, 0..1.
  final double confidence;
  final int answeredCount;

  /// Accuracy per skill name, 0..100.
  final Map<String, double> skillScores;

  bool get completed => status == LevelAssessmentStatus.completed;
  bool get skipped => status == LevelAssessmentStatus.skipped;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'selfReportedLevel': selfReportedLevel,
      'assessedLevel': assessedLevel,
      'score': score,
      'confidence': confidence,
      'answeredCount': answeredCount,
      'skillScores': skillScores,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  static LevelAssessmentResult? fromJson(Map<String, dynamic> json) {
    final LevelAssessmentStatus? status = LevelAssessmentStatus.values
        .where((LevelAssessmentStatus s) => s.name == json['status'])
        .firstOrNull;
    final DateTime? recordedAt = DateTime.tryParse(
      json['recordedAt'] as String? ?? '',
    );

    if (status == null || recordedAt == null) {
      return null;
    }

    final Object? assessed = json['assessedLevel'];
    final Object? rawSkills = json['skillScores'];

    return LevelAssessmentResult(
      status: status,
      selfReportedLevel: json['selfReportedLevel'] is String
          ? json['selfReportedLevel'] as String
          : '',
      assessedLevel: assessed is String && assessmentLevels.contains(assessed)
          ? assessed
          : null,
      score: (json['score'] as num?)?.toDouble().clamp(0.0, 100.0) ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0,
      answeredCount: (json['answeredCount'] as num?)?.toInt() ?? 0,
      skillScores: rawSkills is Map
          ? <String, double>{
              for (final MapEntry<dynamic, dynamic> entry in rawSkills.entries)
                if (entry.key is String && entry.value is num)
                  entry.key as String: (entry.value as num).toDouble(),
            }
          : const <String, double>{},
      recordedAt: recordedAt.toUtc(),
    );
  }
}
