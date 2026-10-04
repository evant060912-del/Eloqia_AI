import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../features/tutors/mia/mia_emotion_engine.dart';
import '../../../features/tutors/mia/widgets/mia_companion_card.dart';
import '../../../theme/app_colors.dart';
import '../widgets/onboarding_background.dart';
import 'level_assessment_data.dart';
import 'level_assessment_engine.dart';
import 'level_assessment_result.dart';
import 'level_assessment_service.dart';

enum _AssessmentPhase { offer, question, result }

/// Optional placement check shown after onboarding. The learner's declared
/// level is never replaced: the outcome is stored separately.
class LevelAssessmentScreen extends StatefulWidget {
  const LevelAssessmentScreen({
    super.key,
    required this.profile,
    required this.onFinished,
  });

  final LearningProfile profile;

  /// Called once the learner skips or has seen the result.
  final VoidCallback onFinished;

  @override
  State<LevelAssessmentScreen> createState() => _LevelAssessmentScreenState();
}

class _LevelAssessmentScreenState extends State<LevelAssessmentScreen> {
  late final LevelAssessmentEngine _engine;
  _AssessmentPhase _phase = _AssessmentPhase.offer;
  AssessmentQuestion? _question;
  int? _selected;
  MiaReaction? _reaction;
  bool _showingFeedback = false;
  LevelAssessmentResult? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _engine = LevelAssessmentEngine(
      selfReportedLevel: widget.profile.currentLevel,
    );
  }

  void _start() {
    setState(() {
      _phase = _AssessmentPhase.question;
      _question = _engine.nextQuestion();
    });
  }

  Future<void> _skip() async {
    if (_busy) {
      return;
    }
    _busy = true;
    final bool saved = await LevelAssessmentService.saveSkipped(
      selfReportedLevel: widget.profile.currentLevel,
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The skip choice could not be saved.')),
      );
    }
    widget.onFinished();
  }

  Future<void> _submit() async {
    if (_showingFeedback) {
      await _continueAfterFeedback();
      return;
    }

    final AssessmentQuestion? question = _question;
    final int? selected = _selected;

    if (question == null || selected == null || _busy) {
      return;
    }

    final int previousMistakes = _engine.answers
        .where(
          (AssessmentAnswer answer) =>
              answer.question.skill == question.skill && !answer.correct,
        )
        .length;
    final int previousCorrectStreak = _engine.answers.reversed
        .takeWhile((AssessmentAnswer answer) => answer.correct)
        .length;

    _engine.submit(question, selected);
    setState(() {
      _reaction = MiaEmotionEngine.forAssessmentAnswer(
        question: question,
        selectedIndex: selected,
        previousMistakesInSkill: previousMistakes,
        previousCorrectStreak: previousCorrectStreak,
        correctionStyle: widget.profile.preferredCorrectionStyle,
      );
      _showingFeedback = true;
    });
  }

  Future<void> _continueAfterFeedback() async {
    if (_engine.isFinished) {
      _busy = true;
      final LevelAssessmentResult result = _engine.buildResult();
      final bool saved = await LevelAssessmentService.save(result);
      if (saved) {
        try {
          await LevelAssessmentService.saveMistakeMemories(
            answers: _engine.answers,
            assessmentId: result.recordedAt.microsecondsSinceEpoch.toString(),
          );
        } on Object {
          // Optional memory summaries must not block the assessment result.
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _result = result;
        _phase = _AssessmentPhase.result;
      });
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assessment finished, but could not be saved on this device.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _selected = null;
      _question = _engine.nextQuestion();
      _reaction = null;
      _showingFeedback = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: OnboardingBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: switch (_phase) {
                    _AssessmentPhase.offer => _buildOffer(),
                    _AssessmentPhase.question => _buildQuestion(),
                    _AssessmentPhase.result => _buildResult(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffer() {
    return Column(
      key: const ValueKey<String>('offer'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'QUICK LEVEL CHECK',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Let Mia check your real level',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Up to 8 short questions on grammar, vocabulary, reading and '
          'natural English, in about 3 minutes. The difficulty adapts to '
          'your answers. Your declared level is kept as you chose it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(label: 'START ASSESSMENT', onPressed: _start),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skip,
          child: const Text(
            'SKIP FOR NOW',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    final AssessmentQuestion? question = _question;

    if (question == null) {
      return Center(
        key: const ValueKey<String>('empty'),
        child: _PrimaryButton(label: 'CONTINUE', onPressed: widget.onFinished),
      );
    }

    return Column(
      key: ValueKey<String>(question.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _engine.answeredCount / _engine.maxQuestions,
                  minHeight: 5,
                  backgroundColor: AppColors.glass,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_engine.answeredCount + 1}/${_engine.maxQuestions}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: _skip,
              child: const Text(
                'SKIP',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _skillLabel(question.skill),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                if (question.passage != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      question.passage!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  question.prompt,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < question.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      label: question.options[i],
                      selected: _selected == i,
                      onTap: _showingFeedback
                          ? () {}
                          : () => setState(() => _selected = i),
                    ),
                  ),
                if (_reaction != null) ...<Widget>[
                  const SizedBox(height: 8),
                  MiaCompanionCard(reaction: _reaction!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: _showingFeedback
              ? (_engine.isFinished ? 'SEE RESULT' : 'CONTINUE')
              : 'CHECK ANSWER',
          onPressed: _selected == null ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final LevelAssessmentResult result = _result!;
    final String declared = widget.profile.currentLevel.trim().toUpperCase();
    final int confidencePercent = (result.confidence * 100).round();

    return Column(
      key: const ValueKey<String>('result'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'ESTIMATED LEVEL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          result.assessedLevel ?? '--',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 64,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confidence $confidencePercent% after ${result.answeredCount} '
          'questions. This is a short estimate, not a certification.'
          '${declared.isEmpty ? '' : ' You declared $declared; '
                    'that choice stays unchanged.'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(label: 'CONTINUE', onPressed: widget.onFinished),
      ],
    );
  }

  static String _skillLabel(AssessmentSkill skill) {
    return switch (skill) {
      AssessmentSkill.grammar => 'GRAMMAR',
      AssessmentSkill.vocabulary => 'VOCABULARY',
      AssessmentSkill.reading => 'READING',
      AssessmentSkill.usage => 'NATURAL ENGLISH',
    };
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.glassMedium,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
