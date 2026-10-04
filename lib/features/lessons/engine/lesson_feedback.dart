import '../../tutors/mia/mia_emotion_engine.dart';
import '../models/lesson_models.dart';
import 'exercise_evaluator.dart';

class LessonFeedback {
  const LessonFeedback({
    required this.correct,
    required this.resultTitle,
    required this.yourAnswer,
    required this.why,
    required this.mia,
    required this.nextStep,
    this.rule,
    this.example,
    this.hint,
    this.canRetry = false,
    this.revealed = false,
  });

  final bool correct;
  final String resultTitle;

  /// Restates what the learner answered.
  final String yourAnswer;
  final String why;
  final String? rule;
  final String? example;
  final String? hint;
  final MiaReaction mia;
  final String nextStep;
  final bool canRetry;

  /// The correct answer is being shown after a second miss.
  final bool revealed;
}

class FeedbackContext {
  const FeedbackContext({
    required this.attempt,
    required this.previousMistakesOnTopic,
    required this.comboAfter,
    required this.isChallenge,
    required this.correctionStyle,
    required this.skill,
  });

  final int attempt;
  final int previousMistakesOnTopic;
  final int comboAfter;
  final bool isChallenge;
  final String correctionStyle;
  final LessonSkill skill;
}

/// Builds feedback only from the exercise, the learner's response and measured
/// session facts. Wording varies deterministically by exercise id.
class FeedbackBuilder {
  FeedbackBuilder._();

  static LessonFeedback build({
    required Exercise exercise,
    required ExerciseEvaluation evaluation,
    required FeedbackContext context,
  }) {
    final String style = context.correctionStyle.trim().toLowerCase();
    final bool direct = style == 'direct';
    final bool deep = style == 'deep';
    final int variant = exercise.id.hashCode.abs() % 2;
    final String answered = _describeAnswer(exercise, evaluation);

    if (evaluation.correct) {
      final ({MiaEmotion emotion, String title, String message}) line =
          _correctLine(exercise, context, variant);
      return LessonFeedback(
        correct: true,
        resultTitle: 'Correct',
        yourAnswer: answered,
        why: exercise.explanation,
        rule: exercise.rule,
        example: exercise.example,
        nextStep: context.attempt > 1
            ? 'Good recovery. Let\'s keep going.'
            : 'Ready for the next one?',
        mia: MiaReaction(
          emotion: line.emotion,
          intensity:
              context.isChallenge || exercise.difficulty >= 3
              ? MiaEmotionIntensity.vivid
              : MiaEmotionIntensity.warm,
          title: line.title,
          message: line.message,
          explanation: '',
          isCorrect: true,
        ),
      );
    }

    final bool canRetry = context.attempt < 2;
    final String? note = exercise.type == ExerciseType.matching
        ? null
        : exercise.notes[evaluation.response];
    final String why = note == null
        ? exercise.explanation
        : '$note ${exercise.explanation}';
    final String? hint = canRetry && exercise.hints.isNotEmpty
        ? exercise.hints.first
        : null;

    final ({MiaEmotion emotion, String title, String message}) line =
        _wrongLine(exercise, context, direct: direct, deep: deep);

    return LessonFeedback(
      correct: false,
      resultTitle: canRetry ? (direct ? 'Not quite' : 'Almost') : 'Let\'s review',
      yourAnswer: answered,
      why: why,
      rule: exercise.rule,
      example: exercise.example,
      hint: hint,
      canRetry: canRetry,
      revealed: !canRetry,
      nextStep: canRetry
          ? 'Try once more${hint == null ? '' : ' — use the hint'}.'
          : 'I\'ll bring this one back at the end so it sticks.',
      mia: MiaReaction(
        emotion: line.emotion,
        intensity: MiaEmotionIntensity.subtle,
        title: line.title,
        message: line.message,
        explanation: '',
        isCorrect: false,
      ),
    );
  }

  static String _describeAnswer(Exercise exercise, ExerciseEvaluation e) {
    if (e.response.trim().isEmpty) {
      final String shown = exercise.type == ExerciseType.matching
          ? exercise.pairs.entries
                .map((MapEntry<String, String> p) => '${p.key} → ${p.value}')
                .join(', ')
          : exercise.answers.first;
      return 'The answer is "$shown".';
    }
    if (exercise.type == ExerciseType.matching) {
      return e.correct
          ? 'You matched every pair.'
          : 'These pairs need another look: ${e.wrongPairs.join(', ')}.';
    }
    final String value = e.response.trim();
    return value.isEmpty ? 'You did not give an answer.' : 'You answered "$value".';
  }

  static ({MiaEmotion emotion, String title, String message}) _correctLine(
    Exercise exercise,
    FeedbackContext context,
    int variant,
  ) {
    if (context.comboAfter >= 5 && context.attempt == 1) {
      return (
        emotion: MiaEmotion.celebrating,
        title: '${context.comboAfter} in a row.',
        message: 'Okay, I see you.',
      );
    }
    if (context.comboAfter == 3 && context.attempt == 1) {
      return (
        emotion: MiaEmotion.proud,
        title: 'Three in a row.',
        message: 'You\'re finding your rhythm.',
      );
    }
    if (context.isChallenge || exercise.difficulty >= 3) {
      return (
        emotion: MiaEmotion.excited,
        title: 'That one was tough.',
        message: 'And you nailed it.',
      );
    }
    final String topic = exercise.topic;
    return switch (context.skill) {
      LessonSkill.vocabulary => (
        emotion: MiaEmotion.warm,
        title: variant == 0 ? 'Good call.' : 'Exactly.',
        message: 'That word was tricky because of the context, and you read it well.',
      ),
      LessonSkill.grammar => (
        emotion: MiaEmotion.warm,
        title: variant == 0 ? 'Exactly.' : 'That\'s it.',
        message: 'You spotted the $topic pattern.',
      ),
      LessonSkill.reading => (
        emotion: MiaEmotion.warm,
        title: 'Right.',
        message: 'You found the detail in the passage.',
      ),
      LessonSkill.listening => (
        emotion: MiaEmotion.warm,
        title: 'Nice listening.',
        message: 'You caught the key phrase.',
      ),
    };
  }

  static ({MiaEmotion emotion, String title, String message}) _wrongLine(
    Exercise exercise,
    FeedbackContext context, {
    required bool direct,
    required bool deep,
  }) {
    final String topic = exercise.topic;

    if (!(context.attempt < 2)) {
      return (
        emotion: MiaEmotion.gentleCorrection,
        title: 'That\'s okay.',
        message: 'This one is worth seeing again, so it comes back at the end.',
      );
    }
    if (context.previousMistakesOnTopic >= 3) {
      return (
        emotion: MiaEmotion.playfulFrustration,
        title: 'Okay, okay.',
        message:
            'I think this rule and I need to have a little conversation. One more careful look.',
      );
    }
    if (context.previousMistakesOnTopic >= 2) {
      return (
        emotion: MiaEmotion.focused,
        title: 'We keep tripping on $topic.',
        message: 'Let\'s slow down and look at the rule together.',
      );
    }
    if (deep) {
      return (
        emotion: MiaEmotion.focused,
        title: 'Let\'s unpack it.',
        message: 'Read the rule below, then compare it with the sentence.',
      );
    }
    if (direct) {
      return (
        emotion: MiaEmotion.focused,
        title: 'Not quite.',
        message: 'Check the rule, then try again.',
      );
    }
    return switch (context.skill) {
      LessonSkill.grammar => (
        emotion: MiaEmotion.gentleCorrection,
        title: 'Almost.',
        message: 'I know what tripped you up: it\'s the $topic.',
      ),
      LessonSkill.vocabulary => (
        emotion: MiaEmotion.gentleCorrection,
        title: 'Close.',
        message: 'This one depends on the context, so read the whole sentence.',
      ),
      LessonSkill.reading => (
        emotion: MiaEmotion.gentleCorrection,
        title: 'Almost.',
        message: exercise.evidence ?? 'Look back at the passage.',
      ),
      LessonSkill.listening => (
        emotion: MiaEmotion.gentleCorrection,
        title: 'Almost.',
        message: exercise.evidence ?? 'Listen again for the key phrase.',
      ),
    };
  }
}
