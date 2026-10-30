import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../services/voice/voice_output_provider.dart';
import '../../../theme/app_colors.dart';
import '../../tutors/mia/widgets/mia_presence.dart';
import '../engine/lesson_coach.dart';
import '../engine/lesson_result_service.dart';
import '../engine/lesson_session.dart';
import '../models/lesson_models.dart';
import '../review/review_deck.dart';
import '../review/review_service.dart';
import 'exercise_widgets.dart';
import 'feedback_panel.dart';
import 'listening_player.dart';

enum _Stage { intro, exercise, complete }

/// Runs one lesson: Mia's introduction, adaptive exercises, feedback and the
/// completion summary. State lives in [LessonSession]; this widget is UI only.
class LessonRunnerScreen extends StatefulWidget {
  const LessonRunnerScreen({
    super.key,
    required this.lesson,
    required this.profile,
    this.reason,
    this.buildNext,
  });

  final Lesson lesson;
  final LearningProfile profile;

  /// Why the engine chose this lesson, shown to the learner.
  final String? reason;
  final Future<Widget> Function()? buildNext;

  @override
  State<LessonRunnerScreen> createState() => _LessonRunnerScreenState();
}

class _LessonRunnerScreenState extends State<LessonRunnerScreen> {
  late final LessonSession _session = LessonSession(
    lesson: widget.lesson,
    correctionStyle: widget.profile.preferredCorrectionStyle,
  );
  final ScrollController _scroll = ScrollController();

  _Stage _stage = _Stage.intro;
  ExerciseOutcome? _outcome;
  String? _response;
  final Set<String> _eliminated = <String>{};
  int _inputKey = 0;
  LessonSummary? _summary;
  LessonRecord? _record;
  ReviewChange? _reviewChange;
  bool _saving = false;
  bool _loadingNext = false;

  @override
  void dispose() {
    _scroll.dispose();
    unawaited(MiaVoice.provider.stop());
    super.dispose();
  }

  void _start() {
    setState(() => _stage = _Stage.exercise);
    unawaited(MiaVoice.provider.stop());
  }

  void _check() {
    final String? response = _response;
    if (response == null || _outcome != null) {
      return;
    }
    final ExerciseOutcome outcome = _session.submit(response);
    setState(() {
      _outcome = outcome;
      if (!outcome.evaluation.correct) {
        _eliminated.add(response);
      }
    });
    _scrollToFeedback();
  }

  void _tryAgain() {
    _session.retry();
    setState(() {
      _outcome = null;
      _response = null;
      _inputKey++;
    });
  }

  void _showAnswer() {
    _session.retry();
    final ExerciseOutcome outcome = _session.submit('');
    setState(() => _outcome = outcome);
    _scrollToFeedback();
  }

  void _next() {
    unawaited(MiaVoice.provider.stop());
    if (_session.advance()) {
      setState(() {
        _outcome = null;
        _response = null;
        _eliminated.clear();
        _inputKey++;
      });
      if (_scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    } else {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    final LessonSummary summary = _session.summarize();
    setState(() {
      _summary = summary;
      _stage = _Stage.complete;
      _saving = true;
    });
    final LessonRecord record = await LessonResultService.record(
      summary: summary,
      profile: widget.profile,
    );
    ReviewChange? change;
    try {
      change = await ReviewService.recordLesson(_session.firstTryResults);
    } on Object {
      change = null; // The lesson result is saved even if the deck is not.
    }
    if (mounted) {
      setState(() {
        _record = record;
        _reviewChange = change;
        _saving = false;
      });
    }
  }

  void _scrollToFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _confirmExit() async {
    if (_stage != _Stage.exercise ||
        _session.position == 0 && _outcome == null) {
      Navigator.of(context).pop();
      return;
    }
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave this lesson?'),
        content: const Text('Your progress in this lesson will not be saved.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openNext() async {
    final Future<Widget> Function()? build = widget.buildNext;
    if (build == null || _loadingNext) {
      return;
    }
    setState(() => _loadingNext = true);
    final NavigatorState navigator = Navigator.of(context);
    final Widget next = await build();
    if (mounted) {
      navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop:
          _stage != _Stage.exercise ||
          _session.position == 0 && _outcome == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_confirmExit());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: <Widget>[
                  _header(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: switch (_stage) {
                        _Stage.intro => _intro(),
                        _Stage.exercise => _exercise(),
                        _Stage.complete => _complete(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final bool exercising = _stage == _Stage.exercise;
    final double progress = _stage == _Stage.complete
        ? 1
        : exercising
        ? (_session.position + (_outcome?.evaluation.correct == true ? 1 : 0)) /
              _session.queueLength
        : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close lesson',
            onPressed: _confirmExit,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.glass,
                      color: AppColors.primary,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (exercising) ...<Widget>[
            if (_session.combo >= 2)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _miniChip(
                  Icons.local_fire_department_rounded,
                  '${_session.combo}x',
                  AppColors.warmth,
                ),
              ),
            _miniChip(Icons.bolt_rounded, '${_session.answerXp}', AppColors.xp),
          ],
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> a) =>
          ScaleTransition(scale: a, child: child),
      child: Container(
        key: ValueKey<String>(text),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- intro

  Widget _intro() {
    final Lesson lesson = widget.lesson;
    final CoachLine coach = LessonCoach.intro(lesson);
    final LessonActivity intro = lesson.intro;
    return Column(
      key: const ValueKey<String>('intro'),
      children: <Widget>[
        Expanded(child: _introContent(lesson, coach, intro)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _primaryButton('Start lesson', _start),
        ),
      ],
    );
  }

  Widget _introContent(Lesson lesson, CoachLine coach, LessonActivity intro) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: <Widget>[
        Center(
          child: MiaPresence(
            size: 104,
            state: MiaPresenceState.fromEmotion(coach.emotion),
          ),
        ),
        const SizedBox(height: 14),
        _coachBubble(coach),
        const SizedBox(height: 18),
        Text(
          lesson.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lesson.objective,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _tag(lesson.skill.label, AppColors.primary),
            _tag('Level ${lesson.level}', AppColors.secondary),
            _tag('${lesson.estimatedMinutes} min', AppColors.electricBlue),
            _tag('up to ${lesson.xpReward} XP', AppColors.xp),
          ],
        ),
        if (widget.reason != null) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'WHY THIS LESSON',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reason!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (final String paragraph in intro.explanation)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              paragraph,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
        for (final String example in intro.examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: AppColors.electricBlue.withValues(alpha: 0.8),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                example,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _coachBubble(CoachLine coach) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            coach.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (coach.message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              coach.message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 4),
          ValueListenableBuilder<bool>(
            valueListenable: MiaVoice.provider.speaking,
            builder: (BuildContext context, bool speaking, Widget? child) =>
                TextButton.icon(
                  onPressed: () => speaking
                      ? MiaVoice.provider.stop()
                      : MiaVoice.provider.speak(
                          '${coach.title} ${coach.message}',
                          style: speechStyleFor(coach.emotion),
                        ),
                  icon: Icon(
                    speaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_rounded,
                    size: 16,
                  ),
                  label: Text(speaking ? 'Stop' : 'Hear Mia'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 32),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.glassMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- exercise

  Widget _exercise() {
    final Exercise exercise = _session.current!;
    final ExerciseOutcome? outcome = _outcome;
    final AnswerResult result = outcome == null
        ? AnswerResult.none
        : (outcome.evaluation.correct
              ? AnswerResult.correct
              : AnswerResult.incorrect);

    return Column(
      key: ValueKey<String>('exercise-${exercise.id}-${_session.position}'),
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _tag(widget.lesson.skill.label, AppColors.primary),
                  _tag(exercise.topic, AppColors.textSecondary),
                  if (_session.isReview) _tag('REVIEW', AppColors.secondary),
                  if (_session.isChallenge)
                    _tag('CHALLENGE · 2× XP', AppColors.xp),
                ],
              ),
              if (_session.isChallenge && _outcome == null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  LessonCoach.challenge.message,
                  style: const TextStyle(
                    color: AppColors.xp,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (widget.lesson.passage != null) ...<Widget>[
                _passage(widget.lesson.passage!),
                const SizedBox(height: 14),
              ],
              if (widget.lesson.audio.isNotEmpty) ...<Widget>[
                ListeningPlayer(
                  lines: widget.lesson.audio,
                  showTranscript: outcome != null,
                ),
                const SizedBox(height: 14),
              ],
              _prompt(exercise, result),
              if (exercise.instructions != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  exercise.instructions!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ExerciseInput(
                key: ValueKey<String>(
                  'input-${exercise.id}-$_inputKey-${_session.position}',
                ),
                exercise: exercise,
                result: result,
                locked: outcome != null,
                eliminated: _eliminated,
                wrongPairs: outcome?.evaluation.wrongPairs ?? const <String>[],
                revealAnswer:
                    outcome != null &&
                    !outcome.evaluation.correct &&
                    outcome.feedback.revealed,
                onChanged: (String? value) => setState(() => _response = value),
                onSubmit: _check,
              ),
              if (outcome != null)
                FeedbackPanel(
                  key: ValueKey<String>(
                    'feedback-${exercise.id}-${outcome.attempt}',
                  ),
                  outcome: outcome,
                  totalXp: _session.answerXp,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _actionBar(outcome),
        ),
      ],
    );
  }

  Widget _actionBar(ExerciseOutcome? outcome) {
    if (outcome == null) {
      return _primaryButton('Check answer', _response == null ? null : _check);
    }
    if (!outcome.evaluation.correct && outcome.feedback.canRetry) {
      return Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _showAnswer,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Show answer'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _primaryButton('Try again', _tryAgain)),
        ],
      );
    }
    return _primaryButton('Continue', _next);
  }

  Widget _passage(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.menu_book_rounded,
                color: AppColors.vocabulary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'READ',
                style: TextStyle(
                  color: AppColors.vocabulary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final String paragraph in text.split('\n\n'))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectableText(
                paragraph,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.5,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _prompt(Exercise exercise, AnswerResult result) {
    const TextStyle style = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.4,
    );
    if (exercise.type != ExerciseType.fillBlank ||
        !exercise.prompt.contains('___')) {
      return Text(exercise.prompt, style: style);
    }
    final List<String> parts = exercise.prompt.split('___');
    final Color color = result == AnswerResult.none
        ? AppColors.primary
        : (result == AnswerResult.correct
              ? AppColors.success
              : kCorrectionColor);
    return Text.rich(
      TextSpan(
        style: style,
        children: <InlineSpan>[
          TextSpan(text: parts.first),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              constraints: const BoxConstraints(minWidth: 72),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: color, width: 2)),
              ),
              child: Text(
                _response ?? '',
                textAlign: TextAlign.center,
                style: style.copyWith(color: color),
              ),
            ),
          ),
          TextSpan(text: parts.skip(1).join('___')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- complete

  Widget _complete() {
    final LessonSummary summary = _summary!;
    final LessonRecord? record = _record;
    final CoachLine coach = LessonCoach.completion(summary, record);
    final int accuracy = (summary.accuracy * 100).round();

    return ListView(
      key: const ValueKey<String>('complete'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Center(
          child: MiaPresence(
            size: 112,
            state: MiaPresenceState.fromEmotion(coach.emotion),
          ),
        ),
        const SizedBox(height: 14),
        _coachBubble(coach),
        const SizedBox(height: 18),
        Text(
          widget.lesson.title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Center(
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: record?.xpAwarded ?? 0),
            duration: const Duration(milliseconds: 900),
            builder: (BuildContext context, int value, Widget? child) => Text(
              '+$value XP',
              style: const TextStyle(
                color: AppColors.xp,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(child: _saveStatus(record)),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(child: _stat('Accuracy', '$accuracy%', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'First-try',
                '${summary.firstTryCorrect}/${summary.totalExercises}',
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Best combo',
                '${summary.maxCombo}x',
                AppColors.warmth,
              ),
            ),
          ],
        ),
        if (record?.skillMastery != null) ...<Widget>[
          const SizedBox(height: 12),
          _masteryBar(record!.skillMastery!),
        ],
        if (summary.missedTopics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _infoCard(
            'TO REVIEW',
            AppColors.electricBlue,
            'Mia will bring back: ${summary.missedTopics.keys.join(', ')}.',
          ),
        ],
        if (_reviewChange != null && !_reviewChange!.isEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _infoCard(
            'SPACED REVIEW',
            AppColors.vocabulary,
            reviewChangeText(_reviewChange!),
          ),
        ],
        for (final a in record?.newAchievements ?? const []) ...<Widget>[
          const SizedBox(height: 12),
          _infoCard(
            'ACHIEVEMENT UNLOCKED',
            AppColors.xp,
            '${a.title}: ${a.description}',
          ),
        ],
        const SizedBox(height: 22),
        if (widget.buildNext != null)
          _primaryButton(
            _loadingNext ? 'Loading…' : 'Next recommended lesson',
            _saving || _loadingNext ? null : _openNext,
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Back to Learn'),
          ),
        ),
      ],
    );
  }

  Widget _saveStatus(LessonRecord? record) {
    if (_saving || record == null) {
      return const Text(
        'Saving your progress…',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    if (!record.sessionSaved || !record.progressSaved) {
      return const Text(
        'Progress could not be saved on this device, so no XP was awarded.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kCorrectionColor, fontSize: 12),
      );
    }
    return Text(
      record.leveledUp
          ? 'Level ${record.newLevel} reached'
          : 'Saved to your progress',
      style: TextStyle(
        color: record.leveledUp ? AppColors.xp : AppColors.textMuted,
        fontSize: 12,
        fontWeight: record.leveledUp ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _masteryBar(double mastery) {
    return _infoCard(
      '${widget.lesson.skill.label.toUpperCase()} MEASURED MASTERY',
      AppColors.primary,
      '${mastery.round()}% from your completed lessons',
      bar: mastery / 100,
    );
  }

  Widget _infoCard(String label, Color color, String text, {double? bar}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          if (bar != null) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: bar.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.glass,
                      color: color,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One sentence about what a lesson changed in the review deck.
String reviewChangeText(ReviewChange change) {
  final List<String> parts = <String>[
    if (change.added > 0)
      '${change.added} new ${change.added == 1 ? 'exercise' : 'exercises'} '
          'to review from tomorrow',
    if (change.promoted > 0) '${change.promoted} moved further away',
    if (change.mastered > 0) '${change.mastered} mastered',
    if (change.reset > 0) '${change.reset} back for tomorrow',
  ];
  final String text = parts.join(', ');
  return '${text[0].toUpperCase()}${text.substring(1)}.';
}
