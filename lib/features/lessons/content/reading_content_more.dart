import '../models/lesson_models.dart';
import 'content_helpers.dart';

/// Second reading lesson for each level A1–C1. Texts are original.
final List<Lesson> moreReadingLessons = <Lesson>[
  Lesson(
    id: 'reading-a1-new-school',
    title: 'A new school',
    description: 'Read a short text about Omar’s first day.',
    skill: LessonSkill.reading,
    levelIndex: 0,
    topic: 'basic details',
    estimatedMinutes: 5,
    xpReward: 20,
    objective: 'Find simple facts in a short text.',
    tags: const <String>['basics'],
    passage:
        'Omar is eleven. Today is his first day at a new school in Leeds. '
        'His old school was small, but this school is very big.\n\n'
        'His teacher is Mrs Hill. She is friendly and she speaks slowly. '
        'Omar sits next to a boy called Ben. Ben likes football, like Omar.\n\n'
        'At lunch, Omar eats pasta in the canteen. After school, his mother '
        'asks, "How was your day?" Omar smiles. "Good. I have a new friend."',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Read the text once for the general idea, then again to find '
            'details.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-a1-ns-1',
          topic: 'basic details',
          prompt: 'Where is Omar’s new school?',
          options: const <String>['In Leeds', 'In London', 'In Omar’s village'],
          answer: 'In Leeds',
          why: 'The first paragraph says "a new school in Leeds".',
          evidence: 'Look at the second sentence.',
        ),
        Exercise.trueFalse(
          id: 'r-a1-ns-2',
          topic: 'basic details',
          prompt: 'The new school is smaller than the old school.',
          answer: false,
          why: 'The old school was small; the new one is very big.',
          evidence: 'Look at the end of the first paragraph.',
        ),
        Exercise.choice(
          id: 'r-a1-ns-3',
          topic: 'basic details',
          prompt: 'What do Omar and Ben both like?',
          options: const <String>['Football', 'Pasta', 'Mrs Hill'],
          answer: 'Football',
          why: '"Ben likes football, like Omar."',
          evidence: 'Look at the second paragraph.',
        ),
        Exercise.choice(
          id: 'r-a1-ns-4',
          topic: 'basic details',
          prompt: 'How does Omar feel at the end of the day?',
          options: const <String>['Happy', 'Tired and sad', 'Angry'],
          answer: 'Happy',
          why: 'He smiles and says his day was good.',
          evidence: 'Look at the last two sentences.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-a2-email-friend',
    title: 'An email from Lucía',
    description: 'Read an email about a trip and plans.',
    skill: LessonSkill.reading,
    levelIndex: 1,
    topic: 'finding details',
    estimatedMinutes: 6,
    xpReward: 25,
    objective: 'Understand plans, times and reasons in an email.',
    tags: const <String>['travel'],
    passage:
        'Hi Jess,\n\n'
        'I’m writing from Lisbon! We arrived on Monday and the weather has '
        'been sunny every day. Yesterday we took an old yellow tram up the '
        'hill to the castle. The view was amazing, but the tram was very '
        'crowded, so next time I’ll walk.\n\n'
        'Tomorrow we’re going to the beach at Cascais. It’s forty minutes by '
        'train. My brother wanted to rent bikes, but my parents said it was '
        'too far.\n\n'
        'We fly home on Saturday. Are you free on Sunday afternoon? I’d love '
        'to show you my photos.\n\n'
        'Love,\nLucía',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Look for time words (yesterday, tomorrow, on Saturday): they tell '
            'you when each thing happens.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-a2-em-1',
          topic: 'finding details',
          prompt: 'What did Lucía do yesterday?',
          options: const <String>[
            'She took a tram to the castle',
            'She went to the beach',
            'She rented a bike',
          ],
          answer: 'She took a tram to the castle',
          why:
              'The first paragraph says yesterday they took a tram up to the '
              'castle.',
          evidence: 'Find "Yesterday" in the first paragraph.',
        ),
        Exercise.choice(
          id: 'r-a2-em-2',
          topic: 'finding details',
          prompt: 'Why will Lucía walk next time?',
          options: const <String>[
            'The tram was too crowded',
            'The tram was too expensive',
            'The castle was closed',
          ],
          answer: 'The tram was too crowded',
          why: '"the tram was very crowded, so next time I’ll walk".',
          evidence: 'Look at the last sentence of the first paragraph.',
        ),
        Exercise.trueFalse(
          id: 'r-a2-em-3',
          topic: 'finding details',
          prompt: 'The family will cycle to Cascais.',
          answer: false,
          why: 'They go by train; the parents said cycling was too far.',
          evidence: 'Read the second paragraph.',
        ),
        Exercise.choice(
          id: 'r-a2-em-4',
          topic: 'finding details',
          prompt: 'Why does Lucía write to Jess?',
          options: const <String>[
            'To share her news and suggest meeting',
            'To ask for help with a problem',
            'To cancel a plan',
          ],
          answer: 'To share her news and suggest meeting',
          why: 'She describes the trip and asks if Jess is free on Sunday.',
          evidence: 'Look at the last paragraph.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-b1-volunteering',
    title: 'Why teenagers volunteer',
    description: 'Read about young volunteers and their reasons.',
    skill: LessonSkill.reading,
    levelIndex: 2,
    topic: 'main points',
    estimatedMinutes: 7,
    xpReward: 30,
    difficulty: 2,
    objective: 'Identify main points and the writer’s purpose.',
    tags: const <String>['career', 'culture'],
    passage:
        'Every Saturday morning, sixteen-year-old Nadia spends three hours '
        'at an animal shelter, cleaning cages and walking dogs. She is not '
        'paid, and she does not have to be there. So why does she go?\n\n'
        '"At first, I just wanted something for my CV," she admits. "But '
        'now I’d miss it. I’ve learned to stay calm with nervous animals, '
        'and I’ve made friends I would never have met at school."\n\n'
        'Nadia is not unusual. Surveys suggest that many teenagers volunteer '
        'at least once a year, often in sport, the environment or care for '
        'animals. Their reasons change over time: practical motives such as '
        'gaining experience are common at the start, but young people who '
        'continue usually mention a sense of belonging.\n\n'
        'Organisers say the challenge is not finding volunteers but keeping '
        'them. Short, flexible shifts and real responsibility, they explain, '
        'make young people far more likely to stay.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Each paragraph has one main point. Ask yourself: what is this '
            'paragraph about?',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-b1-vol-1',
          topic: 'main points',
          prompt: 'Why did Nadia start volunteering?',
          options: const <String>[
            'To improve her CV',
            'Because her school required it',
            'To earn some money',
          ],
          answer: 'To improve her CV',
          why: 'She says "At first, I just wanted something for my CV".',
          evidence: 'Look at the start of the second paragraph.',
        ),
        Exercise.choice(
          id: 'r-b1-vol-2',
          topic: 'main points',
          prompt: 'What is the main point of the third paragraph?',
          options: const <String>[
            'Teenagers’ reasons for volunteering change over time',
            'Animal shelters need more money',
            'Most teenagers dislike volunteering',
          ],
          answer: 'Teenagers’ reasons for volunteering change over time',
          why:
              'It says practical motives come first, then a sense of '
              'belonging.',
          evidence: 'Read the third paragraph, last sentence.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'r-b1-vol-3',
          topic: 'main points',
          prompt: 'According to organisers, it is hard to find volunteers.',
          answer: false,
          why:
              'They say the challenge is keeping volunteers, not finding '
              'them.',
          evidence: 'Look at the first sentence of the last paragraph.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-b1-vol-4',
          topic: 'main points',
          prompt: 'What helps young volunteers stay?',
          options: const <String>[
            'Flexible shifts and real responsibility',
            'Longer shifts',
            'Volunteering only with friends',
          ],
          answer: 'Flexible shifts and real responsibility',
          why:
              'The last paragraph names short, flexible shifts and real '
              'responsibility.',
          evidence: 'Read the last sentence.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-b2-sleep-memory',
    title: 'Sleep and memory',
    description: 'A science article about what sleep does for learning.',
    skill: LessonSkill.reading,
    levelIndex: 3,
    topic: 'argument and attitude',
    estimatedMinutes: 8,
    xpReward: 35,
    difficulty: 2,
    objective: 'Follow an explanation and the writer’s conclusions.',
    tags: const <String>['academic', 'technology'],
    passage:
        'Students preparing for exams often sacrifice sleep to study for '
        'longer. The logic seems obvious: more hours with the books should '
        'mean more knowledge. Research on memory, however, points in the '
        'opposite direction.\n\n'
        'During deep sleep, the brain appears to replay what was learned '
        'during the day, strengthening some connections and weakening '
        'others. In a typical experiment, volunteers learn a list of word '
        'pairs; those allowed a full night’s sleep remember noticeably more '
        'the next morning than those kept awake, even when both groups are '
        'tested at the same time of day.\n\n'
        'Sleep does not only protect memories; it may also reorganise them. '
        'Some studies report that people are more likely to discover a '
        'hidden rule in a problem after sleeping on it.\n\n'
        'None of this means that sleep can replace study. Material that was '
        'never properly learned cannot be consolidated. But the evidence '
        'suggests that the last hours before an exam are usually better '
        'spent in bed than at the desk.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Notice how the writer moves from a common belief to evidence, then '
            'to a careful conclusion.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-b2-sl-1',
          topic: 'argument and attitude',
          prompt: 'What does "the opposite direction" refer to?',
          options: const <String>[
            'The idea that sleep, not extra study time, helps memory',
            'The idea that students should study at night',
            'The idea that exams are too difficult',
          ],
          answer: 'The idea that sleep, not extra study time, helps memory',
          why:
              'Research contradicts the belief that cutting sleep to study '
              'more is better.',
          evidence: 'Link the first and last sentences of paragraph one.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-b2-sl-2',
          topic: 'argument and attitude',
          prompt: 'Why are both groups tested at the same time of day?',
          options: const <String>[
            'So that the time of testing cannot explain the difference',
            'Because the researchers were busy',
            'To make the test easier',
          ],
          answer: 'So that the time of testing cannot explain the difference',
          why: 'It rules out another explanation: only sleep differs.',
          evidence: 'Look at the end of the second paragraph.',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'r-b2-sl-3',
          topic: 'argument and attitude',
          prompt: 'The writer claims that sleep can replace studying.',
          answer: false,
          why:
              'The last paragraph says "None of this means that sleep can '
              'replace study".',
          evidence: 'Read the start of the last paragraph.',
        ),
        Exercise.choice(
          id: 'r-b2-sl-4',
          topic: 'argument and attitude',
          prompt: 'How certain is the writer’s conclusion?',
          options: const <String>[
            'Careful: the evidence "suggests" it',
            'Completely certain for every student',
            'Not supported by any evidence',
          ],
          answer: 'Careful: the evidence "suggests" it',
          why: 'Words like "suggests" and "usually" show a careful claim.',
          evidence: 'Look at the verbs in the last sentence.',
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'reading-c1-citizen-science',
    title: 'Citizen science',
    description: 'An article on volunteers who collect scientific data.',
    skill: LessonSkill.reading,
    levelIndex: 4,
    topic: 'implied meaning',
    estimatedMinutes: 9,
    xpReward: 40,
    difficulty: 3,
    objective: 'Infer attitude and weigh benefits against limits.',
    tags: const <String>['academic', 'culture'],
    passage:
        'When a team of ecologists wanted to know how garden birds were '
        'responding to warmer winters, they faced a familiar obstacle: no '
        'research budget could pay for observers in thousands of gardens. '
        'Their solution was to ask the gardeners themselves. Within two '
        'winters, volunteers had submitted more records than professional '
        'surveys had gathered in a decade.\n\n'
        'Projects of this kind, known as citizen science, are now common, '
        'from counting butterflies to classifying distant galaxies in online '
        'images. Their appeal is plain: scale. A handful of experts cannot '
        'watch a whole continent; a hundred thousand enthusiasts, '
        'collectively, almost can.\n\n'
        'Sceptics point to the quality of the data. Volunteers misidentify '
        'species, report more often from pleasant places than from remote '
        'ones, and tend to notice the spectacular rather than the common. '
        'Yet these biases are not fatal. Because they are predictable, they '
        'can be measured and partly corrected, and large numbers smooth out '
        'many individual errors.\n\n'
        'Perhaps the most underrated benefit lies elsewhere. Participants, '
        'surveys indicate, come to understand how evidence is built — and '
        'are correspondingly harder to fool. Science, in other words, gains '
        'not only data but allies.',
    activities: <LessonActivity>[
      introActivity('Before you read', const <String>[
        'Writers often concede a weakness before answering it. Watch for '
            '"Yet", "Perhaps" and "in other words".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'r-c1-cs-1',
          topic: 'implied meaning',
          prompt: 'What does "almost can" suggest about volunteers?',
          options: const <String>[
            'Together they come close to observing an entire continent',
            'They are better scientists than experts',
            'They rarely agree with each other',
          ],
          answer: 'Together they come close to observing an entire continent',
          why:
              'The contrast with "a handful of experts cannot" shows their '
              'collective reach.',
          evidence: 'Read the end of the second paragraph.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-c1-cs-2',
          topic: 'implied meaning',
          prompt: 'What is the writer’s attitude to the sceptics’ criticism?',
          options: const <String>[
            'It is valid, but the problems can be managed',
            'It is completely wrong',
            'It proves citizen science should stop',
          ],
          answer: 'It is valid, but the problems can be managed',
          why:
              'The writer lists real biases, then says they are "not fatal" '
              'and can be corrected.',
          evidence: 'Look at "Yet these biases are not fatal".',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'r-c1-cs-3',
          topic: 'implied meaning',
          prompt: 'Volunteers tend to report more from remote places.',
          answer: false,
          why:
              'They report more often from pleasant places than remote '
              'ones.',
          evidence: 'Read the third paragraph, second sentence.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'r-c1-cs-4',
          topic: 'implied meaning',
          prompt: 'What does "science gains not only data but allies" mean?',
          options: const <String>[
            'Participants become people who understand and support evidence',
            'Scientists recruit more professional staff',
            'Data becomes cheaper to store',
          ],
          answer:
              'Participants become people who understand and support evidence',
          why:
              'Participants learn how evidence is built and are harder to '
              'fool: they become allies of science.',
          evidence: 'Connect the last two sentences.',
          difficulty: 3,
        ),
      ]),
    ],
  ),
];
