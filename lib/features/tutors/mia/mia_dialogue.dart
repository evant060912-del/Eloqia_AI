/// Curated prompts and transparent, deterministic feedback for Mia's local
/// writing-practice mode. This is not an AI response evaluator.
class MiaDialogue {
  const MiaDialogue._();

  static const List<MiaPracticePrompt> prompts = <MiaPracticePrompt>[
    MiaPracticePrompt(
      title: 'Start naturally',
      prompt:
          'Imagine you have just met someone from another country. Introduce '
          'yourself naturally and tell them something interesting about you.',
      hint:
          'Try to sound natural rather than perfect. Imagine you are speaking '
          'to a real person.',
      focus: 'Fluency',
    ),
    MiaPracticePrompt(
      title: 'Share your opinion',
      prompt:
          'What is something you genuinely enjoy learning or doing? Explain '
          'why it matters to you.',
      hint: 'Give a reason and add a personal example if you can.',
      focus: 'Expression',
    ),
    MiaPracticePrompt(
      title: 'Keep the conversation going',
      prompt:
          'Your conversation partner says: “I would love to visit your '
          'country one day.” What would you say next?',
      hint: 'React to what they said and ask a natural follow-up question.',
      focus: 'Interaction',
      encourageQuestion: true,
    ),
  ];

  static MiaPracticeFeedback review(
    String response, {
    required bool encourageQuestion,
  }) {
    final String cleaned = response.trim();
    final List<String> words = cleaned.isEmpty
        ? const <String>[]
        : cleaned.split(RegExp(r'\s+'));
    final int sentences = cleaned.isEmpty
        ? 0
        : RegExp(r'[.!?]+').allMatches(cleaned).length;
    final bool asksQuestion = cleaned.contains('?');

    final List<String> observations = <String>[
      '${words.length} ${words.length == 1 ? 'word' : 'words'} written',
      '$sentences ${sentences == 1 ? 'sentence' : 'sentences'} detected',
    ];

    String nextStep;
    if (words.length < 8) {
      nextStep = 'Try adding one detail or a reason to develop your idea.';
    } else if (encourageQuestion && !asksQuestion) {
      nextStep = 'Try ending with a question to invite the other person in.';
    } else if (sentences < 2) {
      nextStep = 'Try extending your answer with a second sentence.';
    } else {
      nextStep = 'Your response has room to continue the conversation.';
    }

    return MiaPracticeFeedback(
      observations: List<String>.unmodifiable(observations),
      nextStep: nextStep,
    );
  }
}

class MiaPracticePrompt {
  const MiaPracticePrompt({
    required this.title,
    required this.prompt,
    required this.hint,
    required this.focus,
    this.encourageQuestion = false,
  });

  final String title;
  final String prompt;
  final String hint;
  final String focus;
  final bool encourageQuestion;
}

class MiaPracticeFeedback {
  const MiaPracticeFeedback({
    required this.observations,
    required this.nextStep,
  });

  final List<String> observations;
  final String nextStep;
}
