import '../../onboarding/assessment/level_assessment_data.dart';

enum MiaEmotion {
  curious,
  warm,
  proud,
  excited,
  gentleCorrection,
  focused,
  playfulFrustration,
  empathetic,
  listening,
  thinking,
  speaking,
  celebrating,
}

enum MiaEmotionIntensity { subtle, warm, vivid }

class MiaReaction {
  const MiaReaction({
    required this.emotion,
    required this.intensity,
    required this.title,
    required this.message,
    required this.explanation,
    required this.isCorrect,
  });

  final MiaEmotion emotion;
  final MiaEmotionIntensity intensity;
  final String title;
  final String message;
  final String explanation;
  final bool isCorrect;
}

/// Deterministic reactions derived from objective assessment context.
/// It does not infer emotion from learner text or select reactions randomly.
class MiaEmotionEngine {
  MiaEmotionEngine._();

  static MiaReaction forAssessmentAnswer({
    required AssessmentQuestion question,
    required int selectedIndex,
    required int previousMistakesInSkill,
    required int previousCorrectStreak,
    String correctionStyle = 'gentle',
  }) {
    final bool correct = selectedIndex == question.correctIndex;
    final String answer = question.options[question.correctIndex];
    final String selectedAnswer = question.options[selectedIndex];
    final String skill = _skillName(question.skill);
    final String explanation = question.teachingPoint;
    final String style = correctionStyle.trim().toLowerCase();

    if (correct && question.levelIndex >= 4) {
      return MiaReaction(
        emotion: MiaEmotion.excited,
        intensity: MiaEmotionIntensity.vivid,
        title: 'That was a tough one.',
        message:
            'Exactly: "$answer." You handled a ${question.level} question.',
        explanation: explanation,
        isCorrect: true,
      );
    }

    if (correct && previousCorrectStreak >= 2) {
      final int streak = previousCorrectStreak + 1;
      return MiaReaction(
        emotion: MiaEmotion.proud,
        intensity: MiaEmotionIntensity.warm,
        title: 'You found your rhythm.',
        message:
            '$streak accurate answers in a row. That is real progress in this check.',
        explanation: explanation,
        isCorrect: true,
      );
    }

    if (correct) {
      return MiaReaction(
        emotion: MiaEmotion.warm,
        intensity: MiaEmotionIntensity.warm,
        title: 'Exactly.',
        message: '"$answer" fits this ${question.level} $skill question.',
        explanation: explanation,
        isCorrect: true,
      );
    }

    if (previousMistakesInSkill >= 3 && style != 'direct' && style != 'deep') {
      return MiaReaction(
        emotion: MiaEmotion.playfulFrustration,
        intensity: MiaEmotionIntensity.warm,
        title: 'We are not letting this one win.',
        message:
            'Okay, let’s try a different angle. The best answer is "$answer."',
        explanation: explanation,
        isCorrect: false,
      );
    }

    if (previousMistakesInSkill >= 1) {
      return MiaReaction(
        emotion: MiaEmotion.focused,
        intensity: MiaEmotionIntensity.subtle,
        title: 'Let’s look at it another way.',
        message: 'Almost. The best answer is "$answer."',
        explanation: explanation,
        isCorrect: false,
      );
    }

    if (style == 'direct') {
      return MiaReaction(
        emotion: MiaEmotion.focused,
        intensity: MiaEmotionIntensity.subtle,
        title: 'Not quite.',
        message:
            'You chose "$selectedAnswer"; the correct answer is "$answer."',
        explanation: explanation,
        isCorrect: false,
      );
    }

    if (style == 'deep') {
      return MiaReaction(
        emotion: MiaEmotion.focused,
        intensity: MiaEmotionIntensity.warm,
        title: 'Let’s unpack the pattern.',
        message: 'The correct answer is "$answer." $explanation',
        explanation:
            'Try noticing this cue the next time you see a similar question.',
        isCorrect: false,
      );
    }

    if (style == 'balanced') {
      return MiaReaction(
        emotion: MiaEmotion.gentleCorrection,
        intensity: MiaEmotionIntensity.subtle,
        title: 'Close, but not quite.',
        message: 'The best answer is "$answer."',
        explanation: explanation,
        isCorrect: false,
      );
    }

    return MiaReaction(
      emotion: MiaEmotion.gentleCorrection,
      intensity: MiaEmotionIntensity.subtle,
      title: 'Almost.',
      message:
          'The best answer is "$answer." Mistakes are useful clues, not a score of you.',
      explanation: explanation,
      isCorrect: false,
    );
  }

  static String _skillName(AssessmentSkill skill) => switch (skill) {
    AssessmentSkill.grammar => 'grammar',
    AssessmentSkill.vocabulary => 'vocabulary',
    AssessmentSkill.reading => 'reading',
    AssessmentSkill.usage => 'natural English',
  };
}
