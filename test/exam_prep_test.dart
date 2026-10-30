import 'dart:convert';

import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/exams/build_sentence.dart';
import 'package:eloqia_ai/features/exams/build_sentence_screen.dart';
import 'package:eloqia_ai/features/exams/exam_clock.dart';
import 'package:eloqia_ai/features/exams/exam_formats.dart';
import 'package:eloqia_ai/features/exams/exam_progress.dart';
import 'package:eloqia_ai/features/exams/exam_score_store.dart';
import 'package:eloqia_ai/features/exams/exam_space_screen.dart';
import 'package:eloqia_ai/features/exams/exam_visual_view.dart';
import 'package:eloqia_ai/features/exams/exam_visuals.dart';
import 'package:eloqia_ai/features/writing/writing_catalog.dart';
import 'package:eloqia_ai/features/writing/writing_workspace_screen.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/mia/mia_chat_client.dart';
import 'package:eloqia_ai/services/mia/writing_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Genres accepted by `backend/app/writing.py` for exam tasks.
const Set<String> _serverExamGenres = <String>{
  'toefl_email',
  'toefl_discussion',
  'ielts_task1_academic',
  'ielts_task1_general',
  'ielts_task2',
};

ExamAttempt _attempt(
  String id,
  ExamTaskType type,
  double value,
  DateTime at, {
  Map<String, int> criteria = const <String, int>{},
}) => ExamAttempt(
  id: id,
  type: type,
  taskId: 'task-$id',
  title: 'Task $id',
  value: value,
  scaleMax: type.scaleMax,
  at: at,
  criteria: criteria,
  criteriaMax: criteria.isEmpty ? 0 : type.scaleMax,
);

Map<String, dynamic> _ieltsReview() => <String, dynamic>{
  'overall': 'A clear position, with some repetition.',
  'score_percent': 72,
  'criteria': <Map<String, dynamic>>[
    for (final MapEntry<String, int> c in <String, int>{
      'task_response': 7,
      'coherence_cohesion': 6,
      'lexical_resource': 6,
      'grammatical_range_accuracy': 7,
    }.entries)
      <String, dynamic>{
        'criterion': c.key,
        'label': c.key,
        'score': c.value,
        'max_score': 9,
        'weight': 1,
        'comment': '',
      },
  ],
  'strengths': <String>[],
  'weaknesses': <String>[],
  'corrections': <Map<String, dynamic>>[],
  'revision_plan': <String>[],
  'revised_version': '',
  'word_count': 260,
  'estimate_note': 'Practice estimate.',
  'exam_estimate': <String, dynamic>{
    'exam': 'IELTS',
    'label': 'Estimated band for this task',
    'value': 6.5,
    'scale_max': 9,
    'note': 'Unofficial practice estimate.',
  },
  'safety_redirect': false,
};

void main() {
  group('formats', () {
    test('official times and scales', () {
      expect(
        ExamTaskType.toeflBuildSentence.timeLimit,
        const Duration(minutes: 6, seconds: 50),
      );
      expect(ExamTaskType.toeflEmail.timeLimit.inMinutes, 7);
      expect(ExamTaskType.toeflDiscussion.timeLimit.inMinutes, 10);
      expect(ExamTaskType.ieltsTask1Academic.timeLimit.inMinutes, 20);
      expect(ExamTaskType.ieltsTask1General.timeLimit.inMinutes, 20);
      expect(ExamTaskType.ieltsTask2.timeLimit.inMinutes, 40);
      expect(ExamTaskType.ieltsTask2.minWords, 250);
      expect(ExamTaskType.ieltsTask2.scaleMax, 9);
      expect(ExamTaskType.toeflEmail.scaleMax, 5);
      expect(ExamTaskType.toeflBuildSentence.timeLabel, '6 min 50 s');
      expect(formatClock(const Duration(minutes: 19, seconds: 5)), '19:05');
    });

    test('writing task types match the server genres', () {
      final Set<String> writing = ExamTaskType.values
          .where((ExamTaskType t) => t.isWriting)
          .map((ExamTaskType t) => t.apiValue)
          .toSet();
      expect(writing, _serverExamGenres);
      for (final String api in writing) {
        expect(WritingGenre.byApiValue(api)?.isExam, isTrue);
      }
    });

    test('every advice points to a task type of the same exam family', () {
      for (final CriterionAdvice advice in examCriterionAdvice.values) {
        expect(advice.tips, isNotEmpty);
        expect(advice.label, isNotEmpty);
      }
      expect(
        examCriterionAdvice['task_achievement']!.practice.exam,
        ExamKind.ielts,
      );
      expect(examCriterionAdvice['engagement']!.practice.exam, ExamKind.toefl);
    });
  });

  group('catalog', () {
    test('exam tasks have their material, time and length', () {
      for (final WritingGenre genre in WritingGenre.values.where(
        (WritingGenre g) => g.isExam,
      )) {
        final List<WritingTask> tasks = WritingCatalog.tasksFor(genre);
        expect(tasks.length, greaterThanOrEqualTo(5), reason: genre.label);
        for (final WritingTask task in tasks) {
          expect(task.timeLimit, genre.examTask!.timeLimit);
          expect(task.reviewSource?.length ?? 0, lessThanOrEqualTo(3000));
          if (genre == WritingGenre.ieltsTask1Academic) {
            expect(task.visual?.isValid, isTrue, reason: task.id);
            expect(task.reviewSource, contains('invented'));
          }
          if (genre == WritingGenre.toeflDiscussion) {
            expect(task.discussion!.posts, hasLength(2));
            expect(task.reviewSource, contains('Professor'));
          }
        }
      }
    });

    test('Task 1 visuals cover every kind', () {
      final Set<ExamVisualKind> kinds = WritingCatalog.tasksFor(
        WritingGenre.ieltsTask1Academic,
      ).map((WritingTask t) => t.visual!.kind).toSet();
      expect(kinds, ExamVisualKind.values.toSet());
    });

    test('studio tasks are never timed', () {
      for (final WritingTask task in WritingCatalog.tasks) {
        if (!task.genre.isExam) expect(task.timeLimit, isNull);
      }
    });
  });

  group('visuals', () {
    test('describe gives Mia every figure', () {
      const ExamVisual visual = ExamVisual(
        kind: ExamVisualKind.bar,
        title: 'Sales',
        unit: 'units',
        axisLabel: 'year',
        categories: <String>['2020', '2021'],
        series: <ChartSeries>[
          ChartSeries('Shop A', <double>[1200, 1500.5]),
        ],
      );
      expect(
        visual.describe(),
        'Bar chart: Sales. Unit: units. By year. Shop A: 2020 1,200, '
        '2021 1,500.5. All data is invented for practice.',
      );
      expect(visual.isValid, isTrue);
    });

    test('map features are placed by compass area', () {
      expect(
        const MapFeature('Park', MapFeatureKind.green, 0, 0, 0.2, 0.2).area,
        'north-west',
      );
      expect(
        const MapFeature(
          'Hall',
          MapFeatureKind.building,
          0.4,
          0.4,
          0.2,
          0.2,
        ).area,
        'centre',
      );
    });

    test('nice axis', () {
      expect(niceAxis(14).top, 15);
      expect(niceAxis(290).top, 300);
      expect(niceAxis(0).top, 1);
    });
  });

  group('clock', () {
    test('counts down, warns, then shows overtime', () {
      DateTime now = DateTime(2026, 10, 30, 9);
      final ExamClock clock = ExamClock(
        limit: const Duration(minutes: 20),
        now: () => now,
      );
      expect(clock.phase, ExamClockPhase.notStarted);
      expect(clock.display, '20:00');
      clock.start();
      now = now.add(const Duration(minutes: 5));
      expect(clock.phase, ExamClockPhase.running);
      expect(clock.display, '15:00');
      now = now.add(const Duration(minutes: 13, seconds: 30));
      expect(clock.phase, ExamClockPhase.lastMinutes);
      now = now.add(const Duration(minutes: 2, seconds: 5));
      expect(clock.phase, ExamClockPhase.over);
      expect(clock.display, '+0:35');
      clock.reset();
      expect(clock.started, isFalse);
    });
  });

  group('Build a Sentence', () {
    test('three sets of ten valid items', () {
      expect(BuildSentenceCatalog.sets, hasLength(3));
      final Set<String> ids = <String>{};
      for (final SentenceSet set in BuildSentenceCatalog.sets) {
        expect(set.items, hasLength(10));
        for (final SentenceItem item in set.items) {
          expect(ids.add(item.id), isTrue);
          final List<String> right = <String>[
            for (int i = 0; i < item.answer.length; i++)
              if (!item.fixed.contains(i)) item.answer[i],
          ];
          expect(item.isCorrect(right), isTrue, reason: item.id);
          expect(
            (List<String>.of(item.bank)..sort()),
            (<String>[...right, ...item.extra]..sort()),
          );
          expect(item.bank.length, lessThanOrEqualTo(8));
          if (item.extra.isNotEmpty) {
            final List<String> wrong = List<String>.of(right)
              ..[right.length - 1] = item.extra.first;
            expect(item.isCorrect(wrong), isFalse, reason: item.id);
          }
        }
      }
    });

    test('all or nothing, the bank is stable', () {
      final SentenceItem item = BuildSentenceCatalog.sets.first.items.first;
      expect(item.bank, item.bank);
      expect(item.sentence, 'Do you know if the study rooms are still open?');
      final SentenceAttemptResult result = SentenceAttemptResult.score(
        <SentenceItem>[item, item],
        <List<String?>>[
          <String?>[
            'you',
            'know',
            'if',
            'the study rooms',
            'are',
            'still open',
          ],
          <String?>['you', 'know', 'if', 'the study rooms', 'is', 'still open'],
        ],
      );
      expect(result.correct, 1);
      expect(result.tipsToReview, hasLength(1));
      expect(
        result.outcomes.last.learnerSentence,
        'Do you know if the study rooms is still open?',
      );
      expect(item.isCorrect(<String?>['you', null]), isFalse);
    });
  });

  group('progress', () {
    final DateTime day = DateTime.utc(2026, 10, 1);

    test('weakest criterion, IELTS estimate and untried tasks', () {
      final ExamProgress progress = ExamProgress(<ExamAttempt>[
        _attempt(
          '1',
          ExamTaskType.ieltsTask2,
          6.5,
          day,
          criteria: <String, int>{
            'task_response': 7,
            'coherence_cohesion': 6,
            'lexical_resource': 6,
            'grammatical_range_accuracy': 7,
          },
        ),
        _attempt(
          '2',
          ExamTaskType.ieltsTask1Academic,
          6,
          day.add(const Duration(days: 1)),
          criteria: <String, int>{
            'task_achievement': 5,
            'coherence_cohesion': 6,
            'lexical_resource': 6,
            'grammatical_range_accuracy': 7,
          },
        ),
        _attempt(
          '3',
          ExamTaskType.toeflBuildSentence,
          6,
          day.add(const Duration(days: 2)),
        ),
      ]);
      expect(progress.attempts.first.id, '3');
      expect(progress.ieltsWritingEstimate(), 6.5);
      expect(
        progress.recommendation(ExamKind.ielts)!.criterion,
        'task_achievement',
      );
      expect(
        progress.recommendation(ExamKind.toefl)!.criterion,
        'sentence_building',
      );
      expect(progress.untried(ExamKind.toefl), <ExamTaskType>[
        ExamTaskType.toeflEmail,
        ExamTaskType.toeflDiscussion,
      ]);
      expect(progress.trend(ExamTaskType.ieltsTask2), <double>[6.5]);
      expect(roundHalfBand(6.25), 6.5);
      expect(roundHalfBand(6.75), 7);
    });

    test('no IELTS estimate without both tasks', () {
      final ExamProgress progress = ExamProgress(<ExamAttempt>[
        _attempt('1', ExamTaskType.ieltsTask2, 7, day),
      ]);
      expect(progress.ieltsWritingEstimate(), isNull);
      expect(progress.recommendation(ExamKind.ielts), isNull);
    });

    test('attempts round-trip and malformed entries are skipped', () {
      final ExamAttempt attempt = _attempt(
        '9',
        ExamTaskType.toeflEmail,
        4,
        day,
        criteria: <String, int>{'task_completion': 4},
      );
      final ExamAttempt again = ExamAttempt.tryParse(
        jsonDecode(jsonEncode(attempt.toJson())),
      )!;
      expect(again.type, ExamTaskType.toeflEmail);
      expect(again.criteria, <String, int>{'task_completion': 4});
      expect(again.display, '4');
      expect(ExamAttempt.tryParse(<String, dynamic>{'id': 1}), isNull);
      expect(
        ExamAttempt.tryParse(<String, dynamic>{
          'id': 'x',
          'type': 'nope',
          'value': 1,
          'scaleMax': 5,
          'at': '2026-10-01T00:00:00Z',
        }),
        isNull,
      );
    });
  });

  group('storage and client', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ExamScoreStore.key);
    });

    test('a reviewed exam text becomes an attempt', () async {
      final WritingReview review = WritingReview.tryParse(_ieltsReview())!;
      final ExamAttempt attempt = ExamScoreStore.fromReview(
        id: 'w-1',
        genre: 'ielts_task2',
        taskId: 'ielts-t2-remote-work',
        title: 'Working from home',
        review: review,
        at: DateTime.utc(2026, 10, 30),
        timeLimit: const Duration(minutes: 40),
        timeUsed: const Duration(minutes: 42),
      )!;
      expect(attempt.value, 6.5);
      expect(attempt.criteriaMax, 9);
      expect(attempt.overTime, isTrue);
      await ExamScoreStore.add(attempt);
      expect((await ExamScoreStore.attempts()).single.id, 'w-1');
      expect(
        ExamScoreStore.fromReview(
          id: 'w-2',
          genre: 'email',
          taskId: 'email-invite-friend',
          title: 'Invite',
          review: review,
          at: DateTime.utc(2026, 10, 30),
        ),
        isNull,
      );
    });

    test('timed attempts send the limit and the time used', () {
      final Map<String, dynamic> timed =
          MiaChatClient.buildWritingReviewRequest(
            genre: 'ielts_task2',
            taskId: 'ielts-t2-remote-work',
            taskTitle: 'Working from home',
            prompt: 'Is this positive?',
            minWords: 250,
            maxWords: 0,
            text: 'Text.',
            context: <String, dynamic>{},
            timeLimit: const Duration(minutes: 40),
            timeUsed: const Duration(minutes: 38, seconds: 12),
          );
      expect(timed['time_limit_seconds'], 2400);
      expect(timed['time_used_seconds'], 2292);
      final Map<String, dynamic> untimed =
          MiaChatClient.buildWritingReviewRequest(
            genre: 'free',
            taskId: 'free-my-week',
            taskTitle: 'My week',
            prompt: 'Write.',
            minWords: 40,
            maxWords: 0,
            text: 'Text.',
            context: <String, dynamic>{},
          );
      expect(untimed.containsKey('time_limit_seconds'), isFalse);
    });
  });

  group('screens', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ExamScoreStore.key);
    });

    testWidgets('every Task 1 visual draws without error', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final WritingTask task in WritingCatalog.tasksFor(
        WritingGenre.ieltsTask1Academic,
      )) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ExamVisualView(visual: task.visual!),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: task.id);
        expect(find.text(task.visual!.title), findsOneWidget);
      }
    });

    testWidgets('IELTS space lists the tasks and the format', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: ExamSpaceScreen(
            exam: ExamKind.ielts,
            profile: LearningProfile(currentLevel: 'B2'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('IELTS Writing'), findsOneWidget);
      expect(find.text('Task 2 Essay'), findsOneWidget);
      expect(find.text('Task 1 Academic'), findsOneWidget);
      expect(find.textContaining('No score yet'), findsOneWidget);
      expect(find.textContaining('not affiliated'), findsOneWidget);
    });

    testWidgets('Build a Sentence: place words and see the score', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final SentenceSet set = BuildSentenceCatalog.sets.first;
      await tester.pumpWidget(MaterialApp(home: BuildSentenceScreen(set: set)));
      await tester.tap(find.text('Practise without the timer'));
      await tester.pumpAndSettle();
      expect(find.text('Item 1 of 10'), findsOneWidget);

      final SentenceItem item = set.items.first;
      for (int i = 0; i < item.answer.length; i++) {
        if (item.fixed.contains(i)) continue;
        await tester.tap(find.text(item.answer[i]).last);
        await tester.pump();
      }
      for (int i = 1; i < set.items.length; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 10'), findsOneWidget);
      expect((await ExamScoreStore.attempts()).single.value, 1);
    });

    testWidgets('exam tasks show the official timer, studio tasks do not', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: WritingWorkspaceScreen(
            task: WritingCatalog.byId('toefl-email-extension')!,
            profile: LearningProfile(currentLevel: 'B1'),
            client: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Official time: 7 min'), findsOneWidget);
      await tester.tap(find.text('Start timer'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Time left'), findsOneWidget);

      // A fresh tree, so the next screen gets its own state.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: WritingWorkspaceScreen(
            task: WritingCatalog.byId('free-my-week')!,
            profile: LearningProfile(currentLevel: 'A2'),
            client: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Start timer'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
