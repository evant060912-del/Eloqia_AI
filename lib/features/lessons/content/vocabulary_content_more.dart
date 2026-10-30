import '../models/lesson_models.dart';
import 'content_helpers.dart';

/// Second vocabulary lesson for each level A1–C1.
final List<Lesson> moreVocabularyLessons = <Lesson>[
  Lesson(
    id: 'vocab-a1-family',
    title: 'Family and friends',
    description: 'Words for the people in your life.',
    skill: LessonSkill.vocabulary,
    levelIndex: 0,
    topic: 'family',
    estimatedMinutes: 5,
    xpReward: 20,
    objective: 'Name family members and describe people simply.',
    tags: const <String>['basics', 'speaking'],
    activities: <LessonActivity>[
      introActivity(
        'People in your life',
        const <String>[
          'parents: your mother and father. aunt: your parent’s sister. '
              'cousin: your aunt’s or uncle’s child. neighbour: a person who '
              'lives next to you.',
          'Describe people with simple adjectives: kind, funny, tall, quiet.',
        ],
        const <String>[
          'My parents live in Lyon.',
          'My cousin is very funny.',
          'Our neighbour is kind and quiet.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.match(
          id: 'v-a1-fam-1',
          topic: 'family',
          pairs: const <String, String>{
            'aunt': 'your mother’s or father’s sister',
            'cousin': 'the child of your aunt or uncle',
            'neighbour': 'a person who lives next to you',
          },
          why: 'Each word is matched with the person it describes.',
        ),
        Exercise.choice(
          id: 'v-a1-fam-2',
          topic: 'family',
          prompt: 'My mother’s brother is my ___.',
          options: const <String>['uncle', 'aunt', 'cousin'],
          answer: 'uncle',
          why: 'Your parent’s brother is your uncle.',
          notes: const <String, String>{
            'aunt': 'An aunt is your parent’s sister.',
            'cousin': 'A cousin is your uncle’s or aunt’s child.',
          },
        ),
        Exercise.fill(
          id: 'v-a1-fam-3',
          topic: 'family',
          prompt: 'My mother and father are my ___.',
          answers: const <String>['parents'],
          why: 'Your mother and father together are your parents.',
        ),
        Exercise.choice(
          id: 'v-a1-fam-4',
          topic: 'family',
          prompt: 'Sara always makes us laugh. She is very ___.',
          options: const <String>['funny', 'quiet', 'tall'],
          answer: 'funny',
          why: 'Someone who makes people laugh is funny.',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.trueFalse(
          id: 'v-a1-fam-5',
          topic: 'family',
          prompt: 'Your grandparents are your parents’ parents.',
          answer: true,
          why: 'Grandparents are the mother and father of your parents.',
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'vocab-a2-food',
    title: 'Food and cooking',
    description: 'Ingredients, cooking verbs and ordering.',
    skill: LessonSkill.vocabulary,
    levelIndex: 1,
    topic: 'food and cooking',
    estimatedMinutes: 6,
    xpReward: 25,
    objective: 'Talk about food, recipes and meals.',
    tags: const <String>['travel', 'culture'],
    activities: <LessonActivity>[
      introActivity(
        'In the kitchen',
        const <String>[
          'Cooking verbs: boil (in hot water), fry (in oil), bake (in the '
              'oven), chop (cut into small pieces).',
          'Containers: a bottle of water, a jar of honey, a packet of rice.',
        ],
        const <String>[
          'Boil the pasta for ten minutes.',
          'Chop the onions and fry them in a little oil.',
          'Can I have a bottle of water, please?',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.match(
          id: 'v-a2-food-1',
          topic: 'food and cooking',
          pairs: const <String, String>{
            'boil': 'cook in very hot water',
            'bake': 'cook in an oven',
            'chop': 'cut into small pieces',
          },
          why: 'Each verb describes a different way to prepare food.',
        ),
        Exercise.choice(
          id: 'v-a2-food-2',
          topic: 'food and cooking',
          prompt: 'We ___ a cake for my grandmother’s birthday.',
          options: const <String>['baked', 'boiled', 'chopped'],
          answer: 'baked',
          why: 'Cakes are cooked in the oven: we bake them.',
          notes: const <String, String>{
            'boiled': 'You boil eggs or pasta in water, not a cake.',
          },
        ),
        Exercise.choice(
          id: 'v-a2-food-3',
          topic: 'food and cooking',
          prompt: 'Could you buy a ___ of honey?',
          options: const <String>['jar', 'bottle', 'slice'],
          answer: 'jar',
          why: 'Honey usually comes in a glass jar.',
        ),
        Exercise.fill(
          id: 'v-a2-food-4',
          topic: 'food and cooking',
          prompt: '___ the potatoes in a pan of hot oil.',
          answers: const <String>['fry'],
          why: 'Cooking in hot oil is frying.',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'v-a2-food-5',
          topic: 'food and cooking',
          prompt: 'The soup is too ___. Can you add some salt?',
          options: const <String>['bland', 'spicy', 'salty'],
          answer: 'bland',
          why: '"bland" means it has very little taste, so salt helps.',
          notes: const <String, String>{
            'salty': 'If it were salty, you would not add more salt.',
          },
          difficulty: 2,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'vocab-b1-phrasal-verbs',
    title: 'Everyday phrasal verbs',
    description: 'Common verbs with up, out, off and on.',
    skill: LessonSkill.vocabulary,
    levelIndex: 2,
    topic: 'phrasal verbs',
    estimatedMinutes: 7,
    xpReward: 30,
    difficulty: 2,
    objective: 'Understand and use ten frequent phrasal verbs.',
    tags: const <String>['speaking', 'fluency'],
    activities: <LessonActivity>[
      introActivity(
        'Phrasal verbs',
        const <String>[
          'A phrasal verb is a verb + a small word that changes its meaning.',
          'find out: discover information. give up: stop trying. look after: '
              'take care of. run out of: have no more. put off: delay. turn '
              'down: refuse.',
        ],
        const <String>[
          'I found out the answer online.',
          'Don’t give up: you’re nearly there.',
          'We ran out of milk, so I went to the shop.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.match(
          id: 'v-b1-pv-1',
          topic: 'phrasal verbs',
          pairs: const <String, String>{
            'give up': 'stop trying',
            'look after': 'take care of',
            'put off': 'delay',
            'turn down': 'refuse',
          },
          why:
              'Each phrasal verb has a meaning you cannot guess from the '
              'verb alone.',
        ),
        Exercise.choice(
          id: 'v-b1-pv-2',
          topic: 'phrasal verbs',
          prompt: 'Can you ___ my cat while I’m away?',
          options: const <String>['look after', 'look for', 'look up'],
          answer: 'look after',
          why: '"look after" means take care of.',
          notes: const <String, String>{
            'look for': '"look for" means try to find.',
            'look up': '"look up" means search for information.',
          },
        ),
        Exercise.choice(
          id: 'v-b1-pv-3',
          topic: 'phrasal verbs',
          prompt:
              'The meeting was ___ until next week because the manager was '
              'ill.',
          options: const <String>['put off', 'turned down', 'found out'],
          answer: 'put off',
          why: 'To delay something is to put it off.',
        ),
        Exercise.fill(
          id: 'v-b1-pv-4',
          topic: 'phrasal verbs',
          prompt: 'We ran ___ of coffee, so I bought some more.',
          answers: const <String>['out'],
          why: '"run out of" means have no more of something.',
        ),
        Exercise.trueFalse(
          id: 'v-b1-pv-5',
          topic: 'phrasal verbs',
          prompt: '"She turned down the job" means she accepted it.',
          answer: false,
          why: '"turn down" means refuse.',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'v-b1-pv-6',
          topic: 'phrasal verbs',
          prompt: 'How did you ___ that the shop was closing?',
          options: const <String>['find out', 'give up', 'run out'],
          answer: 'find out',
          why: '"find out" means discover information.',
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'vocab-b2-environment',
    title: 'The environment',
    description: 'Talk about climate and sustainability precisely.',
    skill: LessonSkill.vocabulary,
    levelIndex: 3,
    topic: 'environment',
    estimatedMinutes: 8,
    xpReward: 35,
    difficulty: 2,
    objective: 'Use key environmental vocabulary and collocations.',
    tags: const <String>['academic', 'culture'],
    activities: <LessonActivity>[
      introActivity(
        'Environmental vocabulary',
        const <String>[
          'emissions: gases released into the air. renewable energy: energy '
              'from sources that do not run out (sun, wind). biodiversity: the '
              'variety of living things. sustainable: able to continue without '
              'damaging the environment.',
          'Collocations: reduce emissions, tackle climate change, protect '
              'habitats, a carbon footprint.',
        ],
        const <String>[
          'Cities are trying to reduce emissions from traffic.',
          'Solar panels produce renewable energy.',
          'Flying increases your carbon footprint.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.match(
          id: 'v-b2-env-1',
          topic: 'environment',
          pairs: const <String, String>{
            'emissions': 'gases released into the air',
            'biodiversity': 'the variety of living things',
            'sustainable': 'able to continue without harming nature',
          },
          why: 'These are the core words of environmental texts.',
        ),
        Exercise.choice(
          id: 'v-b2-env-2',
          topic: 'environment',
          prompt: 'Governments must ___ climate change urgently.',
          options: const <String>['tackle', 'make', 'do'],
          answer: 'tackle',
          why: 'We "tackle" a problem: it is the natural collocation.',
          notes: const <String, String>{
            'make': 'We do not say "make climate change" for fighting it.',
          },
        ),
        Exercise.choice(
          id: 'v-b2-env-3',
          topic: 'environment',
          prompt: 'Taking the train instead of flying lowers your carbon ___.',
          options: const <String>['footprint', 'step', 'trace'],
          answer: 'footprint',
          why: 'The fixed expression is "carbon footprint".',
        ),
        Exercise.fill(
          id: 'v-b2-env-4',
          topic: 'environment',
          prompt: 'Wind and solar power are ___ energy sources.',
          answers: const <String>['renewable'],
          why: 'Sources that do not run out are renewable.',
        ),
        Exercise.trueFalse(
          id: 'v-b2-env-5',
          topic: 'environment',
          prompt: 'Deforestation means planting new forests.',
          answer: false,
          why:
              'Deforestation is cutting down forests; planting is '
              'reforestation.',
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'v-b2-env-6',
          topic: 'environment',
          prompt: 'The new park helps to protect the ___ of rare birds.',
          options: const <String>['habitat', 'habit', 'inhabitant'],
          answer: 'habitat',
          why: 'A habitat is the natural home of an animal or plant.',
          notes: const <String, String>{
            'habit': 'A habit is something you do regularly.',
          },
          difficulty: 3,
        ),
      ]),
    ],
  ),
  Lesson(
    id: 'vocab-c1-academic-register',
    title: 'Academic register',
    description: 'Formal verbs and hedging for essays.',
    skill: LessonSkill.vocabulary,
    levelIndex: 4,
    topic: 'academic register',
    estimatedMinutes: 8,
    xpReward: 40,
    difficulty: 3,
    objective: 'Replace informal words and make careful claims.',
    tags: const <String>['academic', 'career'],
    activities: <LessonActivity>[
      introActivity(
        'Formal and careful',
        const <String>[
          'Formal verbs replace phrasal verbs: look into → investigate, find '
              'out → discover, go up → increase, cut down on → reduce.',
          'Hedging makes claims careful: tends to, appears to, is likely to, '
              'evidence suggests that.',
        ],
        const <String>[
          'The study investigates the causes of stress.',
          'Prices increased sharply in 2024.',
          'This approach appears to reduce costs.',
        ],
      ),
      practiceActivity(<Exercise>[
        Exercise.match(
          id: 'v-c1-ac-1',
          topic: 'academic register',
          pairs: const <String, String>{
            'look into': 'investigate',
            'go up': 'increase',
            'cut down on': 'reduce',
            'find out': 'discover',
          },
          why: 'Each phrasal verb has a more formal single-word equivalent.',
        ),
        Exercise.choice(
          id: 'v-c1-ac-2',
          topic: 'academic register',
          prompt: 'Choose the most academic version: "Prices went up a lot."',
          options: const <String>[
            'Prices rose considerably.',
            'Prices got way higher.',
            'Prices went up loads.',
          ],
          answer: 'Prices rose considerably.',
          why: '"rose considerably" is formal and precise.',
        ),
        Exercise.choice(
          id: 'v-c1-ac-3',
          topic: 'academic register',
          prompt: 'Which sentence is appropriately hedged?',
          options: const <String>[
            'Social media appears to affect sleep quality.',
            'Social media destroys everyone’s sleep.',
            'Social media obviously ruins sleep.',
          ],
          answer: 'Social media appears to affect sleep quality.',
          why: '"appears to" makes a careful claim the evidence can support.',
          difficulty: 2,
        ),
        Exercise.fill(
          id: 'v-c1-ac-4',
          topic: 'academic register',
          prompt:
              'Recent evidence ___ that the policy has worked. (one word, '
              'formal, careful)',
          answers: const <String>['suggests', 'indicates'],
          why:
              '"suggests" or "indicates" present evidence without '
              'overclaiming.',
          difficulty: 2,
        ),
      ]),
      challengeActivity(<Exercise>[
        Exercise.choice(
          id: 'v-c1-ac-5',
          topic: 'academic register',
          prompt: 'The researchers ___ the effect of noise on concentration.',
          options: const <String>['examined', 'checked out', 'had a look at'],
          answer: 'examined',
          why: '"examined" is the formal choice for research.',
          notes: const <String, String>{
            'checked out': 'Too informal for academic writing.',
          },
          difficulty: 3,
        ),
      ]),
    ],
  ),
];
