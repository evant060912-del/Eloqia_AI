import '../../../models/learning_memory.dart';
import '../../../services/learning/learning_memory_service.dart';
import '../../../core/storage/local_storage.dart';
import 'level_assessment_engine.dart';
import 'level_assessment_data.dart';
import 'level_assessment_result.dart';

/// Persists the level assessment separately from the learning profile so the
/// learner's declared level is never overwritten.
class LevelAssessmentService {
  const LevelAssessmentService._();

  static Future<LevelAssessmentResult?> load() async {
    final Map<String, dynamic>? json = await LocalStorage.readJsonMap(
      LocalStorage.assessmentKey,
    );

    return json == null ? null : LevelAssessmentResult.fromJson(json);
  }

  static Future<bool> save(LevelAssessmentResult result) {
    return LocalStorage.saveJson(LocalStorage.assessmentKey, result.toJson());
  }

  static Future<bool> saveSkipped({required String selfReportedLevel}) {
    return save(
      LevelAssessmentResult.skipped(selfReportedLevel: selfReportedLevel),
    );
  }

  static Future<int> saveMistakeMemories({
    required List<AssessmentAnswer> answers,
    required String assessmentId,
  }) async {
    final String normalizedId = assessmentId.trim();
    if (normalizedId.isEmpty || answers.isEmpty) {
      return 0;
    }

    final Map<AssessmentSkill, List<bool>> outcomes =
        <AssessmentSkill, List<bool>>{};
    for (final AssessmentAnswer answer in answers) {
      outcomes
          .putIfAbsent(answer.question.skill, () => <bool>[])
          .add(answer.correct);
    }

    int saved = 0;
    for (final MapEntry<AssessmentSkill, List<bool>> entry
        in outcomes.entries) {
      final int missed = entry.value.where((bool correct) => !correct).length;
      if (missed == 0) {
        continue;
      }

      final LearningMemory? memory = await MemoryService.createMemory(
        id: 'placement-$normalizedId-${entry.key.name}',
        type: LearningMemoryType.weakness,
        source: LearningMemorySource.assessment,
        content:
            'Short placement check: missed $missed of ${entry.value.length} '
            'sampled ${entry.key.name} items. This is a limited practice '
            'signal, not a proficiency diagnosis.',
        tags: <String>['assessment', entry.key.name],
        confidence: 35,
        importance: 45,
        metadata: <String, dynamic>{
          'assessmentId': normalizedId,
          'skill': entry.key.name,
          'missedItems': missed,
          'sampledItems': entry.value.length,
        },
      );
      if (memory != null) {
        saved++;
      }
    }

    return saved;
  }

  static Future<bool> clear() =>
      LocalStorage.delete(LocalStorage.assessmentKey);
}
