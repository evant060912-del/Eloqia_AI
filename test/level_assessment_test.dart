import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_data.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_engine.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_result.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LevelAssessmentEngine _run(String declared, bool Function(int level) correct) {
  final LevelAssessmentEngine engine = LevelAssessmentEngine(
    selfReportedLevel: declared,
  );
  AssessmentQuestion? q = engine.nextQuestion();
  while (q != null) {
    final bool ok = correct(q.levelIndex);
    engine.submit(q, ok ? q.correctIndex : (q.correctIndex + 1) % 4);
    q = engine.nextQuestion();
  }
  return engine;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('question bank covers 4 skills across 6 levels with valid answers', () {
    for (final AssessmentSkill skill in AssessmentSkill.values) {
      for (int level = 0; level < assessmentLevels.length; level++) {
        expect(
          assessmentQuestionBank.where(
            (AssessmentQuestion q) => q.skill == skill && q.levelIndex == level,
          ),
          hasLength(1),
          reason: '$skill level $level',
        );
      }
    }
    for (final AssessmentQuestion q in assessmentQuestionBank) {
      expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
      expect(q.teachingPoint.trim(), isNotEmpty, reason: q.id);
    }
  });

  test('all correct answers estimate C2 and never exceed the question cap', () {
    final LevelAssessmentEngine engine = _run('A1', (_) => true);
    final LevelAssessmentResult result = engine.buildResult();

    expect(engine.answeredCount, lessThanOrEqualTo(8));
    expect(result.completed, isTrue);
    expect(result.assessedLevel, 'C2');
    expect(result.score, 100);
  });

  test('all wrong answers estimate A1', () {
    final LevelAssessmentResult result = _run('C1', (_) => false).buildResult();

    expect(result.assessedLevel, 'A1');
    expect(result.score, 0);
  });

  test('mixed answers settle near the true boundary', () {
    final LevelAssessmentResult result = _run(
      'A1',
      (int level) => level <= 2,
    ).buildResult();

    expect(result.assessedLevel, 'B1');
    expect(result.confidence, inInclusiveRange(0, 1));
  });

  test('difficulty adapts upward after a correct answer', () {
    final LevelAssessmentEngine engine = LevelAssessmentEngine(
      selfReportedLevel: 'B1',
    );
    final AssessmentQuestion first = engine.nextQuestion()!;
    expect(first.level, 'B1');
    engine.submit(first, first.correctIndex);
    expect(engine.nextQuestion()!.levelIndex, 3);
  });

  test('too few answers produce an incomplete result without a level', () {
    final LevelAssessmentEngine engine = LevelAssessmentEngine(
      selfReportedLevel: 'B1',
    );
    final AssessmentQuestion q = engine.nextQuestion()!;
    engine.submit(q, q.correctIndex);

    final LevelAssessmentResult result = engine.buildResult();
    expect(result.status, LevelAssessmentStatus.incomplete);
    expect(result.assessedLevel, isNull);
  });

  test(
    'skip and completed results persist apart from the declared level',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      expect(await LevelAssessmentService.load(), isNull);

      await LevelAssessmentService.saveSkipped(selfReportedLevel: 'b2');
      final LevelAssessmentResult? skipped =
          await LevelAssessmentService.load();
      expect(skipped?.skipped, isTrue);
      expect(skipped?.assessedLevel, isNull);
      expect(skipped?.selfReportedLevel, 'b2');

      final LevelAssessmentResult done = _run('B2', (_) => true).buildResult();
      await LevelAssessmentService.save(done);
      final LevelAssessmentResult? loaded = await LevelAssessmentService.load();
      expect(loaded?.completed, isTrue);
      expect(loaded?.assessedLevel, 'C2');
      expect(loaded?.selfReportedLevel, 'B2');
    },
  );

  test('corrupt stored data is ignored', () {
    expect(
      LevelAssessmentResult.fromJson(<String, dynamic>{
        'status': 'bogus',
        'recordedAt': 'x',
      }),
      isNull,
    );
  });
}
