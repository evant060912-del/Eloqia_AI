import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../services/mia/mia_chat_client.dart';
import '../../services/mia/writing_review.dart';
import '../../services/voice/listening_accents.dart';
import '../../services/voice/listening_voices.dart';
import '../../services/voice/speech_input.dart';
import '../../theme/app_colors.dart';
import '../exams/exam_formats.dart';
import '../exams/exam_progress.dart';
import '../exams/exam_score_store.dart';
import '../writing/writing_checks.dart';
import '../writing/writing_review_screen.dart';
import '../writing/writing_store.dart';
import '../writing/writing_widgets.dart';
import 'speaking_analysis.dart';
import 'speaking_tasks.dart';

enum _Stage { intro, prep, ready, answering, done, results }

/// One speaking set: the prompt is read aloud, the learner answers with the
/// microphone (or types when no recogniser is available), then sees local
/// measures and, for interviews and IELTS, Mia's review of the transcript.
class SpeakingSessionScreen extends StatefulWidget {
  const SpeakingSessionScreen({
    super.key,
    required this.set,
    required this.profile,
    this.client,
  });

  final SpeakingSet set;
  final LearningProfile profile;

  /// Null without the server: local measures only.
  final MiaChatClient? client;

  @override
  State<SpeakingSessionScreen> createState() => _SpeakingSessionScreenState();
}

class _SpeakingSessionScreenState extends State<SpeakingSessionScreen> {
  final SpeechInput _mic = SpeechInputs.provider;
  final ListeningVoice _voice = ListeningVoices.provider;
  final TextEditingController _typed = TextEditingController();
  late final List<String> _answers = List<String>.filled(
    widget.set.items.length,
    '',
  );
  late final List<Duration> _durations = List<Duration>.filled(
    widget.set.items.length,
    Duration.zero,
  );

  _Stage _stage = _Stage.intro;
  bool? _micAvailable;
  int _index = 0;
  int _secondsLeft = 0;
  Timer? _timer;
  DateTime? _answerStart;
  bool _reviewing = false;

  SpeakingSet get _set => widget.set;
  SpeakingItem get _item => _set.items[_index];
  bool get _typing => _micAvailable == false;
  ListeningAccent get _accent =>
      _set.kind.isIelts ? ListeningAccent.british : ListeningAccent.american;

  @override
  void initState() {
    super.initState();
    unawaited(
      _mic.isAvailable().then((bool ok) {
        if (mounted) setState(() => _micAvailable = ok);
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_mic.cancel());
    unawaited(_voice.stop());
    _typed.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- flow

  Future<void> _begin() async {
    setState(() => _stage = _Stage.ready);
    await _voice.speakLine(
      speaker: 'Examiner',
      text: _set.intro,
      accent: _accent,
    );
    if (mounted) await _present();
  }

  /// Shows the item; reads the prompt (Part 2 starts its preparation).
  Future<void> _present() async {
    _typed.clear();
    if (_item.prepTime > Duration.zero) {
      _startTimer(_item.prepTime, _Stage.prep, onEnd: _startAnswer);
      return;
    }
    setState(() => _stage = _Stage.ready);
    await _voice.speakLine(
      speaker: 'Examiner',
      text: _item.prompt,
      accent: _accent,
    );
    if (mounted && _stage == _Stage.ready && !_typing) await _startAnswer();
  }

  void _startTimer(Duration length, _Stage stage, {VoidCallback? onEnd}) {
    _timer?.cancel();
    setState(() {
      _stage = stage;
      _secondsLeft = length.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
        onEnd?.call();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _startAnswer() async {
    await _voice.stop();
    _answerStart = DateTime.now();
    _startTimer(_item.responseTime, _Stage.answering, onEnd: _endAnswer);
    if (_typing) return;
    final bool started = await _mic.start(
      maxDuration: _item.responseTime + const Duration(seconds: 2),
      pauseFor: const Duration(seconds: 6),
      onText: (String text, bool isFinal) {
        if (!mounted) return;
        setState(() => _answers[_index] = text);
      },
    );
    if (!started && mounted) setState(() => _micAvailable = false);
  }

  Future<void> _endAnswer() async {
    _timer?.cancel();
    if (!_typing) await _mic.stop();
    if (_typing) _answers[_index] = _typed.text.trim();
    _durations[_index] = DateTime.now().difference(
      _answerStart ?? DateTime.now(),
    );
    if (mounted) setState(() => _stage = _Stage.done);
  }

  Future<void> _redo() async {
    _answers[_index] = '';
    await _present();
  }

  Future<void> _next() async {
    if (_index < _set.items.length - 1) {
      setState(() => _index++);
      await _present();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _stage = _Stage.results);
    if (_set.kind != SpeakingKind.listenRepeat) return;
    final int correct = <int>[
      for (int i = 0; i < _set.items.length; i++)
        if (RepeatScore.compare(_set.items[i].prompt, _answers[i]).correct) i,
    ].length;
    try {
      final DateTime now = DateTime.now().toUtc();
      await ExamScoreStore.add(
        ExamAttempt(
          id: 'lr-${_set.id}-${now.microsecondsSinceEpoch}',
          type: ExamTaskType.toeflListenRepeat,
          taskId: _set.id,
          title: 'Listen and Repeat: ${_set.title}',
          value: correct.toDouble(),
          scaleMax: _set.items.length,
          at: now,
        ),
      );
    } on Object {
      // The result stays on screen even if it cannot be saved.
    }
  }

  /// Interviews and IELTS: Mia reviews the transcript like a text.
  Future<void> _askMia() async {
    final MiaChatClient? client = widget.client;
    if (client == null || _reviewing) return;
    final String text = <String>[
      for (final String a in _answers)
        if (a.trim().isNotEmpty) a.trim(),
    ].join('\n\n');
    if (countWords(text) == 0) return;
    setState(() => _reviewing = true);
    final String prompt = <String>[
      _set.intro,
      for (int i = 0; i < _set.items.length; i++)
        'Question ${i + 1}: ${_set.items[i].prompt}'
            '${_set.items[i].bullets.isEmpty ? '' : ' (${_set.items[i].bullets.join('; ')})'}',
    ].join('\n');
    WritingReview? review;
    try {
      review = await client.reviewWriting(
        genre: _set.kind.examType,
        taskId: _set.id,
        taskTitle: '${_set.kind.label}: ${_set.title}',
        prompt: prompt.length > 1200 ? prompt.substring(0, 1200) : prompt,
        minWords: 0,
        maxWords: 0,
        text: text,
        profile: widget.profile,
      );
    } on MiaChatException catch (error) {
      _snack(error.message);
    } on Object {
      _snack(const MiaChatException('unknown').message);
    }
    if (!mounted) return;
    setState(() => _reviewing = false);
    if (review == null) return;
    final DateTime now = DateTime.now().toUtc();
    final String id = 'sp-${_set.id}-${now.microsecondsSinceEpoch}';
    final ExamAttempt? attempt = ExamScoreStore.fromReview(
      id: id,
      genre: _set.kind.examType,
      taskId: _set.id,
      title: '${_set.kind.label}: ${_set.title}',
      review: review,
      at: now,
    );
    try {
      if (attempt != null) await ExamScoreStore.add(attempt);
      await WritingStore.addToHistory(
        WritingHistoryEntry(
          id: id,
          taskId: _set.id,
          genre: _set.kind.examType,
          taskTitle: '${_set.kind.label}: ${_set.title}',
          text: text,
          submittedAt: now,
          review: review,
        ),
      );
    } on Object {
      // Best effort: the review is shown anyway.
    }
    if (!mounted) return;
    await Navigator.of(context).push<WritingReviewAction>(
      MaterialPageRoute<WritingReviewAction>(
        builder: (_) => WritingReviewScreen(
          taskTitle: '${_set.kind.label}: ${_set.title}',
          genreLabel: 'Speaking (transcript)',
          text: text,
          review: review,
          issues: const <MechanicalIssue>[],
          submittedAt: now,
          canRevise: false,
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          _set.kind.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: switch (_stage) {
                _Stage.intro => _intro(),
                _Stage.results => _results(),
                _ => _itemView(),
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _intro() => <Widget>[
    Text(
      _set.title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    ),
    const SizedBox(height: 10),
    Text(
      _set.intro,
      style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
    ),
    const SizedBox(height: 14),
    WritingPanel(
      accent: _typing ? AppColors.warning : AppColors.info,
      child: Text(
        _micAvailable == null
            ? 'Checking the microphone…'
            : _typing
            ? 'Speech recognition is not available here (try Chrome or the '
                  'mobile app). You can type your answers instead.'
            : 'Your answers go through the free speech recognition of this '
                  'device or browser. Nothing is recorded or stored; only the '
                  'text is kept. Pronunciation is not scored.',
        style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    ),
    const SizedBox(height: 22),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _micAvailable == null ? null : _begin,
      child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
  ];

  List<Widget> _itemView() {
    final bool repeat = _set.kind == SpeakingKind.listenRepeat;
    final bool showPrompt = !repeat || _stage == _Stage.done;
    return <Widget>[
      Text(
        _set.kind == SpeakingKind.ieltsPart2
            ? 'Cue card'
            : 'Item ${_index + 1} of ${_set.items.length}',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      WritingPanel(
        accent: AppColors.speaking,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              showPrompt ? _item.prompt : 'Listen, then repeat the sentence.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            for (final String b in _item.bullets)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '•  $b',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _stage == _Stage.answering
                  ? null
                  : () => _voice.speakLine(
                      speaker: 'Examiner',
                      text: _item.prompt,
                      accent: _accent,
                    ),
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Hear it again'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _timerLine(),
      const SizedBox(height: 12),
      if (_typing && _stage == _Stage.answering)
        TextField(
          controller: _typed,
          minLines: 3,
          maxLines: 8,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Type your answer…',
            filled: true,
            fillColor: AppColors.surface,
          ),
        )
      else
        WritingPanel(
          child: Text(
            _answers[_index].isEmpty
                ? (_stage == _Stage.answering
                      ? 'Listening… speak now.'
                      : 'Your answer will appear here.')
                : _answers[_index],
            style: writingTextStyle,
          ),
        ),
      const SizedBox(height: 16),
      ..._controls(),
    ];
  }

  Widget _timerLine() {
    final String text = switch (_stage) {
      _Stage.prep => 'Preparation: $_secondsLeft s (you can make notes)',
      _Stage.answering => 'Speak now: $_secondsLeft s left',
      _Stage.done => 'Answer saved.',
      _ => 'Listen to the prompt…',
    };
    return Text(
      text,
      style: TextStyle(
        color: _stage == _Stage.answering && _secondsLeft <= 5
            ? AppColors.warning
            : AppColors.primaryBright,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<Widget> _controls() {
    final bool last = _index == _set.items.length - 1;
    switch (_stage) {
      case _Stage.prep:
        return <Widget>[
          OutlinedButton(
            onPressed: _startAnswer,
            child: const Text('I’m ready: start speaking'),
          ),
        ];
      case _Stage.ready:
        return <Widget>[
          FilledButton(
            onPressed: _startAnswer,
            child: Text(_typing ? 'Answer' : 'Start speaking'),
          ),
        ];
      case _Stage.answering:
        return <Widget>[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: _endAnswer,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('I’ve finished'),
          ),
        ];
      case _Stage.done:
        return <Widget>[
          Row(
            children: <Widget>[
              OutlinedButton(onPressed: _redo, child: const Text('Redo')),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last ? 'See results' : 'Next'),
                ),
              ),
            ],
          ),
        ];
      case _Stage.intro:
      case _Stage.results:
        return const <Widget>[];
    }
  }

  List<Widget> _results() {
    final bool repeat = _set.kind == SpeakingKind.listenRepeat;
    if (repeat) {
      final List<RepeatScore> scores = <RepeatScore>[
        for (int i = 0; i < _set.items.length; i++)
          RepeatScore.compare(_set.items[i].prompt, _answers[i]),
      ];
      final int correct = scores.where((RepeatScore s) => s.correct).length;
      return <Widget>[
        Text(
          '$correct / ${scores.length}',
          style: const TextStyle(
            color: AppColors.primaryBright,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'Sentences repeated (90% of the words or more, in order). Based '
          'on what the recogniser heard; it is not a pronunciation score.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const WritingSectionTitle('Every sentence'),
        for (int i = 0; i < scores.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RepeatTile(number: i + 1, score: scores[i]),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ];
    }
    return <Widget>[
      const Text(
        'Your answers',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Measured on the transcript: length, speed and hesitation words.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      for (int i = 0; i < _set.items.length; i++) ...<Widget>[
        const SizedBox(height: 12),
        _AnswerTile(
          question: _set.items[i].prompt,
          answer: _answers[i],
          stats: FluencyStats.of(_answers[i], _durations[i]),
        ),
      ],
      const SizedBox(height: 18),
      if (widget.client == null)
        const WritingServerNotice()
      else
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _reviewing ? null : _askMia,
          child: Text(
            _reviewing ? 'Mia is reading your answers…' : 'Get Mia’s review',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      ),
    ];
  }
}

class _RepeatTile extends StatelessWidget {
  const _RepeatTile({required this.number, required this.score});

  final int number;
  final RepeatScore score;

  @override
  Widget build(BuildContext context) {
    return WritingPanel(
      accent: score.correct ? AppColors.success : AppColors.warning,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$number. ${(score.accuracy * 100).round()}% of the words',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: <Widget>[
              for (final RepeatWord w in score.words)
                Text(
                  w.word,
                  style: TextStyle(
                    color: w.heard ? AppColors.textPrimary : AppColors.warning,
                    fontWeight: w.heard ? FontWeight.w600 : FontWeight.w800,
                    decoration: w.heard ? null : TextDecoration.underline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            score.said.trim().isEmpty
                ? 'Nothing was recognised.'
                : 'Heard: “${score.said.trim()}”',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.question,
    required this.answer,
    required this.stats,
  });

  final String question;
  final String answer;
  final FluencyStats stats;

  @override
  Widget build(BuildContext context) {
    final int? wpm = stats.wordsPerMinute;
    return WritingPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer.trim().isEmpty ? 'No answer recognised.' : answer.trim(),
            style: const TextStyle(color: AppColors.textPrimary, height: 1.45),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              WritingTag('${stats.words} words'),
              if (wpm != null) WritingTag('$wpm words/min'),
              WritingTag(
                '${stats.fillers} hesitation ${stats.fillers == 1 ? 'word' : 'words'}',
                color: stats.fillers > 3
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
