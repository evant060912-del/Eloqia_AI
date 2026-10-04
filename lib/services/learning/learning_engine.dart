import '../../models/learning_profile.dart';
import '../../models/learning_session.dart';

class LearningRecommendation {
  const LearningRecommendation({
    required this.activity,
    required this.title,
    required this.reason,
    required this.targetLevel,
    required this.minutes,
  });

  final LearningActivityType activity;
  final String title;
  final String reason;
  final String targetLevel;
  final int minutes;
}

/// Deterministic recommendation rules for learning activities currently
/// implemented in the app. No model or remote inference is involved.
class LearningEngine {
  LearningEngine._();

  static const int guidedWritingCompletionXp = 10;

  static LearningRecommendation recommend({
    required LearningProfile profile,
    required List<LearningSession> sessions,
  }) {
    final String level = profile.currentLevel.trim().toUpperCase();
    final bool hasWritingGap = profile.difficulties.any((String difficulty) {
      final String normalized = difficulty.toLowerCase();
      return normalized.contains('writ') || normalized.contains('express');
    });
    final int completedWriting = sessions
        .where(
          (LearningSession session) =>
              session.completed &&
              session.activityType == LearningActivityType.writing,
        )
        .length;

    final String reason;
    if (hasWritingGap) {
      reason = 'Writing is listed among your declared learning challenges.';
    } else if (completedWriting == 0) {
      reason =
          'A short writing exercise creates a useful first practice record.';
    } else if (profile.primaryGoal.trim().isNotEmpty) {
      reason = 'Build toward your goal: ${profile.primaryGoal.trim()}.';
    } else {
      reason = 'Continue with the guided writing practice currently available.';
    }

    return LearningRecommendation(
      activity: LearningActivityType.writing,
      title: 'Mia guided writing practice',
      reason: reason,
      targetLevel: level,
      minutes: 5,
    );
  }
}
