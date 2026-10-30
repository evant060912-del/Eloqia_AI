/// Original speaking practice in the public formats of the TOEFL iBT (2026)
/// and IELTS Speaking. Pure Dart (no Flutter import).
library;

enum SpeakingKind {
  listenRepeat('toefl_listen_repeat', 'Listen and Repeat'),
  interview('toefl_interview', 'Take an Interview'),
  ieltsPart1('ielts_speaking', 'IELTS Part 1'),
  ieltsPart2('ielts_speaking', 'IELTS Part 2'),
  ieltsPart3('ielts_speaking', 'IELTS Part 3');

  const SpeakingKind(this.examType, this.label);

  /// `ExamTaskType.apiValue` (and the server genre for reviewed answers).
  final String examType;
  final String label;

  bool get isIelts => examType == 'ielts_speaking';

  /// Reviewed by Mia (Listen and Repeat is scored on the device).
  bool get reviewed => this != listenRepeat;
}

class SpeakingItem {
  const SpeakingItem({
    required this.prompt,
    required this.responseTime,
    this.prepTime = Duration.zero,
    this.bullets = const <String>[],
  });

  /// The sentence to repeat, or the question.
  final String prompt;
  final Duration responseTime;

  /// Preparation before speaking (IELTS Part 2: one minute).
  final Duration prepTime;

  /// Cue-card points (IELTS Part 2).
  final List<String> bullets;
}

class SpeakingSet {
  const SpeakingSet({
    required this.id,
    required this.kind,
    required this.title,
    required this.intro,
    required this.items,
  });

  final String id;
  final SpeakingKind kind;
  final String title;

  /// The situation, read before the first item.
  final String intro;
  final List<SpeakingItem> items;
}

/// Listen and Repeat windows: about 8, 10 or 12 seconds by sentence length.
Duration repeatWindow(String sentence) {
  final int words = sentence.split(RegExp(r'\s+')).length;
  if (words <= 7) return const Duration(seconds: 8);
  if (words <= 11) return const Duration(seconds: 10);
  return const Duration(seconds: 12);
}

SpeakingItem _repeat(String sentence) =>
    SpeakingItem(prompt: sentence, responseTime: repeatWindow(sentence));

SpeakingItem _interview(String question) =>
    SpeakingItem(prompt: question, responseTime: const Duration(seconds: 45));

SpeakingItem _part1(String question) =>
    SpeakingItem(prompt: question, responseTime: const Duration(seconds: 30));

SpeakingItem _part3(String question) =>
    SpeakingItem(prompt: question, responseTime: const Duration(seconds: 60));

SpeakingItem _cueCard(String topic, List<String> bullets) => SpeakingItem(
  prompt: topic,
  bullets: bullets,
  prepTime: const Duration(minutes: 1),
  responseTime: const Duration(minutes: 2),
);

class SpeakingCatalog {
  SpeakingCatalog._();

  static List<SpeakingSet> setsFor(String examType) => sets
      .where((SpeakingSet s) => s.kind.examType == examType)
      .toList(growable: false);

  static SpeakingSet? byId(String id) {
    for (final SpeakingSet set in sets) {
      if (set.id == id) return set;
    }
    return null;
  }

  static final List<SpeakingSet> sets = <SpeakingSet>[
    // --------------------------------------------- TOEFL LISTEN AND REPEAT
    SpeakingSet(
      id: 'lr-library',
      kind: SpeakingKind.listenRepeat,
      title: 'First day at the library',
      intro:
          'You are a new student. A librarian is showing you around the '
          'library. Repeat exactly what you hear.',
      items: <SpeakingItem>[
        _repeat('Welcome to the main library.'),
        _repeat('Your student card works as a library card.'),
        _repeat('Quiet study rooms are on the second floor.'),
        _repeat('You can borrow up to ten books at a time.'),
        _repeat('Laptops can be charged at the desks near the windows.'),
        _repeat(
          'If you need help finding a book, ask at the information desk.',
        ),
        _repeat(
          'Books borrowed for a week must be returned before the library '
          'closes on Friday.',
        ),
      ],
    ),
    SpeakingSet(
      id: 'lr-sports-centre',
      kind: SpeakingKind.listenRepeat,
      title: 'At the sports centre',
      intro:
          'A staff member explains how the campus sports centre works. '
          'Repeat exactly what you hear.',
      items: <SpeakingItem>[
        _repeat('The pool opens at seven.'),
        _repeat('Please bring your own towel and lock.'),
        _repeat('Classes are free for first-year students.'),
        _repeat('You have to book a court at least one day ahead.'),
        _repeat('The gym is usually quieter in the early afternoon.'),
        _repeat(
          'Lost items are kept at reception for two weeks before they are '
          'donated.',
        ),
        _repeat(
          'Anyone who wants to join a team should come to the meeting on '
          'Wednesday evening.',
        ),
      ],
    ),

    // ------------------------------------------------- TOEFL INTERVIEW
    SpeakingSet(
      id: 'iv-study-habits',
      kind: SpeakingKind.interview,
      title: 'Study habits',
      intro:
          'You have agreed to take part in a research study about how '
          'students study. A researcher will ask you four questions. You '
          'have about 45 seconds for each answer.',
      items: <SpeakingItem>[
        _interview('Where do you usually study, and why do you like it?'),
        _interview(
          'Do you prefer studying alone or with other people? Explain why.',
        ),
        _interview(
          'Tell me about a time when you had to learn something difficult '
          'quickly.',
        ),
        _interview(
          'Some schools want to replace printed textbooks with tablets. Do '
          'you think this is a good idea?',
        ),
      ],
    ),
    SpeakingSet(
      id: 'iv-technology',
      kind: SpeakingKind.interview,
      title: 'Technology in daily life',
      intro:
          'A researcher is studying how young people use technology. You '
          'will answer four questions, about 45 seconds each.',
      items: <SpeakingItem>[
        _interview('Which app do you use most every day, and what for?'),
        _interview(
          'Describe a time when technology made a problem easier to solve.',
        ),
        _interview(
          'Do you think people spend too much time on their phones? Why or '
          'why not?',
        ),
        _interview(
          'Should schools teach students how to use artificial intelligence '
          'tools? Explain your opinion.',
        ),
      ],
    ),
    SpeakingSet(
      id: 'iv-travel',
      kind: SpeakingKind.interview,
      title: 'Travel and new places',
      intro:
          'A travel company is interviewing students about their trips. You '
          'will answer four questions, about 45 seconds each.',
      items: <SpeakingItem>[
        _interview('What is the most interesting place you have visited?'),
        _interview('Do you prefer planning a trip carefully or improvising?'),
        _interview(
          'Tell me about a problem you had while travelling and how you '
          'dealt with it.',
        ),
        _interview(
          'Some people think tourism harms the places people visit. What do '
          'you think?',
        ),
      ],
    ),

    // ---------------------------------------------------- IELTS PART 1
    SpeakingSet(
      id: 'ielts-p1-hometown',
      kind: SpeakingKind.ieltsPart1,
      title: 'Your hometown',
      intro:
          'Part 1: the examiner asks short questions about familiar topics. '
          'Answer in two or three sentences.',
      items: <SpeakingItem>[
        _part1('Where is your hometown?'),
        _part1('What do you like most about it?'),
        _part1('Is there anything you would change about your hometown?'),
        _part1('Do you think you will live there in the future?'),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p1-free-time',
      kind: SpeakingKind.ieltsPart1,
      title: 'Free time',
      intro:
          'Part 1: short questions about your free time. Answer in two or '
          'three sentences.',
      items: <SpeakingItem>[
        _part1('What do you usually do at the weekend?'),
        _part1('Have your hobbies changed since you were a child?'),
        _part1('Do you prefer spending free time indoors or outdoors?'),
        _part1('Is there a new activity you would like to try?'),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p1-studies',
      kind: SpeakingKind.ieltsPart1,
      title: 'Studies and work',
      intro:
          'Part 1: short questions about your studies or your work. Answer '
          'in two or three sentences.',
      items: <SpeakingItem>[
        _part1('Do you work or are you a student?'),
        _part1('What do you enjoy most about your studies or your job?'),
        _part1('Is there anything you find difficult about it?'),
        _part1('What would you like to do in the future?'),
      ],
    ),

    // ---------------------------------------------------- IELTS PART 2
    SpeakingSet(
      id: 'ielts-p2-place',
      kind: SpeakingKind.ieltsPart2,
      title: 'A peaceful place',
      intro:
          'Part 2: read the card, prepare for one minute (you can make '
          'notes), then speak for up to two minutes.',
      items: <SpeakingItem>[
        _cueCard('Describe a place where you like to relax.', <String>[
          'where it is',
          'how often you go there',
          'what you do there',
          'and explain why it helps you relax',
        ]),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p2-person',
      kind: SpeakingKind.ieltsPart2,
      title: 'Someone who taught you something',
      intro:
          'Part 2: read the card, prepare for one minute, then speak for up '
          'to two minutes.',
      items: <SpeakingItem>[
        _cueCard('Describe a person who taught you something useful.', <String>[
          'who the person is',
          'what they taught you',
          'how they taught it',
          'and explain why it was useful',
        ]),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p2-object',
      kind: SpeakingKind.ieltsPart2,
      title: 'An object you value',
      intro:
          'Part 2: read the card, prepare for one minute, then speak for up '
          'to two minutes.',
      items: <SpeakingItem>[
        _cueCard('Describe an object that is important to you.', <String>[
          'what it is',
          'how you got it',
          'how often you use it',
          'and explain why it matters to you',
        ]),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p2-event',
      kind: SpeakingKind.ieltsPart2,
      title: 'A celebration',
      intro:
          'Part 2: read the card, prepare for one minute, then speak for up '
          'to two minutes.',
      items: <SpeakingItem>[
        _cueCard('Describe a celebration you enjoyed.', <String>[
          'what was celebrated',
          'who was there',
          'what happened',
          'and explain why you enjoyed it',
        ]),
      ],
    ),

    // ---------------------------------------------------- IELTS PART 3
    SpeakingSet(
      id: 'ielts-p3-cities',
      kind: SpeakingKind.ieltsPart3,
      title: 'Cities and stress',
      intro:
          'Part 3: a discussion on wider questions. Give reasons and '
          'examples; about a minute per answer.',
      items: <SpeakingItem>[
        _part3('Why do many people find city life stressful?'),
        _part3(
          'What could local governments do to give people more places to '
          'relax?',
        ),
        _part3('Do you think people will have more free time in the future?'),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p3-learning',
      kind: SpeakingKind.ieltsPart3,
      title: 'Learning and teaching',
      intro:
          'Part 3: a discussion on wider questions. Give reasons and '
          'examples; about a minute per answer.',
      items: <SpeakingItem>[
        _part3(
          'Is it better to learn practical skills from family or at school?',
        ),
        _part3('How has the internet changed the way people learn?'),
        _part3('What makes someone a good teacher, in your view?'),
      ],
    ),
    SpeakingSet(
      id: 'ielts-p3-possessions',
      kind: SpeakingKind.ieltsPart3,
      title: 'Possessions and consumption',
      intro:
          'Part 3: a discussion on wider questions. Give reasons and '
          'examples; about a minute per answer.',
      items: <SpeakingItem>[
        _part3('Why do people keep objects they no longer use?'),
        _part3(
          'Do young people today care more about possessions than before?',
        ),
        _part3('How could people be encouraged to buy fewer things?'),
      ],
    ),
  ];
}
