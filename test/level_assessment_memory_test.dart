import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_data.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_engine.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_service.dart';
import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/models/learning_memory.dart';
import 'package:eloqia_ai/services/learning/learning_memory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'stores only aggregate missed-skill signals in existing memory storage',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.clearEloqiaData();
      final AssessmentQuestion grammarA1 = assessmentQuestionBank.firstWhere(
        (AssessmentQuestion question) => question.id == 'grammar_a1',
      );
      final AssessmentQuestion grammarA2 = assessmentQuestionBank.firstWhere(
        (AssessmentQuestion question) => question.id == 'grammar_a2',
      );
      final AssessmentQuestion vocabularyA1 = assessmentQuestionBank.firstWhere(
        (AssessmentQuestion question) => question.id == 'vocabulary_a1',
      );

      final int saved = await LevelAssessmentService.saveMistakeMemories(
        assessmentId: 'test-assessment-1',
        answers: <AssessmentAnswer>[
          AssessmentAnswer(question: grammarA1, correct: false),
          AssessmentAnswer(question: grammarA2, correct: false),
          AssessmentAnswer(question: vocabularyA1, correct: true),
        ],
      );

      expect(saved, 1);
      final List<LearningMemory> memories =
          await MemoryService.getActiveMemories();
      expect(memories, hasLength(1));
      expect(memories.single.type, LearningMemoryType.weakness);
      expect(memories.single.source, LearningMemorySource.assessment);
      expect(
        memories.single.content,
        contains('missed 2 of 2 sampled grammar items'),
      );
      expect(memories.single.content, contains('not a proficiency diagnosis'));
      expect(memories.single.metadata['missedItems'], 2);
    },
  );

  test(
    'does not create weakness memories when sampled answers were correct',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.clearEloqiaData();
      final AssessmentQuestion question = assessmentQuestionBank.first;

      final int saved = await LevelAssessmentService.saveMistakeMemories(
        assessmentId: 'test-assessment-2',
        answers: <AssessmentAnswer>[
          AssessmentAnswer(question: question, correct: true),
        ],
      );

      expect(saved, 0);
      expect(await MemoryService.getActiveMemories(), isEmpty);
    },
  );
}
