import '../../../services/voice/listening_accents.dart';
import '../models/lesson_models.dart';
import 'content_helpers.dart';

const ListeningAccent _us = ListeningAccent.american;
const ListeningAccent _uk = ListeningAccent.british;
const ListeningAccent _au = ListeningAccent.australian;

/// Dialogues with several speakers and American, British and Australian
/// accents. New question types: who said it, and dictation. Scripts are
/// original.
final List<Lesson> moreListeningLessons = <Lesson>[
  Lesson(
    id: 'listening-a1-cafe',
    title: 'At the café',
    description: 'Order a drink in a London café.',
    skill: LessonSkill.listening,
    levelIndex: 0,
    topic: 'basic details',
    estimatedMinutes: 4,
    xpReward: 20,
    objective: 'Understand prices, orders and who says what.',
    tags: const <String>['travel', 'basics'],
    audio: const <AudioLine>[
      AudioLine('Barista', 'Hello! What can I get you?', accent: _uk),
      AudioLine('Leo', 'Can I have a hot chocolate, please?', accent: _us),
      AudioLine('Barista', 'Of course. Small or large?', accent: _uk),
      AudioLine('Leo', 'Small, please. How much is it?', accent: _us),
      AudioLine('Barista', 'Three pounds fifty. Anything else?', accent: _uk),
      AudioLine('Leo', 'No, thanks. That’s all.', accent: _us),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'Two people speak with different accents: a British barista and an '
            'American customer. Listen for the drink, the size and the price.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-a1-cafe-1',
          topic: 'basic details',
          prompt: 'What does Leo order?',
          options: const <String>['A hot chocolate', 'A tea', 'A coffee'],
          answer: 'A hot chocolate',
          why: 'Leo asks for "a hot chocolate".',
          evidence: 'Listen to Leo’s first line.',
        ),
        Exercise.choice(
          id: 'l-a1-cafe-2',
          topic: 'basic details',
          prompt: 'How much does it cost?',
          options: const <String>['£3.50', '£5.30', '£3.15'],
          answer: '£3.50',
          why: '"Three pounds fifty" is £3.50.',
          evidence: 'Listen to the barista’s answer about the price.',
        ),
        Exercise.choice(
          id: 'l-a1-cafe-3',
          topic: 'basic details',
          prompt: 'Who says it? "Anything else?"',
          options: const <String>['The barista', 'Leo'],
          answer: 'The barista',
          why: 'The person serving asks "Anything else?".',
          evidence: 'Listen to the line after the price.',
        ),
        Exercise.fill(
          id: 'l-a1-cafe-4',
          topic: 'basic details',
          prompt: 'Dictation: type what Leo answers about the size.',
          answers: const <String>['Small, please', 'small please'],
          why: 'Leo says "Small, please."',
          hints: const <String>['Two words, a size and a polite word.'],
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-a2-directions',
    title: 'Finding the station',
    description: 'Directions from a local in Sydney.',
    skill: LessonSkill.listening,
    levelIndex: 1,
    topic: 'times and plans',
    estimatedMinutes: 5,
    xpReward: 25,
    objective: 'Follow simple directions and distances.',
    tags: const <String>['travel'],
    audio: const <AudioLine>[
      AudioLine(
        'Nina',
        'Excuse me, how do I get to the train station?',
        accent: _uk,
      ),
      AudioLine(
        'Local',
        'Sure. Go straight down this street and turn left at the bank.',
        accent: _au,
      ),
      AudioLine('Nina', 'Left at the bank. Is it far?', accent: _uk),
      AudioLine(
        'Local',
        'Not really, about ten minutes on foot. The station is opposite '
            'the big park.',
        accent: _au,
      ),
      AudioLine('Nina', 'Great, thanks a lot!', accent: _uk),
      AudioLine('Local', 'No worries. Have a good one!', accent: _au),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A British tourist asks an Australian local for directions. Listen '
            'for the turn, the time and a landmark.',
        '"No worries" is a very common Australian way to say "you’re '
            'welcome".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-a2-dir-1',
          topic: 'times and plans',
          prompt: 'Where should Nina turn left?',
          options: const <String>['At the bank', 'At the park', 'At the café'],
          answer: 'At the bank',
          why: 'The local says "turn left at the bank".',
          evidence: 'Listen to the local’s first answer.',
        ),
        Exercise.fill(
          id: 'l-a2-dir-2',
          topic: 'times and plans',
          prompt: 'How many minutes is the walk?',
          answers: const <String>['ten', '10'],
          why: '"about ten minutes on foot".',
          evidence: 'Listen for "on foot".',
        ),
        Exercise.trueFalse(
          id: 'l-a2-dir-3',
          topic: 'times and plans',
          prompt: 'The station is next to the bank.',
          answer: false,
          why: 'The station is opposite the big park.',
          evidence: 'Listen to the end of the local’s second line.',
        ),
        Exercise.choice(
          id: 'l-a2-dir-4',
          topic: 'times and plans',
          prompt: 'What does "No worries" mean here?',
          options: const <String>[
            'You’re welcome',
            'Don’t be afraid',
            'I’m not sure',
          ],
          answer: 'You’re welcome',
          why: 'It answers "thanks a lot", like "you’re welcome".',
          evidence: 'Listen to the last two lines.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-b1-flatmates',
    title: 'Sharing a flat',
    description: 'Three flatmates organise the chores.',
    skill: LessonSkill.listening,
    levelIndex: 2,
    topic: 'implied meaning',
    estimatedMinutes: 6,
    xpReward: 30,
    difficulty: 2,
    objective: 'Follow a three-person conversation and who agrees to what.',
    tags: const <String>['speaking', 'basics'],
    audio: const <AudioLine>[
      AudioLine(
        'Priya',
        'Right, we need a plan for the cleaning. The kitchen was a disaster '
            'last week.',
        accent: _uk,
      ),
      AudioLine(
        'Jake',
        'Fair enough. I’ll take the kitchen if someone else does the '
            'bathroom.',
        accent: _au,
      ),
      AudioLine(
        'Dana',
        'I can do the bathroom, but not on Saturdays. I work all day.',
        accent: _us,
      ),
      AudioLine(
        'Priya',
        'Then I’ll do the shopping and take the rubbish out. Shall we swap '
            'every month?',
        accent: _uk,
      ),
      AudioLine(
        'Jake',
        'Every month sounds good. Can we write it on the fridge?',
        accent: _au,
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'Three speakers, three accents: British, Australian and American. '
            'Note who agrees to which job.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-b1-flat-1',
          topic: 'implied meaning',
          prompt: 'Who will clean the kitchen?',
          options: const <String>['Jake', 'Dana', 'Priya'],
          answer: 'Jake',
          why: 'Jake says "I’ll take the kitchen".',
          evidence: 'Listen to the Australian speaker.',
        ),
        Exercise.choice(
          id: 'l-b1-flat-2',
          topic: 'implied meaning',
          prompt: 'Why can’t Dana clean on Saturdays?',
          options: const <String>[
            'She works all day',
            'She goes shopping',
            'She visits her family',
          ],
          answer: 'She works all day',
          why: 'Dana says "I work all day" on Saturdays.',
          evidence: 'Listen to Dana’s only line.',
        ),
        Exercise.choice(
          id: 'l-b1-flat-3',
          topic: 'implied meaning',
          prompt: 'Who says it? "Shall we swap every month?"',
          options: const <String>['Priya', 'Jake', 'Dana'],
          answer: 'Priya',
          why: 'Priya suggests swapping after choosing the shopping.',
          evidence: 'Listen to the fourth line.',
        ),
        Exercise.trueFalse(
          id: 'l-b1-flat-4',
          topic: 'implied meaning',
          prompt: 'Priya was happy with the kitchen last week.',
          answer: false,
          why: 'She calls it "a disaster": she was not happy.',
          evidence: 'Listen to the first line.',
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-b1-forecast',
    title: 'The weather forecast',
    description: 'A radio forecast for the weekend.',
    skill: LessonSkill.listening,
    levelIndex: 2,
    topic: 'times and plans',
    estimatedMinutes: 5,
    xpReward: 30,
    difficulty: 2,
    objective: 'Catch times, numbers and changes in a forecast.',
    tags: const <String>['travel'],
    audio: const <AudioLine>[
      AudioLine(
        'Presenter',
        'Good morning, here’s your weekend forecast. Saturday starts '
            'cloudy, with temperatures around sixty-five degrees.',
        accent: _us,
      ),
      AudioLine(
        'Presenter',
        'Heavy rain arrives in the afternoon, so if you’re planning a '
            'picnic, do it before lunch.',
        accent: _us,
      ),
      AudioLine(
        'Presenter',
        'Sunday will be sunny and warmer, reaching seventy-four, but the '
            'wind picks up in the evening.',
        accent: _us,
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'American forecasts often use Fahrenheit: sixty-five degrees is about '
            '18 °C, seventy-four about 23 °C.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-b1-fc-1',
          topic: 'times and plans',
          prompt: 'When is the best time for a picnic on Saturday?',
          options: const <String>[
            'Before lunch',
            'In the afternoon',
            'In the evening',
          ],
          answer: 'Before lunch',
          why: 'Rain arrives in the afternoon, so "do it before lunch".',
          evidence: 'Listen to the second sentence.',
        ),
        Exercise.fill(
          id: 'l-b1-fc-2',
          topic: 'times and plans',
          prompt: 'Sunday’s highest temperature (in degrees Fahrenheit):',
          answers: const <String>['74', 'seventy-four', 'seventy four'],
          why: 'Sunday reaches "seventy-four".',
          evidence: 'Listen to the last sentence.',
        ),
        Exercise.trueFalse(
          id: 'l-b1-fc-3',
          topic: 'times and plans',
          prompt: 'Sunday will be calm all day.',
          answer: false,
          why: 'The wind picks up in the evening.',
          evidence: 'Listen to the end of the forecast.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-b2-podcast',
    title: 'Podcast: homework',
    description: 'A host and a teacher discuss banning homework.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'attitude and tone',
    estimatedMinutes: 7,
    xpReward: 35,
    difficulty: 2,
    objective: 'Identify opinions, concessions and attitude.',
    tags: const <String>['academic', 'speaking'],
    audio: const <AudioLine>[
      AudioLine(
        'Host',
        'Some schools have stopped giving homework altogether. Is that '
            'brave or just naive?',
        accent: _us,
      ),
      AudioLine(
        'Teacher',
        'Honestly, a bit of both. Long homework often widens the gap, '
            'because some pupils have help at home and others don’t.',
        accent: _uk,
      ),
      AudioLine('Host', 'So you’d ban it?', accent: _us),
      AudioLine(
        'Teacher',
        'Not entirely. Ten minutes of reading every night is hard to '
            'argue against. What I’d drop is homework that only produces '
            'stress.',
        accent: _uk,
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'Listen for how the teacher qualifies her opinion: "a bit of both", '
            '"not entirely".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-b2-pod-1',
          topic: 'attitude and tone',
          prompt: 'What is the teacher’s overall position?',
          options: const <String>[
            'Keep short, useful homework and drop stressful tasks',
            'Ban all homework immediately',
            'Give more homework to every pupil',
          ],
          answer: 'Keep short, useful homework and drop stressful tasks',
          why:
              'She supports ten minutes of reading but would drop stressful '
              'homework.',
          evidence: 'Listen to her last answer.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'l-b2-pod-2',
          topic: 'attitude and tone',
          prompt: 'Why can long homework "widen the gap"?',
          options: const <String>[
            'Some pupils have help at home and others don’t',
            'Teachers have less time to mark it',
            'Pupils forget to do it',
          ],
          answer: 'Some pupils have help at home and others don’t',
          why: 'She explains the gap with unequal help at home.',
          evidence: 'Listen to her first answer.',
        ),
        Exercise.choice(
          id: 'l-b2-pod-3',
          topic: 'attitude and tone',
          prompt: 'Who says it? "Is that brave or just naive?"',
          options: const <String>['The host', 'The teacher'],
          answer: 'The host',
          why: 'The host asks the opening question.',
          evidence: 'Listen to the first line (American accent).',
        ),
        Exercise.fill(
          id: 'l-b2-pod-4',
          topic: 'attitude and tone',
          prompt:
              'Dictation: type the teacher’s first two words after '
              '"So you’d ban it?"',
          answers: const <String>['Not entirely'],
          why: 'She answers "Not entirely": a partial no.',
          hints: const <String>['A partial "no" in two words.'],
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-b2-interview',
    title: 'A job interview',
    description: 'An interview for a summer job at a museum.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'implied meaning',
    estimatedMinutes: 7,
    xpReward: 35,
    difficulty: 2,
    objective: 'Understand the purpose behind questions and answers.',
    tags: const <String>['career', 'speaking'],
    audio: const <AudioLine>[
      AudioLine(
        'Interviewer',
        'Thanks for coming in. Tell me about a time you dealt with a '
            'difficult visitor.',
        accent: _uk,
      ),
      AudioLine(
        'Mason',
        'At the aquarium last summer, a man was furious because the café '
            'had closed. I listened first, then offered him a voucher for '
            'his next visit.',
        accent: _au,
      ),
      AudioLine('Interviewer', 'And did that calm him down?', accent: _uk),
      AudioLine(
        'Mason',
        'It did. He actually came back a month later with his kids.',
        accent: _au,
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A British interviewer and an Australian candidate. Think about why '
            'the interviewer asks each question.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-b2-int-1',
          topic: 'implied meaning',
          prompt: 'What does the first question try to find out?',
          options: const <String>[
            'How Mason handles problems with people',
            'Whether Mason likes aquariums',
            'How much Mason earned last summer',
          ],
          answer: 'How Mason handles problems with people',
          why: 'A "difficult visitor" question tests how you handle people.',
          evidence: 'Listen to the interviewer’s first line.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'l-b2-int-2',
          topic: 'implied meaning',
          prompt: 'Why was the visitor angry?',
          options: const <String>[
            'The café had closed',
            'The tickets were expensive',
            'His children were lost',
          ],
          answer: 'The café had closed',
          why: 'Mason says he was furious "because the café had closed".',
          evidence: 'Listen to Mason’s first answer.',
        ),
        Exercise.trueFalse(
          id: 'l-b2-int-3',
          topic: 'implied meaning',
          prompt: 'Mason’s solution worked.',
          answer: true,
          why: '"It did": the man calmed down and even came back.',
          evidence: 'Listen to the last line.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'listening-c1-lecture',
    title: 'A lecture on city heat',
    description: 'A lecturer answers a student’s challenge.',
    skill: LessonSkill.listening,
    levelIndex: 4,
    topic: 'implied meaning',
    estimatedMinutes: 8,
    xpReward: 40,
    difficulty: 3,
    objective: 'Follow an academic exchange and the speaker’s stance.',
    tags: const <String>['academic'],
    audio: const <AudioLine>[
      AudioLine(
        'Lecturer',
        'Planting trees is often presented as the solution to urban heat. '
            'It is a solution, but a slow one: a young tree may take fifteen '
            'years to give meaningful shade.',
        accent: _uk,
      ),
      AudioLine(
        'Student',
        'Then shouldn’t cities focus on cool roofs instead? They work '
            'immediately.',
        accent: _us,
      ),
      AudioLine(
        'Lecturer',
        'They do, and they’re cheap. The catch is that they cool the '
            'building more than the street. Pedestrians may notice very '
            'little. So I would frame it as a sequence rather than a choice.',
        accent: _uk,
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'Listen for concessions ("It is a solution, but…", "They do, and…") '
            'and for the lecturer’s final position.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'l-c1-lec-1',
          topic: 'implied meaning',
          prompt: 'What is the lecturer’s main reservation about trees?',
          options: const <String>[
            'They take a long time to be effective',
            'They are too expensive',
            'They make streets hotter',
          ],
          answer: 'They take a long time to be effective',
          why: 'A young tree may take fifteen years to give real shade.',
          evidence: 'Listen to the first line.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'l-c1-lec-2',
          topic: 'implied meaning',
          prompt:
              'What does "frame it as a sequence rather than a choice" '
              'suggest?',
          options: const <String>[
            'Use cool roofs now and trees for the long term',
            'Choose cool roofs instead of trees',
            'Wait until trees grow before doing anything',
          ],
          answer: 'Use cool roofs now and trees for the long term',
          why:
              'A sequence means doing both, one after the other, not '
              'choosing one.',
          evidence: 'Connect the last sentence with the earlier points.',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'l-c1-lec-3',
          topic: 'implied meaning',
          prompt:
              'According to the lecturer, cool roofs make a big '
              'difference for people walking in the street.',
          answer: false,
          why:
              'They cool buildings more than streets: pedestrians may '
              'notice very little.',
          evidence: 'Listen for "The catch is…".',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'l-c1-lec-4',
          topic: 'implied meaning',
          prompt: 'Who says it? "They work immediately."',
          options: const <String>['The student', 'The lecturer'],
          answer: 'The student',
          why: 'The student argues for cool roofs.',
          evidence: 'Listen to the American speaker.',
        ),
      ]),
    ],
  ),
];
