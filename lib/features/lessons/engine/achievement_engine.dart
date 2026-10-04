import '../../../models/learning_session.dart';
import '../../../models/progress.dart';

class Achievement {
  const Achievement(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

/// Achievements are derived from recorded sessions and progress only.
class AchievementEngine {
  AchievementEngine._();

  static const List<Achievement> all = <Achievement>[
    Achievement('first-lesson', 'First Lesson', 'Complete your first lesson.'),
    Achievement('perfect-session', 'Perfect Session', 'Answer every question correctly on the first try.'),
    Achievement('combo-5', 'Five in a Row', 'Reach a combo of 5 in one lesson.'),
    Achievement('vocab-builder', 'Vocabulary Builder', 'Complete three vocabulary lessons.'),
    Achievement('streak-7', '7-Day Streak', 'Learn on seven days in a row.'),
  ];

  static Set<String> unlocked({
    required List<LearningSession> sessions,
    required Progress progress,
  }) {
    final List<LearningSession> lessons = sessions
        .where(
          (LearningSession s) =>
              s.completed && s.metadata['lessonId'] is String,
        )
        .toList();
    return <String>{
      if (lessons.isNotEmpty) 'first-lesson',
      if (lessons.any((LearningSession s) => s.metadata['perfect'] == true))
        'perfect-session',
      if (lessons.any(
        (LearningSession s) =>
            s.metadata['maxCombo'] is num &&
            (s.metadata['maxCombo'] as num) >= 5,
      ))
        'combo-5',
      if (lessons
              .where((LearningSession s) => s.activityType == LearningActivityType.vocabulary)
              .length >=
          3)
        'vocab-builder',
      if (progress.currentStreak >= 7) 'streak-7',
    };
  }
}
