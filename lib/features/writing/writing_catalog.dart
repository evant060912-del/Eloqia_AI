import 'package:flutter/material.dart';

/// Level bands used to pick tasks. Tasks are written for a band, and the
/// review adapts to the learner's exact CEFR level on the server.
enum WritingBand {
  foundation('Foundation', 'A1–A2'),
  intermediate('Intermediate', 'B1–B2'),
  advanced('Advanced', 'C1–C2');

  const WritingBand(this.label, this.levels);

  final String label;
  final String levels;

  static WritingBand forLevel(String cefrLevel) =>
      switch (cefrLevel.trim().toUpperCase()) {
        'B1' || 'B2' => WritingBand.intermediate,
        'C1' || 'C2' => WritingBand.advanced,
        _ => WritingBand.foundation,
      };
}

/// Families shown as sections in the studio.
enum WritingGroup {
  everyday('Everyday writing'),
  arguments('Essays and arguments'),
  stories('Stories and description'),
  information('Information');

  const WritingGroup(this.label);

  final String label;
}

/// The 13 kinds of writing. [apiValue] matches `Genre` in
/// `backend/app/writing.py`, where each genre has its own criteria.
enum WritingGenre {
  email(
    'email',
    'Email',
    'Formal and friendly emails with the right tone',
    Icons.mail_outline_rounded,
    WritingGroup.everyday,
    <String>[
      'Open and close the email in a way that suits the reader',
      'Make the purpose clear in the first lines',
      'Answer every point of the task',
    ],
    'Think about who will read it first: a friend, a teacher, a company? '
        'That decides the greeting, the tone and the closing.',
  ),
  practicalMessage(
    'practical_message',
    'Practical message',
    'Notes, texts and notices people can act on',
    Icons.sticky_note_2_outlined,
    WritingGroup.everyday,
    <String>[
      'Say what, when and where in a few lines',
      'Tell the reader exactly what to do',
      'Keep a tone that suits the reader',
    ],
    'Short is good. The reader should understand the message in one read.',
  ),
  free(
    'free',
    'Free writing',
    'Write about anything and get honest feedback',
    Icons.edit_note_rounded,
    WritingGroup.everyday,
    <String>[
      'Express your own ideas freely',
      'Use vocabulary you are learning',
      'Write naturally, the way you would speak',
    ],
    'There is no wrong topic. Mia focuses on accuracy and natural English.',
  ),
  essay(
    'essay',
    'Essay',
    'Plan, structure and develop an idea',
    Icons.article_outlined,
    WritingGroup.arguments,
    <String>[
      'Understand exactly what the question asks',
      'Give each paragraph one main idea',
      'Link paragraphs and end with a real conclusion',
    ],
    'Spend a minute planning: your main idea, two or three supporting points, '
        'then your conclusion.',
  ),
  argumentative(
    'argumentative',
    'Argumentative',
    'Defend a position with reasons and evidence',
    Icons.gavel_rounded,
    WritingGroup.arguments,
    <String>[
      'State a clear position',
      'Support each reason with an example or a fact',
      'Answer at least one counterargument',
    ],
    'A strong argument anticipates what someone who disagrees would say.',
  ),
  opinion(
    'opinion',
    'Opinion',
    'Say what you think and explain why',
    Icons.record_voice_over_outlined,
    WritingGroup.arguments,
    <String>[
      'Give your opinion clearly at the start',
      'Explain it with personal reasons and examples',
      'Restate it in new words at the end',
    ],
    'Useful openings: "In my opinion", "I strongly believe", "Personally".',
  ),
  forAgainst(
    'for_against',
    'For and against',
    'Present both sides fairly before deciding',
    Icons.balance_rounded,
    WritingGroup.arguments,
    <String>[
      'Present the advantages in one paragraph',
      'Present the disadvantages in another',
      'Keep your own view for the conclusion',
    ],
    'Balance matters: use linking words like "on the other hand" and '
        '"however".',
  ),
  academic(
    'academic',
    'Academic style',
    'Formal register, precise claims, careful hedging',
    Icons.school_outlined,
    WritingGroup.arguments,
    <String>[
      'Use formal language without contractions',
      'Make careful claims ("may", "tends to", "evidence suggests")',
      'Connect ideas precisely',
    ],
    'Academic writing sounds confident but careful: avoid "always", '
        '"never" and chatty expressions.',
  ),
  narrative(
    'narrative',
    'Narrative',
    'Tell a story in a clear order',
    Icons.auto_stories_outlined,
    WritingGroup.stories,
    <String>[
      'Set the scene: who, where, when',
      'Keep past tenses consistent',
      'Build towards an ending',
    ],
    'Time words help the reader follow: first, then, suddenly, after that, '
        'in the end.',
  ),
  descriptive(
    'descriptive',
    'Descriptive',
    'Paint a picture with precise words',
    Icons.landscape_outlined,
    WritingGroup.stories,
    <String>[
      'Use the senses: sight, sound, smell, touch',
      'Choose precise adjectives and verbs',
      'Organise the description in a clear order',
    ],
    'Replace general words ("nice", "big") with precise ones ("cosy", '
        '"enormous").',
  ),
  creative(
    'creative',
    'Creative',
    'Poems, scenes and imaginative pieces',
    Icons.palette_outlined,
    WritingGroup.stories,
    <String>[
      'Use your imagination and your own voice',
      'Play with images and sentence rhythm',
      'Make the reader feel something',
    ],
    'Mia respects deliberate stylistic choices: she only corrects real '
        'mistakes.',
  ),
  summary(
    'summary',
    'Summary',
    'Keep the main ideas, in your own words',
    Icons.short_text_rounded,
    WritingGroup.information,
    <String>[
      'Find the main ideas of the source text',
      'Leave out details, examples and your opinion',
      'Use your own words instead of copying sentences',
    ],
    'Read the text twice. Then write without looking, and check afterwards.',
  ),
  report(
    'report',
    'Report',
    'Factual, organised writing with sections',
    Icons.assignment_outlined,
    WritingGroup.information,
    <String>[
      'Give the report a title and a clear purpose',
      'Organise it in sections with headings',
      'Stay factual and end with recommendations',
    ],
    'Headings like "Introduction", "Findings" and "Recommendations" help the '
        'reader.',
  );

  const WritingGenre(
    this.apiValue,
    this.label,
    this.description,
    this.icon,
    this.group,
    this.objectives,
    this.approach,
  );

  final String apiValue;
  final String label;
  final String description;
  final IconData icon;
  final WritingGroup group;
  final List<String> objectives;
  final String approach;

  static WritingGenre? byApiValue(String value) {
    for (final WritingGenre genre in WritingGenre.values) {
      if (genre.apiValue == value) return genre;
    }
    return null;
  }
}

/// One writing task. Authored, so the prompt is reviewed for quality.
@immutable
class WritingTask {
  const WritingTask({
    required this.id,
    required this.genre,
    required this.band,
    required this.title,
    required this.prompt,
    required this.minWords,
    required this.maxWords,
    this.reader = '',
    this.hints = const <String>[],
    this.sourceText,
  });

  /// Stable id (`[a-z0-9-]`), used for drafts and to avoid duplicate XP.
  final String id;
  final WritingGenre genre;
  final WritingBand band;
  final String title;
  final String prompt;
  final int minWords;

  /// 0 means no maximum.
  final int maxWords;

  /// Who will read the text (shown above the prompt).
  final String reader;
  final List<String> hints;

  /// Text to summarise (summary tasks only).
  final String? sourceText;

  String get lengthLabel => maxWords > 0
      ? '$minWords–$maxWords words'
      : minWords > 0
      ? 'At least $minWords words'
      : 'Any length';

  /// Minimum length for the task to count as completed practice (XP).
  int get countedWords {
    final int fromTask = (minWords * 0.6).round();
    return fromTask < 15 ? 15 : fromTask;
  }
}

class WritingCatalog {
  WritingCatalog._();

  static List<WritingTask> tasksFor(WritingGenre genre, {WritingBand? band}) =>
      tasks
          .where(
            (WritingTask t) =>
                t.genre == genre && (band == null || t.band == band),
          )
          .toList(growable: false);

  static WritingTask? byId(String id) {
    for (final WritingTask task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  static const List<WritingTask> tasks = <WritingTask>[
    // ------------------------------------------------------------------ EMAIL
    WritingTask(
      id: 'email-invite-friend',
      genre: WritingGenre.email,
      band: WritingBand.foundation,
      title: 'Invite a friend',
      reader: 'Your friend Alex',
      prompt:
          'Invite your friend Alex to your birthday party. Say when and where '
          'it is, what you will do, and ask Alex to reply.',
      minWords: 35,
      maxWords: 80,
      hints: <String>[
        'Start with "Hi Alex," and end with "See you soon," and your name.',
        'Use the present continuous for plans: "I\'m having a party on '
            'Saturday."',
        'Finish with a question: "Can you come?"',
      ],
    ),
    WritingTask(
      id: 'email-thank-teacher',
      genre: WritingGenre.email,
      band: WritingBand.foundation,
      title: 'Thank your teacher',
      reader: 'Your teacher, Ms Carter',
      prompt:
          'Your English teacher, Ms Carter, helped you prepare for an important '
          'test. Write to thank her, say how the test went and what helped '
          'you most.',
      minWords: 40,
      maxWords: 90,
      hints: <String>[
        'Open with "Dear Ms Carter," — teachers usually get a polite greeting.',
        'Use the past simple for the test: "The test went well."',
        'Close with "Best wishes," or "Kind regards,".',
      ],
    ),
    WritingTask(
      id: 'email-ask-course',
      genre: WritingGenre.email,
      band: WritingBand.foundation,
      title: 'Ask about a summer course',
      reader: 'The course organiser',
      prompt:
          'You saw an advert for a summer English course in London. Write to '
          'the organiser to ask about the dates, the price and where students '
          'stay.',
      minWords: 40,
      maxWords: 90,
      hints: <String>[
        '"I am writing to ask for information about..." is a classic opening.',
        'Polite questions: "Could you tell me...?" "I would like to know..."',
        'End with "I look forward to hearing from you."',
      ],
    ),
    WritingTask(
      id: 'email-complaint-order',
      genre: WritingGenre.email,
      band: WritingBand.intermediate,
      title: 'Complain about an order',
      reader: 'An online shop’s customer service',
      prompt:
          'You ordered headphones online. They arrived two weeks late and one '
          'side does not work. Write to customer service: explain the '
          'problem, say how you feel about it, and ask for a solution.',
      minWords: 120,
      maxWords: 180,
      hints: <String>[
        'Give the facts first: what you ordered, when, the order number.',
        'Firm but polite: "I was disappointed to find that..."',
        'Say clearly what you want: a refund, a replacement, a reply by a date.',
      ],
    ),
    WritingTask(
      id: 'email-apply-volunteer',
      genre: WritingGenre.email,
      band: WritingBand.intermediate,
      title: 'Apply to volunteer',
      reader: 'The coordinator of a summer festival',
      prompt:
          'A music festival is looking for young volunteers to welcome '
          'visitors. Write to apply: introduce yourself, explain why you are '
          'interested and what makes you a good fit, and mention when you are '
          'available.',
      minWords: 130,
      maxWords: 200,
      hints: <String>[
        'One paragraph per idea: who you are, why you, availability.',
        'Back up qualities with examples: "I am organised: I run my school '
            'club."',
        'Avoid "I want" repeated: try "I would love to", "I am keen to".',
      ],
    ),
    WritingTask(
      id: 'email-follow-up',
      genre: WritingGenre.email,
      band: WritingBand.intermediate,
      title: 'Follow up politely',
      reader: 'A summer camp manager who has not replied',
      prompt:
          'Two weeks ago you applied for a summer job at a camp and you have '
          'had no answer. Write a short follow-up email: remind them of your '
          'application, confirm your interest and ask when they will decide.',
      minWords: 90,
      maxWords: 150,
      hints: <String>[
        'Refer to your first email: "I am following up on my application..."',
        'Stay positive: no reproach, just a reminder.',
        'Make it easy to reply: ask one clear question.',
      ],
    ),
    WritingTask(
      id: 'email-formal-council',
      genre: WritingGenre.email,
      band: WritingBand.advanced,
      title: 'Propose a change to your town council',
      reader: 'The town council',
      prompt:
          'Your town plans to close the only skate park to build a car park. '
          'Write a formal email to the council: explain why the skate park '
          'matters to young people, propose an alternative, and request a '
          'meeting.',
      minWords: 220,
      maxWords: 320,
      hints: <String>[
        'A formal register: no contractions, measured language.',
        'Concede before you argue: "While I understand the need for parking..."',
        'Make the request concrete: who, when, what you will bring.',
      ],
    ),

    // ------------------------------------------------------ PRACTICAL MESSAGE
    WritingTask(
      id: 'message-late-note',
      genre: WritingGenre.practicalMessage,
      band: WritingBand.foundation,
      title: 'Running late',
      reader: 'Your friend, by text message',
      prompt:
          'You are meeting a friend at the cinema at 7 pm, but your bus is '
          'late. Send a text message: say you will be late, how late, and '
          'what your friend should do.',
      minWords: 15,
      maxWords: 45,
      hints: <String>[
        'Text messages can be informal: "Sorry!", "See you soon".',
        'Give a time: "I\'ll be there at 7:20."',
      ],
    ),
    WritingTask(
      id: 'message-club-notice',
      genre: WritingGenre.practicalMessage,
      band: WritingBand.intermediate,
      title: 'Notice for a school club',
      reader: 'Students reading the school notice board',
      prompt:
          'You are starting a new club at school (you choose: chess, film, '
          'coding...). Write a notice: what the club is, when and where it '
          'meets, who can join and how to sign up.',
      minWords: 70,
      maxWords: 130,
      hints: <String>[
        'A catchy title helps: "Love films? Join us!"',
        'Put practical details on separate lines.',
        'End with a clear action: "Sign up with Ms Lee in room 12."',
      ],
    ),
    WritingTask(
      id: 'message-handover',
      genre: WritingGenre.practicalMessage,
      band: WritingBand.advanced,
      title: 'Handover note',
      reader: 'A colleague replacing you for a week',
      prompt:
          'You help run a small online shop and you are away next week. Write '
          'a handover note for the person replacing you: what is urgent, what '
          'can wait, where things are, and who to contact if something goes '
          'wrong.',
      minWords: 120,
      maxWords: 200,
      hints: <String>[
        'Order by priority: urgent first.',
        'Use imperatives for clarity: "Check the orders every morning."',
      ],
    ),

    // --------------------------------------------------------------- FREE
    WritingTask(
      id: 'free-my-week',
      genre: WritingGenre.free,
      band: WritingBand.foundation,
      title: 'My week',
      prompt:
          'Write about your week: what you did, something you enjoyed and '
          'something you want to do next week.',
      minWords: 40,
      maxWords: 0,
      hints: <String>[
        'Past simple for what you did, "going to" for next week.',
      ],
    ),
    WritingTask(
      id: 'free-something-learned',
      genre: WritingGenre.free,
      band: WritingBand.intermediate,
      title: 'Something I learned recently',
      prompt:
          'Write about something you learned recently — at school, online or '
          'from someone — and why it stayed with you.',
      minWords: 100,
      maxWords: 0,
      hints: <String>[
        'Explain the context first, then why it mattered to you.',
      ],
    ),
    WritingTask(
      id: 'free-changed-my-mind',
      genre: WritingGenre.free,
      band: WritingBand.advanced,
      title: 'A time I changed my mind',
      prompt:
          'Write about a time you changed your mind about something important. '
          'What did you believe, what changed it, and what do you think now?',
      minWords: 200,
      maxWords: 0,
      hints: <String>[
        'Contrast past and present beliefs: "I used to think... now I..."',
      ],
    ),

    // --------------------------------------------------------------- ESSAY
    WritingTask(
      id: 'essay-best-day',
      genre: WritingGenre.essay,
      band: WritingBand.foundation,
      title: 'A good day at school',
      prompt:
          'What makes a good day at school? Write a short essay with an '
          'introduction, two reasons and a conclusion.',
      minWords: 60,
      maxWords: 120,
      hints: <String>[
        'Introduction: one sentence that answers the question.',
        'Use "First,", "Also,", "Finally," for your reasons.',
      ],
    ),
    WritingTask(
      id: 'essay-phones-school',
      genre: WritingGenre.essay,
      band: WritingBand.intermediate,
      title: 'Phones at school',
      prompt:
          'Should mobile phones be allowed at school? Write an essay that '
          'answers the question with a clear main idea, supporting paragraphs '
          'and a conclusion.',
      minWords: 150,
      maxWords: 250,
      hints: <String>[
        'Your thesis goes at the end of the introduction.',
        'Each body paragraph: topic sentence, explanation, example.',
        'The conclusion answers the question again in new words.',
      ],
    ),
    WritingTask(
      id: 'essay-failure',
      genre: WritingGenre.essay,
      band: WritingBand.advanced,
      title: 'Learning from failure',
      prompt:
          '"Failure teaches more than success." To what extent do you agree? '
          'Write an essay that develops a nuanced position.',
      minWords: 250,
      maxWords: 380,
      hints: <String>[
        '"To what extent" invites nuance: you can partly agree.',
        'Use precise linking: "admittedly", "nevertheless", "it follows that".',
      ],
    ),

    // -------------------------------------------------------- ARGUMENTATIVE
    WritingTask(
      id: 'argument-school-uniform',
      genre: WritingGenre.argumentative,
      band: WritingBand.foundation,
      title: 'School uniforms',
      prompt:
          'Should students wear a school uniform? Choose your position and '
          'give two reasons with examples.',
      minWords: 60,
      maxWords: 120,
      hints: <String>[
        'Start with your answer: "I think students should..."',
        'Give a reason, then "For example,".',
      ],
    ),
    WritingTask(
      id: 'argument-four-day-week',
      genre: WritingGenre.argumentative,
      band: WritingBand.intermediate,
      title: 'A four-day school week',
      prompt:
          'Some schools are trying a four-day week with longer days. Argue for '
          'or against this idea. Support your reasons and answer one '
          'counterargument.',
      minWords: 160,
      maxWords: 260,
      hints: <String>[
        'Counterargument: "Some people argue that... However,..."',
        'Facts or realistic examples make reasons stronger.',
      ],
    ),
    WritingTask(
      id: 'argument-ai-homework',
      genre: WritingGenre.argumentative,
      band: WritingBand.advanced,
      title: 'AI and homework',
      prompt:
          'Should students be allowed to use AI tools for homework? Build a '
          'reasoned argument, address the strongest opposing view and '
          'propose conditions or limits.',
      minWords: 260,
      maxWords: 400,
      hints: <String>[
        'Define what "using AI" means before arguing.',
        'Address the strongest opposing view, not the weakest.',
      ],
    ),

    // ----------------------------------------------------------------- OPINION
    WritingTask(
      id: 'opinion-favourite-season',
      genre: WritingGenre.opinion,
      band: WritingBand.foundation,
      title: 'The best season',
      prompt:
          'Which season is the best? Give your opinion and explain why with '
          'examples from your life.',
      minWords: 50,
      maxWords: 100,
      hints: <String>['"In my opinion, ... is the best season because..."'],
    ),
    WritingTask(
      id: 'opinion-social-media',
      genre: WritingGenre.opinion,
      band: WritingBand.intermediate,
      title: 'Social media at 13',
      prompt:
          'Many apps require users to be at least 13. Is this the right age? '
          'Give your opinion with reasons and examples.',
      minWords: 140,
      maxWords: 220,
      hints: <String>[
        'Vary your opinion phrases: "I am convinced", "It seems to me".',
      ],
    ),
    WritingTask(
      id: 'opinion-tourism',
      genre: WritingGenre.opinion,
      band: WritingBand.advanced,
      title: 'Limiting tourism',
      prompt:
          'Some cities now limit the number of tourists. Is this a fair '
          'solution? Give a well-supported personal view.',
      minWords: 230,
      maxWords: 350,
      hints: <String>['Acknowledge complexity without losing your position.'],
    ),

    // ----------------------------------------------------------- FOR / AGAINST
    WritingTask(
      id: 'for-against-pets',
      genre: WritingGenre.forAgainst,
      band: WritingBand.foundation,
      title: 'Having a pet',
      prompt:
          'Write about the good and bad points of having a pet. Give your own '
          'opinion only at the end.',
      minWords: 60,
      maxWords: 120,
      hints: <String>[
        'One paragraph "good points", one paragraph "bad points".',
        'Use "but" and "however" to change side.',
      ],
    ),
    WritingTask(
      id: 'for-against-online-learning',
      genre: WritingGenre.forAgainst,
      band: WritingBand.intermediate,
      title: 'Learning online',
      prompt:
          'Discuss the advantages and disadvantages of learning online instead '
          'of in a classroom. Conclude with your own view.',
      minWords: 160,
      maxWords: 250,
      hints: <String>[
        'Balanced linking: "On the one hand... On the other hand..."',
        'Keep "I" out of the body paragraphs.',
      ],
    ),
    WritingTask(
      id: 'for-against-space',
      genre: WritingGenre.forAgainst,
      band: WritingBand.advanced,
      title: 'Spending on space exploration',
      prompt:
          'Should governments spend money on space exploration when there are '
          'problems on Earth? Present both sides fairly and reach a reasoned '
          'conclusion.',
      minWords: 260,
      maxWords: 380,
      hints: <String>['Give each side its strongest arguments.'],
    ),

    // -------------------------------------------------------------- ACADEMIC
    WritingTask(
      id: 'academic-sleep',
      genre: WritingGenre.academic,
      band: WritingBand.foundation,
      title: 'Why sleep matters',
      prompt:
          'Write a short formal paragraph explaining why sleep is important '
          'for students. Use formal language and no contractions.',
      minWords: 50,
      maxWords: 100,
      hints: <String>[
        'Write "do not" instead of "don\'t".',
        'Begin with a topic sentence: "Sleep is essential for..."',
      ],
    ),
    WritingTask(
      id: 'academic-plastic',
      genre: WritingGenre.academic,
      band: WritingBand.intermediate,
      title: 'Reducing plastic waste',
      prompt:
          'In a formal style, explain two causes of plastic pollution and two '
          'realistic ways to reduce it. Be careful with claims you cannot '
          'prove.',
      minWords: 170,
      maxWords: 260,
      hints: <String>[
        'Hedging: "may", "can contribute to", "it is likely that".',
        'Avoid "a lot of" and "things": try "a significant amount", '
            '"factors".',
      ],
    ),
    WritingTask(
      id: 'academic-bilingualism',
      genre: WritingGenre.academic,
      band: WritingBand.advanced,
      title: 'Benefits of bilingualism',
      prompt:
          'Write an academic-style text discussing the possible cognitive and '
          'social benefits of bilingualism, and the limits of what can be '
          'claimed.',
      minWords: 280,
      maxWords: 400,
      hints: <String>['Distinguish what is established from what is debated.'],
    ),

    // ------------------------------------------------------------- NARRATIVE
    WritingTask(
      id: 'narrative-lost',
      genre: WritingGenre.narrative,
      band: WritingBand.foundation,
      title: 'Lost in a new city',
      prompt:
          'Write a short story that begins: "When I got off the train, my '
          'phone was dead and I didn\'t know where I was."',
      minWords: 60,
      maxWords: 130,
      hints: <String>[
        'Past simple for events: walked, saw, asked.',
        'Time words: first, then, after that, in the end.',
      ],
    ),
    WritingTask(
      id: 'narrative-unexpected-visitor',
      genre: WritingGenre.narrative,
      band: WritingBand.intermediate,
      title: 'An unexpected visitor',
      prompt:
          'Write a story about an unexpected visitor. Build some suspense and '
          'end with a surprise.',
      minWords: 170,
      maxWords: 270,
      hints: <String>[
        'Past continuous for the background: "It was raining and I was '
            'reading when..."',
        'Past perfect for earlier events: "I had forgotten that..."',
      ],
    ),
    WritingTask(
      id: 'narrative-last-day',
      genre: WritingGenre.narrative,
      band: WritingBand.advanced,
      title: 'The last day',
      prompt:
          'Write a story about the last day of something — a summer, a job, a '
          'friendship, a place. Let the reader feel the change.',
      minWords: 280,
      maxWords: 420,
      hints: <String>['Show, don\'t tell: let details carry the emotion.'],
    ),

    // ----------------------------------------------------------- DESCRIPTIVE
    WritingTask(
      id: 'descriptive-my-room',
      genre: WritingGenre.descriptive,
      band: WritingBand.foundation,
      title: 'My favourite place at home',
      prompt:
          'Describe your favourite place at home. What can you see, hear and '
          'feel there?',
      minWords: 50,
      maxWords: 110,
      hints: <String>[
        'There is / there are, next to, in front of, above.',
        'Add one adjective to each noun.',
      ],
    ),
    WritingTask(
      id: 'descriptive-market',
      genre: WritingGenre.descriptive,
      band: WritingBand.intermediate,
      title: 'A busy market',
      prompt:
          'Describe a busy market (real or imagined) so that the reader feels '
          'they are there: the colours, sounds, smells and people.',
      minWords: 150,
      maxWords: 240,
      hints: <String>[
        'Precise verbs: shout, bargain, sizzle, wander.',
        'Vary how sentences begin.',
      ],
    ),
    WritingTask(
      id: 'descriptive-storm',
      genre: WritingGenre.descriptive,
      band: WritingBand.advanced,
      title: 'Before the storm',
      prompt:
          'Describe a place in the minutes before a storm. Create atmosphere '
          'through precise, varied language.',
      minWords: 230,
      maxWords: 350,
      hints: <String>['Change the rhythm: long sentences, then a short one.'],
    ),

    // -------------------------------------------------------------- CREATIVE
    WritingTask(
      id: 'creative-talking-object',
      genre: WritingGenre.creative,
      band: WritingBand.foundation,
      title: 'If my backpack could talk',
      prompt:
          'Imagine your backpack can talk. Write what it says about a normal '
          'day with you.',
      minWords: 50,
      maxWords: 120,
      hints: <String>[
        'Write as the backpack: "Every morning, she throws me on the bus..."',
      ],
    ),
    WritingTask(
      id: 'creative-letter-future',
      genre: WritingGenre.creative,
      band: WritingBand.intermediate,
      title: 'A letter from the future',
      prompt:
          'Write a letter from yourself in 2040 to yourself today. What do you '
          'want to tell your younger self?',
      minWords: 150,
      maxWords: 250,
      hints: <String>[
        'Mix tenses on purpose: what happened, what is true now, what to do.',
      ],
    ),
    WritingTask(
      id: 'creative-scene-dialogue',
      genre: WritingGenre.creative,
      band: WritingBand.advanced,
      title: 'A scene in dialogue',
      prompt:
          'Write a scene where two characters disagree about something '
          'important, mostly through dialogue. Let the reader understand what '
          'is really at stake without saying it directly.',
      minWords: 250,
      maxWords: 380,
      hints: <String>[
        'New speaker, new line. Punctuation goes inside the quotation marks.',
      ],
    ),

    // --------------------------------------------------------------- SUMMARY
    WritingTask(
      id: 'summary-bees',
      genre: WritingGenre.summary,
      band: WritingBand.foundation,
      title: 'Why bees matter',
      prompt: 'Summarise the text in 2 to 4 sentences, in your own words.',
      minWords: 25,
      maxWords: 60,
      hints: <String>[
        'Find the one main idea first.',
        'Do not copy whole sentences from the text.',
      ],
      sourceText:
          'Bees are small, but they are very important. When bees fly from '
          'flower to flower, they carry pollen. This helps plants make fruit '
          'and seeds. Many foods we eat, like apples, strawberries and '
          'almonds, need bees. Today, there are fewer bees than before. '
          'Pesticides, disease and the loss of wild flowers are some of the '
          'reasons. People can help bees by planting flowers, using fewer '
          'chemicals in gardens and buying honey from local beekeepers.',
    ),
    WritingTask(
      id: 'summary-sleep-teens',
      genre: WritingGenre.summary,
      band: WritingBand.intermediate,
      title: 'Teenagers and sleep',
      prompt:
          'Summarise the article for a classmate who has not read it, in one '
          'paragraph and in your own words.',
      minWords: 70,
      maxWords: 120,
      hints: <String>[
        'Keep the cause, the consequences and the proposed solutions.',
        'Leave out the examples and figures that are not essential.',
      ],
      sourceText:
          'Many teenagers find it hard to fall asleep before eleven at night, '
          'and parents often blame phones. Screens do play a part, but '
          'researchers point to another cause: during adolescence, the body '
          'clock shifts. The hormone that makes us feel sleepy is released '
          'later in the evening than it is for children or adults, so a '
          'fifteen-year-old who goes to bed at ten may simply lie awake.\n\n'
          'Because school usually starts early, many teenagers lose one or two '
          'hours of sleep every night. Over weeks, this lack of sleep is linked '
          'to lower concentration, more frequent bad moods and a higher risk of '
          'accidents on the way to school.\n\n'
          'Some schools have tried starting the day thirty to sixty minutes '
          'later. In several of these schools, attendance improved and '
          'students reported feeling more alert in morning lessons. Experts '
          'also advise teenagers to keep regular sleep times at weekends and to '
          'avoid bright screens in the hour before bed.',
    ),
    WritingTask(
      id: 'summary-cities-heat',
      genre: WritingGenre.summary,
      band: WritingBand.advanced,
      title: 'Cooling cities',
      prompt:
          'Write a concise summary of the article for a city newsletter, '
          'keeping the argument and its key evidence, without adding your own '
          'opinion.',
      minWords: 100,
      maxWords: 160,
      hints: <String>[
        'Rebuild the logic: problem, cause, solutions, trade-offs.',
        'Paraphrase technical terms only if you keep their meaning.',
      ],
      sourceText:
          'On summer afternoons, the centre of a large city can be several '
          'degrees hotter than the surrounding countryside. This "urban heat '
          'island" effect has a simple origin: asphalt, concrete and dark '
          'roofs absorb sunlight during the day and release it slowly at '
          'night, while traffic and air conditioning add their own heat. '
          'Fewer trees means less shade and less cooling through evaporation.\n\n'
          'The consequences go beyond discomfort. During heatwaves, hospital '
          'admissions rise, particularly among older residents, and energy '
          'demand peaks just as power networks are under strain.\n\n'
          'Cities are responding in different ways. Some are planting trees on '
          'a large scale, aiming to shade a fixed share of every neighbourhood. '
          'Others paint roofs and pavements in light colours that reflect more '
          'sunlight, or replace car parks with green spaces that absorb rain. '
          'None of these measures is free of trade-offs: trees take years to '
          'grow and need water, while reflective surfaces can create glare. '
          'Urban planners increasingly argue that the most effective approach '
          'combines several measures and targets the poorest districts first, '
          'since they often have the least green space.',
    ),

    // ---------------------------------------------------------------- REPORT
    WritingTask(
      id: 'report-school-trip',
      genre: WritingGenre.report,
      band: WritingBand.foundation,
      title: 'Report on a school trip',
      prompt:
          'Write a short report about a school trip (real or imagined) for '
          'your school website: where you went, what you did, and if you '
          'recommend it.',
      minWords: 60,
      maxWords: 120,
      hints: <String>[
        'Use headings: "The trip", "What we did", "Recommendation".',
      ],
    ),
    WritingTask(
      id: 'report-canteen-survey',
      genre: WritingGenre.report,
      band: WritingBand.intermediate,
      title: 'Canteen survey results',
      prompt:
          'You asked 50 students about the school canteen: 60% like the food, '
          '70% think the queue is too long, 40% want more vegetarian options. '
          'Write a report for the head teacher presenting the findings and '
          'making recommendations.',
      minWords: 150,
      maxWords: 230,
      hints: <String>[
        'Sections: Introduction, Findings, Recommendations.',
        'Report numbers accurately: "Most students (70%) feel that..."',
      ],
    ),
    WritingTask(
      id: 'report-youth-centre',
      genre: WritingGenre.report,
      band: WritingBand.advanced,
      title: 'Proposal for a youth centre',
      prompt:
          'Your town has funding for one youth project. Write a report for '
          'the council comparing two options (a youth centre or free '
          'transport for under-18s) and recommending one, with justification.',
      minWords: 260,
      maxWords: 380,
      hints: <String>[
        'Compare options against the same criteria: cost, reach, impact.',
        'Recommendations should follow logically from your findings.',
      ],
    ),
  ];
}
