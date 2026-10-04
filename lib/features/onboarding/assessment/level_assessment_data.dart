enum AssessmentSkill { grammar, vocabulary, reading, usage }

const List<String> assessmentLevels = <String>[
  'A1',
  'A2',
  'B1',
  'B2',
  'C1',
  'C2',
];

const Map<String, String> assessmentTeachingPoints = <String, String>{
  'grammar_a1': 'Use "is" with the singular subject "she".',
  'vocabulary_a1': 'A bakery is where bread is made and sold.',
  'reading_a1': 'The passage says Tom goes to school by bus.',
  'usage_a1':
      'Good morning is the usual greeting when you meet in the morning.',
  'grammar_a2':
      '"Yesterday" signals the simple past; the past form of "go" is "went".',
  'vocabulary_a2': '"Expensive" means costing a lot, the opposite of "cheap".',
  'reading_a2':
      'The passage directly says Anna reads at home because it is raining.',
  'usage_a2': '"Could I have ... please?" is a polite way to make a request.',
  'grammar_b1':
      'Use present simple after "if" and "will" plus the base verb for a likely future condition.',
  'vocabulary_b1': '"Anxious" means worried or uneasy about what may happen.',
  'reading_b1':
      'The passage says some remote workers feel isolated because they rarely meet colleagues.',
  'usage_b1':
      'Acknowledge the disappointing news and show sympathy before changing the subject.',
  'grammar_b2':
      'For regret about a past situation, use "wish" plus past perfect: "had had".',
  'vocabulary_b2': '"Abandon" means to stop or leave a plan or activity.',
  'reading_b2':
      'The policy moved congestion to nearby streets instead of removing it.',
  'usage_b2':
      '"I am writing to enquire" is a conventional, appropriately formal opening.',
  'grammar_c1':
      'When "not only" begins the sentence, invert the auxiliary and subject: "did they meet".',
  'vocabulary_c1':
      'A "watertight" argument is logically sound and difficult to challenge.',
  'reading_c1':
      'The author says innovation grows as networks test and refine ideas.',
  'usage_c1':
      'Recognize the other person\'s point, then introduce disagreement with a measured phrase.',
  'grammar_c2':
      'This inverted third conditional means "if the committee had been informed, it would have reached".',
  'vocabulary_c2': '"Veiled" means indirect or partly concealed.',
  'reading_c2':
      'The passage argues that metaphors shape how we reason, not just how language sounds.',
  'usage_c2':
      'The mild understatement implies the presentation went badly without stating it dramatically.',
};

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.skill,
    required this.levelIndex,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.passage,
  });

  final String id;
  final AssessmentSkill skill;

  /// Index into [assessmentLevels].
  final int levelIndex;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? passage;

  String get level => assessmentLevels[levelIndex];
  String get teachingPoint =>
      assessmentTeachingPoints[id] ??
      'Use the surrounding sentence or passage as evidence for the best answer.';
}

const List<AssessmentQuestion> assessmentQuestionBank = <AssessmentQuestion>[
  // A1
  AssessmentQuestion(
    id: 'grammar_a1',
    skill: AssessmentSkill.grammar,
    levelIndex: 0,
    prompt: 'She ___ a student.',
    options: ['is', 'are', 'am', 'be'],
    correctIndex: 0,
  ),
  AssessmentQuestion(
    id: 'vocabulary_a1',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 0,
    prompt: 'Where can you buy bread?',
    options: ['At a library', 'At an airport', 'At a bakery', 'At a hospital'],
    correctIndex: 2,
  ),
  AssessmentQuestion(
    id: 'reading_a1',
    skill: AssessmentSkill.reading,
    levelIndex: 0,
    passage:
        'Tom gets up at seven. He eats breakfast and goes to school by bus.',
    prompt: 'How does Tom go to school?',
    options: ['On foot', 'By car', 'By bike', 'By bus'],
    correctIndex: 3,
  ),
  AssessmentQuestion(
    id: 'usage_a1',
    skill: AssessmentSkill.usage,
    levelIndex: 0,
    prompt: 'What do you say when you meet someone in the morning?',
    options: ['Good night', 'Good morning', 'Goodbye', 'Thank you'],
    correctIndex: 1,
  ),
  // A2
  AssessmentQuestion(
    id: 'grammar_a2',
    skill: AssessmentSkill.grammar,
    levelIndex: 1,
    prompt: 'Yesterday we ___ to the cinema.',
    options: ['go', 'went', 'going', 'gone'],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'vocabulary_a2',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 1,
    prompt: 'What is the opposite of "cheap"?',
    options: ['quick', 'early', 'dirty', 'expensive'],
    correctIndex: 3,
  ),
  AssessmentQuestion(
    id: 'reading_a2',
    skill: AssessmentSkill.reading,
    levelIndex: 1,
    passage:
        'Anna lives in a small flat near the park. She likes walking there '
        'after work, but today it is raining, so she is reading at home.',
    prompt: 'Why is Anna reading at home?',
    options: [
      'Because it is raining',
      'Because she is tired',
      'Because the park is closed',
      'Because she has no work',
    ],
    correctIndex: 0,
  ),
  AssessmentQuestion(
    id: 'usage_a2',
    skill: AssessmentSkill.usage,
    levelIndex: 1,
    prompt: 'Which sentence is a polite request?',
    options: [
      'Give me water.',
      'Water now.',
      'Could I have some water, please?',
      'I want water.',
    ],
    correctIndex: 2,
  ),
  // B1
  AssessmentQuestion(
    id: 'grammar_b1',
    skill: AssessmentSkill.grammar,
    levelIndex: 2,
    prompt: 'If it rains tomorrow, we ___ at home.',
    options: ['would stayed', 'will stay', 'had stayed', 'stay would'],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'vocabulary_b1',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 2,
    prompt: 'He was ___ about the exam result, so he could not sleep.',
    options: ['generous', 'ordinary', 'anxious', 'faithful'],
    correctIndex: 2,
  ),
  AssessmentQuestion(
    id: 'reading_b1',
    skill: AssessmentSkill.reading,
    levelIndex: 2,
    passage:
        'Many people now work from home. This saves travel time, but some '
        'workers say they feel isolated because they rarely meet colleagues.',
    prompt: 'What problem do some home workers mention?',
    options: [
      'They travel too much',
      'They feel isolated',
      'They earn less money',
      'They work fewer hours',
    ],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'usage_b1',
    skill: AssessmentSkill.usage,
    levelIndex: 2,
    prompt: 'A friend says: "I have just failed my driving test." Best reply?',
    options: [
      'Congratulations!',
      'That is very funny.',
      'See you later.',
      'Oh no, I am sorry to hear that.',
    ],
    correctIndex: 3,
  ),
  // B2
  AssessmentQuestion(
    id: 'grammar_b2',
    skill: AssessmentSkill.grammar,
    levelIndex: 3,
    prompt: 'I wish I ___ more time to prepare yesterday.',
    options: ['had had', 'have had', 'would have', 'having'],
    correctIndex: 0,
  ),
  AssessmentQuestion(
    id: 'vocabulary_b2',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 3,
    prompt:
        'The company decided to ___ the project because it was losing '
        'money.',
    options: ['enhance', 'abandon', 'promote', 'inherit'],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'reading_b2',
    skill: AssessmentSkill.reading,
    levelIndex: 3,
    passage:
        'Although the new policy was intended to reduce traffic, residents '
        'reported that congestion simply moved to neighbouring streets.',
    prompt: 'What does the passage suggest about the policy?',
    options: [
      'It completely eliminated traffic',
      'It was widely popular',
      'It shifted the problem rather than solving it',
      'It was never applied',
    ],
    correctIndex: 2,
  ),
  AssessmentQuestion(
    id: 'usage_b2',
    skill: AssessmentSkill.usage,
    levelIndex: 3,
    prompt: 'Which sentence sounds most natural in a formal email?',
    options: [
      'Hey, so I wanna ask about the job thing.',
      'Tell me about the job now.',
      'About the job, what is up?',
      'I am writing to enquire about the position advertised on your website.',
    ],
    correctIndex: 3,
  ),
  // C1
  AssessmentQuestion(
    id: 'grammar_c1',
    skill: AssessmentSkill.grammar,
    levelIndex: 4,
    prompt: 'Not only ___ the deadline, but they also exceeded expectations.',
    options: ['they met', 'did they meet', 'met they', 'they did meet'],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'vocabulary_c1',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 4,
    prompt: 'Her argument was so ___ that nobody could find a flaw in it.',
    options: ['fragile', 'shallow', 'tedious', 'watertight'],
    correctIndex: 3,
  ),
  AssessmentQuestion(
    id: 'reading_c1',
    skill: AssessmentSkill.reading,
    levelIndex: 4,
    passage:
        'The author contends that innovation seldom emerges from isolated '
        'genius; rather, it arises from networks in which ideas are '
        'repeatedly tested and refined.',
    prompt: 'According to the author, where does innovation mostly come from?',
    options: [
      'Individual geniuses working alone',
      'Collaborative networks that refine ideas',
      'Random luck',
      'Government funding',
    ],
    correctIndex: 1,
  ),
  AssessmentQuestion(
    id: 'usage_c1',
    skill: AssessmentSkill.usage,
    levelIndex: 4,
    prompt: 'Which phrase politely disagrees in a meeting?',
    options: [
      'You are wrong.',
      'That is nonsense.',
      'I see your point, but I would argue that...',
      'No.',
    ],
    correctIndex: 2,
  ),
  // C2
  AssessmentQuestion(
    id: 'grammar_c2',
    skill: AssessmentSkill.grammar,
    levelIndex: 5,
    prompt:
        'Had the committee been better informed, it ___ a different '
        'decision.',
    options: [
      'would reach',
      'reached',
      'would have reached',
      'will have reached',
    ],
    correctIndex: 2,
  ),
  AssessmentQuestion(
    id: 'vocabulary_c2',
    skill: AssessmentSkill.vocabulary,
    levelIndex: 5,
    prompt:
        'His ___ remarks, though delivered with a smile, left the '
        'audience uneasy.',
    options: ['jovial', 'trivial', 'lucid', 'veiled'],
    correctIndex: 3,
  ),
  AssessmentQuestion(
    id: 'reading_c2',
    skill: AssessmentSkill.reading,
    levelIndex: 5,
    passage:
        'Far from being a mere ornament, the metaphor structures how we '
        'reason: to describe an argument as "a battle" is already to prefer '
        'certain responses over others.',
    prompt: "What is the author's main claim about metaphor?",
    options: [
      'It should be avoided in arguments',
      'It makes arguments more peaceful',
      'It is purely ornamental',
      'It shapes reasoning rather than merely decorating language',
    ],
    correctIndex: 3,
  ),
  AssessmentQuestion(
    id: 'usage_c2',
    skill: AssessmentSkill.usage,
    levelIndex: 5,
    prompt:
        'After a presentation where the projector failed and the slides '
        'were lost, which remark is understated irony?',
    options: [
      'It was a total catastrophe!',
      'That could have gone slightly better.',
      'The projector was broken.',
      'I will prepare new slides.',
    ],
    correctIndex: 1,
  ),
];
