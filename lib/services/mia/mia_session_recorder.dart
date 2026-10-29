import '../../features/lessons/engine/achievement_engine.dart';
import '../../features/lessons/engine/lesson_result_service.dart';
import '../../models/learning_profile.dart';
import '../../models/learning_session.dart';
import '../../models/progress.dart';
import '../learning/learning_progress_service.dart';
import '../learning/learning_session_service.dart';
import 'mia_chat_client.dart';

/// Result of recording a finished conversation with Mia.
class MiaSessionRecord {
  const MiaSessionRecord({
    required this.saved,
    required this.xpAwarded,
    required this.newAchievements,
  });

  final bool saved;
  final int xpAwarded;
  final List<Achievement> newAchievements;
}

/// Records a finished Mia conversation through the app's existing session,
/// progress, streak and achievement systems (same path as lessons).
class MiaSessionRecorder {
  MiaSessionRecorder._();

  /// Learner messages needed before a session counts as practice.
  static const int minLearnerTurns = 3;
  static const int xpPerTurn = 5;
  static const int maxXp = 40;
  static const int writingXp = 15;

  /// XP rule: only real learner messages count (at least 3 words each).
  static int xpFor({
    required MiaChatMode mode,
    required List<MiaChatTurn> history,
  }) {
    final List<MiaChatTurn> learner = history
        .where(
          (MiaChatTurn t) =>
              t.fromLearner && t.text.trim().split(RegExp(r'\s+')).length >= 3,
        )
        .toList();
    if (mode == MiaChatMode.writing) {
      return learner.isEmpty ? 0 : writingXp;
    }
    if (learner.length < minLearnerTurns) return 0;
    final int xp = learner.length * xpPerTurn;
    return xp > maxXp ? maxXp : xp;
  }

  static LearningActivityType activityFor(MiaChatMode mode) => switch (mode) {
    MiaChatMode.writing => LearningActivityType.writing,
    MiaChatMode.ask => LearningActivityType.lesson,
    MiaChatMode.conversation ||
    MiaChatMode.roleplay => LearningActivityType.conversation,
  };

  /// Records the session once; [sessionId] must be unique per session so
  /// that reopening or retrying never awards XP twice.
  static Future<MiaSessionRecord> record({
    required String sessionId,
    required MiaChatMode mode,
    required List<MiaChatTurn> history,
    required LearningProfile profile,
    required Duration duration,
    MiaScenario? scenario,
    MiaSessionSummary? summary,
  }) async {
    const MiaSessionRecord nothing = MiaSessionRecord(
      saved: false,
      xpAwarded: 0,
      newAchievements: <Achievement>[],
    );
    final int xp = xpFor(mode: mode, history: history);
    if (xp == 0) return nothing;
    if (await LearningSessionService.getSession(sessionId) != null) {
      return nothing; // Already recorded.
    }

    final Progress before = await LearningProgressService.getProgress();
    final Set<String> unlockedBefore = AchievementEngine.unlocked(
      sessions: await LearningSessionService.getHistory(),
      progress: before,
    );

    final int learnerTurns = history
        .where((MiaChatTurn t) => t.fromLearner)
        .length;
    try {
      final LearningSession? created =
          await LearningSessionService.createSession(
            id: sessionId,
            activityType: activityFor(mode),
            tutorId: 'mia',
            tutorName: 'Mia',
            targetLevel: profile.currentLevel,
            startingLevel: profile.currentLevel,
            primaryGoal: profile.primaryGoal,
            skills: mode == MiaChatMode.writing
                ? const <LearningSkill>[LearningSkill.writing]
                : const <LearningSkill>[
                    LearningSkill.speaking,
                    LearningSkill.fluency,
                  ],
            topics: <String>[
              if (scenario != null) scenario.apiValue,
              ...?summary?.practiced,
            ],
          );
      if (created == null) return nothing;

      await LearningSessionService.startSession(
        sessionId,
        startedAt: DateTime.now().toUtc().subtract(duration),
      );
      await LearningSessionService.updateDuration(sessionId, duration);
      await LearningSessionService.updateObjectives(
        sessionId,
        completed: learnerTurns,
        total: learnerTurns,
      );
      if (summary != null) {
        await LearningSessionService.updateInsights(
          sessionId,
          strengths: summary.strengths,
          weaknesses: summary.improvements
              .map((MiaEvidenceItem i) => i.suggestion)
              .where((String s) => s.isNotEmpty)
              .toList(),
          vocabularyLearned: summary.usefulExpressions,
        );
      }
      final LearningSession? latest = await LearningSessionService.getSession(
        sessionId,
      );
      if (latest != null) {
        await LearningSessionService.updateSession(
          latest.copyWith(
            metadata: <String, dynamic>{
              'miaMode': mode.apiValue,
              if (scenario != null) 'scenario': scenario.apiValue,
              'learnerTurns': learnerTurns,
            },
          ),
        );
      }
      final LearningSession? completed =
          await LearningSessionService.completeSession(sessionId, xpEarned: xp);
      if (completed == null) return nothing;
    } on Object {
      return nothing;
    }

    final Progress base = await LearningProgressService.getProgress();
    Progress updated = base
        .addXp(xp)
        .copyWith(
          statistics: base.statistics.copyWith(
            totalSessions: base.statistics.totalSessions + 1,
            learningMinutes:
                base.statistics.learningMinutes + duration.inMinutes,
          ),
          lastActivity: DateTime.now().toUtc(),
        );
    updated = LessonResultService.withStreak(updated, base);
    final Progress? saved = await LearningProgressService.save(updated);
    if (saved == null) {
      final LearningSession? done = await LearningSessionService.getSession(
        sessionId,
      );
      if (done != null) {
        await LearningSessionService.updateSession(done.copyWith(xpEarned: 0));
      }
      return nothing;
    }

    final Set<String> unlockedAfter = AchievementEngine.unlocked(
      sessions: await LearningSessionService.getHistory(),
      progress: saved,
    );
    return MiaSessionRecord(
      saved: true,
      xpAwarded: xp,
      newAchievements: <Achievement>[
        for (final Achievement a in AchievementEngine.all)
          if (unlockedAfter.contains(a.id) && !unlockedBefore.contains(a.id)) a,
      ],
    );
  }
}
