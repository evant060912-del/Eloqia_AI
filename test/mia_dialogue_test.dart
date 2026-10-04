import 'package:eloqia_ai/features/tutors/mia/mia_dialogue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'provides three curated prompts across distinct conversation skills',
    () {
      expect(MiaDialogue.prompts, hasLength(3));
      expect(
        MiaDialogue.prompts.map((MiaPracticePrompt prompt) => prompt.focus),
        containsAll(<String>['Fluency', 'Expression', 'Interaction']),
      );
    },
  );

  test('feedback reports only observable local writing measurements', () {
    final MiaPracticeFeedback feedback = MiaDialogue.review(
      'I enjoy learning languages. It helps me meet new people.',
      encourageQuestion: false,
    );

    expect(feedback.observations, contains('10 words written'));
    expect(feedback.observations, contains('2 sentences detected'));
    expect(feedback.nextStep, contains('room to continue'));
  });

  test('short answers get a concrete extension suggestion', () {
    final MiaPracticeFeedback feedback = MiaDialogue.review(
      'I like reading.',
      encourageQuestion: false,
    );

    expect(feedback.nextStep, contains('adding one detail or a reason'));
  });

  test('interaction prompt checks for a follow-up question only', () {
    final MiaPracticeFeedback missing = MiaDialogue.review(
      'I would love to show you my city one day.',
      encourageQuestion: true,
    );
    final MiaPracticeFeedback present = MiaDialogue.review(
      'I would love to show you my city one day. What would you like to see?',
      encourageQuestion: true,
    );

    expect(missing.nextStep, contains('ending with a question'));
    expect(present.nextStep, contains('room to continue'));
  });
}
