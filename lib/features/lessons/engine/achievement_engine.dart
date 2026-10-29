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
    Achievement(
      'perfect-session',
      'Perfect Session',
      'Answer every question correctly on the first try.',
    ),
    Achievement(
      'combo-5',
      'Five in a Row',
      'Reach a combo of 5 in one lesson.',
    ),
    Achievement(
      'vocab-builder',
      'Vocabulary Builder',
      'Complete three vocabulary lessons.',
    ),
    Achievement('streak-7', '7-Day Streak', 'Learn on seven days in a row.'),
    Achievement(
      'first-conversation',
      'First Conversation',
      'Complete a conversation with Mia.',
    ),
    Achievement(
      'role-player',
      'Role Player',
      'Complete three role-plays with Mia.',
    ),
    Achievement('writer', 'Writer', 'Get feedback from Mia on your writing.'),
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
              .where(
                (LearningSession s) =>
                    s.activityType == LearningActivityType.vocabulary,
              )
              .length >=
          3)
        'vocab-builder',
      if (progress.currentStreak >= 7) 'streak-7',
      ..._miaAchievements(sessions),
    };
  }

  static Set<String> _miaAchievements(List<LearningSession> sessions) {
    final List<String> modes = <String>[
      for (final LearningSession s in sessions)
        if (s.completed && s.metadata['miaMode'] is String)
          s.metadata['miaMode'] as String,
    ];
    return <String>{
      if (modes.isNotEmpty) 'first-conversation',
      if (modes.where((String m) => m == 'roleplay').length >= 3) 'role-player',
      if (modes.contains('writing')) 'writer',
    };
  }
}
