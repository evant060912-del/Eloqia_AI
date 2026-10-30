import '../content/content_helpers.dart';
import '../engine/lesson_engine.dart';
import '../models/lesson_models.dart';
import 'review_deck.dart';

/// Builds the daily review as a regular lesson, so it reuses the lesson
/// runner (feedback, XP, progress). Pure Dart (no Flutter import).
class ReviewSessions {
  ReviewSessions._();

  static const String idPrefix = 'review-';

  /// Grammar and vocabulary exercises stand on their own; reading and
  /// listening ones need their text or audio.
  static bool eligible(String exerciseId) {
    final LessonSkill? skill = LessonCatalog.exercise(exerciseId)?.lesson.skill;
    return skill == LessonSkill.grammar || skill == LessonSkill.vocabulary;
  }

  static bool isReview(Lesson lesson) => lesson.id.startsWith(idPrefix);

  /// Due exercises that still exist in the catalog, at most one session.
  static List<Exercise> dueExercises(ReviewDeck deck, DateTime now) =>
      <Exercise>[
        for (final ReviewItem item in deck.due(now))
          if (LessonCatalog.exercise(item.exerciseId) != null)
            LessonCatalog.exercise(item.exerciseId)!.exercise,
      ].take(ReviewDeck.sessionSize).toList(growable: false);

  /// Today's review lesson, or null when nothing is due.
  static Lesson? build(ReviewDeck deck, DateTime now) {
    final List<Exercise> exercises = dueExercises(deck, now);
    if (exercises.isEmpty) return null;
    final Map<LessonSkill, int> bySkill = <LessonSkill, int>{};
    int levels = 0;
    final Set<String> topics = <String>{};
    for (final Exercise e in exercises) {
      final Lesson lesson = LessonCatalog.exercise(e.id)!.lesson;
      bySkill[lesson.skill] = (bySkill[lesson.skill] ?? 0) + 1;
      levels += lesson.levelIndex;
      topics.add(e.topic);
    }
    final LessonSkill skill = bySkill.entries
        .reduce(
          (MapEntry<LessonSkill, int> a, MapEntry<LessonSkill, int> b) =>
              b.value > a.value ? b : a,
        )
        .key;
    final DateTime d = now.toLocal();
    final String day =
        '${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
    return Lesson(
      id: '$idPrefix$day',
      title: 'Spaced review',
      description: 'Exercises you missed before, at the right moment.',
      skill: skill,
      levelIndex: (levels / exercises.length).round(),
      topic: 'review',
      estimatedMinutes: (exercises.length / 2).ceil().clamp(2, 6),
      xpReward: 10 + 2 * exercises.length,
      objective: 'Answer each one at the first try to move it further away.',
      tags: const <String>['review'],
      activities: <LessonActivity>[
        introActivity(
          'Spaced review',
          <String>[
            'These ${exercises.length} exercises are ones you missed earlier. '
                'Seeing them again just before you forget makes them stick.',
            'A correct first try sends an exercise further away (1, 3, 7, 14, '
                'then 30 days). A mistake brings it back tomorrow.',
          ],
          <String>['Topics: ${topics.join(', ')}.'],
        ),
        practiceActivity(exercises),
      ],
    );
  }
}
