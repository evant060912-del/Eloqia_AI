import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_data.dart';
import 'package:eloqia_ai/features/tutors/mia/mia_emotion_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AssessmentQuestion basicGrammar = assessmentQuestionBank.first;
  final AssessmentQuestion advancedGrammar = assessmentQuestionBank.firstWhere(
    (AssessmentQuestion question) => question.id == 'grammar_c1',
  );

  test('correct difficult answers cause a stronger contextual reaction', () {
    final MiaReaction reaction = MiaEmotionEngine.forAssessmentAnswer(
      question: advancedGrammar,
      selectedIndex: advancedGrammar.correctIndex,
      previousMistakesInSkill: 0,
      previousCorrectStreak: 0,
    );

    expect(reaction.emotion, MiaEmotion.excited);
    expect(reaction.intensity, MiaEmotionIntensity.vivid);
    expect(reaction.message, contains('C1 question'));
    expect(reaction.isCorrect, isTrue);
  });

  test('only a measured streak gets praised as consecutive success', () {
    final MiaReaction reaction = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex,
      previousMistakesInSkill: 0,
      previousCorrectStreak: 2,
    );

    expect(reaction.emotion, MiaEmotion.proud);
    expect(reaction.message, contains('3 accurate answers in a row'));
  });

  test('first mistake is gently corrected with skill-specific explanation', () {
    final MiaReaction reaction = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex + 1,
      previousMistakesInSkill: 0,
      previousCorrectStreak: 0,
    );

    expect(reaction.emotion, MiaEmotion.gentleCorrection);
    expect(reaction.isCorrect, isFalse);
    expect(reaction.message, contains('is'));
    expect(reaction.explanation, contains('singular subject'));
  });

  test('repeated errors change Mia to focused then gently playful', () {
    final MiaReaction repeated = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex + 1,
      previousMistakesInSkill: 1,
      previousCorrectStreak: 0,
    );
    final MiaReaction persistent = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex + 1,
      previousMistakesInSkill: 3,
      previousCorrectStreak: 0,
    );

    expect(repeated.emotion, MiaEmotion.focused);
    expect(persistent.emotion, MiaEmotion.playfulFrustration);
    expect(persistent.message, contains('different angle'));
    expect(persistent.message, isNot(contains('wrong')));
  });

  test('direct and deep correction follow the learner preference', () {
    final MiaReaction direct = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex + 1,
      previousMistakesInSkill: 0,
      previousCorrectStreak: 0,
      correctionStyle: 'direct',
    );
    final MiaReaction deep = MiaEmotionEngine.forAssessmentAnswer(
      question: basicGrammar,
      selectedIndex: basicGrammar.correctIndex + 1,
      previousMistakesInSkill: 0,
      previousCorrectStreak: 0,
      correctionStyle: 'deep',
    );

    expect(direct.message, contains('You chose'));
    expect(direct.message, contains('are'));
    expect(deep.title, contains('unpack'));
    expect(deep.message, contains('singular subject'));
    expect(deep.explanation, contains('similar question'));
  });
}
