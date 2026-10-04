import '../models/lesson_models.dart';
import 'content_helpers.dart';

final List<Lesson> readingLessons = <Lesson>[
  Lesson(
    id: 'reading-a1-lena',
    title: 'Lena and Max',
    description: 'A short text about a morning routine.',
    skill: LessonSkill.reading,
    levelIndex: 0,
    topic: 'finding details',
    estimatedMinutes: 4,
    xpReward: 20,
    objective: 'Find simple facts in a short text.',
    tags: const <String>['basics'],
    passage:
        'My name is Lena. I live in a small house with my brother. We have a dog called Max.\n\n'
        'Every morning I walk with Max in the park. In the afternoon I go to school.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Read the text slowly. Then answer each question by finding the detail in the text.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-a1-1',
          topic: 'finding details',
          prompt: 'Who does Lena live with?',
          options: const <String>['Her brother', 'Her sister', 'Her friend'],
          answer: 'Her brother',
          why: 'The first paragraph says: "I live in a small house with my brother."',
          evidence: 'Look at the first paragraph, second sentence.',
          notes: const <String, String>{
            'Her sister': 'The text mentions a brother, not a sister.',
          },
        ),
        Exercise.trueFalse(
          id: 'r-a1-2',
          topic: 'finding details',
          prompt: 'Lena has a cat.',
          answer: false,
          why: 'The text says they have a dog called Max.',
          evidence: 'Look at the last sentence of the first paragraph.',
        ),
        Exercise.choice(
          id: 'r-a1-3',
          topic: 'finding details',
          prompt: 'When does Lena walk with Max?',
          options: const <String>[
            'Every morning',
            'In the afternoon',
            'Every night',
          ],
          answer: 'Every morning',
          why: 'The second paragraph begins: "Every morning I walk with Max in the park."',
          evidence: 'Look at the first sentence of the second paragraph.',
          notes: const <String, String>{
            'In the afternoon': 'In the afternoon Lena goes to school.',
          },
        ),
        Exercise.fill(
          id: 'r-a1-4',
          topic: 'finding details',
          prompt: 'Max is a ___.',
          answers: const <String>['dog'],
          why: 'The text says: "We have a dog called Max."',
          evidence: 'Look at the first paragraph.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-a2-market',
    title: 'The Saturday market',
    description: 'Understand a text about weekend plans.',
    skill: LessonSkill.reading,
    levelIndex: 1,
    topic: 'main idea and details',
    estimatedMinutes: 5,
    xpReward: 25,
    objective: 'Identify the main idea and key details.',
    tags: const <String>['travel', 'basics'],
    passage:
        'Every Saturday morning, the town centre has a market. People sell fresh fruit, bread and flowers. '
        'It starts at eight o\'clock and finishes at one.\n\n'
        'Last Saturday, I went with my friend Sara. We bought strawberries and a loaf of bread. '
        'It rained in the afternoon, so we went home early and made sandwiches.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Read the text once for the general idea, then look for details when you answer.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-a2-1',
          topic: 'main idea and details',
          prompt: 'What is the text mostly about?',
          options: const <String>[
            'A weekly market and a visit there',
            'A school lesson',
            'A holiday in Spain',
          ],
          answer: 'A weekly market and a visit there',
          why: 'Both paragraphs are about the Saturday market: what it is and a visit last Saturday.',
          evidence: 'Think about what both paragraphs have in common.',
        ),
        Exercise.choice(
          id: 'r-a2-2',
          topic: 'main idea and details',
          prompt: 'What time does the market finish?',
          options: const <String>['At eight', 'At one', 'In the afternoon'],
          answer: 'At one',
          why: 'The first paragraph says it starts at eight and finishes at one.',
          evidence: 'Look at the last sentence of the first paragraph.',
          notes: const <String, String>{'At eight': 'Eight is when it starts, not when it finishes.'},
        ),
        Exercise.trueFalse(
          id: 'r-a2-3',
          topic: 'main idea and details',
          prompt: 'The writer bought flowers at the market.',
          answer: false,
          why: 'The writer bought strawberries and bread. Flowers are sold there, but the writer did not buy them.',
          evidence: 'Look at the second paragraph, second sentence.',
        ),
        Exercise.choice(
          id: 'r-a2-4',
          topic: 'main idea and details',
          prompt: 'Why did they go home early?',
          options: const <String>['It rained', 'They were hungry', 'The market closed'],
          answer: 'It rained',
          why: 'The text says: "It rained in the afternoon, so we went home early."',
          evidence: 'Find the word "so" in the last sentence: it points to the reason.',
          notes: const <String, String>{
            'The market closed': 'The market finishes at one, but the text gives rain as the reason.',
          },
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-b1-remote-work',
    title: 'Working from home',
    description: 'Read about the benefits and problems of remote work.',
    skill: LessonSkill.reading,
    levelIndex: 2,
    topic: 'inference',
    estimatedMinutes: 7,
    xpReward: 30,
    difficulty: 2,
    objective: 'Understand opinions and draw simple inferences.',
    tags: const <String>['career', 'technology'],
    passage:
        'Over the last decade, more and more people have started working from home. '
        'Many employees say it saves hours of travel and allows them to organise their day more freely.\n\n'
        'However, remote work is not perfect for everyone. Some workers say they feel isolated because they rarely meet colleagues, '
        'and others find it hard to switch off after work.\n\n'
        'As a result, a number of companies now offer a mixed model: two or three days at home and the rest in the office.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'This text gives different points of view. Notice linking words such as "however" and "as a result".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-b1-1',
          topic: 'inference',
          prompt: 'According to the text, what is one advantage of working from home?',
          options: const <String>[
            'It saves travel time',
            'It improves team meetings',
            'It lowers salaries',
          ],
          answer: 'It saves travel time',
          why: 'The first paragraph says it "saves hours of travel".',
          evidence: 'Look at the first paragraph, last sentence.',
        ),
        Exercise.choice(
          id: 'r-b1-2',
          topic: 'inference',
          prompt: 'What does "However" at the start of the second paragraph signal?',
          options: const <String>[
            'A contrast with the previous ideas',
            'An example of the previous idea',
            'A final conclusion',
          ],
          answer: 'A contrast with the previous ideas',
          why: '"However" introduces a contrast: the first paragraph is positive and the second describes problems.',
          evidence: 'Compare the tone of paragraphs one and two.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'r-b1-3',
          topic: 'inference',
          prompt: 'The text says all workers prefer working from home.',
          answer: false,
          why: 'The text says remote work "is not perfect for everyone" and gives problems such as isolation.',
          evidence: 'Look at the first sentence of the second paragraph.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-b1-4',
          topic: 'inference',
          prompt: 'Why do some companies offer a mixed model?',
          options: const <String>[
            'To reduce the problems of fully remote work while keeping its advantages',
            'Because offices are cheaper',
            'Because employees dislike travel',
          ],
          answer: 'To reduce the problems of fully remote work while keeping its advantages',
          why: 'The third paragraph begins with "As a result": companies react to both the benefits and the problems.',
          evidence: 'Look at "As a result" in the last paragraph and link it to the previous paragraphs.',
          notes: const <String, String>{
            'Because offices are cheaper': 'The text does not mention cost.',
          },
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-b2-bikes',
    title: 'A city changes its streets',
    description: 'Follow an argument about city planning.',
    skill: LessonSkill.reading,
    levelIndex: 3,
    topic: 'argument and attitude',
    estimatedMinutes: 8,
    xpReward: 35,
    difficulty: 2,
    objective: 'Identify an author\'s argument and attitude.',
    tags: const <String>['academic', 'culture'],
    passage:
        'When the city council closed the main street to cars, many shop owners predicted disaster. '
        'Yet after a year, the number of visitors had risen by almost a fifth.\n\n'
        'Critics argue that the figures are misleading, because the street was also redesigned and new cafés opened at the same time. '
        'Supporters reply that fewer cars made the area quieter and safer, which is exactly why people stayed longer.\n\n'
        'What is clear is that the outcome was far from the disaster that had been predicted.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Pay attention to who says what: the council, shop owners, critics and supporters.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-b2-1',
          topic: 'argument and attitude',
          prompt: 'What did many shop owners expect at first?',
          options: const <String>['A disaster', 'More customers', 'No change'],
          answer: 'A disaster',
          why: 'The first sentence says they "predicted disaster".',
          evidence: 'Look at the first sentence.',
        ),
        Exercise.choice(
          id: 'r-b2-2',
          topic: 'argument and attitude',
          prompt: 'Why do critics doubt the figures?',
          options: const <String>[
            'Other changes happened at the same time',
            'The council invented the numbers',
            'Fewer people visited the street',
          ],
          answer: 'Other changes happened at the same time',
          why: 'The second paragraph says the street was redesigned and new cafés opened as well.',
          evidence: 'Look at the first sentence of the second paragraph, after "because".',
          notes: const <String, String>{
            'Fewer people visited the street': 'The text says visitors rose by almost a fifth.',
          },
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'r-b2-3',
          topic: 'argument and attitude',
          prompt: 'Supporters say the area became noisier.',
          answer: false,
          why: 'Supporters say fewer cars made the area quieter and safer.',
          evidence: 'Look at the second sentence of the second paragraph.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-b2-4',
          topic: 'argument and attitude',
          prompt: 'What is the writer\'s attitude in the final sentence?',
          options: const <String>[
            'Cautiously positive about the result',
            'Strongly opposed to the change',
            'Completely neutral and uninterested',
          ],
          answer: 'Cautiously positive about the result',
          why: 'The writer says the result was "far from the disaster" predicted, which is positive without claiming the figures are perfect.',
          evidence: 'Read the final sentence and notice "far from the disaster".',
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-c1-attention',
    title: 'The limits of multitasking',
    description: 'Analyse a nuanced argument about attention.',
    skill: LessonSkill.reading,
    levelIndex: 4,
    topic: 'implied meaning',
    estimatedMinutes: 9,
    xpReward: 40,
    difficulty: 3,
    objective: 'Understand implied meaning and the structure of an argument.',
    tags: const <String>['academic', 'technology'],
    passage:
        'Multitasking is often celebrated as a mark of efficiency, yet the evidence suggests that what we call multitasking is rarely simultaneous. '
        'More accurately, the brain switches rapidly between tasks, and each switch carries a small but measurable cost.\n\n'
        'Admittedly, some routine activities can be combined without difficulty, such as walking while listening to music. '
        'It is when both tasks demand focused thought that performance declines, and, paradoxically, people tend to overestimate how well they cope.\n\n'
        'The implication is not that we should abandon flexibility altogether, but that we should be sceptical of our own confidence.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'This is an argument with concessions. Notice words such as "yet", "admittedly" and "paradoxically".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-c1-1',
          topic: 'implied meaning',
          prompt: 'According to the first paragraph, what really happens when people "multitask"?',
          options: const <String>[
            'The brain switches rapidly between tasks',
            'The brain processes everything simultaneously',
            'The brain ignores the second task',
          ],
          answer: 'The brain switches rapidly between tasks',
          why: 'The writer says multitasking is "rarely simultaneous" and that the brain switches between tasks.',
          evidence: 'Look at the second sentence of the first paragraph.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-c1-2',
          topic: 'implied meaning',
          prompt: 'What is the function of "Admittedly" in the second paragraph?',
          options: const <String>[
            'It concedes a point that limits the writer\'s claim',
            'It introduces the main conclusion',
            'It gives a personal anecdote',
          ],
          answer: 'It concedes a point that limits the writer\'s claim',
          why: '"Admittedly" acknowledges that some activities can be combined, so the claim is not absolute.',
          evidence: 'Notice how the sentence after "Admittedly" qualifies the first paragraph.',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'r-c1-3',
          topic: 'implied meaning',
          prompt: 'The writer suggests people judge their own multitasking ability accurately.',
          answer: false,
          why: 'The text says people "tend to overestimate how well they cope".',
          evidence: 'Look at "paradoxically" in the second paragraph.',
          difficulty: 3,
        ),
        Exercise.choice(
          id: 'r-c1-4',
          topic: 'implied meaning',
          prompt: 'What does the writer recommend in the final paragraph?',
          options: const <String>[
            'Being sceptical of our own confidence',
            'Stopping all flexible work',
            'Trusting our instincts more',
          ],
          answer: 'Being sceptical of our own confidence',
          why: 'The last sentence says we should be sceptical of our own confidence while not abandoning flexibility.',
          evidence: 'Read the last sentence and notice "not ... but ...".',
          notes: const <String, String>{
            'Stopping all flexible work': 'The writer says we need not "abandon flexibility altogether".',
          },
          difficulty: 3,
        ),
      ]),
    ],
  ),
];
