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

  Lesson(
    id: 'video-voa-hello-anna',
    title: 'Video: new neighbours',
    description:
        'Anna meets Jonathan and learns who lives where (real actors).',
    skill: LessonSkill.listening,
    levelIndex: 0,
    topic: 'basic details',
    estimatedMinutes: 6,
    xpReward: 25,
    objective: 'Catch names, apartment numbers and where people are from.',
    tags: const <String>['basics', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2021/02/4/42/'
          '4298a2ba-d665-4b1c-aaa1-502bbcb9b88d.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English”, Lesson 2: Hello, I’m '
          'Anna! Public domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-lesson-2-'
          'hello/3113733.html',
    ),
    audio: const <AudioLine>[
      AudioLine('Jonathan', 'Hey, Pete! Who’s your friend?'),
      AudioLine('Pete', 'She is Anna. She is new to D.C.'),
      AudioLine('Jonathan', 'Where are you from?'),
      AudioLine('Anna', 'I am from a small town.'),
      AudioLine('Jonathan', 'Well, welcome to D.C.'),
      AudioLine('Anna', 'Thank you.'),
      AudioLine('Jonathan', 'I am Jonathan. I am in apartment B4.'),
      AudioLine('Anna', 'I am in apartment C2. Marsha is my roommate.'),
      AudioLine('Jonathan', 'I know Marsha. She is nice.'),
      AudioLine('Pete', 'And I am in Apartment D7. I have to go now.'),
      AudioLine('Anna', 'Oh!'),
      AudioLine(
        'Pete',
        'Remember to call Marsha at work. Tell her you’re here.',
      ),
      AudioLine('Anna', 'Right, thanks, Pete. Nice to meet you!'),
      AudioLine('Jonathan', 'You too, Bye.'),
      AudioLine('Anna', 'Apartment C2, here I come!'),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real VOA video. Anna meets a neighbour in her new building.',
        'Listen for three apartment numbers: one for each person.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa3-1',
          topic: 'basic details',
          prompt: 'Where is Anna from?',
          options: const <String>['A small town', 'A big city', 'Washington'],
          answer: 'A small town',
          why: 'She answers "I am from a small town."',
          evidence: 'Jonathan asks "Where are you from?"',
        ),
        Exercise.choice(
          id: 'v-voa3-2',
          topic: 'basic details',
          prompt: 'Which apartment is Jonathan’s?',
          options: const <String>['B4', 'C2', 'D7'],
          answer: 'B4',
          why: '"I am Jonathan. I am in apartment B4."',
          evidence: 'Jonathan introduces himself.',
        ),
        Exercise.choice(
          id: 'v-voa3-3',
          topic: 'basic details',
          prompt: 'Which apartment is Anna’s?',
          options: const <String>['C2', 'B4', 'D7'],
          answer: 'C2',
          why: '"I am in apartment C2." She says it again at the end.',
          evidence: 'Anna answers Jonathan, and her last line.',
        ),
        Exercise.choice(
          id: 'v-voa3-4',
          topic: 'basic details',
          prompt: 'Who is Anna’s roommate?',
          options: const <String>['Marsha', 'Jonathan', 'Pete'],
          answer: 'Marsha',
          why: '"Marsha is my roommate."',
          evidence: 'Anna talks about her apartment.',
        ),
        Exercise.trueFalse(
          id: 'v-voa3-5',
          topic: 'basic details',
          prompt: 'Jonathan does not know Marsha.',
          answer: false,
          why: 'He says "I know Marsha. She is nice."',
          evidence: 'Jonathan’s answer about the roommate.',
        ),
        Exercise.fill(
          id: 'v-voa3-6',
          topic: 'basic details',
          prompt: 'Pete says: "Remember to ___ Marsha at work."',
          answers: const <String>['call'],
          why: 'Pete reminds Anna to phone Marsha.',
          evidence: 'Pete’s line before he leaves.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'video-voa-wrong-number',
    title: 'Video: the wrong number',
    description: 'Anna phones her roommate, but first gets a stranger.',
    skill: LessonSkill.listening,
    levelIndex: 0,
    topic: 'numbers',
    estimatedMinutes: 6,
    xpReward: 25,
    objective: 'Hear phone numbers and an address in a real phone call.',
    tags: const <String>['basics', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2016/05/0/02/'
          '027f8fdd-e9b0-409c-8618-45be49fcefe8.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English”, Lesson 3: I’m Here! '
          'Public domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-lesson-3-'
          'i-am-here/3126527.html',
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Anna',
        'I am in my new apartment! Great! I live with Marsha. We’re '
            'roommates. I want to cook dinner. Oh! Hmmm. Is there a '
            'supermarket near here? Marsha knows. Marsha’s work number is '
            '555-8986.',
      ),
      AudioLine('Man', 'Hello.'),
      AudioLine('Anna', 'Hello. Is this Marsha? It is Anna.'),
      AudioLine('Man', 'I am sorry. You have the wrong number.'),
      AudioLine('Anna', 'Oh. Is this 555-8986?'),
      AudioLine('Man', 'No. This is 555-8689.'),
      AudioLine('Anna', 'Oh. Excuse me!'),
      AudioLine('Man', 'Okay. ’Bye.'),
      AudioLine('Anna', 'One more time. 555-8986. Please be Marsha.'),
      AudioLine('Marsha', 'Hello. This is Marsha.'),
      AudioLine('Anna', 'Yes, Marsha. I want to cook dinner.'),
      AudioLine('Marsha', 'Excuse me? Anna? Is that you?'),
      AudioLine('Anna', 'Oh, yes. I am here!'),
      AudioLine('Marsha', 'Good. You are there.'),
      AudioLine('Anna', 'I want to find a supermarket.'),
      AudioLine(
        'Marsha',
        'Oh, okay. The supermarket is at 1500 Irving Street. It is near the '
            'apartment.',
      ),
      AudioLine('Anna', 'Great! Goodbye!'),
      AudioLine('Marsha', 'Goodbye, Anna.'),
      AudioLine(
        'Anna',
        'There is a big supermarket on our street. And Marsha says I am a '
            'good cook! Until next time! Bye!',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real VOA video. Anna wants to cook dinner and needs a supermarket.',
        'Listen carefully to the phone numbers: two of them look very alike.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa4-1',
          topic: 'numbers',
          prompt: 'Why does Anna call Marsha?',
          options: const <String>[
            'To find a supermarket',
            'To find her apartment',
            'To invite her to a film',
          ],
          answer: 'To find a supermarket',
          why: 'She wants to cook dinner and asks where a supermarket is.',
          evidence: 'Anna’s first lines and the end of the call.',
        ),
        Exercise.choice(
          id: 'v-voa4-2',
          topic: 'numbers',
          prompt: 'What is Marsha’s work number?',
          options: const <String>['555-8986', '555-8689', '555-6898'],
          answer: '555-8986',
          why: 'Anna says it before calling: 555-8986.',
          evidence: 'Anna’s first lines.',
        ),
        Exercise.choice(
          id: 'v-voa4-3',
          topic: 'numbers',
          prompt: 'What number does Anna reach the first time?',
          options: const <String>['555-8689', '555-8986', '555-9886'],
          answer: '555-8689',
          why: 'The man says "No. This is 555-8689."',
          evidence: 'The first phone call.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'v-voa4-4',
          topic: 'numbers',
          prompt: 'Where is the supermarket?',
          options: const <String>[
            '1500 Irving Street',
            '1400 Irving Street',
            '1500 Irving Avenue',
          ],
          answer: '1500 Irving Street',
          why: 'Marsha: "The supermarket is at 1500 Irving Street."',
          evidence: 'Marsha’s last answer.',
        ),
        Exercise.trueFalse(
          id: 'v-voa4-5',
          topic: 'numbers',
          prompt: 'The supermarket is far from the apartment.',
          answer: false,
          why: 'Marsha says it is near the apartment, on the same street.',
          evidence: 'Marsha’s answer and Anna’s last line.',
        ),
        Exercise.fill(
          id: 'v-voa4-6',
          topic: 'numbers',
          prompt: 'The man says: "You have the ___ number."',
          answers: const <String>['wrong'],
          why: '"The wrong number" is the usual phrase on the phone.',
          evidence: 'The first phone call.',
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'video-voa-the-interview',
    title: 'Video: the job interview',
    description: 'Anna finds a very "different" partner for her new show.',
    skill: LessonSkill.listening,
    levelIndex: 2,
    topic: 'implied meaning',
    estimatedMinutes: 8,
    xpReward: 35,
    difficulty: 2,
    objective: 'Follow a job interview and two-word verbs (team up, find out).',
    tags: const <String>['career', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2021/02/1/17/'
          '1706ec69-afcc-40bb-a79c-4a053b5c77ad.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English – Level 2”, Lesson 2: '
          'The Interview. Public domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-level-2-'
          'lesson-2/3960471.html',
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Anna',
        'Ms. Weaver is giving new assignments out. I am ready to take on '
            'anything she gives me. Well, except reporting traffic from a '
            'helicopter. Wish me luck.',
      ),
      AudioLine(
        'Ms. Weaver',
        'Anna, you’re good at asking questions. So, I want you to go back to '
            'hosting and reporting.',
      ),
      AudioLine('Anna', 'That sounds great.'),
      AudioLine(
        'Ms. Weaver',
        'You’re also a team player. So, I want you team up with someone … '
            'someone who is very "different" from you.',
      ),
      AudioLine('Anna', 'That sounds … what do you mean "different"?'),
      AudioLine(
        'Ms. Weaver',
        'Well, you are very cheerful, you’re a people person. I want you to '
            'team up with someone who … isn’t.',
      ),
      AudioLine('Anna', 'Ms. Weaver, I will find that person.'),
      AudioLine(
        'Pete',
        'Sure. But I don’t have lots of time, Anna. I’m busy looking for '
            'work.',
      ),
      AudioLine(
        'Anna',
        'Pete, you can tear these want ads up and throw them away! I have '
            'good news! I have a job offer for you! My boss wants me to team '
            'up with someone to host a talk show. But the person must be '
            'different from me. So, I thought of you.',
      ),
      AudioLine(
        'Anna',
        'Here’s my boss’s address. Your interview is tomorrow morning at '
            '10 am. Just be yourself, Pete.',
      ),
      AudioLine(
        'Ms. Weaver',
        'I need to find out if you have the skills for this job. Pete, are '
            'you a people person?',
      ),
      AudioLine('Pete', 'Well, okay, sometimes I think people talk too much.'),
      AudioLine(
        'Pete',
        'Last year, I locked myself in a cabin and wrote a book. I didn’t '
            'speak to anybody the entire time! It was the best two months of '
            'my life.',
      ),
      AudioLine(
        'Pete',
        'Well, she said I was grumpy and not good with people. And, I got '
            'the job!',
      ),
      AudioLine('Anna', 'I knew it! Congratulations! Let’s go celebrate.'),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real VOA video. Anna gets a new assignment and needs a partner '
            'who is not like her.',
        'Listen for two-word verbs: give out, take on, team up, find out, '
            'throw away.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa5-1',
          topic: 'implied meaning',
          prompt: 'What is Anna’s new assignment?',
          options: const <String>[
            'Hosting a talk show with a partner',
            'Reporting traffic from a helicopter',
            'Writing a book',
          ],
          answer: 'Hosting a talk show with a partner',
          why:
              'Ms. Weaver wants her to go back to hosting and team up with '
              'someone; Anna then talks about a talk show.',
          evidence: 'Ms. Weaver’s office, then Anna with Pete.',
        ),
        Exercise.choice(
          id: 'v-voa5-2',
          topic: 'implied meaning',
          prompt: 'What kind of partner does Ms. Weaver want for Anna?',
          options: const <String>[
            'Someone who is not a people person',
            'Someone cheerful like Anna',
            'Someone who asks good questions',
          ],
          answer: 'Someone who is not a people person',
          why:
              'Anna is cheerful and a people person; the partner should be '
              'someone who "isn’t".',
          evidence: 'Ms. Weaver explains "different".',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'v-voa5-3',
          topic: 'implied meaning',
          prompt: 'What is Pete doing when Anna arrives?',
          options: const <String>[
            'Looking for work in want ads',
            'Preparing for an interview',
            'Writing a book',
          ],
          answer: 'Looking for work in want ads',
          why:
              'He is "busy looking for work", and Anna tells him to throw the '
              'want ads away.',
          evidence: 'The café scene.',
        ),
        Exercise.choice(
          id: 'v-voa5-4',
          topic: 'implied meaning',
          prompt: 'When is Pete’s interview?',
          options: const <String>[
            'Tomorrow at 10 am',
            'Today at 10 am',
            'Tomorrow at 10 pm',
          ],
          answer: 'Tomorrow at 10 am',
          why: '"Your interview is tomorrow morning at 10 am."',
          evidence: 'Anna gives Pete the address.',
        ),
        Exercise.choice(
          id: 'v-voa5-5',
          topic: 'implied meaning',
          prompt: 'What was the best time of Pete’s life?',
          options: const <String>[
            'Two months alone in a cabin',
            'A year working at The Studio',
            'A trip with his friends',
          ],
          answer: 'Two months alone in a cabin',
          why: 'He wrote a book alone in a cabin and spoke to nobody.',
          evidence: 'Pete’s answer about the work he is proud of.',
        ),
        Exercise.trueFalse(
          id: 'v-voa5-6',
          topic: 'implied meaning',
          prompt: 'Pete gets the job because he is grumpy.',
          answer: true,
          why:
              'Ms. Weaver wanted someone different from cheerful Anna: '
              'grumpy Pete is exactly that.',
          evidence: 'Pete’s last lines and Ms. Weaver’s request at the start.',
          difficulty: 3,
        ),
      ]),
    ],
  ),

  Lesson(
    id: 'video-voa-he-said-she-said',
    title: 'Video: two versions of one morning',
    description: 'Anna and Pete arrive late and tell very different stories.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'implied meaning',
    estimatedMinutes: 9,
    xpReward: 40,
    difficulty: 2,
    objective:
        'Compare two points of view and spot the past perfect (had + '
        'past participle).',
    tags: const <String>['career', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-video-ns.akamaized.net/pangeavideo/2021/02/e/ee/'
          'ee3e6fb5-9ea6-4f8b-88b4-c24e14fb2780.mp4',
      credit:
          'VOA Learning English, “Let’s Learn English – Level 2”, Lesson 3: '
          'He Said – She Said. Public domain (U.S. government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/lets-learn-english-level-2-'
          'lesson-3/4027340.html',
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Anna',
        'Today, Pete and I are meeting with a consultant who will help us '
            'with our new show. Yesterday, Pete had promised to meet me here '
            'at 8:00 a.m. but he did not come on time.',
      ),
      AudioLine(
        'Kelly',
        'You two are late -- exactly 43 minutes late! What happened?',
      ),
      AudioLine(
        'Anna',
        'He had to get his "special" coffee -- SPECIAL coffee!',
      ),
      AudioLine('Pete', 'She had to feed her birds -- HER birds!'),
      AudioLine(
        'Kelly',
        'You can’t both talk at the same time. You have to take turns. '
            'Alright, Anna, you go first.',
      ),
      AudioLine(
        'Anna',
        'Pete and I live in the same building. So, we decided to meet at '
            '8:00 a.m. to come to work together. I had waited 15 minutes when '
            'Pete arrived! After Pete had wasted time waiting for coffee, we '
            'were late. I left you a message.',
      ),
      AudioLine('Kelly', 'Hum. I didn’t get that message.'),
      AudioLine(
        'Pete',
        'I had arrived on time at 8:00 a.m. but didn’t see Anna. She was '
            'standing behind a tree. I always walk to work. But she said that '
            'would take too long and that a scooter would be much faster. It '
            'was awful. I hated it. And it added too much time to our commute!',
      ),
      AudioLine(
        'Pete',
        'Then Anna stopped by a pond to feed the birds. She had named them '
            'after characters from books … Romeo! Juliet! Sherlock! By the '
            'time she had fed all the birds, we were late.',
      ),
      AudioLine(
        'Kelly',
        'You two see the same event very differently. It’s good to see things '
            'differently. We will call the show "He Said, She Said." For every '
            'story, you tell a different point of view.',
      ),
      AudioLine(
        'Anna',
        'That is a great idea, Kelly! Pete, we are different. That’s why I '
            'thought of you for this job!',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you watch', const <String>[
        'A real VOA video. Anna and Pete are late for a meeting with a '
            'consultant, and each one blames the other.',
        'Listen for the past perfect: "had promised", "had waited", '
            '"had wasted".',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'v-voa6-1',
          topic: 'implied meaning',
          prompt: 'How late are Anna and Pete?',
          options: const <String>['43 minutes', '15 minutes', '8 minutes'],
          answer: '43 minutes',
          why: 'Kelly says they are "exactly 43 minutes late".',
          evidence: 'Kelly’s first line.',
        ),
        Exercise.choice(
          id: 'v-voa6-2',
          topic: 'implied meaning',
          prompt: 'According to Anna, why are they late?',
          options: const <String>[
            'Pete waited for his special coffee',
            'Pete took the wrong scooter',
            'The meeting time changed',
          ],
          answer: 'Pete waited for his special coffee',
          why: '"After Pete had wasted time waiting for coffee, we were late."',
          evidence: 'Anna’s version.',
        ),
        Exercise.choice(
          id: 'v-voa6-3',
          topic: 'implied meaning',
          prompt: 'According to Pete, why are they late?',
          options: const <String>[
            'Anna fed the birds at a pond',
            'Anna forgot the meeting',
            'Anna walked too slowly',
          ],
          answer: 'Anna fed the birds at a pond',
          why: '"By the time she had fed all the birds, we were late."',
          evidence: 'Pete’s version.',
        ),
        Exercise.choice(
          id: 'v-voa6-4',
          topic: 'implied meaning',
          prompt: 'How does Pete usually go to work?',
          options: const <String>['He walks', 'By scooter', 'By bus'],
          answer: 'He walks',
          why: '"I always walk to work." The scooter was Anna’s idea.',
          evidence: 'Pete’s version.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'v-voa6-5',
          topic: 'implied meaning',
          prompt: 'What does Kelly decide?',
          options: const <String>[
            'To build the show on their two points of view',
            'To find a new partner for Anna',
            'To start meetings later',
          ],
          answer: 'To build the show on their two points of view',
          why:
              'She calls the show "He Said, She Said": a different point of '
              'view for every story.',
          evidence: 'Kelly’s idea near the end.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'v-voa6-6',
          topic: 'implied meaning',
          prompt: 'Kelly received Anna’s message about being late.',
          answer: false,
          why: 'Kelly says "I didn’t get that message."',
          evidence: 'Just after Anna’s version.',
        ),
        Exercise.fill(
          id: 'v-voa6-7',
          topic: 'implied meaning',
          prompt: 'Anna: "I had ___ 15 minutes when Pete arrived!"',
          answers: const <String>['waited'],
          why: 'Past perfect: had + waited, the first of two past events.',
          evidence: 'Anna’s version.',
          difficulty: 2,
        ),
      ]),
    ],
  ),
];
