/// Exam preparation formats (writing part).
///
/// Facts come from the public test descriptions (TOEFL iBT format introduced
/// on 21 January 2026, IELTS Writing). Every prompt in Eloqia is original and
/// every score is an unofficial practice estimate: Eloqia is not affiliated
/// with ETS or the IELTS partners. Pure Dart, so it is easy to test.
library;

enum ExamKind {
  toefl(
    'TOEFL',
    'TOEFL iBT',
    'ETS',
    'TOEFL iBT (format introduced in January 2026). Writing: about 23 '
        'minutes, three task types. Speaking: about 8 minutes, Listen and '
        'Repeat and an interview. Section scores are reported on a 1–6 '
        'scale.',
  ),
  ielts(
    'IELTS',
    'IELTS',
    'the IELTS partners',
    'IELTS Writing: 60 minutes, two tasks; Task 2 counts twice as much as '
        'Task 1. IELTS Speaking: 11 to 14 minutes in three parts. Each is '
        'marked from 0 to 9 on four criteria.',
  );

  const ExamKind(this.label, this.fullName, this.owner, this.overview);

  final String label;
  final String fullName;

  /// Organisation that runs the exam (for the disclaimer).
  final String owner;
  final String overview;

  String get disclaimer =>
      'Original practice tasks. Scores are unofficial estimates; Eloqia is '
      'not affiliated with or endorsed by $owner.';

  static ExamKind? byLabel(String value) {
    for (final ExamKind exam in ExamKind.values) {
      if (exam.label == value || exam.name == value) return exam;
    }
    return null;
  }
}

/// One task type of an exam. [apiValue] matches `Genre` in
/// `backend/app/writing.py` (except Build a Sentence, scored on the device).
enum ExamTaskType {
  toeflBuildSentence(
    'toefl_build_sentence',
    ExamKind.toefl,
    'Build a Sentence',
    'Put words in the right order to complete a reply.',
    Duration(minutes: 6, seconds: 50),
    0,
    10,
    <String>[
      '10 items, 6 min 50 s in total (about 41 seconds each).',
      'Someone says something; you complete the reply by placing words and '
          'phrases in the blanks. Some words are already in place, and there '
          'may be one word too many.',
      'All or nothing: one word in the wrong place and the item scores 0.',
    ],
  ),
  toeflEmail(
    'toefl_email',
    ExamKind.toefl,
    'Write an Email',
    'Answer a real-life situation by email, covering every point.',
    Duration(minutes: 7),
    80,
    5,
    <String>[
      'One email, 7 minutes.',
      'The situation lists what your email must do: cover every point.',
      'Choose the tone for the reader (a professor, a manager, a friend).',
      'Scored 0–5 on how completely and appropriately you communicate.',
    ],
  ),
  toeflDiscussion(
    'toefl_discussion',
    ExamKind.toefl,
    'Academic Discussion',
    'Post your opinion in a class discussion forum.',
    Duration(minutes: 10),
    100,
    5,
    <String>[
      'One post, 10 minutes. Aim for at least 100 words.',
      'A professor asks a question and two students answer it.',
      'Give a clear opinion, add a new reason or example, and respond to '
          'what the other students said.',
      'Scored 0–5.',
    ],
  ),
  ieltsTask1Academic(
    'ielts_task1_academic',
    ExamKind.ielts,
    'Task 1 Academic',
    'Describe a graph, table, process or map.',
    Duration(minutes: 20),
    150,
    9,
    <String>[
      'About 20 minutes, at least 150 words.',
      'Write an overview of the main trends, then select, report and compare '
          'the key features.',
      'Describe only what you see: no opinion, no causes.',
      'Marked 0–9 on Task Achievement, Coherence and Cohesion, Lexical '
          'Resource, Grammatical Range and Accuracy.',
    ],
  ),
  ieltsTask1General(
    'ielts_task1_general',
    ExamKind.ielts,
    'Task 1 General Training',
    'Write a letter that covers three points.',
    Duration(minutes: 20),
    150,
    9,
    <String>[
      'About 20 minutes, at least 150 words.',
      'A letter to a friend, a manager or an organisation: cover and develop '
          'the three bullet points.',
      'Make the purpose clear and keep the right tone (informal, '
          'semi-formal or formal).',
      'Marked 0–9 on the same four criteria as Academic Task 1.',
    ],
  ),
  ieltsTask2(
    'ielts_task2',
    ExamKind.ielts,
    'Task 2 Essay',
    'Write an essay that answers every part of the question.',
    Duration(minutes: 40),
    250,
    9,
    <String>[
      'About 40 minutes, at least 250 words. Counts twice as much as Task 1.',
      'Answer every part of the question with a clear position.',
      'Develop and support your ideas; organise them in paragraphs.',
      'Marked 0–9 on Task Response, Coherence and Cohesion, Lexical '
          'Resource, Grammatical Range and Accuracy.',
    ],
  ),

  // --------------------------------------------------------------- speaking
  toeflListenRepeat(
    'toefl_listen_repeat',
    ExamKind.toefl,
    'Listen and Repeat',
    'Repeat sentences exactly as you hear them.',
    Duration(minutes: 2),
    0,
    7,
    <String>[
      'Speaking section, about 8 minutes in total, no preparation time.',
      '7 sentences, from short to long; about 8 to 12 seconds to repeat '
          'each one.',
      'Repeat every word in order. Eloqia compares what the recogniser '
          'heard with the sentence; it does not score pronunciation.',
    ],
  ),
  toeflInterview(
    'toefl_interview',
    ExamKind.toefl,
    'Take an Interview',
    'Answer four interview questions on one topic.',
    Duration(minutes: 3),
    0,
    5,
    <String>[
      '4 questions on one topic, about 45 seconds for each answer.',
      'Answer directly, then add a reason or an example.',
      'Mia reviews the transcript (0–5): content, coherence, language. '
          'Pronunciation is not assessed.',
    ],
  ),
  ieltsSpeaking(
    'ielts_speaking',
    ExamKind.ielts,
    'Speaking',
    'Part 1 questions, a Part 2 long turn, Part 3 discussion.',
    Duration(minutes: 14),
    0,
    9,
    <String>[
      'About 11 to 14 minutes with an examiner, in three parts.',
      'Part 1: short questions on familiar topics (4–5 minutes).',
      'Part 2: a cue card, 1 minute to prepare, up to 2 minutes to speak.',
      'Part 3: a discussion of wider questions (4–5 minutes).',
      'Marked 0–9 on Fluency and Coherence, Lexical Resource, Grammatical '
          'Range and Accuracy, and Pronunciation. Mia reviews the transcript '
          'on the first three; pronunciation is not assessed here.',
    ],
  );

  const ExamTaskType(
    this.apiValue,
    this.exam,
    this.label,
    this.summary,
    this.timeLimit,
    this.minWords,
    this.scaleMax,
    this.format,
  );

  final String apiValue;
  final ExamKind exam;
  final String label;
  final String summary;

  /// Official time for one attempt.
  final Duration timeLimit;

  /// Recommended or required minimum length (0 for Build a Sentence).
  final int minWords;

  /// Top of the score scale (items for Build a Sentence).
  final int scaleMax;
  final List<String> format;

  bool get isSpeaking =>
      this == toeflListenRepeat ||
      this == toeflInterview ||
      this == ieltsSpeaking;

  bool get isWriting => !isSpeaking && this != toeflBuildSentence;

  String get timeLabel => formatClock(timeLimit, withUnits: true);

  static ExamTaskType? byApiValue(String value) {
    for (final ExamTaskType type in ExamTaskType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  static List<ExamTaskType> of(ExamKind exam) => ExamTaskType.values
      .where((ExamTaskType t) => t.exam == exam)
      .toList(growable: false);
}

/// "6:50", or "6 min 50 s" with [withUnits]. Negative durations are shown
/// without sign (callers add "+" for overtime).
String formatClock(Duration duration, {bool withUnits = false}) {
  final int total = duration.inSeconds.abs();
  final int minutes = total ~/ 60;
  final int seconds = total % 60;
  if (withUnits) {
    return seconds == 0 ? '$minutes min' : '$minutes min $seconds s';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Advice attached to an exam criterion: what it means and how to improve.
class CriterionAdvice {
  const CriterionAdvice({
    required this.label,
    required this.meaning,
    required this.tips,
    required this.practice,
  });

  final String label;
  final String meaning;
  final List<String> tips;

  /// The task type that trains this criterion best.
  final ExamTaskType practice;
}

/// Advice per criterion name (as sent by the server).
const Map<String, CriterionAdvice> examCriterionAdvice =
    <String, CriterionAdvice>{
      'task_achievement': CriterionAdvice(
        label: 'Task Achievement',
        meaning: 'A clear overview, with key features selected and compared.',
        tips: <String>[
          'Write a two-sentence overview of the biggest trends before any '
              'detail.',
          'Select: compare the highest, the lowest and the biggest changes '
              'instead of listing every number.',
          'Check every figure you quote against the visual.',
        ],
        practice: ExamTaskType.ieltsTask1Academic,
      ),
      'task_response': CriterionAdvice(
        label: 'Task Response',
        meaning: 'Every part of the question answered with a clear position.',
        tips: <String>[
          'Underline each part of the question and answer all of them.',
          'State your position in the introduction and keep it to the end.',
          'Extend each main idea with an explanation and an example.',
        ],
        practice: ExamTaskType.ieltsTask2,
      ),
      'coherence_cohesion': CriterionAdvice(
        label: 'Coherence and Cohesion',
        meaning: 'Logical organisation, paragraphs and linking.',
        tips: <String>[
          'One central idea per paragraph, announced in its first sentence.',
          'Vary linking words (however, as a result, in contrast) and do not '
              'start every sentence with one.',
          'Refer back with "this", "these" or pronouns instead of repeating.',
        ],
        practice: ExamTaskType.ieltsTask2,
      ),
      'lexical_resource': CriterionAdvice(
        label: 'Lexical Resource',
        meaning: 'Range, precision and accuracy of vocabulary.',
        tips: <String>[
          'Paraphrase the question instead of copying it.',
          'Learn collocations as blocks: "a sharp rise", "play a key role".',
          'Replace repeated general words (good, big, thing) with precise '
              'ones.',
        ],
        practice: ExamTaskType.ieltsTask1Academic,
      ),
      'grammatical_range_accuracy': CriterionAdvice(
        label: 'Grammatical Range and Accuracy',
        meaning: 'Varied structures, used accurately.',
        tips: <String>[
          'Mix simple sentences with relative clauses, conditionals and '
              'passives.',
          'Keep two minutes to check agreement, articles and tenses.',
          'Accuracy first: a correct simple sentence beats a broken complex '
              'one.',
        ],
        practice: ExamTaskType.ieltsTask2,
      ),
      'task_completion': CriterionAdvice(
        label: 'Task completion',
        meaning: 'Every point of the situation is covered.',
        tips: <String>[
          'Turn each point of the task into one or two sentences.',
          'Tick the points off before you finish.',
          'Add one concrete detail to each point (a date, a reason).',
        ],
        practice: ExamTaskType.toeflEmail,
      ),
      'tone_conventions': CriterionAdvice(
        label: 'Tone and conventions',
        meaning: 'Greeting, closing and politeness suit the reader.',
        tips: <String>[
          'Professor or manager: "Dear Professor Lee," … "Best regards,".',
          'Ask politely: "Could you…?", "I would appreciate it if…".',
          'Say why you are writing in the first sentence.',
        ],
        practice: ExamTaskType.toeflEmail,
      ),
      'contribution': CriterionAdvice(
        label: 'Contribution',
        meaning: 'A clear opinion that adds something new.',
        tips: <String>[
          'Give your opinion in your first sentence.',
          'Add a reason or an example that neither student mentioned.',
          'Explain it in two or three sentences rather than listing ideas.',
        ],
        practice: ExamTaskType.toeflDiscussion,
      ),
      'engagement': CriterionAdvice(
        label: 'Engagement with others',
        meaning: 'You respond to what the other students wrote.',
        tips: <String>[
          'Name a classmate: "I agree with Maya that…, but…".',
          'Show why their point is incomplete, then add yours.',
          'Keep the reply about the professor’s question.',
        ],
        practice: ExamTaskType.toeflDiscussion,
      ),
      'language_use': CriterionAdvice(
        label: 'Language use',
        meaning: 'Range and accuracy of grammar and vocabulary.',
        tips: <String>[
          'Vary sentence openings and structures.',
          'Use precise words instead of very common ones.',
          'Save 30 seconds to re-read for agreement and tense.',
        ],
        practice: ExamTaskType.toeflBuildSentence,
      ),
      'sentence_repetition': CriterionAdvice(
        label: 'Listen and Repeat',
        meaning: 'Repeating sentences word for word.',
        tips: <String>[
          'Shadow short audio: repeat right after the speaker, every day.',
          'Listen for chunks ("at least one day ahead"), not single words.',
          'Keep the small words: articles and prepositions count.',
        ],
        practice: ExamTaskType.toeflListenRepeat,
      ),
      'fluency_coherence': CriterionAdvice(
        label: 'Fluency and Coherence',
        meaning: 'Speaking at length with linked ideas.',
        tips: <String>[
          'Answer, then extend: "because…", "for example…", "so…".',
          'Replace silent pauses with short fillers like "Well, let me '
              'think".',
          'For Part 2, use the card’s points as your plan.',
        ],
        practice: ExamTaskType.ieltsSpeaking,
      ),
      'relevance_development': CriterionAdvice(
        label: 'Relevance and development',
        meaning: 'Answering the question and developing it.',
        tips: <String>[
          'Start with a one-sentence direct answer.',
          'Add one reason and one concrete example.',
          'Finish with a short conclusion if time remains.',
        ],
        practice: ExamTaskType.toeflInterview,
      ),
      'coherence': CriterionAdvice(
        label: 'Coherence',
        meaning: 'Ideas that follow logically.',
        tips: <String>[
          'Use signposts: "First…", "Another reason is…", "Overall…".',
          'Keep one idea per sentence when speaking.',
          'Link back to the question at the end.',
        ],
        practice: ExamTaskType.toeflInterview,
      ),
      'sentence_building': CriterionAdvice(
        label: 'Sentence building',
        meaning: 'Word order in Build a Sentence.',
        tips: <String>[
          'Check the final punctuation first: question or statement?',
          'Inside "Do you know…/Can you tell me…", keep statement order.',
          'Check agreement to spot the extra word ("is"/"are", "do"/"does").',
        ],
        practice: ExamTaskType.toeflBuildSentence,
      ),
    };

/// TOEFL "Write for an Academic Discussion": the professor's question and
/// two students' posts, shown like a class forum.
class DiscussionPost {
  const DiscussionPost(this.author, this.text);

  final String author;
  final String text;
}

class DiscussionBoard {
  const DiscussionBoard({
    required this.course,
    required this.professor,
    required this.question,
    required this.posts,
  });

  final String course;
  final String professor;
  final String question;
  final List<DiscussionPost> posts;

  /// Source material sent to Mia with the learner's post.
  String asSourceText() {
    final StringBuffer out = StringBuffer(
      'Course: $course.\nProfessor $professor: $question',
    );
    for (final DiscussionPost post in posts) {
      out.write('\n${post.author}: ${post.text}');
    }
    return out.toString();
  }
}
