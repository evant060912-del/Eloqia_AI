import '../models/lesson_models.dart';
import 'content_helpers.dart';

/// Listening with real people on video. VOA Learning English videos are
/// works of the U.S. government, in the public domain: the app may play them
/// and show their transcripts. Questions are written for Eloqia.
///
/// To add a video, see docs/VIDEO_LISTENING.md.
final List<Lesson> videoListeningLessons = <Lesson>[
  Lesson(
    id: 'video-voa-welcome',
    title: 'Video: a new apartment',
    description: 'Anna meets Pete at her new apartment (real actors).',
    skill: LessonSkill.listening,
    levelIndex: 0,
    topic: 'basic details',
    estimatedMinutes: 6,
    xpReward: 25,
    objective: 'Follow a real conversation: names, spelling and an address.',
    tags: const <String>['basics', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2021/02/5/5f/'
          '5f00c78a-0f84-41e6-949d-bd808bcadf50.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English”, Lesson 1. Public '
          'domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-lesson-'
          'one/3111026.html',
    ),
    audio: const <AudioLine>[
      AudioLine('Pete', 'Hi! Are you Anna?'),
      AudioLine('Anna', 'Yes! Hi there! Are you Pete?'),
      AudioLine('Pete', 'I am Pete.'),
      AudioLine('Anna', 'Nice to meet you.'),
      AudioLine('Anna', 'Let’s try that again. I’m Anna. Nice to meet you.'),
      AudioLine('Pete', 'I’m Pete. “Anna” Is that A-N-A?'),
      AudioLine('Anna', 'No. A-N-N-A'),
      AudioLine(
        'Pete',
        'Well, Anna with two “n’s” … Welcome to … 1400 Irving Street!',
      ),
      AudioLine('Anna', 'My new apartment! Yes!'),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real video from VOA Learning English. Watch the conversation '
            'between Anna and Pete; the video also includes a short lesson.',
        'Listen for how Anna spells her name and for the address.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa1-1',
          topic: 'basic details',
          prompt: 'Who meets Anna at her new apartment?',
          options: const <String>['Pete', 'Jonathan', 'Kaveh'],
          answer: 'Pete',
          why: 'He asks "Are you Anna?" and says "I am Pete."',
          evidence: 'The first lines of the conversation.',
        ),
        Exercise.choice(
          id: 'v-voa1-2',
          topic: 'basic details',
          prompt: 'How does Anna spell her name?',
          options: const <String>['A-N-N-A', 'A-N-A', 'A-N-N-E'],
          answer: 'A-N-N-A',
          why: 'Pete tries "A-N-A", and Anna corrects him: "A-N-N-A".',
          evidence: 'Listen when Pete asks about the spelling.',
        ),
        Exercise.choice(
          id: 'v-voa1-3',
          topic: 'basic details',
          prompt: 'What is the address of the apartment?',
          options: const <String>[
            '1400 Irving Street',
            '4100 Irving Street',
            '1400 Irving Avenue',
          ],
          answer: '1400 Irving Street',
          why: 'Pete says "Welcome to … 1400 Irving Street!"',
          evidence: 'Near the end of the conversation.',
        ),
        Exercise.trueFalse(
          id: 'v-voa1-4',
          topic: 'basic details',
          prompt: 'Pete spells Anna’s name correctly the first time.',
          answer: false,
          why: 'He says "A-N-A"; Anna has two n’s.',
          evidence: 'Listen to Pete’s question about the spelling.',
        ),
        Exercise.fill(
          id: 'v-voa1-5',
          topic: 'basic details',
          prompt: 'Anna says: "Nice to ___ you."',
          answers: const <String>['meet'],
          why: '"Nice to meet you" is what we say when we meet someone.',
          evidence: 'Anna says it twice.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'video-voa-budget-cuts',
    title: 'Video: rumours at work',
    description: 'Anna and her co-workers fear budget cuts (real actors).',
    skill: LessonSkill.listening,
    levelIndex: 2,
    topic: 'implied meaning',
    estimatedMinutes: 8,
    xpReward: 35,
    difficulty: 2,
    objective: 'Follow a story with several speakers and work vocabulary.',
    tags: const <String>['career', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2021/02/7/7a/'
          '7a055fd0-0345-41e4-b24d-37df1736f3d1.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English – Level 2”, Lesson 1: '
          'Budget Cuts. Public domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-level-2-'
          'lesson1/3960391.html',
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Anna',
        'Hum. Oh! “Important meeting. Everyone must come.” Well, back to '
            'work! And my boss has called a meeting. I wonder what it’s about. '
            'Maybe we’re all getting raises! Ooo, there’s Jonathan! Maybe he '
            'knows.',
      ),
      AudioLine(
        'Anna',
        'So, Jonathan, what do you think today’s meeting is about? The email '
            'sounded important.',
      ),
      AudioLine(
        'Jonathan',
        'Well, I have heard people in the building talking about budget '
            'cuts.',
      ),
      AudioLine(
        'Anna',
        'Oh! Budget cuts? Wait, who has been talking about budget cuts?',
      ),
      AudioLine('Jonathan', 'Mark in Accounting.'),
      AudioLine(
        'Anna',
        'Mark in Accounting? That’s one person. That’s not “people.”',
      ),
      AudioLine(
        'Jonathan',
        'I know, but Mark knows everything that goes on at The Studio.',
      ),
      AudioLine(
        'Anna',
        'That is true. But wait, look at us. We shouldn’t gossip. That’s how '
            'rumors start. We’ll just go to the meeting and see what happens.',
      ),
      AudioLine('Jonathan', 'You’re right. No more talk about budget cuts.'),
      AudioLine(
        'Amelia',
        'Budget cuts? Oh no! I just heard Anna and Jonathan talking about '
            'budget cuts.',
      ),
      AudioLine(
        'Kaveh',
        'That must be what the meeting is about. When there are budget cuts, '
            'people lose their jobs.',
      ),
      AudioLine('Amelia', 'Not you. You’re a good reporter.'),
      AudioLine(
        'Kaveh',
        'And it’s not you. You’ve done a great job as a videographer.',
      ),
      AudioLine(
        'Amelia',
        'I can’t go back to being a detective. Criminals scare me!',
      ),
      AudioLine(
        'Kaveh',
        'And I can’t go back to being a teacher! High school kids scare me!',
      ),
      AudioLine(
        'Kaveh',
        'Penelope, have you heard the news? Today’s meeting is about budget '
            'cuts.',
      ),
      AudioLine('Penelope', 'That’s awful! What should I do?'),
      AudioLine(
        'Kaveh',
        'Update your résumé. I’ve already updated mine. I’ll see you at the '
            'meeting.',
      ),
      AudioLine(
        'Ms. Weaver',
        'What is wrong with everyone? You look like I’m going to fire you.',
      ),
      AudioLine('Anna', 'We’ve been worrying that you are going to fire us!'),
      AudioLine(
        'Ms. Weaver',
        'I’m not going to fire any of you! No! The reason for this meeting is '
            'to tell you what a good job you’ve been doing and give out new '
            'assignments. Budget cuts have been happening. But only one person '
            'has lost their job -- Mark in Accounting?',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real video from VOA Learning English, with several co-workers at '
            'a video studio. A rumour spreads before a meeting.',
        'Listen for who says what, and for work words: boss, raise, budget '
            'cuts, résumé, fire, assignment.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa2-1',
          topic: 'implied meaning',
          prompt: 'What does Anna hope at first?',
          options: const <String>[
            'That everyone is getting a raise',
            'That the meeting is cancelled',
            'That she will get a new boss',
          ],
          answer: 'That everyone is getting a raise',
          why: 'She says "Maybe we’re all getting raises!"',
          evidence: 'Anna’s first lines.',
        ),
        Exercise.choice(
          id: 'v-voa2-2',
          topic: 'implied meaning',
          prompt: 'Who started the talk about budget cuts?',
          options: const <String>[
            'Mark in Accounting',
            'Ms. Weaver',
            'Penelope',
          ],
          answer: 'Mark in Accounting',
          why: 'Jonathan heard it from Mark in Accounting.',
          evidence: 'Listen when Anna asks "who has been talking…?"',
        ),
        Exercise.choice(
          id: 'v-voa2-3',
          topic: 'implied meaning',
          prompt: 'Why does Anna want to stop talking about it?',
          options: const <String>[
            'Gossip is how rumours start',
            'The meeting has already started',
            'Jonathan has to go back to work',
          ],
          answer: 'Gossip is how rumours start',
          why: '"We shouldn’t gossip. That’s how rumors start."',
          evidence: 'Anna’s answer to Jonathan.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'v-voa2-4',
          topic: 'implied meaning',
          prompt: 'What was Amelia’s job before?',
          options: const <String>['Detective', 'Teacher', 'Reporter'],
          answer: 'Detective',
          why: '"I can’t go back to being a detective."',
          evidence: 'Amelia and Kaveh’s conversation.',
        ),
        Exercise.choice(
          id: 'v-voa2-5',
          topic: 'implied meaning',
          prompt: 'What advice does Kaveh give Penelope?',
          options: const <String>[
            'Update her résumé',
            'Talk to Ms. Weaver',
            'Go home early',
          ],
          answer: 'Update her résumé',
          why: 'He says "Update your résumé. I’ve already updated mine."',
          evidence: 'Kaveh speaks to Penelope before the meeting.',
        ),
        Exercise.trueFalse(
          id: 'v-voa2-6',
          topic: 'implied meaning',
          prompt: 'Ms. Weaver fires several people at the meeting.',
          answer: false,
          why:
              'She fires nobody; the meeting is about new assignments. Only '
              'Mark in Accounting has lost his job.',
          evidence: 'Ms. Weaver’s last answer.',
          difficulty: 2,
        ),
      ]),
    ],
  ),
];
