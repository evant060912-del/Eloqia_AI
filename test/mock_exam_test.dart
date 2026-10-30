import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/exams/build_sentence_screen.dart';
import 'package:eloqia_ai/features/exams/exam_formats.dart';
import 'package:eloqia_ai/features/exams/exam_progress.dart';
import 'package:eloqia_ai/features/exams/exam_score_store.dart';
import 'package:eloqia_ai/features/exams/mock_exam.dart';
import 'package:eloqia_ai/features/exams/mock_exam_screen.dart';
import 'package:eloqia_ai/features/speaking/speaking_tasks.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _start = DateTime.utc(2026, 10, 31, 9);

ExamAttempt _attempt(
  String id,
  ExamTaskType type,
  String taskId,
  double value,
  Duration after, [
  Map<String, int> criteria = const <String, int>{},
]) => ExamAttempt(
  id: id,
  type: type,
  taskId: taskId,
  title: id,
  value: value,
  scaleMax: type.scaleMax,
  at: _start.add(after),
  criteria: criteria,
  criteriaMax: criteria.isEmpty ? 0 : type.scaleMax,
);

MockSession _ielts() => MockSession(
  exam: ExamKind.ielts,
  startedAt: _start,
  steps: const <MockStep>[
    MockStep(
      type: ExamTaskType.ieltsTask1Academic,
      taskId: 't1',
      title: 'T1',
      section: MockSection.writing,
    ),
    MockStep(
      type: ExamTaskType.ieltsTask2,
      taskId: 't2',
      title: 'T2',
      section: MockSection.writing,
    ),
    MockStep(
      type: ExamTaskType.ieltsSpeaking,
      taskId: 'p1',
      title: 'P1',
      section: MockSection.speaking,
    ),
    MockStep(
      type: ExamTaskType.ieltsSpeaking,
      taskId: 'p2',
      title: 'P2',
      section: MockSection.speaking,
    ),
  ],
);

void main() {
  group('mock logic', () {
    test('results come from attempts made during the mock', () {
      final MockSession session = _ielts();
      final List<ExamAttempt> attempts = <ExamAttempt>[
        _attempt(
          'old',
          ExamTaskType.ieltsTask1Academic,
          't1',
          9,
          const Duration(days: -1),
        ),
        _attempt(
          'a',
          ExamTaskType.ieltsTask1Academic,
          't1',
          6,
          const Duration(minutes: 20),
          <String, int>{'task_achievement': 5, 'lexical_resource': 6},
        ),
        _attempt(
          'b',
          ExamTaskType.ieltsTask2,
          't2',
          6.5,
          const Duration(minutes: 60),
        ),
        _attempt(
          'c',
          ExamTaskType.ieltsSpeaking,
          'p1',
          6,
          const Duration(minutes: 70),
        ),
      ];
      expect(session.nextStep(attempts), 3);
      final MockReport report = session.report(attempts);
      expect(report.results.first!.id, 'a');
      expect(report.ieltsWriting, 6.5);
      expect(report.ieltsSpeaking, 6);
      expect(report.ieltsPartialOverall, 6.5);
      expect(report.advice?.criterion, 'task_achievement');
      expect(report.complete, isFalse);
    });

    test('TOEFL sections are shown as percentages', () {
      final MockSession session = MockSession(
        exam: ExamKind.toefl,
        startedAt: _start,
        steps: const <MockStep>[
          MockStep(
            type: ExamTaskType.toeflEmail,
            taskId: 'e',
            title: 'E',
            section: MockSection.writing,
          ),
        ],
      );
      final MockReport report = session.report(<ExamAttempt>[
        _attempt('x', ExamTaskType.toeflEmail, 'e', 4, Duration.zero),
      ]);
      expect(report.toeflPercent(MockSection.writing), 80);
      expect(report.toeflPercent(MockSection.speaking), isNull);
      expect(report.ieltsWriting, isNull);
    });

    test('sessions survive a round-trip', () {
      final MockSession again = MockSession.tryParse(
        _ielts().finish(_start).toJson(),
      )!;
      expect(again.steps, hasLength(4));
      expect(again.finished, isTrue);
      expect(MockSession.tryParse(<String, dynamic>{'exam': 'X'}), isNull);
    });

    test('steps follow the exam order and prefer new tasks', () {
      final List<MockStep> toefl = pickMockSteps(
        ExamKind.toefl,
        ieltsAcademic: true,
        done: <String>{'bas-campus-life'},
      );
      expect(toefl.map((MockStep s) => s.type), mockOrder(ExamKind.toefl));
      expect(toefl.first.taskId, isNot('bas-campus-life'));
      final List<MockStep> ielts = pickMockSteps(
        ExamKind.ielts,
        ieltsAcademic: false,
        done: <String>{},
      );
      expect(ielts.first.type, ExamTaskType.ieltsTask1General);
      expect(
        ielts.skip(2).map((MockStep s) => SpeakingCatalog.byId(s.taskId)!.kind),
        <SpeakingKind>[
          SpeakingKind.ieltsPart1,
          SpeakingKind.ieltsPart2,
          SpeakingKind.ieltsPart3,
        ],
      );
    });
  });

  group('screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ExamScoreStore.key);
      await MockExamStore.clear(ExamKind.toefl);
    });

    testWidgets(
      'starting a TOEFL mock opens the first task and keeps progress',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: MockExamScreen(
              exam: ExamKind.toefl,
              profile: LearningProfile(currentLevel: 'B2'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Start the mock exam'), findsOneWidget);
        await tester.tap(find.text('Start the mock exam'));
        await tester.pumpAndSettle();
        expect(find.byType(BuildSentenceScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(BuildSentenceScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.text('0 of 5 tasks done'), findsOneWidget);
        expect(await MockExamStore.current(ExamKind.toefl), isNotNull);
      },
    );
  });
}
