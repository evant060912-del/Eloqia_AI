import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../writing/writing_widgets.dart';
import 'build_sentence.dart';
import 'exam_clock.dart';
import 'exam_formats.dart';
import 'exam_progress.dart';
import 'exam_score_store.dart';
import 'exam_widgets.dart';

/// One Build a Sentence set: 10 items, 6 min 50 s, scored on the device.
class BuildSentenceScreen extends StatefulWidget {
  const BuildSentenceScreen({super.key, required this.set, this.now});

  final SentenceSet set;

  /// Clock source, injected in tests.
  final DateTime Function()? now;

  @override
  State<BuildSentenceScreen> createState() => _BuildSentenceScreenState();
}

enum _Stage { intro, items, results }

class _BuildSentenceScreenState extends State<BuildSentenceScreen> {
  late final ExamClock _clock = ExamClock(
    limit: BuildSentenceCatalog.timeLimit,
    now: widget.now,
  );
  Timer? _ticker;
  _Stage _stage = _Stage.intro;
  bool _timed = true;
  bool _timeRanOut = false;
  int _index = 0;

  /// For each item, the bank index placed in each blank (null when empty).
  late final List<List<int?>> _slots = <List<int?>>[
    for (final SentenceItem item in widget.set.items)
      List<int?>.filled(item.blanks, null),
  ];
  late final List<List<String>> _banks = <List<String>>[
    for (final SentenceItem item in widget.set.items) item.bank,
  ];
  SentenceAttemptResult? _result;

  List<SentenceItem> get _items => widget.set.items;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start({required bool timed}) {
    setState(() {
      _timed = timed;
      _stage = _Stage.items;
    });
    if (!timed) return;
    _clock.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_clock.isOver) {
        _timeRanOut = true;
        _finish();
      } else {
        setState(() {});
      }
    });
  }

  List<String?> _placed(int item) => <String?>[
    for (final int? i in _slots[item]) i == null ? null : _banks[item][i],
  ];

  void _place(int bankIndex) {
    final List<int?> slots = _slots[_index];
    final int empty = slots.indexOf(null);
    if (empty < 0 || slots.contains(bankIndex)) return;
    setState(() => slots[empty] = bankIndex);
  }

  void _clear(int blank) {
    setState(() => _slots[_index][blank] = null);
  }

  Future<void> _finish() async {
    if (_stage == _Stage.results) return;
    _ticker?.cancel();
    final SentenceAttemptResult result = SentenceAttemptResult.score(
      _items,
      <List<String?>>[for (int i = 0; i < _items.length; i++) _placed(i)],
    );
    setState(() {
      _result = result;
      _stage = _Stage.results;
    });
    try {
      final DateTime now = DateTime.now().toUtc();
      await ExamScoreStore.add(
        ExamAttempt(
          id: 'bas-${widget.set.id}-${now.microsecondsSinceEpoch}',
          type: ExamTaskType.toeflBuildSentence,
          taskId: widget.set.id,
          title: 'Build a Sentence: ${widget.set.title}',
          value: result.correct.toDouble(),
          scaleMax: result.total,
          at: now,
          timeLimitSeconds: _timed ? _clock.limit.inSeconds : 0,
          timeUsedSeconds: _timed ? _clock.elapsed.inSeconds : 0,
        ),
      );
    } on Object {
      // The result stays on screen even if it cannot be saved.
    }
  }

  void _restart() {
    _ticker?.cancel();
    _clock.reset();
    setState(() {
      for (final List<int?> slots in _slots) {
        slots.fillRange(0, slots.length, null);
      }
      _index = 0;
      _result = null;
      _timeRanOut = false;
      _stage = _Stage.intro;
    });
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
          'Build a Sentence',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (_stage) {
              _Stage.intro => _intro(),
              _Stage.items => _itemView(),
              _Stage.results => _results(),
            },
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        Text(
          widget.set.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.set.level,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        for (final String line in ExamTaskType.toeflBuildSentence.format)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
                    line,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Tap a word to place it in the next blank; tap a placed word to '
          'send it back.',
          style: TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 14),
        const ExamDisclaimer(exam: ExamKind.toefl),
        const SizedBox(height: 22),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _start(timed: true),
          child: const Text(
            'Start (6 min 50 s)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _start(timed: false),
          child: const Text('Practise without the timer'),
        ),
      ],
    );
  }

  Widget _itemView() {
    final SentenceItem item = _items[_index];
    final List<int?> slots = _slots[_index];
    final List<String> bank = _banks[_index];
    final bool last = _index == _items.length - 1;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Item ${_index + 1} of ${_items.length}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_timed)
                    Semantics(
                      label: 'Time left ${_clock.display}',
                      child: ExcludeSemantics(
                        child: Text(
                          _clock.display,
                          style: TextStyle(
                            color: _clock.phase == ExamClockPhase.lastMinutes
                                ? AppColors.warning
                                : AppColors.primaryBright,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_index + 1) / _items.length,
                minHeight: 4,
                color: AppColors.primary,
                backgroundColor: AppColors.white08,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 18),
              WritingPanel(
                accent: AppColors.listening,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.speaker,
                      style: const TextStyle(
                        color: AppColors.listening,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${item.prompt}”',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your reply',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _ReplyLine(item: item, placed: _placed(_index), onClear: _clear),
              const SizedBox(height: 22),
              const Text(
                'Words',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (int i = 0; i < bank.length; i++)
                    _Chunk(
                      text: bank[i],
                      used: slots.contains(i),
                      onTap: () => _place(i),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: _index == 0 ? null : () => setState(() => _index--),
                child: const Text('Back'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: last ? _finish : () => setState(() => _index++),
                  child: Text(
                    last ? 'Finish' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _results() {
    final SentenceAttemptResult result = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        Text(
          '${result.correct} / ${result.total}',
          style: const TextStyle(
            color: AppColors.primaryBright,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _timeRanOut
              ? 'Time ran out: unanswered items count as wrong, as in the '
                    'exam.'
              : 'Items fully correct (all or nothing, as in the exam).',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        if (result.tipsToReview.isNotEmpty) ...<Widget>[
          const WritingSectionTitle('Patterns to review'),
          for (final String tip in result.tipsToReview.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WritingPanel(
                accent: AppColors.warning,
                padding: const EdgeInsets.all(14),
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ),
        ],
        const WritingSectionTitle('Every item'),
        for (int i = 0; i < result.outcomes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OutcomeTile(number: i + 1, outcome: result.outcomes[i]),
          ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            OutlinedButton(onPressed: _restart, child: const Text('Try again')),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The reply with fixed words and blanks.
class _ReplyLine extends StatelessWidget {
  const _ReplyLine({
    required this.item,
    required this.placed,
    required this.onClear,
  });

  final SentenceItem item;
  final List<String?> placed;
  final ValueChanged<int> onClear;

  @override
  Widget build(BuildContext context) {
    final List<Widget> parts = <Widget>[];
    int blank = 0;
    for (int i = 0; i < item.answer.length; i++) {
      if (item.fixed.contains(i)) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              item.answer[i],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else {
        final int index = blank;
        final String? word = index < placed.length ? placed[index] : null;
        parts.add(
          Semantics(
            button: word != null,
            label: word == null
                ? 'Blank ${index + 1}'
                : 'Blank ${index + 1}: $word. Tap to remove.',
            child: ExcludeSemantics(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: word == null ? null : () => onClear(index),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: word == null
                        ? AppColors.white05
                        : AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: word == null
                          ? AppColors.white18
                          : AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    word ?? ' ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        blank++;
      }
    }
    parts.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          item.ending,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: parts,
    );
  }
}

class _Chunk extends StatelessWidget {
  const _Chunk({required this.text, required this.used, required this.onTap});

  final String text;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: used ? 0.3 : 1,
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: used ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white12),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({required this.number, required this.outcome});

  final int number;
  final SentenceOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final bool ok = outcome.correct;
    return WritingPanel(
      accent: ok ? AppColors.success : AppColors.error,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: ok ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$number. “${outcome.item.prompt}”',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            outcome.item.sentence,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          if (!ok) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'You built: ${outcome.learnerSentence}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              outcome.item.tip,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
