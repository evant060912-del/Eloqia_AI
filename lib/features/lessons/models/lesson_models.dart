import '../../../services/voice/listening_accents.dart';
import '../../onboarding/assessment/level_assessment_data.dart';

enum LessonSkill { grammar, vocabulary, reading, listening }

enum ExerciseType { multipleChoice, trueFalse, fillBlank, ordering, matching }

enum ActivityKind { intro, practice, challenge, review }

extension LessonSkillX on LessonSkill {
  String get label => switch (this) {
    LessonSkill.grammar => 'Grammar',
    LessonSkill.vocabulary => 'Vocabulary',
    LessonSkill.reading => 'Reading',
    LessonSkill.listening => 'Listening',
  };
}

/// One answerable item. Content only: evaluation lives in [ExerciseEvaluator].
class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.topic,
    required this.prompt,
    required this.answers,
    required this.explanation,
    this.instructions,
    this.options = const <String>[],
    this.rule,
    this.example,
    this.notes = const <String, String>{},
    this.hints = const <String>[],
    this.evidence,
    this.difficulty = 1,
    this.pairs = const <String, String>{},
  });

  factory Exercise.choice({
    required String id,
    required String topic,
    required String prompt,
    required List<String> options,
    required String answer,
    required String why,
    String? rule,
    String? example,
    Map<String, String> notes = const <String, String>{},
    List<String> hints = const <String>[],
    String? evidence,
    int difficulty = 1,
  }) => Exercise(
    id: id,
    type: ExerciseType.multipleChoice,
    topic: topic,
    prompt: prompt,
    instructions: 'Choose the best answer.',
    options: options,
    answers: <String>[answer],
    explanation: why,
    rule: rule,
    example: example,
    notes: notes,
    hints: hints,
    evidence: evidence,
    difficulty: difficulty,
  );

  factory Exercise.trueFalse({
    required String id,
    required String topic,
    required String prompt,
    required bool answer,
    required String why,
    String? rule,
    String? example,
    List<String> hints = const <String>[],
    String? evidence,
    int difficulty = 1,
  }) => Exercise(
    id: id,
    type: ExerciseType.trueFalse,
    topic: topic,
    prompt: prompt,
    instructions: 'Decide whether the statement is true or false.',
    options: const <String>['True', 'False'],
    answers: <String>[answer ? 'True' : 'False'],
    explanation: why,
    rule: rule,
    example: example,
    hints: hints,
    evidence: evidence,
    difficulty: difficulty,
  );

  factory Exercise.fill({
    required String id,
    required String topic,
    required String prompt,
    required List<String> answers,
    required String why,
    String? rule,
    String? example,
    List<String> hints = const <String>[],
    String? evidence,
    int difficulty = 1,
  }) => Exercise(
    id: id,
    type: ExerciseType.fillBlank,
    topic: topic,
    prompt: prompt,
    instructions: 'Type the missing word or words.',
    answers: answers,
    explanation: why,
    rule: rule,
    example: example,
    hints: hints,
    evidence: evidence,
    difficulty: difficulty,
  );

  factory Exercise.order({
    required String id,
    required String topic,
    required String sentence,
    required String why,
    String? rule,
    String? prompt,
    List<String> hints = const <String>[],
    int difficulty = 1,
  }) => Exercise(
    id: id,
    type: ExerciseType.ordering,
    topic: topic,
    prompt: prompt ?? 'Build the sentence.',
    instructions: 'Tap the words in the right order.',
    options: sentence.split(' '),
    answers: <String>[sentence],
    explanation: why,
    rule: rule,
    example: sentence,
    hints: hints,
    difficulty: difficulty,
  );

  factory Exercise.match({
    required String id,
    required String topic,
    required Map<String, String> pairs,
    required String why,
    String? prompt,
    int difficulty = 1,
  }) => Exercise(
    id: id,
    type: ExerciseType.matching,
    topic: topic,
    prompt: prompt ?? 'Match each item with its meaning.',
    instructions: 'Tap an item on the left, then its match on the right.',
    pairs: pairs,
    answers: <String>[canonicalPairs(pairs)],
    explanation: why,
    difficulty: difficulty,
  );

  final String id;
  final ExerciseType type;
  final String topic;
  final String prompt;
  final String? instructions;
  final List<String> options;

  /// Accepted answers; ordering and matching use one canonical form.
  final List<String> answers;
  final String explanation;
  final String? rule;
  final String? example;

  /// Why a specific wrong option is wrong, keyed by that option.
  final Map<String, String> notes;
  final List<String> hints;

  /// Where the learner should look (passage detail or audio phrase).
  final String? evidence;
  final int difficulty;
  final Map<String, String> pairs;

  static String canonicalPairs(Map<String, String> pairs) {
    final List<String> keys = pairs.keys.toList()..sort();
    return keys.map((String k) => '$k=${pairs[k]}').join(';');
  }
}

class LessonActivity {
  const LessonActivity({
    required this.kind,
    required this.title,
    this.exercises = const <Exercise>[],
    this.explanation = const <String>[],
    this.examples = const <String>[],
  });

  final ActivityKind kind;
  final String title;
  final List<Exercise> exercises;

  /// Teaching text for intro activities.
  final List<String> explanation;
  final List<String> examples;
}

/// A real video (or recording) used for listening practice.
///
/// [mp4] plays a file the app may show legally (public domain, such as VOA
/// Learning English, or your own recordings). [youtube] uses YouTube's
/// official embedded player: the video stays on YouTube, with its captions,
/// and only our questions are added.
class VideoClip {
  const VideoClip.mp4({
    required String this.url,
    required this.credit,
    required this.sourcePage,
    this.publicDomain = true,
  }) : youtubeId = null,
       startSeconds = 0,
       endSeconds = null;

  const VideoClip.youtube({
    required String id,
    required this.credit,
    required this.sourcePage,
    this.startSeconds = 0,
    this.endSeconds,
  }) : youtubeId = id,
       url = null,
       publicDomain = false;

  final String? url;
  final String? youtubeId;

  /// Who made it ("VOA Learning English (public domain)").
  final String credit;

  /// Page where the original is published.
  final String sourcePage;
  final bool publicDomain;

  /// Part of a YouTube video to play (seconds).
  final int startSeconds;
  final int? endSeconds;

  bool get isYoutube => youtubeId != null;
}

class AudioLine {
  const AudioLine(this.speaker, this.text, {this.accent});

  final String speaker;
  final String text;

  /// Accent of the speaker's voice; null keeps the default voice.
  final ListeningAccent? accent;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.skill,
    required this.levelIndex,
    required this.topic,
    required this.estimatedMinutes,
    required this.xpReward,
    required this.objective,
    required this.activities,
    this.difficulty = 1,
    this.tags = const <String>[],
    this.passage,
    this.audio = const <AudioLine>[],
    this.video,
  });

  final String id;
  final String title;
  final String description;
  final LessonSkill skill;
  final int levelIndex;
  final String topic;
  final int estimatedMinutes;
  final int xpReward;
  final String objective;
  final List<LessonActivity> activities;
  final int difficulty;

  /// Interest/goal tags used for personalization.
  final List<String> tags;
  final String? passage;
  final List<AudioLine> audio;

  String get level => assessmentLevels[levelIndex];

  LessonActivity get intro => activities.firstWhere(
    (LessonActivity a) => a.kind == ActivityKind.intro,
    orElse: () => const LessonActivity(kind: ActivityKind.intro, title: ''),
  );

  List<Exercise> exercisesOf(ActivityKind kind) => <Exercise>[
    for (final LessonActivity a in activities)
      if (a.kind == kind) ...a.exercises,
  ];

  /// A real video for this listening lesson. Its transcript, when it may be
  /// shown (public domain), is in [audio] and appears after answering.
  final VideoClip? video;

  /// Accents heard in the audio (listening library filters).
  Set<ListeningAccent> get accents => <ListeningAccent>{
    for (final AudioLine line in audio)
      if (line.accent != null) line.accent!,
  };

  List<Exercise> get allExercises => <Exercise>[
    for (final LessonActivity a in activities) ...a.exercises,
  ];
}
