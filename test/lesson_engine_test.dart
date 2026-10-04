import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/lessons/engine/achievement_engine.dart';
import 'package:eloqia_ai/features/lessons/engine/exercise_evaluator.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_result_service.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_session.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/models/learning_memory.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/learning/learning_memory_service.dart';
import 'package:eloqia_ai/services/learning/learning_progress_service.dart';
import 'package:eloqia_ai/services/learning/learning_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Lesson _lesson(String id) => LessonCatalog.byId(id)!;

String _correct(Exercise e) => e.answers.first;

String _wrong(Exercise e) {
  if (e.type == ExerciseType.matching) {
    final List<String> keys = e.pairs.keys.toList();
    return keys.map((String k) => '$k=${e.pairs.values.first}').join(';');
  }
  if (e.options.isNotEmpty && e.type != ExerciseType.ordering) {
    return e.options.firstWhere((String o) => !e.answers.contains(o));
  }
  return 'zzz';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.clearEloqiaData();
  });

  group('content', () {
    test('every skill has lessons and every exercise is well formed', () {
      final Set<String> ids = <String>{};
      for (final LessonSkill skill in LessonSkill.values) {
        expect(LessonCatalog.forSkill(skill), isNotEmpty, reason: skill.name);
      }
      for (final Lesson lesson in LessonCatalog.all) {
        expect(ids.add(lesson.id), isTrue, reason: 'duplicate ${lesson.id}');
        expect(lesson.intro.explanation, isNotEmpty, reason: lesson.id);
        expect(lesson.exercisesOf(ActivityKind.practice).length, greaterThanOrEqualTo(3));
        if (lesson.skill == LessonSkill.reading) {
          expect(lesson.passage, isNotNull, reason: lesson.id);
        }
        if (lesson.skill == LessonSkill.listening) {
          expect(lesson.audio, isNotEmpty, reason: lesson.id);
        }
        for (final Exercise e in lesson.allExercises) {
          expect(ids.add(e.id), isTrue, reason: 'duplicate ${e.id}');
          expect(e.explanation.trim(), isNotEmpty, reason: e.id);
          expect(e.answers, isNotEmpty, reason: e.id);
          if (e.type == ExerciseType.multipleChoice) {
            expect(e.options, contains(e.answers.first), reason: e.id);
            expect(e.options.toSet().length, e.options.length, reason: e.id);
            for (final String key in e.notes.keys) {
              expect(e.options, contains(key), reason: '${e.id} note $key');
            }
          }
          if (e.type == ExerciseType.ordering) {
            expect(e.options.length, greaterThanOrEqualTo(4), reason: e.id);
          }
          if (e.type == ExerciseType.matching) {
            expect(e.pairs.length, greaterThanOrEqualTo(3), reason: e.id);
          }
          if (lesson.skill == LessonSkill.reading ||
              lesson.skill == LessonSkill.listening) {
            expect(e.evidence ?? e.hints.join(), isNotEmpty, reason: e.id);
          }
        }
      }
    });
  });

  group('evaluation and feedback', () {
    test('answers are normalised and matching reports the wrong pairs', () {
      final Exercise fill = _lesson('grammar-b1-conditionals')
          .allExercises
          .firstWhere((Exercise e) => e.id == 'g-b1-cond-3');
      expect(ExerciseEvaluator.evaluate(fill, '  Studied. ').correct, isTrue);
      expect(ExerciseEvaluator.evaluate(fill, 'study').correct, isFalse);

      final Exercise match = _lesson('vocab-a1-daily-life').allExercises.first;
      final ExerciseEvaluation partial = ExerciseEvaluator.evaluate(
        match,
        'bakery=the room where you cook;breakfast=the first meal of the day;kitchen=the room where you cook',
      );
      expect(partial.correct, isFalse);
      expect(partial.wrongPairs, contains('bakery'));
    });

    test('feedback names the specific mistake for the conditional example', () {
      final LessonSession session = LessonSession(
        lesson: _lesson('grammar-b1-conditionals'),
      );
      session.submit('will stay');
      session.advance();
      final ExerciseOutcome wrong = session.submit('have');

      expect(wrong.evaluation.correct, isFalse);
      expect(wrong.feedback.yourAnswer, contains('"have"'));
      expect(wrong.feedback.why, contains('real possibility'));
      expect(wrong.feedback.rule, contains('past simple'));
      expect(wrong.feedback.hint, isNotNull);
      expect(wrong.feedback.canRetry, isTrue);
      expect(wrong.feedback.mia.isCorrect, isFalse);
    });

    test('reading and listening feedback points to evidence', () {
      final LessonSession reading = LessonSession(
        lesson: _lesson('reading-a2-market'),
      );
      reading.submit('A school lesson');
      reading.advance();
      final ExerciseOutcome miss = reading.submit('At eight');
      expect(miss.feedback.mia.message, contains('last sentence'));

      final LessonSession listening = LessonSession(
        lesson: _lesson('listening-b1-restaurant'),
      );
      expect(
        listening.submit('He is ill').feedback.mia.message,
        contains('after "but"'),
      );
    });
  });

  group('session', () {
    test('perfect run earns combo bonuses and unlocks the challenge', () {
      final Lesson lesson = _lesson('grammar-a1-be');
      final LessonSession session = LessonSession(lesson: lesson);
      int xp = 0;
      while (!session.isComplete) {
        final Exercise e = session.current!;
        final ExerciseOutcome o = session.submit(_correct(e));
        expect(o.evaluation.correct, isTrue);
        xp += o.totalXp;
        session.advance();
      }
      final LessonSummary summary = session.summarize();

      expect(summary.totalExercises, 7);
      expect(summary.perfect, isTrue);
      expect(summary.maxCombo, 7);
      expect(summary.answerXp, xp);
      expect(summary.completionXp, lesson.xpReward);
    });

    test('mistakes retry, reveal, come back, and skip the challenge', () {
      final Lesson lesson = _lesson('grammar-a1-be');
      final LessonSession session = LessonSession(lesson: lesson);
      final List<String> seen = <String>[];
      int safety = 0;
      while (!session.isComplete && safety++ < 40) {
        final Exercise e = session.current!;
        seen.add(e.id);
        final bool failPractice = e.id == 'g-a1-be-1' || e.id == 'g-a1-be-2';
        if (failPractice && !session.isReview) {
          final ExerciseOutcome first = session.submit(_wrong(e));
          expect(first.feedback.canRetry, isTrue);
          session.retry();
          final ExerciseOutcome second = session.submit(_wrong(e));
          expect(second.feedback.revealed, isTrue);
          expect(second.xp, 0);
        } else {
          session.submit(_correct(e));
        }
        session.advance();
      }

      // 3 of 5 practice items correct first time: below the challenge threshold.
      expect(seen, isNot(contains('g-a1-be-6')));
      expect(seen.where((String id) => id == 'g-a1-be-1'), hasLength(2));
      final LessonSummary summary = session.summarize();
      expect(summary.missedTopics['the verb be'], 2);
      expect(summary.completionXp, lessThan(lesson.xpReward));
    });

    test('a correct retry earns reduced XP and no combo', () {
      final LessonSession session = LessonSession(
        lesson: _lesson('grammar-a1-be'),
      );
      final Exercise e = session.current!;
      session.submit(_wrong(e));
      session.retry();
      final ExerciseOutcome retry = session.submit(_correct(e));
      expect(retry.xp, 1);
      expect(retry.comboBonus, 0);
      expect(retry.combo, 0);
    });
  });

  group('engine', () {
    test('selects by level, weakness and interests and explains why', () async {
      final LearningProfile profile = LearningProfile(
        currentLevel: 'B2',
        interests: <String>['technology'],
      );
      final LessonChoice vocab = LessonEngine.select(
        skill: LessonSkill.vocabulary,
        profile: profile,
      );
      expect(vocab.lesson.levelIndex, 3);
      expect(vocab.reason, contains('declared B2'));

      final LearningMemory weak = LearningMemory.create(
        id: 'w1',
        content: 'Missed conditionals',
        type: LearningMemoryType.weakness,
        metadata: <String, dynamic>{
          'lessonTopic': 'conditionals',
          'lessonSkill': 'grammar',
        },
      );
      final LessonChoice grammar = LessonEngine.select(
        skill: LessonSkill.grammar,
        profile: LearningProfile(currentLevel: 'B1'),
        memories: <LearningMemory>[weak],
      );
      expect(grammar.lesson.topic, 'conditionals');
      expect(grammar.reason, contains('You missed conditionals earlier'));

      final LessonChoice next = LessonEngine.recommend(
        profile: profile,
        memories: <LearningMemory>[weak],
      );
      expect(next.lesson.skill, LessonSkill.grammar);
    });

    test('recommends the least practised skill when no weakness exists', () {
      final LessonChoice choice = LessonEngine.recommend(
        profile: LearningProfile(currentLevel: 'A2'),
      );
      expect(choice.reason, contains('not completed'));
    });
  });

  group('persistence', () {
    test('records session, xp, skill, streak, memory and achievements', () async {
      final Lesson lesson = _lesson('grammar-b1-conditionals');
      final LessonSession session = LessonSession(lesson: lesson);
      while (!session.isComplete) {
        final Exercise e = session.current!;
        if (e.id == 'g-b1-cond-2') {
          session.submit(_wrong(e));
          session.retry();
        }
        session.submit(_correct(e));
        session.advance();
      }
      final LessonSummary summary = session.summarize();

      final LessonRecord record = await LessonResultService.record(
        summary: summary,
        profile: LearningProfile(currentLevel: 'B1'),
      );

      expect(record.sessionSaved, isTrue);
      expect(record.progressSaved, isTrue);
      expect(record.xpAwarded, summary.totalXp);
      expect(record.newAchievements.map((Achievement a) => a.id), contains('first-lesson'));
      expect(record.skillMastery, closeTo(summary.accuracy * 100, 0.01));

      final progress = await LearningProgressService.getProgress();
      expect(progress.xp, summary.totalXp);
      expect(progress.skills['grammar'], isNotNull);
      expect(progress.currentStreak, 1);
      expect(progress.statistics.completedLessons, 1);
      expect(progress.level, progress.xp ~/ 100 + 1);

      final sessions = await LearningSessionService.getHistory();
      expect(sessions.single.metadata['lessonId'], lesson.id);
      expect(sessions.single.xpEarned, summary.totalXp);

      final memories = await MemoryService.getActiveMemories();
      expect(memories.single.metadata['lessonTopic'], 'conditionals');
      expect(LessonEngine.weakTopics(memories), contains('conditionals'));
    });
  });
}
