import '../../core/storage/local_storage.dart';
import '../../services/mia/writing_review.dart';
import 'exam_formats.dart';
import 'exam_progress.dart';

/// Exam practice history, kept on the device under the `eloqia.` namespace
/// (so "reset my data" also clears it).
class ExamScoreStore {
  ExamScoreStore._();

  static const String key = '${LocalStorage.namespace}.exams.attempts';
  static const int schemaVersion = 1;
  static const int maxAttempts = 150;

  /// Most recent first; malformed entries are skipped.
  static Future<List<ExamAttempt>> attempts() async {
    final Map<String, dynamic>? stored = await LocalStorage.readJsonMap(key);
    final Object? items = stored?['items'];
    if (items is! List) return <ExamAttempt>[];
    return ExamProgress(
      items.map(ExamAttempt.tryParse).whereType<ExamAttempt>(),
    ).attempts;
  }

  static Future<ExamProgress> progress() async =>
      ExamProgress(await attempts());

  static Future<bool> add(ExamAttempt attempt) async {
    final List<ExamAttempt> list = (await attempts())
        .where((ExamAttempt a) => a.id != attempt.id)
        .toList();
    list.insert(0, attempt);
    return LocalStorage.saveJson(key, <String, dynamic>{
      'version': schemaVersion,
      'items': list
          .take(maxAttempts)
          .map((ExamAttempt a) => a.toJson())
          .toList(),
    });
  }

  /// The attempt for a reviewed exam text, or null when the review has no
  /// exam estimate (not an exam task, too few criteria, safety redirect).
  static ExamAttempt? fromReview({
    required String id,
    required String genre,
    required String taskId,
    required String title,
    required WritingReview review,
    required DateTime at,
    Duration? timeLimit,
    Duration? timeUsed,
  }) {
    final ExamTaskType? type = ExamTaskType.byApiValue(genre);
    final ExamEstimate? estimate = review.examEstimate;
    if (type == null || estimate == null || review.safetyRedirect) {
      return null;
    }
    int top = 0;
    final Map<String, int> criteria = <String, int>{};
    for (final WritingCriterion c in review.criteria) {
      criteria[c.criterion] = c.score;
      if (c.maxScore > top) top = c.maxScore;
    }
    return ExamAttempt(
      id: id,
      type: type,
      taskId: taskId,
      title: title,
      value: estimate.value,
      scaleMax: estimate.scaleMax,
      at: at.toUtc(),
      criteria: criteria,
      criteriaMax: top,
      timeLimitSeconds: timeLimit?.inSeconds ?? 0,
      timeUsedSeconds: timeUsed?.inSeconds ?? 0,
    );
  }
}
