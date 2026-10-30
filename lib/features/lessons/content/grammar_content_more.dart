import '../models/lesson_models.dart';
import 'content_helpers.dart';

/// Second grammar lesson for each level A1–C1.
final List<Lesson> moreGrammarLessons = <Lesson>[
  Lesson(
    id: 'grammar-a1-present-simple',
    title: 'Daily routines',
    description: 'The present simple for habits and facts.',
    skill: LessonSkill.grammar,
    levelIndex: 0,
    topic: 'present simple',
    estimatedMinutes: 6,
    xpReward: 20,
    objective: 'Use the present simple, with -s for he, she and it.',
    tags: const <String>['basics'],
    activities: <LessonActivity>[
      introActivity(
        'Present simple',
        const <String>[
          'Use the present simple for habits and things that are always true.',
          'With he, she and it, add -s to the verb: I work → she works. '
              'Verbs ending in -sh, -ch, -o, -x add -es: watch → watches, go → '
              'goes.',
          'Questions and negatives use do/does + base verb: Does she work? She '
              'doesn’t work.',
        ],
        const <String>[
          'I get up at seven every day.',
          'My brother watches TV after school.',
          'Does your sister like music?',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'g-a1-ps-1',
          topic: 'present simple',
          prompt: 'My father ___ in a hospital.',
          options: const <String>['work', 'works', 'working'],
          answer: 'works',
          why: '"My father" is he, so the verb takes -s: works.',
          rule: 'he / she / it + verb-s',
          example: 'My father works in a hospital.',
          notes: const <String, String>{
            'work': 'With he, she or it, add -s: works.',
            'working': '"working" needs "is": he is working (now).',
          },
        ),
        Exercise.fill(
          id: 'g-a1-ps-2',
          topic: 'present simple',
          prompt: 'She ___ (watch) a film every Friday.',
          answers: const <String>['watches'],
          why: 'Verbs ending in -ch add -es with she: watches.',
          rule: '-sh, -ch, -o, -x → -es',
          example: 'She watches a film every Friday.',
        ),
        Exercise.choice(
          id: 'g-a1-ps-3',
          topic: 'present simple',
          prompt: '___ your brother play football?',
          options: const <String>['Do', 'Does', 'Is'],
          answer: 'Does',
          why: 'Questions with he, she or it use "does".',
          rule: 'Does + he/she/it + base verb?',
          example: 'Does your brother play football?',
          notes: const <String, String>{
            'Do': '"Do" goes with I, you, we and they.',
            'Is': '"Is" does not go with the base verb "play".',
          },
        ),
        Exercise.order(
          id: 'g-a1-ps-4',
          topic: 'present simple',
          sentence: 'We do not have classes on Sunday',
          why: 'Negative: subject + do not + base verb.',
          rule: 'I/you/we/they + do not + base verb',
        ),
        Exercise.trueFalse(
          id: 'g-a1-ps-5',
          topic: 'present simple',
          prompt: '"He don’t like coffee" is correct.',
          answer: false,
          why: 'With he, use "doesn’t": He doesn’t like coffee.',
          rule: 'he / she / it + doesn’t + base verb',
          example: 'He doesn’t like coffee.',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.fill(
          id: 'g-a1-ps-6',
          topic: 'present simple',
          prompt: 'Tom ___ (go) to school by bus.',
          answers: const <String>['goes'],
          why: '"go" ends in -o, so it becomes "goes" with he.',
          rule: '-o → -es: go → goes, do → does',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'g-a1-ps-7',
          topic: 'present simple',
          prompt: 'Does she ___ English?',
          options: const <String>['speak', 'speaks', 'speaking'],
          answer: 'speak',
          why: 'After "does", the verb has no -s: Does she speak?',
          rule: 'does + base verb',
          notes: const <String, String>{
            'speaks': '"does" already shows he/she/it: no second -s.',
          },
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'grammar-a2-comparatives',
    title: 'Comparing things',
    description: 'Comparatives and superlatives.',
    skill: LessonSkill.grammar,
    levelIndex: 1,
    topic: 'comparatives',
    estimatedMinutes: 7,
    xpReward: 25,
    objective: 'Compare people, places and things correctly.',
    tags: const <String>['travel', 'basics'],
    activities: <LessonActivity>[
      introActivity(
        'Comparatives and superlatives',
        const <String>[
          'Short adjectives: add -er / -est. cheap → cheaper → the cheapest.',
          'Long adjectives: more / the most. expensive → more expensive → the '
              'most expensive.',
          'Irregular: good → better → the best; bad → worse → the worst; far → '
              'farther/further.',
          'Compare two things with "than": Trains are faster than buses.',
        ],
        const <String>[
          'My room is bigger than yours.',
          'This is the most beautiful beach in the region.',
          'Today is better than yesterday.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'g-a2-comp-1',
          topic: 'comparatives',
          prompt: 'A plane is ___ than a train.',
          options: const <String>['faster', 'fastest', 'more fast'],
          answer: 'faster',
          why: '"fast" is short: add -er, and compare with "than".',
          rule: 'short adjective + -er + than',
          example: 'A plane is faster than a train.',
          notes: const <String, String>{
            'fastest': 'The superlative needs "the" and compares a group.',
            'more fast': 'Short adjectives take -er, not "more".',
          },
        ),
        Exercise.fill(
          id: 'g-a2-comp-2',
          topic: 'comparatives',
          prompt:
              'This hotel is ___ (expensive) than the one near the station.',
          answers: const <String>['more expensive'],
          why: '"expensive" is long, so we use "more".',
          rule: 'more + long adjective + than',
          example: 'This hotel is more expensive than the other one.',
        ),
        Exercise.choice(
          id: 'g-a2-comp-3',
          topic: 'comparatives',
          prompt: 'It was the ___ day of my holiday.',
          options: const <String>['good', 'better', 'best'],
          answer: 'best',
          why:
              'After "the", one day in a group: the superlative of good is '
              '"best".',
          rule: 'good → better → the best',
          notes: const <String, String>{
            'better': '"better" compares two things, with "than".',
          },
        ),
        Exercise.trueFalse(
          id: 'g-a2-comp-4',
          topic: 'comparatives',
          prompt: '"My sister is more tall than me" is correct.',
          answer: false,
          why: '"tall" is short: taller than.',
          rule: 'short adjective + -er',
          example: 'My sister is taller than me.',
        ),
        Exercise.fill(
          id: 'g-a2-comp-5',
          topic: 'comparatives',
          prompt: 'The weather today is ___ (bad) than yesterday.',
          answers: const <String>['worse'],
          why: '"bad" is irregular: bad → worse → the worst.',
          rule: 'bad → worse → the worst',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.order(
          id: 'g-a2-comp-6',
          topic: 'comparatives',
          sentence: 'This is the most interesting book I have read',
          why: 'Long adjective: the most + adjective.',
          rule: 'the most + long adjective',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'g-a2-comp-7',
          topic: 'comparatives',
          prompt: 'Our new flat is ___ than the old one.',
          options: const <String>['bigger', 'biger', 'more big'],
          answer: 'bigger',
          why: 'One vowel + one consonant at the end: double it. big → bigger.',
          rule: 'big → bigger, hot → hotter',
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'grammar-b1-modals-obligation',
    title: 'Should, must and have to',
    description: 'Advice, obligation and no obligation.',
    skill: LessonSkill.grammar,
    levelIndex: 2,
    topic: 'modals of obligation',
    estimatedMinutes: 8,
    xpReward: 30,
    difficulty: 2,
    objective: 'Choose the right modal for advice and rules.',
    tags: const <String>['career', 'travel'],
    activities: <LessonActivity>[
      introActivity(
        'Advice and obligation',
        const <String>[
          'should: advice. You should sleep more.',
          'must / have to: obligation. You must wear a seatbelt. I have to '
              'work on Saturday.',
          'mustn’t: it is forbidden. You mustn’t smoke here.',
          'don’t have to: it is not necessary (but allowed). You don’t have to '
              'come.',
        ],
        const <String>[
          'You should try the local food.',
          'Visitors must show their tickets.',
          'You don’t have to bring anything; we have everything.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'g-b1-mod-1',
          topic: 'modals of obligation',
          prompt: 'You look tired. You ___ go to bed earlier.',
          options: const <String>['should', 'mustn’t', 'don’t have to'],
          answer: 'should',
          why: 'This is advice, so "should".',
          rule: 'should + base verb = advice',
          notes: const <String, String>{
            'mustn’t': '"mustn’t" means it is forbidden.',
            'don’t have to': '"don’t have to" means it is not necessary.',
          },
        ),
        Exercise.choice(
          id: 'g-b1-mod-2',
          topic: 'modals of obligation',
          prompt: 'It’s Saturday, so I ___ get up early. I can sleep.',
          options: const <String>['don’t have to', 'mustn’t', 'must'],
          answer: 'don’t have to',
          why: 'Getting up early is not necessary: "don’t have to".',
          rule: 'don’t have to = not necessary',
          notes: const <String, String>{
            'mustn’t': '"mustn’t" would mean getting up early is forbidden.',
          },
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'g-b1-mod-3',
          topic: 'modals of obligation',
          prompt: 'You ___ use your phone during the exam. It is not allowed.',
          options: const <String>['mustn’t', 'don’t have to', 'shouldn’t to'],
          answer: 'mustn’t',
          why: 'It is forbidden: "mustn’t".',
          rule: 'mustn’t = forbidden',
          notes: const <String, String>{
            'shouldn’t to':
                'Modals are followed by the base verb, without '
                '"to".',
          },
        ),
        Exercise.fill(
          id: 'g-b1-mod-4',
          topic: 'modals of obligation',
          prompt: 'Yesterday I ___ (have to) finish my report before six.',
          answers: const <String>['had to'],
          why: '"must" has no past form; use "had to".',
          rule: 'past obligation: had to',
          example: 'I had to finish my report.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'g-b1-mod-5',
          topic: 'modals of obligation',
          prompt: '"She musts work tomorrow" is correct.',
          answer: false,
          why: 'Modals never take -s: She must work tomorrow.',
          rule: 'modal + base verb, no -s',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'g-b1-mod-6',
          topic: 'modals of obligation',
          prompt: 'Entry is free: you ___ pay.',
          options: const <String>['don’t have to', 'mustn’t', 'have to'],
          answer: 'don’t have to',
          why: 'Paying is not necessary, not forbidden.',
          rule: 'don’t have to = not necessary',
          difficulty: 3,
        ),
        Exercise.order(
          id: 'g-b1-mod-7',
          topic: 'modals of obligation',
          sentence: 'Do we have to wear a uniform',
          prompt: 'Build the question.',
          why: 'Questions with "have to" use do/does.',
          rule: 'Do + subject + have to + base verb?',
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'grammar-b2-relative-clauses',
    title: 'Relative clauses',
    description: 'Who, which, that, whose and where.',
    skill: LessonSkill.grammar,
    levelIndex: 3,
    topic: 'relative clauses',
    estimatedMinutes: 9,
    xpReward: 35,
    difficulty: 2,
    objective: 'Join ideas with defining and non-defining relative clauses.',
    tags: const <String>['academic', 'career'],
    activities: <LessonActivity>[
      introActivity(
        'Relative clauses',
        const <String>[
          'who for people, which for things, whose for possession, where for '
              'places.',
          'Defining clauses (no commas) say which one: The man who called is '
              'my uncle. "that" can replace who/which here.',
          'Non-defining clauses (with commas) add extra information: My uncle, '
              'who lives in Rome, is a chef. "that" is not possible here.',
        ],
        const <String>[
          'The book that I borrowed is excellent.',
          'Paris, which I visited last year, was crowded.',
          'She is the student whose project won.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'g-b2-rel-1',
          topic: 'relative clauses',
          prompt: 'That’s the café ___ we first met.',
          options: const <String>['where', 'which', 'who'],
          answer: 'where',
          why: 'For a place with a full clause after it, use "where".',
          rule: 'place + where + subject + verb',
          notes: const <String, String>{
            'which': '"which" would need a preposition: the café in which…',
          },
        ),
        Exercise.choice(
          id: 'g-b2-rel-2',
          topic: 'relative clauses',
          prompt: 'I know a girl ___ brother plays for the national team.',
          options: const <String>['whose', 'who', 'that'],
          answer: 'whose',
          why: 'Possession (her brother) is "whose".',
          rule: 'whose + noun = possession',
        ),
        Exercise.choice(
          id: 'g-b2-rel-3',
          topic: 'relative clauses',
          prompt: 'My phone, ___ I bought last month, has already broken.',
          options: const <String>['which', 'that', 'what'],
          answer: 'which',
          why: 'With commas (extra information), "that" is not possible.',
          rule: 'non-defining clause: who / which, never that',
          notes: const <String, String>{
            'that': '"that" is only for defining clauses, without commas.',
            'what': '"what" is not a relative pronoun after a noun.',
          },
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'g-b2-rel-4',
          topic: 'relative clauses',
          prompt:
              'In "The film that we watched was long", "that" can be left '
              'out.',
          answer: true,
          why:
              '"that" is the object of "watched", so it can be omitted: The '
              'film we watched was long.',
          rule: 'object pronoun in a defining clause can be omitted',
          difficulty: 2,
        ),
        Exercise.fill(
          id: 'g-b2-rel-5',
          topic: 'relative clauses',
          prompt: 'The scientist ___ discovered the vaccine received a prize.',
          answers: const <String>['who', 'that'],
          why: 'A person who is the subject: "who" (or "that").',
          rule: 'person + who/that + verb',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'g-b2-rel-6',
          topic: 'relative clauses',
          prompt: 'He passed all his exams, ___ surprised everyone.',
          options: const <String>['which', 'that', 'what'],
          answer: 'which',
          why: '"which" can refer to the whole previous idea.',
          rule: ', which = and this',
          difficulty: 3,
        ),
        Exercise.order(
          id: 'g-b2-rel-7',
          topic: 'relative clauses',
          sentence: 'The town where I grew up has changed a lot',
          why: 'The relative clause "where I grew up" follows "town".',
          rule: 'noun + relative clause + main verb',
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'grammar-c1-mixed-conditionals',
    title: 'Mixed conditionals',
    description: 'Link the past and the present in imaginary situations.',
    skill: LessonSkill.grammar,
    levelIndex: 4,
    topic: 'mixed conditionals',
    estimatedMinutes: 9,
    xpReward: 40,
    difficulty: 3,
    objective: 'Combine past causes and present results, and the reverse.',
    tags: const <String>['academic', 'fluency'],
    activities: <LessonActivity>[
      introActivity(
        'Mixed conditionals',
        const <String>[
          'Past cause → present result: If + past perfect, would + base verb. '
              'If I had taken the job, I would live in Tokyo now.',
          'Present situation → past result: If + past simple, would have + past '
              'participle. If she were more careful, she wouldn’t have lost her '
              'keys.',
          'Time words (now, yesterday) help you see which half is past and '
              'which is present.',
        ],
        const <String>[
          'If I had studied medicine, I would be a doctor now.',
          'If he spoke French, he would have understood the guide.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'g-c1-mix-1',
          topic: 'mixed conditionals',
          prompt: 'If I had saved more money last year, I ___ on holiday now.',
          options: const <String>['would be', 'would have been', 'will be'],
          answer: 'would be',
          why:
              'Past cause (last year), present result (now): would + base '
              'verb.',
          rule: 'If + past perfect, would + base verb (now)',
          notes: const <String, String>{
            'would have been':
                'That is a past result; "now" shows a present '
                'result.',
          },
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'g-c1-mix-2',
          topic: 'mixed conditionals',
          prompt: 'If she weren’t so shy, she ___ to the party last night.',
          options: const <String>['would have come', 'would come', 'came'],
          answer: 'would have come',
          why: 'Present character (shy), past result (last night).',
          rule: 'If + past simple, would have + past participle',
          difficulty: 3,
        ),
        Exercise.fill(
          id: 'g-c1-mix-3',
          topic: 'mixed conditionals',
          prompt: 'If they ___ (not miss) the train, they would be here now.',
          answers: const <String>['hadn’t missed', 'had not missed'],
          why: 'The cause is in the past: past perfect.',
          rule: 'past cause: if + past perfect',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'g-c1-mix-4',
          topic: 'mixed conditionals',
          prompt:
              '"If I had learned to drive, I would drive to work today" '
              'is a correct mixed conditional.',
          answer: true,
          why:
              'Past cause (had learned) and present result (would drive '
              'today).',
          rule: 'If + past perfect, would + base verb',
          difficulty: 2,
        ),
        Exercise.order(
          id: 'g-c1-mix-5',
          topic: 'mixed conditionals',
          sentence: 'If he were more organised he would have finished on time',
          why:
              'Present quality (were organised), past result (would have '
              'finished).',
          rule: 'If + past simple, would have + past participle',
          difficulty: 3,
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'g-c1-mix-6',
          topic: 'mixed conditionals',
          prompt: 'I ___ so tired today if I hadn’t stayed up so late.',
          options: const <String>[
            'wouldn’t be',
            'wouldn’t have been',
            'won’t be',
          ],
          answer: 'wouldn’t be',
          why: 'Present result (today) of a past cause (stayed up).',
          rule: 'would + base verb, if + past perfect',
          difficulty: 3,
        ),
        Exercise.fill(
          id: 'g-c1-mix-7',
          topic: 'mixed conditionals',
          prompt:
              'If I ___ (be) taller, I would have joined the basketball '
              'team at school.',
          answers: const <String>['were', 'was'],
          why:
              'A present (permanent) quality: past simple, "were" (or '
              '"was" informally).',
          rule: 'If + past simple, would have + past participle',
          difficulty: 3,
        ),
      ]),
    ],
  ),
];
