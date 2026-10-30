/// Score history of exam practice and what it says about the next step.
/// Pure Dart (no Flutter import).
library;

import 'exam_formats.dart';

/// One finished exam task (a reviewed text or a Build a Sentence set).
class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.type,
    required this.taskId,
    required this.title,
    required this.value,
    required this.scaleMax,
    required this.at,
    this.criteria = const <String, int>{},
    this.criteriaMax = 0,
    this.timeLimitSeconds = 0,
    this.timeUsedSeconds = 0,
  });

  static ExamAttempt? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final ExamTaskType? type = ExamTaskType.byApiValue('${raw['type']}');
    final Object? id = raw['id'];
    final Object? value = raw['value'];
    final Object? scale = raw['scaleMax'];
    final DateTime? at = DateTime.tryParse('${raw['at']}');
    if (type == null ||
        id is! String ||
        value is! num ||
        scale is! num ||
        scale <= 0 ||
        at == null) {
      return null;
    }
    final Map<String, int> criteria = <String, int>{};
    final Object? rawCriteria = raw['criteria'];
    if (rawCriteria is Map) {
      for (final MapEntry<Object?, Object?> e in rawCriteria.entries) {
        if (e.key is String && e.value is num) {
          criteria[e.key! as String] = (e.value! as num).toInt();
        }
      }
    }
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    return ExamAttempt(
      id: id,
      type: type,
      taskId: '${raw['taskId'] ?? ''}',
      title: '${raw['title'] ?? type.label}',
      value: value.toDouble().clamp(0, scale.toDouble()),
      scaleMax: scale.toInt(),
      at: at.toUtc(),
      criteria: criteria,
      criteriaMax: asInt(raw['criteriaMax']),
      timeLimitSeconds: asInt(raw['timeLimitSeconds']),
      timeUsedSeconds: asInt(raw['timeUsedSeconds']),
    );
  }

  final String id;
  final ExamTaskType type;
  final String taskId;
  final String title;

  /// IELTS band, TOEFL task score or Build a Sentence items correct.
  final double value;
  final int scaleMax;
  final DateTime at;

  /// Criterion scores of the review (empty for Build a Sentence).
  final Map<String, int> criteria;
  final int criteriaMax;
  final int timeLimitSeconds;
  final int timeUsedSeconds;

  ExamKind get exam => type.exam;
  bool get timed => timeLimitSeconds > 0;
  bool get overTime => timed && timeUsedSeconds > timeLimitSeconds;

  /// 0–1, comparable across task types.
  double get ratio => scaleMax == 0 ? 0 : value / scaleMax;

  /// "6.5", "4", "8/10".
  String get display => type == ExamTaskType.toeflBuildSentence
      ? '${value.round()}/$scaleMax'
      : formatScore(value);

  /// Normalised criterion scores (0–1). Build a Sentence counts as the
  /// "sentence_building" criterion.
  Map<String, double> get criterionRatios {
    if (type == ExamTaskType.toeflBuildSentence) {
      return <String, double>{'sentence_building': ratio};
    }
    if (criteriaMax <= 0) return const <String, double>{};
    return <String, double>{
      for (final MapEntry<String, int> e in criteria.entries)
        e.key: (e.value / criteriaMax).clamp(0, 1).toDouble(),
    };
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.apiValue,
    'taskId': taskId,
    'title': title,
    'value': value,
    'scaleMax': scaleMax,
    'at': at.toUtc().toIso8601String(),
    'criteria': criteria,
    'criteriaMax': criteriaMax,
    'timeLimitSeconds': timeLimitSeconds,
    'timeUsedSeconds': timeUsedSeconds,
  };
}

/// "6.5" or "7".
String formatScore(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

/// Same rule as the server: nearest half band, halves rounded up.
double roundHalfBand(double value) => (value * 2 + 0.5).floorToDouble() / 2;

class ExamRecommendation {
  const ExamRecommendation({
    required this.criterion,
    required this.advice,
    required this.average,
    required this.attempts,
  });

  final String criterion;
  final CriterionAdvice advice;

  /// Average 0–1 over the recent attempts.
  final double average;
  final int attempts;
}

class ExamProgress {
  ExamProgress(Iterable<ExamAttempt> attempts)
    : attempts = List<ExamAttempt>.of(attempts)
        ..sort((ExamAttempt a, ExamAttempt b) => b.at.compareTo(a.at));

  /// Most recent first.
  final List<ExamAttempt> attempts;

  /// Attempts considered for recommendations.
  static const int window = 6;

  List<ExamAttempt> of(ExamKind exam) =>
      attempts.where((ExamAttempt a) => a.exam == exam).toList();

  List<ExamAttempt> ofType(ExamTaskType type) =>
      attempts.where((ExamAttempt a) => a.type == type).toList();

  ExamAttempt? latest(ExamTaskType type) {
    for (final ExamAttempt a in attempts) {
      if (a.type == type) return a;
    }
    return null;
  }

  double? best(ExamTaskType type) {
    double? top;
    for (final ExamAttempt a in ofType(type)) {
      if (top == null || a.value > top) top = a.value;
    }
    return top;
  }

  /// Oldest first, for a trend line.
  List<double> trend(ExamTaskType type, {int last = 10}) => ofType(
    type,
  ).take(last).map((ExamAttempt a) => a.value).toList().reversed.toList();

  /// Average normalised score per criterion over the last [window]
  /// attempts of [exam].
  Map<String, double> criterionAverages(ExamKind exam) {
    final Map<String, double> sums = <String, double>{};
    final Map<String, int> counts = <String, int>{};
    for (final ExamAttempt a in of(exam).take(window)) {
      a.criterionRatios.forEach((String name, double value) {
        sums[name] = (sums[name] ?? 0) + value;
        counts[name] = (counts[name] ?? 0) + 1;
      });
    }
    return <String, double>{
      for (final String name in sums.keys) name: sums[name]! / counts[name]!,
    };
  }

  /// The criterion to work on next: the lowest recent average. Ties go to
  /// the criterion seen most often, then alphabetical order (stable).
  ExamRecommendation? recommendation(ExamKind exam) {
    final Map<String, double> averages = criterionAverages(exam);
    if (averages.isEmpty) return null;
    final List<ExamAttempt> recent = of(exam).take(window).toList();
    int seen(String name) => recent
        .where((ExamAttempt a) => a.criterionRatios.containsKey(name))
        .length;
    final List<String> names =
        averages.keys
            .where((String n) => examCriterionAdvice.containsKey(n))
            .toList()
          ..sort((String a, String b) {
            final int byScore = averages[a]!.compareTo(averages[b]!);
            if (byScore != 0) return byScore;
            final int bySeen = seen(b).compareTo(seen(a));
            return bySeen != 0 ? bySeen : a.compareTo(b);
          });
    if (names.isEmpty) return null;
    final String weakest = names.first;
    return ExamRecommendation(
      criterion: weakest,
      advice: examCriterionAdvice[weakest]!,
      average: averages[weakest]!,
      attempts: seen(weakest),
    );
  }

  /// Unofficial IELTS Writing estimate from the latest Task 1 (Academic or
  /// General) and the latest Task 2: Task 2 counts double.
  double? ieltsWritingEstimate() {
    final ExamAttempt? task1 = _latestOf(<ExamTaskType>[
      ExamTaskType.ieltsTask1Academic,
      ExamTaskType.ieltsTask1General,
    ]);
    final ExamAttempt? task2 = latest(ExamTaskType.ieltsTask2);
    if (task1 == null || task2 == null) return null;
    return roundHalfBand((task1.value + 2 * task2.value) / 3);
  }

  /// Task types of [exam] never attempted yet.
  List<ExamTaskType> untried(ExamKind exam) => ExamTaskType.of(
    exam,
  ).where((ExamTaskType t) => latest(t) == null).toList(growable: false);

  ExamAttempt? _latestOf(List<ExamTaskType> types) {
    for (final ExamAttempt a in attempts) {
      if (types.contains(a.type)) return a;
    }
    return null;
  }
}
