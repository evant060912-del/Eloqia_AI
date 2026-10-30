import 'package:flutter/material.dart';

import '../../core/storage/local_storage.dart';
import '../../models/learning_profile.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../theme/app_colors.dart';
import '../speaking/speaking_session_screen.dart';
import '../speaking/speaking_tasks.dart';
import '../writing/writing_catalog.dart';
import '../writing/writing_widgets.dart';
import '../writing/writing_workspace_screen.dart';
import 'build_sentence.dart';
import 'build_sentence_screen.dart';
import 'exam_formats.dart';
import 'exam_progress.dart';
import 'exam_score_store.dart';
import 'exam_widgets.dart';
import 'mock_exam.dart';

/// Mock exams on the device: one in progress per exam, and past reports.
class MockExamStore {
  MockExamStore._();

  static String currentKey(ExamKind exam) =>
      '${LocalStorage.namespace}.exams.mock.${exam.name}';
  static String historyKey(ExamKind exam) =>
      '${LocalStorage.namespace}.exams.mock.${exam.name}.history';
  static const int maxHistory = 10;

  static Future<MockSession?> current(ExamKind exam) async =>
      MockSession.tryParse(await LocalStorage.readJsonMap(currentKey(exam)));

  static Future<bool> save(MockSession session) =>
      LocalStorage.saveJson(currentKey(session.exam), session.toJson());

  static Future<void> clear(ExamKind exam) =>
      LocalStorage.delete(currentKey(exam));

  static Future<List<MockSession>> history(ExamKind exam) async {
    final Map<String, dynamic>? stored = await LocalStorage.readJsonMap(
      historyKey(exam),
    );
    final Object? items = stored?['items'];
    if (items is! List) return <MockSession>[];
    return items.map(MockSession.tryParse).whereType<MockSession>().toList();
  }

  static Future<void> archive(MockSession session) async {
    final List<MockSession> list = await history(session.exam)
      ..insert(0, session);
    await LocalStorage.saveJson(historyKey(session.exam), <String, dynamic>{
      'items': list
          .take(maxHistory)
          .map((MockSession s) => s.toJson())
          .toList(),
    });
    await clear(session.exam);
  }
}

/// Chooses the tasks of a new mock, preferring ones not done yet.
List<MockStep> pickMockSteps(
  ExamKind exam, {
  required bool ieltsAcademic,
  required Set<String> done,
}) {
  T pick<T>(List<T> items, String Function(T) id) => items.firstWhere(
    (T item) => !done.contains(id(item)),
    orElse: () => items.first,
  );
  final List<MockStep> steps = <MockStep>[];
  int ieltsPart = 0;
  for (final ExamTaskType type in mockOrder(
    exam,
    ieltsAcademic: ieltsAcademic,
  )) {
    if (type == ExamTaskType.toeflBuildSentence) {
      final SentenceSet set = pick(
        BuildSentenceCatalog.sets,
        (SentenceSet s) => s.id,
      );
      steps.add(
        MockStep(
          type: type,
          taskId: set.id,
          title: 'Build a Sentence: ${set.title}',
          section: MockSection.writing,
        ),
      );
    } else if (type.isWriting) {
      final WritingTask task = pick(
        WritingCatalog.tasksFor(WritingGenre.byApiValue(type.apiValue)!),
        (WritingTask t) => t.id,
      );
      steps.add(
        MockStep(
          type: type,
          taskId: task.id,
          title: '${type.label}: ${task.title}',
          section: MockSection.writing,
        ),
      );
    } else {
      List<SpeakingSet> sets = SpeakingCatalog.setsFor(type.apiValue);
      if (type == ExamTaskType.ieltsSpeaking) {
        final SpeakingKind kind = <SpeakingKind>[
          SpeakingKind.ieltsPart1,
          SpeakingKind.ieltsPart2,
          SpeakingKind.ieltsPart3,
        ][ieltsPart++ % 3];
        sets = sets.where((SpeakingSet s) => s.kind == kind).toList();
      }
      final SpeakingSet set = pick(sets, (SpeakingSet s) => s.id);
      steps.add(
        MockStep(
          type: type,
          taskId: set.id,
          title: '${set.kind.label}: ${set.title}',
          section: MockSection.speaking,
        ),
      );
    }
  }
  return steps;
}

class MockExamScreen extends StatefulWidget {
  const MockExamScreen({
    super.key,
    required this.exam,
    required this.profile,
    this.client,
  });

  final ExamKind exam;
  final LearningProfile profile;
  final MiaChatClient? client;

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  MockSession? _session;
  List<ExamAttempt> _attempts = <ExamAttempt>[];
  List<MockSession> _history = <MockSession>[];
  bool _loading = true;
  bool _academic = true;

  ExamKind get _exam => widget.exam;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    MockSession? session;
    List<ExamAttempt> attempts = <ExamAttempt>[];
    List<MockSession> history = <MockSession>[];
    try {
      session = await MockExamStore.current(_exam);
      attempts = await ExamScoreStore.attempts();
      history = await MockExamStore.history(_exam);
      if (session != null && session.nextStep(attempts) == null) {
        final MockSession done = session.finish(DateTime.now());
        await MockExamStore.archive(done);
        history = <MockSession>[done, ...history];
        session = null;
      }
    } on Object {
      // Show what could be read.
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _attempts = attempts;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final Set<String> done = _attempts.map((ExamAttempt a) => a.taskId).toSet();
    final MockSession session = MockSession(
      exam: _exam,
      startedAt: DateTime.now().toUtc(),
      steps: pickMockSteps(_exam, ieltsAcademic: _academic, done: done),
    );
    await MockExamStore.save(session);
    await _load();
    if (mounted) await _openStep(0);
  }

  Future<void> _openStep(int index) async {
    final MockSession? session = _session;
    if (session == null) return;
    final MockStep step = session.steps[index];
    Widget? screen;
    if (step.type == ExamTaskType.toeflBuildSentence) {
      final SentenceSet? set = BuildSentenceCatalog.byId(step.taskId);
      if (set != null) screen = BuildSentenceScreen(set: set);
    } else if (step.type.isWriting) {
      final WritingTask? task = WritingCatalog.byId(step.taskId);
      if (task != null) {
        screen = WritingWorkspaceScreen(
          task: task,
          profile: widget.profile,
          client: widget.client,
          autoStartTimer: true,
        );
      }
    } else {
      final SpeakingSet? set = SpeakingCatalog.byId(step.taskId);
      if (set != null) {
        screen = SpeakingSessionScreen(
          set: set,
          profile: widget.profile,
          client: widget.client,
          autoReview: true,
        );
      }
    }
    if (screen == null) return;
    final Widget page = screen;
    await Navigator.of(
      context,
    ).push<Object?>(MaterialPageRoute<Object?>(builder: (_) => page));
    await _load();
  }

  Future<void> _abandon() async {
    await MockExamStore.clear(_exam);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          '${_exam.label} mock exam',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: _session == null ? _intro() : _progress(),
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _intro() {
    final List<ExamTaskType> order = mockOrder(_exam, ieltsAcademic: _academic);
    final int minutes = order.toSet().fold(
      0,
      (int m, ExamTaskType t) => m + t.timeLimit.inMinutes,
    );
    return <Widget>[
      Text(
        _exam == ExamKind.toefl
            ? 'The Writing and Speaking sections in the 2026 order: Build a '
                  'Sentence, an email, an academic discussion, Listen and '
                  'Repeat, then the interview.'
            : 'Writing (Task 1, then Task 2) and the three parts of '
                  'Speaking, in exam order.',
        style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      const SizedBox(height: 8),
      Text(
        'About $minutes minutes. Official timers start by themselves; you '
        'can stop and come back, your progress is kept. Reading and '
        'Listening sections are not part of this mock.',
        style: const TextStyle(color: AppColors.textMuted, height: 1.45),
      ),
      const SizedBox(height: 10),
      ExamDisclaimer(exam: _exam),
      if (widget.client == null) ...<Widget>[
        const SizedBox(height: 12),
        const WritingServerNotice(),
      ],
      if (_exam == ExamKind.ielts) ...<Widget>[
        const WritingSectionTitle('Module'),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Academic'),
              selected: _academic,
              onSelected: (_) => setState(() => _academic = true),
            ),
            ChoiceChip(
              label: const Text('General Training'),
              selected: !_academic,
              onSelected: (_) => setState(() => _academic = false),
            ),
          ],
        ),
      ],
      const SizedBox(height: 22),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _start,
        child: const Text(
          'Start the mock exam',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      if (_history.isNotEmpty) ...<Widget>[
        const WritingSectionTitle('Past mock exams'),
        for (final MockSession s in _history)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReportCard(report: s.report(_attempts)),
          ),
      ],
    ];
  }

  List<Widget> _progress() {
    final MockSession session = _session!;
    final List<ExamAttempt?> results = session.results(_attempts);
    final int? next = session.nextStep(_attempts);
    return <Widget>[
      Text(
        '${results.whereType<ExamAttempt>().length} of '
        '${session.steps.length} tasks done',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'A task counts once it has a score (for writing and interviews, '
        'after Mia’s review).',
        style: TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      const SizedBox(height: 14),
      for (int i = 0; i < session.steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _StepTile(
            step: session.steps[i],
            number: i + 1,
            result: results[i],
            current: i == next,
            onOpen: () => _openStep(i),
          ),
        ),
      const SizedBox(height: 12),
      if (next != null)
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _openStep(next),
          child: Text(
            'Continue: ${session.steps[next].title}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      const SizedBox(height: 8),
      TextButton(onPressed: _abandon, child: const Text('Abandon this mock')),
    ];
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.number,
    required this.result,
    required this.current,
    required this.onOpen,
  });

  final MockStep step;
  final int number;
  final ExamAttempt? result;
  final bool current;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ExamAttempt? r = result;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: r == null ? onOpen : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: current
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.white08,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: r != null
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.white08,
                child: r != null
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.success,
                      )
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${step.section == MockSection.writing ? 'Writing' : 'Speaking'}'
                      ' · ${step.type.timeLabel}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (r != null)
                Text(
                  r.display,
                  style: const TextStyle(
                    color: AppColors.primaryBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Report of a finished (or partly finished) mock.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final MockReport report;

  @override
  Widget build(BuildContext context) {
    final MockSession s = report.session;
    final List<(String, String)> lines = s.exam == ExamKind.ielts
        ? <(String, String)>[
            if (report.ieltsWriting != null)
              ('Writing band', formatScore(report.ieltsWriting!)),
            if (report.ieltsSpeaking != null)
              ('Speaking band', formatScore(report.ieltsSpeaking!)),
            if (report.ieltsPartialOverall != null)
              (
                'Writing and Speaking average',
                formatScore(report.ieltsPartialOverall!),
              ),
          ]
        : <(String, String)>[
            for (final MockSection section in MockSection.values)
              if (report.toeflPercent(section) != null)
                (
                  section == MockSection.writing
                      ? 'Writing tasks'
                      : 'Speaking tasks',
                  '${report.toeflPercent(section)}%',
                ),
          ];
    final ExamRecommendation? advice = report.advice;
    return WritingPanel(
      accent: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${describeWhen(s.finishedAt ?? s.startedAt)} · '
            '${report.done}/${report.results.length} tasks',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          for (final (String label, String value) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          for (int i = 0; i < s.steps.length; i++)
            Text(
              '${s.steps[i].title}: ${report.results[i]?.display ?? '—'}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          if (advice != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Work on: ${advice.advice.label}. ${advice.advice.tips.first}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            s.exam == ExamKind.ielts
                ? 'Unofficial. The official overall band also needs Reading '
                      'and Listening.'
                : 'Unofficial percentages of the task maxima; the official '
                      '1–6 section scores use a conversion that is not public.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
