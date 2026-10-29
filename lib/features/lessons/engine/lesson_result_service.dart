import '../../../models/learning_memory.dart';
import '../../../models/learning_profile.dart';
import '../../../models/learning_session.dart';
import '../../../models/progress.dart';
import '../../../services/learning/learning_memory_service.dart';
import '../../../services/learning/learning_progress_service.dart';
import '../../../services/learning/learning_session_service.dart';
import '../models/lesson_models.dart';
import 'achievement_engine.dart';
import 'lesson_session.dart';

class LessonRecord {
  const LessonRecord({
    required this.sessionSaved,
    required this.progressSaved,
    required this.xpAwarded,
    required this.previousLevel,
    required this.newLevel,
    required this.newAchievements,
    required this.skillMastery,
  });

  final bool sessionSaved;
  final bool progressSaved;
  final int xpAwarded;
  final int previousLevel;
  final int newLevel;
  final List<Achievement> newAchievements;

  /// Measured mastery for the lesson's skill after this lesson, if saved.
  final double? skillMastery;

  bool get leveledUp => newLevel > previousLevel;
}

/// Persists a finished lesson through the existing session, progress and
/// memory services. XP is awarded only after progress is saved.
class LessonResultService {
  LessonResultService._();

  static LearningActivityType activityFor(LessonSkill skill) => switch (skill) {
    LessonSkill.grammar => LearningActivityType.grammar,
    LessonSkill.vocabulary => LearningActivityType.vocabulary,
    LessonSkill.reading => LearningActivityType.reading,
    LessonSkill.listening => LearningActivityType.listening,
  };

  static LearningSkill learningSkillFor(LessonSkill skill) => switch (skill) {
    LessonSkill.grammar => LearningSkill.grammar,
    LessonSkill.vocabulary => LearningSkill.vocabulary,
    LessonSkill.reading => LearningSkill.reading,
    LessonSkill.listening => LearningSkill.listening,
  };

  /// Smooths measured accuracy; a missing or zero value means unmeasured.
  static double nextMastery(double? previous, double accuracyPercent) =>
      previous == null || previous <= 0
      ? accuracyPercent
      : previous * 0.7 + accuracyPercent * 0.3;

  static Future<LessonRecord> record({
    required LessonSummary summary,
    required LearningProfile profile,
  }) async {
    final Lesson lesson = summary.lesson;
    final Progress before = await LearningProgressService.getProgress();
    final List<LearningSession> sessionsBefore =
        await LearningSessionService.getHistory();
    final Set<String> unlockedBefore = AchievementEngine.unlocked(
      sessions: sessionsBefore,
      progress: before,
    );

    final String id =
        'lesson-${lesson.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final double accuracyPercent = summary.accuracy * 100;
    bool sessionSaved = false;
    int xpAwarded = 0;

    try {
      final LearningSession? created =
          await LearningSessionService.createSession(
            id: id,
            activityType: activityFor(lesson.skill),
            tutorId: 'mia',
            tutorName: 'Mia',
            targetLevel: lesson.level,
            startingLevel: profile.currentLevel,
            primaryGoal: profile.primaryGoal,
            skills: <LearningSkill>[learningSkillFor(lesson.skill)],
            topics: <String>[lesson.topic],
            adaptive: true,
          );

      if (created != null) {
        await LearningSessionService.startSession(
          id,
          startedAt: DateTime.now().toUtc().subtract(summary.duration),
        );
        await LearningSessionService.updateDuration(id, summary.duration);
        await LearningSessionService.updateObjectives(
          id,
          completed: summary.firstTryCorrect,
          total: summary.totalExercises,
        );
        await LearningSessionService.updatePerformance(
          id,
          score: accuracyPercent,
          grammarScore: lesson.skill == LessonSkill.grammar ? accuracyPercent : null,
          vocabularyScore: lesson.skill == LessonSkill.vocabulary
              ? accuracyPercent
              : null,
        );
        await LearningSessionService.updateInsights(
          id,
          weaknesses: summary.missedTopics.keys.toList(),
          strengths: summary.accuracy >= 0.8 ? <String>[lesson.topic] : <String>[],
        );

        final LearningSession? latest = await LearningSessionService.getSession(
          id,
        );
        if (latest != null) {
          await LearningSessionService.updateSession(
            latest.copyWith(
              metadata: <String, dynamic>{
                'lessonId': lesson.id,
                'accuracy': summary.accuracy,
                'maxCombo': summary.maxCombo,
                'perfect': summary.perfect,
              },
            ),
          );
        }

        final LearningSession? completed =
            await LearningSessionService.completeSession(
              id,
              xpEarned: summary.totalXp,
            );
        sessionSaved = completed != null;
      }
    } on Object {
      sessionSaved = false;
    }

    Progress? saved;
    double? mastery;
    if (sessionSaved) {
      final Progress base = await LearningProgressService.getProgress();
      mastery = nextMastery(base.skills[lesson.skill.name], accuracyPercent);
      Progress updated = base
          .addXp(summary.totalXp)
          .updateSkill(lesson.skill.name, mastery)
          .copyWith(
            statistics: base.statistics.copyWith(
              completedLessons: base.statistics.completedLessons + 1,
              learningMinutes:
                  base.statistics.learningMinutes + summary.duration.inMinutes,
            ),
            lastActivity: DateTime.now().toUtc(),
          );
      updated = withStreak(updated, base);
      saved = await LearningProgressService.save(updated);
      if (saved != null) {
        xpAwarded = summary.totalXp;
      }
    }

    if (saved == null) {
      mastery = null;
      if (sessionSaved) {
        // Keep history and rewards consistent when progress could not be saved.
        final LearningSession? done = await LearningSessionService.getSession(id);
        if (done != null) {
          await LearningSessionService.updateSession(done.copyWith(xpEarned: 0));
        }
      }
    }

    try {
      await _updateMemory(summary);
    } on Object {
      // Memory is a best-effort enrichment of the lesson record.
    }

    final Progress after = saved ?? before;
    final List<LearningSession> sessionsAfter =
        await LearningSessionService.getHistory();
    final Set<String> unlockedAfter = AchievementEngine.unlocked(
      sessions: sessionsAfter,
      progress: after,
    );

    return LessonRecord(
      sessionSaved: sessionSaved,
      progressSaved: saved != null,
      xpAwarded: xpAwarded,
      previousLevel: before.level,
      newLevel: after.level,
      newAchievements: <Achievement>[
        for (final Achievement a in AchievementEngine.all)
          if (unlockedAfter.contains(a.id) && !unlockedBefore.contains(a.id)) a,
      ],
      skillMastery: mastery,
    );
  }

  /// Shared streak rule (also used by Mia conversations).
  static Progress withStreak(Progress updated, Progress base) {
    final DateTime now = DateTime.now().toUtc();
    final DateTime? last = base.lastActivity?.toUtc();
    final bool sameDay =
        last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    final bool consecutive =
        last != null && now.difference(DateTime.utc(last.year, last.month, last.day)).inDays == 1;
    final int streak = sameDay
        ? base.currentStreak
        : (consecutive ? base.currentStreak + 1 : 1);
    return updated.copyWith(
      currentStreak: streak,
      longestStreak: streak > base.longestStreak ? streak : base.longestStreak,
    );
  }

  static Future<void> _updateMemory(LessonSummary summary) async {
    final Lesson lesson = summary.lesson;
    for (final MapEntry<String, int> entry in summary.missedTopics.entries) {
      final String id = 'lesson-weak-${lesson.skill.name}-${_slug(entry.key)}';
      final LearningMemory? existing = await MemoryService.getMemory(id);
      if (existing != null) {
        await MemoryService.saveMemory(
          existing.reinforce(confidenceBoost: 8, importanceBoost: 3).copyWith(
            active: true,
            content: _weaknessText(lesson, entry.key, entry.value),
          ),
        );
        continue;
      }
      await MemoryService.createMemory(
        id: id,
        type: LearningMemoryType.weakness,
        source: LearningMemorySource.session,
        content: _weaknessText(lesson, entry.key, entry.value),
        tutorId: 'mia',
        tags: <String>['lesson', lesson.skill.name],
        confidence: 40,
        importance: 55,
        metadata: <String, dynamic>{
          'lessonTopic': entry.key,
          'lessonSkill': lesson.skill.name,
          'lessonId': lesson.id,
        },
      );
    }

    // A clean lesson on a topic retires its earlier weakness signal.
    if (summary.missedTopics.isEmpty && summary.accuracy >= 0.8) {
      final String id = 'lesson-weak-${lesson.skill.name}-${_slug(lesson.topic)}';
      final LearningMemory? existing = await MemoryService.getMemory(id);
      if (existing != null && existing.active) {
        await MemoryService.saveMemory(existing.deactivate());
      }
    }
  }

  static String _weaknessText(Lesson lesson, String topic, int misses) =>
      'Missed $misses ${misses == 1 ? 'item' : 'items'} on $topic in a '
      '${lesson.level} ${lesson.skill.label.toLowerCase()} lesson. '
      'This is a practice signal, not a diagnosis.';

  static String _slug(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
