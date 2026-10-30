import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../theme/app_colors.dart';
import '../writing/writing_catalog.dart';
import '../writing/writing_checks.dart';
import '../writing/writing_review_screen.dart';
import '../writing/writing_store.dart';
import '../writing/writing_widgets.dart';
import '../writing/writing_workspace_screen.dart';
import '../speaking/speaking_session_screen.dart';
import '../speaking/speaking_tasks.dart';
import 'build_sentence.dart';
import 'build_sentence_screen.dart';
import 'exam_formats.dart';
import 'exam_progress.dart';
import 'exam_score_store.dart';
import 'exam_widgets.dart';

/// TOEFL or IELTS space: the official formats, the learner's score history,
/// advice on the weakest criterion and the practice tasks.
class ExamSpaceScreen extends StatefulWidget {
  const ExamSpaceScreen({
    super.key,
    required this.exam,
    required this.profile,
    this.client,
  });

  final ExamKind exam;
  final LearningProfile profile;

  /// Null without the server: tasks still work with automatic checks only.
  final MiaChatClient? client;

  @override
  State<ExamSpaceScreen> createState() => _ExamSpaceScreenState();
}

class _ExamSpaceScreenState extends State<ExamSpaceScreen> {
  ExamProgress _progress = ExamProgress(const <ExamAttempt>[]);
  bool _loading = true;

  ExamKind get _exam => widget.exam;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    ExamProgress progress;
    try {
      progress = await ExamScoreStore.progress();
    } on Object {
      progress = ExamProgress(const <ExamAttempt>[]);
    }
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _practise(ExamTaskType type) async {
    if (type.isSpeaking) {
      final SpeakingSet? set = await _pickSpeakingSet(type);
      if (set == null || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SpeakingSessionScreen(
            set: set,
            profile: widget.profile,
            client: widget.client,
          ),
        ),
      );
    } else if (type == ExamTaskType.toeflBuildSentence) {
      final SentenceSet? set = await _pickSentenceSet();
      if (set == null || !mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => BuildSentenceScreen(set: set)),
      );
    } else {
      final WritingGenre? genre = WritingGenre.byApiValue(type.apiValue);
      if (genre == null) return;
      final WritingTask? task = await _pickTask(genre);
      if (task == null || !mounted) return;
      await _openTask(task);
    }
    await _load();
  }

  Future<void> _openTask(WritingTask task) async {
    final WritingGenre? next = await Navigator.of(context).push<WritingGenre>(
      MaterialPageRoute<WritingGenre>(
        builder: (_) => WritingWorkspaceScreen(
          task: task,
          profile: widget.profile,
          client: widget.client,
        ),
      ),
    );
    if (next != null && mounted) {
      final ExamTaskType? type = next.examTask;
      if (type != null) await _practise(type);
    }
  }

  Future<WritingTask?> _pickTask(WritingGenre genre) {
    final Set<String> done = _progress.attempts
        .map((ExamAttempt a) => a.taskId)
        .toSet();
    return showModalBottomSheet<WritingTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => _PickerSheet<WritingTask>(
        title: genre.label,
        subtitle: genre.approach,
        items: WritingCatalog.tasksFor(genre),
        label: (WritingTask t) => t.title,
        detail: (WritingTask t) => t.prompt,
        tags: (WritingTask t) => <String>[
          if (t.timeLimit != null) formatClock(t.timeLimit!, withUnits: true),
          t.lengthLabel,
          if (done.contains(t.id)) 'Done',
        ],
      ),
    );
  }

  Future<SpeakingSet?> _pickSpeakingSet(ExamTaskType type) {
    final Set<String> done = _progress.attempts
        .map((ExamAttempt a) => a.taskId)
        .toSet();
    return showModalBottomSheet<SpeakingSet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => _PickerSheet<SpeakingSet>(
        title: type.label,
        subtitle: type.summary,
        items: SpeakingCatalog.setsFor(type.apiValue),
        label: (SpeakingSet s) => type == ExamTaskType.ieltsSpeaking
            ? '${s.kind.label}: ${s.title}'
            : s.title,
        detail: (SpeakingSet s) => s.intro,
        tags: (SpeakingSet s) => <String>[
          s.items.length == 1 ? '1 cue card' : '${s.items.length} items',
          if (done.contains(s.id)) 'Done',
        ],
      ),
    );
  }

  Future<SentenceSet?> _pickSentenceSet() {
    final Set<String> done = _progress.attempts
        .map((ExamAttempt a) => a.taskId)
        .toSet();
    return showModalBottomSheet<SentenceSet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => _PickerSheet<SentenceSet>(
        title: 'Build a Sentence',
        subtitle:
            '10 items in 6 min 50 s, as in the TOEFL. Tap the words in '
            'order to fill the blanks.',
        items: BuildSentenceCatalog.sets,
        label: (SentenceSet s) => s.title,
        detail: (SentenceSet s) => s.level,
        tags: (SentenceSet s) => <String>[
          '${s.items.length} items',
          if (done.contains(s.id)) 'Done',
        ],
      ),
    );
  }

  Future<void> _openAttempt(ExamAttempt attempt) async {
    if (attempt.type == ExamTaskType.toeflListenRepeat) {
      final SpeakingSet? set = SpeakingCatalog.byId(attempt.taskId);
      if (set == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SpeakingSessionScreen(
            set: set,
            profile: widget.profile,
            client: widget.client,
          ),
        ),
      );
      await _load();
      return;
    }
    if (attempt.type == ExamTaskType.toeflBuildSentence) {
      final SentenceSet? set = BuildSentenceCatalog.byId(attempt.taskId);
      if (set == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => BuildSentenceScreen(set: set)),
      );
      await _load();
      return;
    }
    WritingHistoryEntry? entry;
    for (final WritingHistoryEntry e in await WritingStore.history()) {
      if (e.id == attempt.id) entry = e;
    }
    if (!mounted) return;
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'This text is no longer on the device: only the last 20 reviews '
            'are kept. Its score stays in your history.',
          ),
        ),
      );
      return;
    }
    final WritingTask? task = WritingCatalog.byId(entry.taskId);
    final WritingReviewAction? action = await Navigator.of(context)
        .push<WritingReviewAction>(
          MaterialPageRoute<WritingReviewAction>(
            builder: (_) => WritingReviewScreen(
              taskTitle: entry!.taskTitle,
              genreLabel:
                  WritingGenre.byApiValue(entry.genre)?.label ?? 'Writing',
              text: entry.text,
              review: entry.review,
              issues: mechanicalIssues(entry.text),
              submittedAt: entry.submittedAt,
              canRevise: false,
            ),
          ),
        );
    if (!mounted || task == null) return;
    if (action == WritingReviewAction.newTask) {
      final ExamTaskType? type = task.genre.examTask;
      if (type != null) await _practise(type);
    }
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
          '${_exam.label} practice',
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
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: <Widget>[
                      Text(
                        _exam.overview,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ExamDisclaimer(exam: _exam),
                      if (widget.client == null) ...<Widget>[
                        const SizedBox(height: 14),
                        const WritingServerNotice(),
                      ],
                      const WritingSectionTitle('Your progress'),
                      ..._progressSection(),
                      const WritingSectionTitle('Practise each task'),
                      for (final ExamTaskType type in ExamTaskType.of(_exam))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TaskTypeCard(
                            type: type,
                            progress: _progress,
                            onPractise: () => _practise(type),
                          ),
                        ),
                      if (_progress.of(_exam).isNotEmpty) ...<Widget>[
                        const WritingSectionTitle('Recent scores'),
                        for (final ExamAttempt a in _progress.of(_exam).take(8))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttemptTile(
                              attempt: a,
                              onTap: () => _openAttempt(a),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _progressSection() {
    final List<ExamAttempt> mine = _progress.of(_exam);
    if (mine.isEmpty) {
      return <Widget>[
        const WritingPanel(
          child: Text(
            'No score yet. Try any task below: your scores, your trend and '
            'advice on your weakest criterion will appear here.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ];
    }
    final ExamRecommendation? advice = _progress.recommendation(_exam);
    final double? band = _exam == ExamKind.ielts
        ? _progress.ieltsWritingEstimate()
        : null;
    return <Widget>[
      if (_exam == ExamKind.ielts)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WritingPanel(
            accent: AppColors.primary,
            child: band == null
                ? const Text(
                    'Complete one Task 1 and one Task 2 to see an estimated '
                    'Writing band (Task 2 counts double).',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  )
                : Row(
                    children: <Widget>[
                      Text(
                        formatScore(band),
                        style: const TextStyle(
                          color: AppColors.primaryBright,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Estimated Writing band from your latest Task 1 '
                          'and Task 2 (Task 2 counts double). Unofficial.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      if (advice != null) _AdviceCard(advice: advice, onPractise: _practise),
      if (_progress.untried(_exam).isNotEmpty) ...<Widget>[
        const SizedBox(height: 10),
        Text(
          'Not tried yet: '
          '${_progress.untried(_exam).map((ExamTaskType t) => t.label).join(', ')}.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    ];
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice, required this.onPractise});

  final ExamRecommendation advice;
  final ValueChanged<ExamTaskType> onPractise;

  @override
  Widget build(BuildContext context) {
    final int percent = (advice.average * 100).round();
    return WritingPanel(
      accent: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Work on: ${advice.advice.label}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${advice.advice.meaning} Your weakest area over your last '
            '${advice.attempts == 1 ? 'attempt' : '${advice.attempts} attempts'}'
            ' ($percent% of the maximum).',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          for (final String tip in advice.advice.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            onPressed: () => onPractise(advice.advice.practice),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('Practise: ${advice.advice.practice.label}'),
          ),
        ],
      ),
    );
  }
}

class _TaskTypeCard extends StatelessWidget {
  const _TaskTypeCard({
    required this.type,
    required this.progress,
    required this.onPractise,
  });

  final ExamTaskType type;
  final ExamProgress progress;
  final VoidCallback onPractise;

  @override
  Widget build(BuildContext context) {
    final ExamAttempt? latest = progress.latest(type);
    final List<double> trend = progress.trend(type);
    final int count = type.isWriting
        ? WritingCatalog.tasksFor(
            WritingGenre.byApiValue(type.apiValue)!,
          ).length
        : type.isSpeaking
        ? SpeakingCatalog.setsFor(type.apiValue).length
        : BuildSentenceCatalog.sets.length;
    return WritingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      type.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.summary,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (latest != null) ...<Widget>[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      latest.display,
                      style: const TextStyle(
                        color: AppColors.primaryBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      type.isWriting ||
                              type == ExamTaskType.toeflInterview ||
                              type == ExamTaskType.ieltsSpeaking
                          ? 'last of ${type.scaleMax}'
                          : 'last',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              WritingTag(type.timeLabel),
              if (type.minWords > 0) WritingTag('${type.minWords}+ words'),
              WritingTag(
                type.isWriting
                    ? '$count tasks'
                    : type.isSpeaking
                    ? '$count sets'
                    : '$count sets of 10',
              ),
              if (type.isSpeaking)
                const WritingTag('Speaking', color: AppColors.speaking),
            ],
          ),
          if (trend.length > 1) ...<Widget>[
            const SizedBox(height: 10),
            ScoreTrend(values: trend, scaleMax: type.scaleMax),
          ],
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 6),
              iconColor: AppColors.textMuted,
              collapsedIconColor: AppColors.textMuted,
              title: const Text(
                'Format',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: <Widget>[
                for (final String line in type.format)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          '•  ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              onPressed: onPractise,
              child: const Text(
                'Practise',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt, required this.onTap});

  final ExamAttempt attempt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: WritingPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    attempt.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${attempt.type.label}, ${describeWhen(attempt.at)}'
                    '${attempt.overTime ? ', over time' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              attempt.display,
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing tasks or sets to choose from.
class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.label,
    required this.detail,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final List<T> items;
  final String Function(T) label;
  final String Function(T) detail;
  final List<String> Function(T) tags;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white18,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            for (final T item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            label(item),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detail(item),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              for (final String tag in tags(item))
                                WritingTag(
                                  tag,
                                  color: tag == 'Done'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
