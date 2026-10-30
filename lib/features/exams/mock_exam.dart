/// Full mock exams: the writing and speaking parts of the TOEFL iBT (2026
/// format) or IELTS, in order and in exam conditions, then one report.
/// Pure Dart (no Flutter import).
library;

import 'exam_formats.dart';
import 'exam_progress.dart';

enum MockSection { writing, speaking }

/// One task of the mock, already chosen (task or set id).
class MockStep {
  const MockStep({
    required this.type,
    required this.taskId,
    required this.title,
    required this.section,
  });

  static MockStep? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final ExamTaskType? type = ExamTaskType.byApiValue('${raw['type']}');
    final Object? id = raw['taskId'];
    final Object? title = raw['title'];
    final MockSection? section = MockSection.values
        .where((MockSection s) => s.name == raw['section'])
        .firstOrNull;
    if (type == null || id is! String || title is! String || section == null) {
      return null;
    }
    return MockStep(type: type, taskId: id, title: title, section: section);
  }

  final ExamTaskType type;
  final String taskId;
  final String title;
  final MockSection section;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.apiValue,
    'taskId': taskId,
    'title': title,
    'section': section.name,
  };
}

/// The order of a mock, by exam (IELTS Task 1 depends on the module).
List<ExamTaskType> mockOrder(ExamKind exam, {bool ieltsAcademic = true}) =>
    switch (exam) {
      ExamKind.toefl => const <ExamTaskType>[
        ExamTaskType.toeflBuildSentence,
        ExamTaskType.toeflEmail,
        ExamTaskType.toeflDiscussion,
        ExamTaskType.toeflListenRepeat,
        ExamTaskType.toeflInterview,
      ],
      ExamKind.ielts => <ExamTaskType>[
        ieltsAcademic
            ? ExamTaskType.ieltsTask1Academic
            : ExamTaskType.ieltsTask1General,
        ExamTaskType.ieltsTask2,
        // Speaking: Part 1, Part 2 and Part 3 are three steps of this type.
        ExamTaskType.ieltsSpeaking,
        ExamTaskType.ieltsSpeaking,
        ExamTaskType.ieltsSpeaking,
      ],
    };

MockSection sectionOf(ExamTaskType type) =>
    type.isSpeaking ? MockSection.speaking : MockSection.writing;

/// A mock in progress or finished. Results are the exam attempts saved by
/// each task after [startedAt] for that task.
class MockSession {
  const MockSession({
    required this.exam,
    required this.startedAt,
    required this.steps,
    this.finishedAt,
  });

  static MockSession? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final ExamKind? exam = ExamKind.byLabel('${raw['exam']}');
    final DateTime? started = DateTime.tryParse('${raw['startedAt']}');
    final Object? list = raw['steps'];
    if (exam == null || started == null || list is! List) return null;
    final List<MockStep> steps = list
        .map(MockStep.tryParse)
        .whereType<MockStep>()
        .toList();
    if (steps.isEmpty) return null;
    return MockSession(
      exam: exam,
      startedAt: started.toUtc(),
      steps: steps,
      finishedAt: DateTime.tryParse('${raw['finishedAt']}')?.toUtc(),
    );
  }

  final ExamKind exam;
  final DateTime startedAt;
  final List<MockStep> steps;
  final DateTime? finishedAt;

  bool get finished => finishedAt != null;

  MockSession finish(DateTime at) => MockSession(
    exam: exam,
    startedAt: startedAt,
    steps: steps,
    finishedAt: at.toUtc(),
  );

  /// The attempt that scores each step (the latest one since the start).
  List<ExamAttempt?> results(Iterable<ExamAttempt> attempts) {
    final List<ExamAttempt> since =
        attempts.where((ExamAttempt a) => !a.at.isBefore(startedAt)).toList()
          ..sort((ExamAttempt a, ExamAttempt b) => b.at.compareTo(a.at));
    return <ExamAttempt?>[
      for (final MockStep step in steps)
        since
            .where(
              (ExamAttempt a) => a.type == step.type && a.taskId == step.taskId,
            )
            .firstOrNull,
    ];
  }

  /// First step without a result, or null when all are done.
  int? nextStep(Iterable<ExamAttempt> attempts) {
    final List<ExamAttempt?> r = results(attempts);
    for (int i = 0; i < r.length; i++) {
      if (r[i] == null) return i;
    }
    return null;
  }

  MockReport report(Iterable<ExamAttempt> attempts) =>
      MockReport(this, results(attempts));

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 1,
    'exam': exam.label,
    'startedAt': startedAt.toUtc().toIso8601String(),
    if (finishedAt != null) 'finishedAt': finishedAt!.toUtc().toIso8601String(),
    'steps': steps.map((MockStep s) => s.toJson()).toList(),
  };
}

class MockReport {
  MockReport(this.session, this.results);

  final MockSession session;
  final List<ExamAttempt?> results;

  int get done => results.whereType<ExamAttempt>().length;
  bool get complete => done == results.length;

  List<ExamAttempt> _of(MockSection section) => <ExamAttempt>[
    for (int i = 0; i < results.length; i++)
      if (session.steps[i].section == section && results[i] != null)
        results[i]!,
  ];

  /// IELTS Writing band: Task 2 counts twice as much as Task 1.
  double? get ieltsWriting {
    if (session.exam != ExamKind.ielts) return null;
    final List<ExamAttempt> writing = _of(MockSection.writing);
    final ExamAttempt? t1 = writing
        .where((ExamAttempt a) => a.type != ExamTaskType.ieltsTask2)
        .firstOrNull;
    final ExamAttempt? t2 = writing
        .where((ExamAttempt a) => a.type == ExamTaskType.ieltsTask2)
        .firstOrNull;
    if (t1 == null || t2 == null) return null;
    return roundHalfBand((t1.value + 2 * t2.value) / 3);
  }

  /// IELTS Speaking band: average of the parts reviewed.
  double? get ieltsSpeaking {
    if (session.exam != ExamKind.ielts) return null;
    final List<ExamAttempt> parts = _of(MockSection.speaking);
    if (parts.isEmpty) return null;
    final double sum = parts.fold(0, (double s, ExamAttempt a) => s + a.value);
    return roundHalfBand(sum / parts.length);
  }

  /// Average of the IELTS sections taken (writing and speaking only: this is
  /// not the official overall band, which also needs reading and listening).
  double? get ieltsPartialOverall {
    final double? writing = ieltsWriting;
    final double? speaking = ieltsSpeaking;
    if (writing == null || speaking == null) return null;
    final List<double> bands = <double>[writing, speaking];
    return roundHalfBand(bands.reduce((double a, double b) => a + b) / 2);
  }

  /// TOEFL: each section as a percentage of its task maxima (indicative;
  /// the official 1–6 conversion is not public).
  int? toeflPercent(MockSection section) {
    if (session.exam != ExamKind.toefl) return null;
    final List<ExamAttempt> list = _of(section);
    if (list.isEmpty) return null;
    final double sum = list.fold(0, (double s, ExamAttempt a) => s + a.ratio);
    return (sum / list.length * 100).round();
  }

  /// Weakest criterion over the mock's own attempts.
  ExamRecommendation? get advice => ExamProgress(
    results.whereType<ExamAttempt>(),
  ).recommendation(session.exam);
}
