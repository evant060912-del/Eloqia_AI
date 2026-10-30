import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../services/learning/learning_profile_service.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../services/mia/writing_review.dart';
import '../../theme/app_colors.dart';
import '../exams/exam_formats.dart';
import '../exams/exam_space_screen.dart';
import 'writing_catalog.dart';
import 'writing_checks.dart';
import 'writing_review_screen.dart';
import 'writing_store.dart';
import 'writing_widgets.dart';
import 'writing_workspace_screen.dart';

/// Entry point of the Writing Studio: 13 kinds of writing, TOEFL and IELTS
/// preparation, drafts in progress and past reviews.
class WritingStudioScreen extends StatefulWidget {
  const WritingStudioScreen({
    super.key,
    this.profile,
    this.client,
    this.initialGenre,
  });

  final LearningProfile? profile;

  /// Injected in tests; built from `--dart-define` otherwise.
  final MiaChatClient? client;

  /// Opens this genre's task list right away (e.g. from a review).
  final WritingGenre? initialGenre;

  @override
  State<WritingStudioScreen> createState() => _WritingStudioScreenState();
}

class _WritingStudioScreenState extends State<WritingStudioScreen> {
  late final MiaChatClient? _client;
  LearningProfile? _profile;
  WritingBand _band = WritingBand.foundation;
  List<WritingDraft> _drafts = <WritingDraft>[];
  List<WritingHistoryEntry> _history = <WritingHistoryEntry>[];
  bool _loading = true;
  bool _bandChosen = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? MiaChatClient.fromEnvironment();
    _load().then((_) {
      final WritingGenre? genre = widget.initialGenre;
      if (genre != null && mounted) _openGenre(genre);
    });
  }

  @override
  void dispose() {
    if (widget.client == null) _client?.close();
    super.dispose();
  }

  Future<void> _load() async {
    LearningProfile profile;
    try {
      profile = widget.profile ?? await LearningProfileService.getProfile();
    } on Object {
      profile = LearningProfile();
    }
    final List<WritingDraft> drafts = await WritingStore.drafts();
    final List<WritingHistoryEntry> history = await WritingStore.history();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      if (!_bandChosen) _band = WritingBand.forLevel(profile.currentLevel);
      _drafts = drafts
          .where((WritingDraft d) => WritingCatalog.byId(d.taskId) != null)
          .toList();
      _history = history;
      _loading = false;
    });
  }

  Future<void> _openTask(WritingTask task, {String? initialText}) async {
    final LearningProfile? profile = _profile;
    if (profile == null) return;
    final WritingGenre? next = await Navigator.of(context).push<WritingGenre>(
      MaterialPageRoute<WritingGenre>(
        builder: (_) => WritingWorkspaceScreen(
          task: task,
          profile: profile,
          client: _client,
          initialText: initialText,
        ),
      ),
    );
    await _load();
    if (next != null && mounted) await _openGenre(next);
  }

  Future<void> _openGenre(WritingGenre genre) async {
    final WritingTask? task = await showModalBottomSheet<WritingTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TaskPicker(genre: genre, band: _band, drafts: _drafts),
    );
    if (task != null && mounted) await _openTask(task);
  }

  Future<void> _openExam(ExamKind exam) async {
    final LearningProfile? profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExamSpaceScreen(exam: exam, profile: profile, client: _client),
      ),
    );
    await _load();
  }

  Future<void> _openHistory(WritingHistoryEntry entry) async {
    final WritingTask? task = WritingCatalog.byId(entry.taskId);
    final WritingReviewAction? action = await Navigator.of(context)
        .push<WritingReviewAction>(
          MaterialPageRoute<WritingReviewAction>(
            builder: (_) => WritingReviewScreen(
              taskTitle: entry.taskTitle,
              genreLabel:
                  WritingGenre.byApiValue(entry.genre)?.label ?? 'Writing',
              text: entry.text,
              review: entry.review,
              issues: mechanicalIssues(entry.text),
              submittedAt: entry.submittedAt,
              canRevise: task != null,
            ),
          ),
        );
    if (!mounted || task == null) return;
    if (action == WritingReviewAction.revise) {
      await _openTask(task, initialText: entry.text);
    } else if (action == WritingReviewAction.newTask) {
      await _openGenre(task.genre);
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
        title: const Text(
          'Writing Studio',
          style: TextStyle(fontWeight: FontWeight.w900),
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
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: <Widget>[
                      _Intro(
                        band: _band,
                        onBand: (WritingBand band) => setState(() {
                          _band = band;
                          _bandChosen = true;
                        }),
                      ),
                      if (_client == null) ...<Widget>[
                        const SizedBox(height: 16),
                        const WritingServerNotice(),
                      ],
                      if (_drafts.isNotEmpty) ...<Widget>[
                        const WritingSectionTitle('Continue writing'),
                        for (final WritingDraft d in _drafts.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DraftTile(
                              draft: d,
                              onTap: () =>
                                  _openTask(WritingCatalog.byId(d.taskId)!),
                            ),
                          ),
                      ],
                      for (final WritingGroup group in WritingGroup.values)
                        if (group != WritingGroup.exams)
                          ..._groupSection(group),
                      const WritingSectionTitle('Exam preparation'),
                      _ExamCards(onOpen: _openExam),
                      if (_history.isNotEmpty) ...<Widget>[
                        const WritingSectionTitle('Your reviews'),
                        for (final WritingHistoryEntry e in _history.take(8))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HistoryTile(
                              entry: e,
                              onTap: () => _openHistory(e),
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

  List<Widget> _groupSection(WritingGroup group) {
    final List<WritingGenre> genres = WritingGenre.values
        .where((WritingGenre g) => g.group == group)
        .toList();
    return <Widget>[
      WritingSectionTitle(group.label),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoColumns = constraints.maxWidth >= 680;
          final double width = twoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final WritingGenre genre in genres)
                SizedBox(
                  width: width,
                  child: _GenreTile(
                    genre: genre,
                    tasks: WritingCatalog.tasksFor(genre, band: _band).length,
                    onTap: () => _openGenre(genre),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }
}

class _ExamCards extends StatelessWidget {
  const _ExamCards({required this.onOpen});

  final ValueChanged<ExamKind> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 680;
        final double width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final ExamKind exam in ExamKind.values)
              SizedBox(
                width: width,
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onOpen(exam),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.academic.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.academic.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: AppColors.academic,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${exam.label} Writing',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ExamTaskType.of(exam)
                                      .map((ExamTaskType t) => t.label)
                                      .join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
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

class _Intro extends StatelessWidget {
  const _Intro({required this.band, required this.onBand});

  final WritingBand band;
  final ValueChanged<WritingBand> onBand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Write, then learn from Mia’s review.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a kind of writing. Mia scores it with criteria made for that '
          'genre, quotes your exact words and explains every important '
          'change.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<WritingBand>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              selectedForegroundColor: AppColors.textOnPrimary,
              selectedBackgroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.white18),
            ),
            segments: <ButtonSegment<WritingBand>>[
              for (final WritingBand b in WritingBand.values)
                ButtonSegment<WritingBand>(
                  value: b,
                  label: Text('${b.label}  ${b.levels}'),
                ),
            ],
            selected: <WritingBand>{band},
            onSelectionChanged: (Set<WritingBand> s) => onBand(s.first),
          ),
        ),
      ],
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({
    required this.genre,
    required this.tasks,
    required this.onTap,
  });

  final WritingGenre genre;
  final int tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.white08),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.writing.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(genre.icon, color: AppColors.writing),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      genre.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      genre.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tasks == 1 ? '1 task' : '$tasks tasks',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onTap});

  final WritingDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final WritingTask task = WritingCatalog.byId(draft.taskId)!;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: WritingPanel(
        accent: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.genre.label}, ${countWords(draft.text)} words, '
                    'saved ${describeWhen(draft.updatedAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final WritingHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int? percent = entry.review?.scorePercent;
    final ExamEstimate? exam = entry.review?.examEstimate;
    final String? score = exam != null
        ? '${exam.exam} ${exam.display}'
        : percent == null
        ? null
        : '$percent%';
    final String status = entry.review == null
        ? 'Automatic checks only'
        : '${entry.review!.corrections.length} corrections';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: WritingPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.taskTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$status, ${describeWhen(entry.submittedAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (score != null)
              Text(
                score,
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

/// Bottom sheet listing the tasks of one genre (learner's band first).
class _TaskPicker extends StatefulWidget {
  const _TaskPicker({
    required this.genre,
    required this.band,
    required this.drafts,
  });

  final WritingGenre genre;
  final WritingBand band;
  final List<WritingDraft> drafts;

  @override
  State<_TaskPicker> createState() => _TaskPickerState();
}

class _TaskPickerState extends State<_TaskPicker> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    // Exam tasks follow the exam's format, not a level band: list them all.
    final bool exam = widget.genre.isExam;
    final List<WritingTask> mine = WritingCatalog.tasksFor(
      widget.genre,
      band: exam ? null : widget.band,
    );
    final List<WritingTask> others = exam
        ? const <WritingTask>[]
        : WritingCatalog.tasksFor(
            widget.genre,
          ).where((WritingTask t) => t.band != widget.band).toList();
    final Set<String> drafted = widget.drafts
        .map((WritingDraft d) => d.taskId)
        .toSet();

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
              widget.genre.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.genre.approach,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            for (final String objective in widget.genre.objectives)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.writing,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        objective,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            WritingSectionTitle(
              exam ? 'Practice tasks' : 'For ${widget.band.levels}',
            ),
            if (mine.isEmpty)
              const Text(
                'No task at this level yet: choose one below.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            for (final WritingTask task in mine)
              _TaskCard(task: task, hasDraft: drafted.contains(task.id)),
            if (others.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Hide other levels' : 'Show other levels',
                ),
              ),
            if (_showAll)
              for (final WritingTask task in others)
                _TaskCard(task: task, hasDraft: drafted.contains(task.id)),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.hasDraft});

  final WritingTask task;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (hasDraft)
                      const WritingTag('Draft', color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.prompt,
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
                    WritingTag(task.band.levels),
                    WritingTag(task.lengthLabel),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
