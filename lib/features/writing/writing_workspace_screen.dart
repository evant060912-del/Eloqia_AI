import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../services/mia/mia_learning_notes.dart';
import '../../services/mia/mia_session_recorder.dart';
import '../../services/mia/writing_review.dart';
import '../../theme/app_colors.dart';
import '../tutors/mia/widgets/mia_presence.dart';
import 'writing_catalog.dart';
import 'writing_checks.dart';
import 'writing_review_screen.dart';
import 'writing_rewards.dart';
import 'writing_store.dart';
import 'writing_widgets.dart';

/// Writing workspace: the brief, the editor and the submission to Mia.
///
/// Pops with a [WritingGenre] when the learner asks for a new task of that
/// genre from the review.
class WritingWorkspaceScreen extends StatefulWidget {
  const WritingWorkspaceScreen({
    super.key,
    required this.task,
    required this.profile,
    required this.client,
    this.initialText,
    this.notes,
  });

  final WritingTask task;
  final LearningProfile profile;

  /// Null when the app runs without the server: automatic checks only.
  final MiaChatClient? client;

  /// Text to revise (from a past review); otherwise the saved draft.
  final String? initialText;
  final MiaLearningNotes? notes;

  @override
  State<WritingWorkspaceScreen> createState() => _WritingWorkspaceScreenState();
}

class _WritingWorkspaceScreenState extends State<WritingWorkspaceScreen>
    with WidgetsBindingObserver {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _saveTimer;
  late final DateTime _openedAt = DateTime.now();

  bool _ready = false;
  bool _saved = true;
  bool _submitting = false;
  bool _briefOpen = false;
  int _hintsShown = 0;
  int _generation = 0;

  /// Last text sent for review: not saved again as a draft when leaving.
  String? _submittedText;

  WritingTask get _task => widget.task;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  Future<void> _restore() async {
    String initial = widget.initialText ?? '';
    if (widget.initialText == null) {
      try {
        initial = (await WritingStore.draftFor(_task.id))?.text ?? '';
      } on Object {
        initial = '';
      }
    }
    if (!mounted) return;
    _text.text = initial;
    _text.addListener(_onEdited);
    setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _saveNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _saveNow();
    _generation++;
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onEdited() {
    if (_saved) setState(() => _saved = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  void _saveNow() {
    if (!_ready) return;
    _saveTimer?.cancel();
    final String text = _text.text;
    if (text == _submittedText) return;
    WritingStore.saveDraft(_task.id, text).then((bool ok) {
      if (ok && mounted && _text.text == text) setState(() => _saved = true);
    });
  }

  // ------------------------------------------------------------------ actions

  void _showChecks() {
    final String text = _text.text;
    final List<MechanicalIssue> issues = mechanicalIssues(text);
    final WritingStats stats = WritingStats.of(text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (BuildContext context, ScrollController controller) =>
            ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: <Widget>[
                const Text(
                  'Automatic checks',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.words} words, ${stats.sentences} sentences, '
                  '${stats.paragraphs} paragraphs. These rules are certain; '
                  'grammar in context, vocabulary and organisation are part '
                  'of Mia’s review.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                if (issues.isEmpty)
                  const WritingPanel(
                    accent: AppColors.success,
                    child: Text(
                      'No mechanical issue found.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                for (final MechanicalIssue issue in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MechanicalIssueCard(issue: issue, text: text),
                  ),
              ],
            ),
      ),
    );
  }

  Future<bool> _confirmShort(int words) async {
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Shorter than the target'),
        content: Text(
          'Your text has $words words; this task asks for '
          '${_task.lengthLabel.toLowerCase()}. Mia can still review it, but '
          'the task only counts for XP from ${_task.countedWords} words.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep writing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit anyway'),
          ),
        ],
      ),
    );
    return go ?? false;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final String text = _text.text.trim();
    final int words = countWords(text);
    if (words == 0) {
      _snack('Write your text first.');
      return;
    }
    if (words < _task.minWords && !await _confirmShort(words)) return;
    if (!mounted) return;
    _saveNow();
    FocusScope.of(context).unfocus();

    final int generation = ++_generation;
    setState(() => _submitting = true);

    WritingReview? review;
    final MiaChatClient? client = widget.client;
    if (client != null) {
      try {
        List<String> difficulties = <String>[];
        try {
          difficulties = await (widget.notes ?? MiaLearningNotes())
              .difficultiesForMia();
        } on Object {
          difficulties = <String>[];
        }
        review = await client.reviewWriting(
          genre: _task.genre.apiValue,
          taskId: _task.id,
          taskTitle: _task.title,
          prompt: _task.prompt,
          minWords: _task.minWords,
          maxWords: _task.maxWords,
          text: text,
          profile: widget.profile,
          sourceText: _task.sourceText,
          knownDifficulties: difficulties,
        );
      } on MiaChatException catch (error) {
        _failed(generation, error.message);
        return;
      } on Object {
        _failed(generation, const MiaChatException('unknown').message);
        return;
      }
    }
    if (!mounted || generation != _generation) return;

    MiaSessionRecord record = WritingRewards.nothing;
    try {
      record = await WritingRewards.record(
        task: _task,
        text: text,
        profile: widget.profile,
        duration: DateTime.now().difference(_openedAt),
        review: review,
      );
      if (review != null) {
        await WritingRewards.remember(
          review,
          sessionId: WritingRewards.sessionIdFor(_task, DateTime.now()),
          notes: widget.notes,
        );
      }
    } on Object {
      // Progress is best effort; the review itself is never lost.
    }

    final DateTime now = DateTime.now().toUtc();
    await WritingStore.addToHistory(
      WritingHistoryEntry(
        id: 'w-${_task.id}-${now.microsecondsSinceEpoch}',
        taskId: _task.id,
        genre: _task.genre.apiValue,
        taskTitle: _task.title,
        text: text,
        submittedAt: now,
        review: review,
        xpAwarded: record.xpAwarded,
      ),
    );
    _submittedText = _text.text;
    await WritingStore.clearDraft(_task.id);
    if (!mounted || generation != _generation) return;
    setState(() {
      _submitting = false;
      _saved = true;
    });

    final WritingReviewAction? action = await Navigator.of(context)
        .push<WritingReviewAction>(
          MaterialPageRoute<WritingReviewAction>(
            builder: (_) => WritingReviewScreen(
              taskTitle: _task.title,
              genreLabel: _task.genre.label,
              text: text,
              review: review,
              issues: mechanicalIssues(text),
              record: record,
              submittedAt: now,
              canRevise: true,
              offline: client == null,
            ),
          ),
        );
    if (!mounted) return;
    switch (action) {
      case WritingReviewAction.revise:
        _focus.requestFocus();
      case WritingReviewAction.newTask:
        Navigator.of(context).pop(_task.genre);
      case WritingReviewAction.done:
      case null:
        Navigator.of(context).pop();
    }
  }

  void _failed(int generation, String message) {
    if (!mounted || generation != _generation) return;
    setState(() => _submitting = false);
    _snack(message, retry: true);
  }

  void _snack(String message, {bool retry = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(message),
          action: retry
              ? SnackBarAction(label: 'Retry', onPressed: _submit)
              : null,
        ),
      );
  }

  // ---------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _task.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              '${_task.genre.label}, ${_task.band.levels}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _saved ? 'Draft saved' : 'Saving…',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: !_ready
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth >= 960) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          width: 380,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 8, 24),
                            child: _brief(expanded: true),
                          ),
                        ),
                        Expanded(child: _editorColumn()),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.45,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: _brief(expanded: _briefOpen),
                        ),
                      ),
                      Expanded(child: _editorColumn()),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _brief({required bool expanded}) {
    final List<String> hints = _task.hints;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WritingPanel(
          accent: AppColors.writing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_task.reader.isNotEmpty) ...<Widget>[
                Text(
                  'For: ${_task.reader}',
                  style: const TextStyle(
                    color: AppColors.writing,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                _task.prompt,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  WritingTag(_task.lengthLabel),
                  if (MediaQuery.sizeOf(context).width < 960)
                    TextButton.icon(
                      onPressed: () => setState(() => _briefOpen = !_briefOpen),
                      icon: Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                      label: Text(expanded ? 'Hide brief' : 'Goals and hints'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_task.sourceText != null) ...<Widget>[
          const WritingSectionTitle('Text to summarise'),
          WritingPanel(
            child: SelectableText(
              _task.sourceText!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !expanded
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const WritingSectionTitle('Goals'),
                    for (final String objective in _task.genre.objectives)
                      _Bullet(objective),
                    const SizedBox(height: 6),
                    Text(
                      _task.genre.approach,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    if (hints.isNotEmpty) ...<Widget>[
                      WritingSectionTitle(
                        'Hints',
                        trailing: Text(
                          '$_hintsShown of ${hints.length}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      for (int i = 0; i < _hintsShown; i++)
                        _Bullet(hints[i], icon: Icons.lightbulb_outline),
                      if (_hintsShown < hints.length)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _hintsShown++),
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: Text(
                            _hintsShown == 0 ? 'Show a hint' : 'Next hint',
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _editorColumn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.white12),
              ),
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: TextField(
                controller: _text,
                focusNode: _focus,
                expands: true,
                maxLines: null,
                minLines: null,
                maxLength: MiaChatClient.maxWritingStudioChars,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textAlignVertical: TextAlignVertical.top,
                style: writingTextStyle,
                cursorColor: AppColors.primary,
                buildCounter:
                    (
                      BuildContext context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) => null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing here…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder:
                (BuildContext context, TextEditingValue value, Widget? _) =>
                    WritingLengthMeter(
                      words: countWords(value.text),
                      minWords: _task.minWords,
                      maxWords: _task.maxWords,
                    ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _submitting ? null : _showChecks,
                icon: const Icon(Icons.spellcheck_rounded, size: 18),
                label: const Text('Check basics'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            MiaPresence(
                              size: 26,
                              showLabel: false,
                              followVoice: false,
                              state: MiaPresenceState.thinking,
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Mia is reading your text…',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.client == null
                              ? 'Finish with automatic checks'
                              : 'Submit to Mia',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.icon = Icons.check_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AppColors.writing),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
