import '../../../models/learning_memory.dart';
import '../../../models/learning_profile.dart';
import '../../../models/learning_session.dart';
import '../../../models/progress.dart';
import '../../../services/learning/personal_plan.dart';
import '../../onboarding/assessment/level_assessment_data.dart';
import '../../onboarding/assessment/level_assessment_result.dart';
import '../content/grammar_content.dart';
import '../content/grammar_content_more.dart';
import '../content/listening_content.dart';
import '../content/listening_content_more.dart';
import '../content/reading_content.dart';
import '../content/reading_content_more.dart';
import '../content/vocabulary_content.dart';
import '../content/vocabulary_content_more.dart';
import '../models/lesson_models.dart';

class LessonCatalog {
  LessonCatalog._();

  static final List<Lesson> all = List<Lesson>.unmodifiable(<Lesson>[
    ...grammarLessons,
    ...moreGrammarLessons,
    ...vocabularyLessons,
    ...moreVocabularyLessons,
    ...readingLessons,
    ...moreReadingLessons,
    ...listeningLessons,
    ...moreListeningLessons,
  ]);

  static final Map<String, ({Exercise exercise, Lesson lesson})> _exercises =
      <String, ({Exercise exercise, Lesson lesson})>{
        for (final Lesson lesson in all)
          for (final Exercise exercise in lesson.allExercises)
            exercise.id: (exercise: exercise, lesson: lesson),
      };

  /// An exercise and its lesson, by exercise id (spaced review).
  static ({Exercise exercise, Lesson lesson})? exercise(String id) =>
      _exercises[id];

  static List<Lesson> forSkill(LessonSkill skill) =>
      all.where((Lesson l) => l.skill == skill).toList();

  static Lesson? byId(String id) {
    for (final Lesson lesson in all) {
      if (lesson.id == id) {
        return lesson;
      }
    }
    return null;
  }
}

class LessonChoice {
  const LessonChoice({required this.lesson, required this.reason});

  final Lesson lesson;
  final String reason;
}

LessonSkill? lessonSkillFromActivity(LearningActivityType type) =>
    switch (type) {
      LearningActivityType.grammar => LessonSkill.grammar,
      LearningActivityType.vocabulary => LessonSkill.vocabulary,
      LearningActivityType.reading => LessonSkill.reading,
      LearningActivityType.listening => LessonSkill.listening,
      _ => null,
    };

/// Chooses lessons from real learner data: level, weaknesses, interests and
/// completed history. It never invents a reason it cannot support.
class LessonEngine {
  LessonEngine._();

  static ({int index, String source}) effectiveLevel({
    required LearningProfile profile,
    LevelAssessmentResult? assessment,
  }) {
    final String? assessed = assessment?.completed == true
        ? assessment!.assessedLevel
        : null;
    if (assessed != null) {
      return (
        index: assessmentLevels.indexOf(assessed),
        source: 'your placement check ($assessed)',
      );
    }
    final String declared = profile.currentLevel.trim().toUpperCase();
    final int declaredIndex = assessmentLevels.indexOf(declared);
    if (declaredIndex >= 0) {
      return (index: declaredIndex, source: 'your declared $declared level');
    }
    return (index: 2, source: 'a default B1 start (no level set yet)');
  }

  static Set<String> completedLessonIds(List<LearningSession> sessions) =>
      <String>{
        for (final LearningSession s in sessions)
          if (s.completed && s.metadata['lessonId'] is String)
            s.metadata['lessonId'] as String,
      };

  static Set<String> weakTopics(List<LearningMemory> memories) => <String>{
    for (final LearningMemory m in memories)
      if (m.isUsable &&
          m.type == LearningMemoryType.weakness &&
          m.metadata['lessonTopic'] is String)
        m.metadata['lessonTopic'] as String,
  };

  static LessonChoice select({
    required LessonSkill skill,
    required LearningProfile profile,
    LevelAssessmentResult? assessment,
    List<LearningSession> sessions = const <LearningSession>[],
    List<LearningMemory> memories = const <LearningMemory>[],
  }) {
    final level = effectiveLevel(profile: profile, assessment: assessment);
    final Set<String> done = completedLessonIds(sessions);
    final Set<String> weak = weakTopics(memories);
    final Set<String> interests = <String>{
      for (final String i in profile.interests) i.toLowerCase(),
      profile.primaryGoal.toLowerCase(),
      ...PersonalPlan.from(profile).lessonTags,
    };

    Lesson? best;
    double bestScore = -1e9;
    for (final Lesson lesson in LessonCatalog.forSkill(skill)) {
      double score = -(lesson.levelIndex - level.index).abs() * 10.0;
      score += done.contains(lesson.id) ? -6 : 4;
      if (weak.contains(lesson.topic)) {
        score += 8;
      }
      score += lesson.tags.where(interests.contains).length * 2;
      if (score > bestScore) {
        best = lesson;
        bestScore = score;
      }
    }

    final Lesson chosen = best!;
    final List<String> reasons = <String>[
      'Matched to ${level.source}.',
      if (weak.contains(chosen.topic))
        'You missed ${chosen.topic} earlier, so this targets it.',
      if (chosen.tags.any(interests.contains))
        'It fits your stated interests or goal.',
      if (done.contains(chosen.id))
        'You completed this before; this is a review.',
    ];
    return LessonChoice(lesson: chosen, reason: reasons.join(' '));
  }

  static LessonChoice recommend({
    required LearningProfile profile,
    LevelAssessmentResult? assessment,
    List<LearningSession> sessions = const <LearningSession>[],
    List<LearningMemory> memories = const <LearningMemory>[],
    Progress? progress,
  }) {
    final Map<LessonSkill, int> practiced = <LessonSkill, int>{
      for (final LessonSkill s in LessonSkill.values) s: 0,
    };
    for (final LearningSession s in sessions) {
      final LessonSkill? skill = lessonSkillFromActivity(s.activityType);
      if (s.completed && skill != null) {
        practiced[skill] = practiced[skill]! + 1;
      }
    }

    final Set<String> weak = weakTopics(memories);
    LessonSkill? weakSkill;
    for (final LearningMemory m in memories) {
      if (m.isUsable &&
          m.type == LearningMemoryType.weakness &&
          m.metadata['lessonSkill'] is String) {
        weakSkill = LessonSkill.values
            .where((LessonSkill s) => s.name == m.metadata['lessonSkill'])
            .firstOrNull;
        if (weakSkill != null) {
          break;
        }
      }
    }

    final PersonalPlan plan = PersonalPlan.from(profile);
    int focusBonus(LessonSkill skill) => plan.bonusFor(planAreaOf(skill));

    LessonSkill pick;
    String why;
    if (weakSkill != null && weak.isNotEmpty) {
      pick = weakSkill;
      why =
          'Your recent ${pick.label.toLowerCase()} practice showed a topic to revisit.';
    } else {
      final List<LessonSkill> order = LessonSkill.values.toList()
        ..sort((LessonSkill a, LessonSkill b) {
          // Onboarding focus areas count as up to two lessons fewer.
          final int byCount = (practiced[a]! - focusBonus(a)).compareTo(
            practiced[b]! - focusBonus(b),
          );
          if (byCount != 0) {
            return byCount;
          }
          final double ma = progress?.skills[a.name] ?? -1;
          final double mb = progress?.skills[b.name] ?? -1;
          final int byMastery = ma.compareTo(mb);
          return byMastery != 0 ? byMastery : a.index.compareTo(b.index);
        });
      pick = order.first;
      final String practice = practiced[pick] == 0
          ? 'You have not completed a ${pick.label.toLowerCase()} lesson yet.'
          : '${pick.label} is where you have practiced least.';
      final PlanFocus? focus = plan.focus
          .where((PlanFocus f) => f.area == planAreaOf(pick))
          .firstOrNull;
      why = focus == null || focusBonus(pick) == 0
          ? practice
          : '${focus.reason} $practice';
    }

    final LessonChoice choice = select(
      skill: pick,
      profile: profile,
      assessment: assessment,
      sessions: sessions,
      memories: memories,
    );
    return LessonChoice(lesson: choice.lesson, reason: '$why ${choice.reason}');
  }
}

/// The plan area a lesson skill trains.
PlanArea planAreaOf(LessonSkill skill) => switch (skill) {
  LessonSkill.grammar => PlanArea.grammar,
  LessonSkill.vocabulary => PlanArea.vocabulary,
  LessonSkill.reading => PlanArea.reading,
  LessonSkill.listening => PlanArea.listening,
};
