import '../../../services/voice/listening_accents.dart';
import '../models/lesson_models.dart';
import 'content_helpers.dart';

/// Real recordings in American English from public-domain sources written
/// by their publisher (VOA stories adapted from news agencies are left out).
final List<Lesson> mediaLessonsUs = <Lesson>[
  Lesson(
    id: 'media-voa-lincoln-1',
    title: 'Abraham Lincoln: the road to civil war',
    description:
        'A real VOA history report on Lincoln, from a log cabin to '
        'the presidency and war.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'implied meaning',
    estimatedMinutes: 16,
    xpReward: 45,
    difficulty: 2,
    objective:
        'Follow an 11-minute history report: causes, events and '
        'consequences.',
    tags: const <String>['history', 'culture'],
    video: const VideoClip.mp4(
      url:
          'https://voa-audio.voanews.eu/vle/2017/06/02/'
          'a671a3ea-6b8c-403b-9525-da81d17ebc7e.mp3',
      credit:
          'VOA Learning English, “America’s Presidents: Abraham Lincoln: '
          'Martyr”, written by Kelly Jean Kelly. Public domain (U.S. '
          'government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/americas-presidents-'
          'abraham-lincoln/3884227.html',
      audioOnly: true,
    ),
    media: const MediaInfo(
      category: ContentCategory.history,
      track: ContentTrack.academic,
      accent: ListeningAccent.american,
      creator: 'VOA Learning English – America’s Presidents',
      vocabulary: <VocabItem>[
        VocabItem(
          'formal education',
          'education received in a school',
          example: 'He had little formal education.',
        ),
        VocabItem(
          'frontier',
          'a distant area where few people live',
          example: 'He was born in the frontier state of Kentucky.',
        ),
        VocabItem(
          'abolitionist',
          'a person who wants to end slavery',
          example:
              'Lincoln was not an anti-slavery activist, an '
              'abolitionist.',
        ),
        VocabItem(
          'to withdraw from',
          'to leave a group or an activity',
          example: 'Seven Southern states withdrew from the Union.',
        ),
        VocabItem(
          'to surrender',
          'to stop fighting and accept defeat',
          example: 'The fort’s Union soldiers surrendered.',
        ),
        VocabItem(
          'hostilities',
          'acts of war, fighting',
          example: 'The official beginning of hostilities.',
        ),
      ],
      idioms: <VocabItem>[
        VocabItem(
          'to make fun of',
          'to laugh at someone unkindly',
          example: 'Critics made fun of his appearance.',
        ),
        VocabItem(
          'to turn one’s attention to',
          'to start concentrating on something else',
          example: 'He turned his attention to his family.',
        ),
        VocabItem(
          'to be sworn in',
          'to officially start an office by making a promise',
          example: 'A little more than a month after he was sworn in.',
        ),
        VocabItem(
          'to pave the way for',
          'to make something possible later',
          example:
              'The Emancipation Proclamation paved the way for the 13th '
              'Amendment.',
        ),
      ],
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Kelly Jean Kelly',
        'He was the 16th president of the United States. Many Americans '
            'consider him one of country’s greatest leaders. Yet people alive '
            'when Lincoln was elected in 1860 would probably be surprised by '
            'modern-day opinions about him. He had little formal education or '
            'government experience.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'During the presidential campaign, critics made fun of his '
            'appearance and his simple way of talking. Some of his opponents – '
            'especially in Southern states – were afraid Lincoln would use the '
            'power of the federal government to end slavery in their states. '
            'They were right.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'Abraham Lincoln was born in the frontier state of Kentucky. His '
            'family was very poor and had a simple home: a log cabin. Lincoln '
            'had to support his parents and his sister by working, so he '
            'rarely went to school. Instead, he taught himself by reading '
            'books. Eventually, he became a lawyer in the state of Illinois.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'He was tall and thin. He was very strong. And he was honest. The '
            'people he defended in court called him “Honest Abe.” He served '
            'one term as a congressman. But he was not popular there. Voters '
            'did not like his opposition to the country’s war with Mexico. So '
            'Lincoln withdrew from politics and turned his attention to his '
            'family.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'Lincoln believed slavery violated the American Declaration of '
            'Independence. He was chosen as the candidate of a new, '
            'anti-slavery party: the Republicans. In debates with Stephen '
            'Douglas, Lincoln’s words moved some voters. But they did not earn '
            'him enough votes to get elected. Douglas took the seat in the '
            'Senate.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'Not a single Southern state supported him in the election of 1860. '
            'But he won anyway. In answer, seven Southern states withdrew from '
            'the Union. Four more later joined them. They formed the '
            'Confederate States of America.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'Soldiers at Fort Sumter needed food. Lincoln sent supply ships. '
            'Confederate soldiers attacked, and a day and a half later the '
            'fort’s Union soldiers surrendered. No one was killed, but the '
            'battle marked the official beginning of hostilities.',
      ),
      AudioLine(
        'Kelly Jean Kelly',
        'The president was careful not to ask Congress to make an official '
            'declaration of war, in part because he did not want to recognize '
            'the Confederacy as a separate nation. Neither side expected the '
            'fighting to last very long. Instead, the Civil War lasted four '
            'and a half years. More than 620,000 men died. The Civil War '
            'remains the bloodiest war in American history.',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A real 11-minute VOA history report (audio). The transcript '
            'excerpts appear after you answer.',
        'Listen for causes and consequences: why voters, states and armies '
            'acted as they did.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'm-lincoln-1',
          topic: 'implied meaning',
          prompt:
              'Why would people in 1860 be surprised by today’s opinion '
              'of Lincoln?',
          options: const <String>[
            'He had little formal education or government experience',
            'He was already famous as a war hero',
            'He came from a rich Southern family',
          ],
          answer: 'He had little formal education or government experience',
          why:
              'The report contrasts today’s admiration with his modest '
              'background at the time.',
          evidence: 'The opening of the report.',
        ),
        Exercise.choice(
          id: 'm-lincoln-2',
          topic: 'implied meaning',
          prompt: 'Why did people call him “Honest Abe”?',
          options: const <String>[
            'The people he defended in court found him honest',
            'He never lost an election',
            'He refused to work for railroad companies',
          ],
          answer: 'The people he defended in court found him honest',
          why: 'The nickname came from the people he defended as a lawyer.',
          evidence: 'The description of the young Lincoln.',
        ),
        Exercise.choice(
          id: 'm-lincoln-3',
          topic: 'implied meaning',
          prompt: 'Why was he unpopular as a congressman?',
          options: const <String>[
            'He opposed the war with Mexico',
            'He supported slavery in the West',
            'He rarely came to Washington',
          ],
          answer: 'He opposed the war with Mexico',
          why:
              'Voters did not like his opposition to that war, so he left '
              'politics for a while.',
          evidence: 'Just after the “Honest Abe” passage.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'm-lincoln-4',
          topic: 'implied meaning',
          prompt:
              'Lincoln won the Senate seat after his debates with Stephen '
              'Douglas.',
          answer: false,
          why: 'His words moved some voters, but Douglas took the Senate seat.',
          evidence: 'The part about the debates.',
        ),
        Exercise.choice(
          id: 'm-lincoln-5',
          topic: 'implied meaning',
          prompt: 'How many Southern states supported Lincoln in 1860?',
          options: const <String>['None', 'Seven', 'Four'],
          answer: 'None',
          why:
              '“Not a single Southern state supported him.” Seven and four '
              'are the states that later left the Union.',
          evidence: 'The election of 1860.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'm-lincoln-6',
          topic: 'implied meaning',
          prompt: 'Why did Lincoln avoid asking Congress to declare war?',
          options: const <String>[
            'He did not want to recognize the Confederacy as a nation',
            'Congress refused to meet',
            'He expected the South to surrender at once',
          ],
          answer: 'He did not want to recognize the Confederacy as a nation',
          why:
              'A declaration of war would treat the South as a separate '
              'country; he called it a rebellion instead.',
          evidence: 'After the battle of Fort Sumter.',
          difficulty: 3,
        ),
        Exercise.fill(
          id: 'm-lincoln-7',
          topic: 'implied meaning',
          prompt: 'The Civil War remains the ___ war in American history.',
          answers: const <String>['bloodiest'],
          why: 'More than 620,000 men died: no other American war killed more.',
          evidence: 'The end of the report.',
        ),
      ]),
    ],
  ),

  Lesson(
    id: 'media-voa-gift-of-the-magi',
    title: 'O. Henry: The Gift of the Magi',
    description:
        'A real VOA reading of O. Henry’s famous short story, with '
        'its surprise ending.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'implied meaning',
    estimatedMinutes: 18,
    xpReward: 45,
    difficulty: 2,
    objective:
        'Follow a literary story read aloud and understand its irony '
        'and its message.',
    tags: const <String>['culture', 'reading'],
    video: const VideoClip.mp4(
      url:
          'https://voa-audio.voanews.eu/vle/2014/12/22/'
          '59cea7ee-599f-40d7-851e-6084533ab6b8.mp3',
      credit:
          'VOA Learning English, “American Stories”: The Gift of the Magi by '
          'O. Henry (1906), adapted by Karen Leggett, read by Shep O’Neal. '
          'Public domain.',
      sourcePage:
          'https://learningenglish.voanews.com/a/the-gift-of-the-magi-o-henry/'
          '4076022.html',
      audioOnly: true,
    ),
    media: const MediaInfo(
      category: ContentCategory.literature,
      accent: ListeningAccent.american,
      creator: 'VOA Learning English – American Stories',
      vocabulary: <VocabItem>[
        VocabItem(
          'to negotiate',
          'to discuss in order to reach an agreement (here: about prices)',
          example: 'Pennies saved by negotiating with the men at the market.',
        ),
        VocabItem(
          'possession',
          'something you own',
          example: 'They had two possessions which they valued.',
        ),
        VocabItem(
          'immovable',
          'not able to be moved, completely still',
          example:
              'Jim stopped inside the door, as immovable as a dog '
              'smelling a bird.',
        ),
        VocabItem(
          'expression',
          'the look on someone’s face that shows a feeling',
          example: 'There was an expression in them that she could not read.',
        ),
        VocabItem(
          'magi',
          'the wise men who brought gifts to the baby Jesus',
          example: 'They are the magi.',
        ),
      ],
      idioms: <VocabItem>[
        VocabItem(
          'does not go far',
          '(money) does not buy much',
          example: 'Jim earned twenty dollars a week, which does not go far.',
        ),
        VocabItem(
          'as if they had wings',
          'very quickly (time)',
          example: 'The next two hours went by as if they had wings.',
        ),
        VocabItem(
          'Do not make any mistake about me',
          'do not misunderstand my feelings',
          example: '“Do not make any mistake about me, Dell,” he said.',
        ),
      ],
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Shep O’Neal',
        'One dollar and eighty-seven cents. That was all. Three times Della '
            'counted it. And the next day would be Christmas. Tomorrow would '
            'be Christmas Day, and she had only one dollar and eighty-seven '
            'cents to buy her husband Jim a gift. Jim earned twenty dollars a '
            'week, which does not go far.',
      ),
      AudioLine(
        'Shep O’Neal',
        'Now, Mr. and Mrs. James Dillingham Young had two possessions which '
            'they valued. One was Jim’s gold time piece, the watch that had '
            'been his father’s and his grandfather’s. The other was Della’s '
            'hair.',
      ),
      AudioLine('Della', 'Will you buy my hair?'),
      AudioLine(
        'Madame Sofronie',
        'I buy hair. Take your hat off and let us have a look at it. Twenty '
            'dollars.',
      ),
      AudioLine('Della', 'Give it to me quick.'),
      AudioLine(
        'Shep O’Neal',
        'She found it at last. It was a chain -- simple round rings of '
            'silver. It was perfect for Jim’s gold watch. She gave the '
            'shopkeeper twenty-one dollars and she hurried home with the '
            'eighty-seven cents that was left.',
      ),
      AudioLine(
        'Shep O’Neal',
        'Jim stopped inside the door, as immovable as a dog smelling a bird. '
            'There was an expression in his eyes that she could not read. It '
            'was not anger, nor surprise, nor fear.',
      ),
      AudioLine(
        'Della',
        'Jim, my love, do not look at me that way. I had my hair cut and sold '
            'because I could not have lived through Christmas without giving '
            'you a gift. My hair grows very fast.',
      ),
      AudioLine(
        'Jim',
        'Do not make any mistake about me, Dell. I do not think there is any '
            'haircut that could make me like my girl any less. But if you '
            'will open that package you may see why you had me frightened at '
            'first.',
      ),
      AudioLine(
        'Shep O’Neal',
        'For there were the combs -- beautiful combs, made of shells, with '
            'jewels at the edge -- just the color to wear in the beautiful '
            'hair that was no longer hers.',
      ),
      AudioLine(
        'Jim',
        'Dell, let us put our Christmas gifts away and keep them a while. '
            'They are too nice to use just right now. I sold my gold watch to '
            'get the money to buy the set of combs for your hair.',
      ),
      AudioLine(
        'Shep O’Neal',
        'Here I have told you the story of two young people who most unwisely '
            'gave for each other the greatest treasures of their house. But of '
            'all who give gifts, these two were the wisest. They are the magi.',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A real VOA reading (14 minutes) of a famous American short story '
            'from 1906. Excerpts of the text appear after you answer.',
        'Listen for what each character sells, what each one buys, and why '
            'the ending is a surprise.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'm-magi-1',
          topic: 'implied meaning',
          prompt: 'How much money does Della have at the start?',
          options: const <String>[r'$1.87', r'$20', r'$21'],
          answer: r'$1.87',
          why:
              'One dollar and eighty-seven cents; twenty dollars is Jim’s '
              'weekly pay and the price of her hair.',
          evidence: 'The first sentences.',
        ),
        Exercise.choice(
          id: 'm-magi-2',
          topic: 'implied meaning',
          prompt: 'What does Della sell to buy Jim’s gift?',
          options: const <String>['Her hair', 'Her combs', 'Her coat'],
          answer: 'Her hair',
          why: 'Madame Sofronie buys her hair for twenty dollars.',
          evidence: 'The scene in the shop.',
        ),
        Exercise.choice(
          id: 'm-magi-3',
          topic: 'implied meaning',
          prompt: 'What does Della buy for Jim?',
          options: const <String>[
            'A silver chain for his watch',
            'A new coat and gloves',
            'A gold watch',
          ],
          answer: 'A silver chain for his watch',
          why:
              'She finds a chain of simple silver rings, perfect for his gold '
              'watch.',
          evidence: 'After she leaves the shop.',
        ),
        Exercise.choice(
          id: 'm-magi-4',
          topic: 'implied meaning',
          prompt: 'Why does Jim’s expression frighten Della?',
          options: const <String>[
            'She cannot read it: it is not anger, surprise or fear',
            'He is clearly angry about her hair',
            'He does not recognise her',
          ],
          answer: 'She cannot read it: it is not anger, surprise or fear',
          why:
              'The story says the look was none of the feelings she had '
              'prepared for; we understand why only at the end.',
          evidence: 'When Jim comes home.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'm-magi-5',
          topic: 'implied meaning',
          prompt: 'Why is the ending ironic?',
          options: const <String>[
            'Each sold their treasure to buy a gift for the other’s treasure',
            'Jim forgot to buy a gift',
            'The combs were too expensive for Della',
          ],
          answer:
              'Each sold their treasure to buy a gift for the other’s treasure',
          why:
              'Jim sold the watch to buy combs for her hair; Della sold her '
              'hair to buy a chain for his watch. Both gifts are now useless.',
          evidence: 'Jim’s last words.',
          difficulty: 3,
        ),
        Exercise.trueFalse(
          id: 'm-magi-6',
          topic: 'implied meaning',
          prompt: 'The narrator finally calls Della and Jim foolish.',
          answer: false,
          why:
              'He says they gave “most unwisely”, but concludes that they were '
              'the wisest of all who give gifts: they are the magi.',
          evidence: 'The last paragraph.',
          difficulty: 3,
        ),
      ]),
    ],
  ),

  Lesson(
    id: 'media-voa-yellowstone',
    title: 'Yellowstone: the world’s first national park',
    description:
        'A real VOA report on a super volcano, geysers and wild '
        'bison.',
    skill: LessonSkill.listening,
    levelIndex: 2,
    topic: 'numbers',
    estimatedMinutes: 8,
    xpReward: 35,
    objective: 'Catch facts and figures in a 4-minute nature report.',
    tags: const <String>['travel', 'science'],
    video: const VideoClip.mp4(
      url:
          'https://voa-audio.voanews.eu/vle/2025/02/13/'
          '776add5c-bbc5-4a14-83a0-08dd4a843460.mp3',
      credit:
          'VOA Learning English, “Yellowstone: The World’s First National '
          'Park”, written by Andrew Smith. Public domain (U.S. government '
          'work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/yellowstone-the-world-s-'
          'first-national-park/7974034.html',
      audioOnly: true,
    ),
    media: const MediaInfo(
      category: ContentCategory.environment,
      accent: ListeningAccent.american,
      creator: 'VOA Learning English – As It Is',
      vocabulary: <VocabItem>[
        VocabItem(
          'geothermal',
          'caused by heat from under the ground',
          example: 'It is famous for its geothermal activity.',
        ),
        VocabItem(
          'geyser',
          'a hot spring that shoots boiling water into the air',
          example: 'The park is home to more than 300 geysers.',
        ),
        VocabItem(
          'plateau',
          'a large flat area of high land',
          example: 'Yellowstone is on a high plateau.',
        ),
        VocabItem(
          'to erupt',
          'to explode or shoot out suddenly (volcano, geyser)',
          example: 'It erupts about every 90 minutes.',
        ),
        VocabItem(
          'herd / population',
          'a group of animals / the number living in a place',
          example: 'The bison population is about 4,500 animals.',
        ),
      ],
      idioms: <VocabItem>[
        VocabItem(
          'to take up',
          'to cover or use an amount of space',
          example: 'It takes up almost 9,000 square kilometers.',
        ),
        VocabItem(
          'the wild west',
          'the untamed American West of the 1800s; here, wild nature',
          example: 'There is still a wild west in America.',
        ),
      ],
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Andrew Smith',
        'Yellowstone National Park in the western United States was the '
            'world’s first national park. Established in 1872, it is famous '
            'for its geothermal activity and wild animals. It takes up almost '
            '9,000 square kilometers. Most of the park lies within the western '
            'state of Wyoming.',
      ),
      AudioLine(
        'Andrew Smith',
        'It sits on top of an ancient super volcano, known as the Yellowstone '
            'Caldera. The caldera remains an active volcano. A lake of hot '
            'liquid rock is about six kilometers under the park.',
      ),
      AudioLine(
        'Andrew Smith',
        'The park is home to more than 300 geysers. There are more geysers '
            'and hot springs in Yellowstone than any other place on Earth. '
            '“Old Faithful” is the name of the park’s most famous geyser '
            'because it erupts about every 90 minutes.',
      ),
      AudioLine(
        'Andrew Smith',
        'Yellowstone is on a high plateau with an average height of 2,400 '
            'meters above sea level. January temperatures average between '
            '-18 degrees and -7 degrees Celsius. However, some areas of the '
            'park remain open to visitors throughout the year.',
      ),
      AudioLine(
        'Andrew Smith',
        'Yellowstone Canyon is about 365 meters deep. The Yellowstone River '
            'drops 93 meters in the Lower Falls. In summer of 1988, forest '
            'fires burned large areas of the park. Most of those areas are now '
            'covered with plants and young trees.',
      ),
      AudioLine(
        'Andrew Smith',
        'Yellowstone is home to the largest group of wild animals in the '
            'lower 48 United States. In 2024, park officials estimated the '
            'bison population to be about 4,500 animals. That makes it the '
            'largest group of wild bison in the world.',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A real 4-minute VOA report (audio). Transcript after you answer.',
        'Listen for numbers: dates, distances, temperatures and animals.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'm-yellow-1',
          topic: 'numbers',
          prompt: 'When was Yellowstone established?',
          options: const <String>['1872', '1988', '1916'],
          answer: '1872',
          why: '“Established in 1872.” 1988 is the year of the big fires.',
          evidence: 'The first sentences.',
        ),
        Exercise.choice(
          id: 'm-yellow-2',
          topic: 'numbers',
          prompt: 'What is under the park?',
          options: const <String>[
            'An active super volcano',
            'An underground river',
            'An old gold mine',
          ],
          answer: 'An active super volcano',
          why:
              'The Yellowstone Caldera “remains an active volcano”, with hot '
              'liquid rock about six kilometers down.',
          evidence: 'Just after the size of the park.',
        ),
        Exercise.choice(
          id: 'm-yellow-3',
          topic: 'numbers',
          prompt: 'Why is the geyser called “Old Faithful”?',
          options: const <String>[
            'It erupts regularly, about every 90 minutes',
            'It is the oldest geyser on Earth',
            'It never stops erupting',
          ],
          answer: 'It erupts regularly, about every 90 minutes',
          why: '“Faithful” means reliable: it erupts on a regular schedule.',
          evidence: 'The part about geysers.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'm-yellow-4',
          topic: 'numbers',
          prompt: 'The whole park closes in winter.',
          answer: false,
          why: 'Winters are very cold, but some areas stay open all year.',
          evidence: 'The part about the plateau and temperatures.',
        ),
        Exercise.choice(
          id: 'm-yellow-5',
          topic: 'numbers',
          prompt: 'What happened to the areas burned in 1988?',
          options: const <String>[
            'Plants and young trees cover most of them now',
            'They are still bare',
            'They were turned into roads',
          ],
          answer: 'Plants and young trees cover most of them now',
          why: 'Nature came back after the fires.',
          evidence: 'After the Lower Falls.',
        ),
        Exercise.fill(
          id: 'm-yellow-6',
          topic: 'numbers',
          prompt: 'About ___ bison live in Yellowstone (2024 estimate).',
          answers: const <String>['4,500', '4500'],
          why: 'The largest group of wild bison in the world.',
          evidence: 'The last part, about wildlife.',
        ),
      ]),
    ],
  ),

  Lesson(
    id: 'media-voa-dead-horse',
    title: 'Idioms: “beating a dead horse”',
    description:
        'A real VOA programme on idioms for talking about the same '
        'thing again and again.',
    skill: LessonSkill.listening,
    levelIndex: 3,
    topic: 'implied meaning',
    estimatedMinutes: 9,
    xpReward: 40,
    difficulty: 2,
    objective:
        'Understand and use idioms about useless repetition, and '
        'their register.',
    tags: const <String>['culture', 'speaking'],
    video: const VideoClip.mp4(
      url:
          'https://voa-audio.voanews.eu/vle/2023/07/27/'
          '01000000-0a00-0242-cd7f-08db8ee81da1.mp3',
      credit:
          'VOA Learning English, “Words and Their Stories: ‘Beating a Dead '
          'Horse’ Is Pointless”, written by Anna Matteo. Public domain (U.S. '
          'government work).',
      sourcePage:
          'https://learningenglish.voanews.com/a/beating-a-dead-horse-is-'
          'pointless/7200547.html',
      audioOnly: true,
    ),
    media: const MediaInfo(
      category: ContentCategory.cultureSociety,
      accent: ListeningAccent.american,
      creator: 'VOA Learning English – Words and Their Stories',
      vocabulary: <VocabItem>[
        VocabItem(
          'pointless',
          'with no purpose, useless',
          example:
              'Why would anyone do something as pointless as beating a '
              'dead animal?',
        ),
        VocabItem(
          'cruel',
          'ready to hurt others',
          example: 'It sounds quite cruel.',
        ),
        VocabItem(
          'ad nauseam',
          'so much that people get sick of it',
          example: 'You have talked about it ad nauseam.',
        ),
        VocabItem(
          'to belabor (UK: belabour)',
          'to explain or insist far too much',
          example: 'Belaboring a point or an issue.',
        ),
      ],
      idioms: <VocabItem>[
        VocabItem(
          'to beat a dead horse',
          'to keep talking about something that cannot change',
          example: 'Not to beat a dead horse, but…',
        ),
        VocabItem(
          'to go over the same ground',
          'to talk about the same thing again and again',
          example: 'We’ve gone over the same ground and nothing has changed.',
        ),
        VocabItem(
          'to run something into the ground',
          'to talk about something too much',
          example: 'I have run it into the ground.',
        ),
        VocabItem(
          'to dwell on',
          'to keep thinking or talking about something for a long time',
          example: 'It is not a good idea to dwell on an old topic.',
        ),
      ],
    ),
    audio: const <AudioLine>[
      AudioLine(
        'Anna Matteo',
        'Today’s idiom does not sound nice. In fact, it sounds quite cruel. '
            'Today, we talk about beating a dead horse. We use the expression '
            'to describe something that is a useless thing to do. You are just '
            'wasting your time. There is no point.',
      ),
      AudioLine(
        'Anna Matteo',
        'Merriam-Webster’s online dictionary says this expression comes from '
            'the mid-19th century. Back then, some people may have beaten '
            'horses to make them go faster. But beating a dead horse would be '
            'pointless – because it’s dead. We often use this expression in '
            'the negative: “Not to beat a dead horse…”',
      ),
      AudioLine(
        'Anna Matteo',
        'Let’s say your friend talks about the same problem. They do not take '
            'your advice. You can say, “Look, we’ve gone over the same ground '
            'and nothing has changed. So, can we please change the topic?”',
      ),
      AudioLine(
        'Anna Matteo',
        'If I have a problem and talk about it too much, I have run it into '
            'the ground. You have talked about it ad nauseam. So, it is not a '
            'good idea to dwell on an old topic. Many people have lost good '
            'friends from belaboring a point or an issue.',
      ),
      AudioLine(
        'Anna Matteo',
        'Not to beat a dead horse, but we really are a great resource for '
            'learning English.',
      ),
    ],
    activities: <LessonActivity>[
      introActivity('Before you listen', const <String>[
        'A real VOA programme about idioms (4 minutes, audio).',
        'Listen for four ways to say “you keep talking about the same thing”, '
            'and for where the first idiom comes from.',
      ], const <String>[]),
      practiceActivity(<Exercise>[
        Exercise.choice(
          id: 'm-horse-1',
          topic: 'implied meaning',
          prompt: 'What does “beating a dead horse” mean?',
          options: const <String>[
            'Doing or saying something useless because nothing will change',
            'Working very hard to win',
            'Being cruel to animals',
          ],
          answer:
              'Doing or saying something useless because nothing will change',
          why:
              'A dead horse will not move, however much you beat it: the '
              'effort is pointless.',
          evidence: 'The beginning of the programme.',
        ),
        Exercise.choice(
          id: 'm-horse-2',
          topic: 'implied meaning',
          prompt: 'Where does the expression come from?',
          options: const <String>[
            'The mid-19th century, when people beat horses to go faster',
            'An old English farming law',
            'A famous American novel',
          ],
          answer: 'The mid-19th century, when people beat horses to go faster',
          why: 'According to Merriam-Webster, as the programme says.',
          evidence: 'The part about the dictionary.',
        ),
        Exercise.choice(
          id: 'm-horse-3',
          topic: 'implied meaning',
          prompt: 'Which expression is a polite alternative for a friend?',
          options: const <String>[
            '“We’ve gone over the same ground…”',
            '“Curiosity killed the cat.”',
            '“Make hay while the sun shines.”',
          ],
          answer: '“We’ve gone over the same ground…”',
          why:
              'Anna suggests it for horse lovers, followed by asking to '
              'change the topic.',
          evidence: 'The example with a friend.',
          difficulty: 2,
        ),
        Exercise.choice(
          id: 'm-horse-4',
          topic: 'implied meaning',
          prompt: 'What does “ad nauseam” suggest?',
          options: const <String>[
            'Talking so much that others feel sick of it',
            'Talking in a very formal way',
            'Talking about health problems',
          ],
          answer: 'Talking so much that others feel sick of it',
          why: 'It means “to a sickening degree”.',
          evidence: 'After “run it into the ground”.',
          difficulty: 2,
        ),
        Exercise.trueFalse(
          id: 'm-horse-5',
          topic: 'implied meaning',
          prompt:
              'The programme says dwelling on an old topic can cost you '
              'friends.',
          answer: true,
          why: '“Many people have lost good friends from belaboring a point.”',
          evidence: 'Near the end.',
        ),
        Exercise.fill(
          id: 'm-horse-6',
          topic: 'implied meaning',
          prompt:
              '“Not to beat a dead ___, but we really are a great '
              'resource.”',
          answers: const <String>['horse'],
          why: 'The idiom is often used in the negative, as a joke here.',
          evidence: 'The last sentence.',
        ),
      ]),
    ],
  ),
];
