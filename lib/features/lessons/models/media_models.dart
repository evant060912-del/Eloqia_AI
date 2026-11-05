/// The real-media library: categories, general or academic track, CEFR
/// levels A1 to C2 with what really changes between them, accents,
/// vocabulary, idioms and replayable passages. Pure Dart.
library;

import '../../../services/voice/listening_accents.dart';

enum ContentCategory {
  technology('Technology', '💻', 'AI, computing, innovation, cybersecurity'),
  science('Science', '🔬', 'Discoveries, space, biology, physics'),
  literature('Literature', '📚', 'Novels, authors, poetry, literary analysis'),
  medicine('Medicine', '🩺', 'Health, medicine, anatomy, research'),
  financeBusiness(
    'Finance & Business',
    '📈',
    'Economy, investing, entrepreneurship',
  ),
  history('History', '🏛️', 'Civilisations, events, biographies'),
  cultureSociety(
    'Culture & Society',
    '🌍',
    'Society, traditions, current affairs, debates',
  ),
  environment('Environment', '🌱', 'Climate, ecology, biodiversity'),
  artsEntertainment(
    'Arts & Entertainment',
    '🎬',
    'Cinema, music, photography, design',
  ),
  everydayEnglish(
    'Everyday English',
    '☕',
    'Daily life, travel, work, conversations',
  );

  const ContentCategory(this.label, this.emoji, this.examples);

  final String label;
  final String emoji;
  final String examples;
}

enum ContentTrack {
  general('General'),
  academic('Academic');

  const ContentTrack(this.label);
  final String label;
}

/// What really changes from one level to the next, so that a C1 video is
/// not an A1 video with harder questions. Used to place each video.
class LevelDescriptor {
  const LevelDescriptor({
    required this.code,
    required this.name,
    required this.speech,
    required this.minWpm,
    required this.maxWpm,
    required this.vocabulary,
    required this.grammar,
    required this.topics,
  });

  final String code;
  final String name;

  /// Speed and delivery of the speakers.
  final String speech;

  /// Typical speaking rate (words per minute).
  final int minWpm;
  final int maxWpm;
  final String vocabulary;
  final String grammar;
  final String topics;
}

const List<LevelDescriptor> levelDescriptors = <LevelDescriptor>[
  LevelDescriptor(
    code: 'A1',
    name: 'Beginner',
    speech: 'Slow, very clear, scripted; short sentences with pauses.',
    minWpm: 80,
    maxWpm: 110,
    vocabulary: 'The 500 most common words: people, places, numbers.',
    grammar: 'Present simple, "to be", basic questions.',
    topics: 'Introductions, home, daily routines.',
  ),
  LevelDescriptor(
    code: 'A2',
    name: 'Elementary',
    speech: 'Slow to moderate, clear; simple linked sentences.',
    minWpm: 100,
    maxWpm: 130,
    vocabulary: 'About 1,000 words: shopping, travel, work basics.',
    grammar: 'Past simple, going to, comparatives.',
    topics: 'Everyday situations, plans, simple stories.',
  ),
  LevelDescriptor(
    code: 'B1',
    name: 'Intermediate',
    speech: 'Moderate natural speed, several speakers, some humour.',
    minWpm: 120,
    maxWpm: 150,
    vocabulary: 'About 2,000 words; common phrasal verbs.',
    grammar: 'Present perfect, conditionals 1–2, reported speech.',
    topics: 'Work, opinions, news for learners, experiences.',
  ),
  LevelDescriptor(
    code: 'B2',
    name: 'Upper Intermediate',
    speech: 'Natural speed, real interviews and reports, mild accents.',
    minWpm: 140,
    maxWpm: 170,
    vocabulary: 'About 4,000 words; topic vocabulary, collocations.',
    grammar: 'Past perfect, passive, all conditionals, modals of deduction.',
    topics: 'Science and society explained, arguments with two sides.',
  ),
  LevelDescriptor(
    code: 'C1',
    name: 'Advanced',
    speech: 'Fast native speech, unscripted talk, interruptions, accents.',
    minWpm: 160,
    maxWpm: 190,
    vocabulary: 'Academic and specialised vocabulary, idioms, irony.',
    grammar: 'Complex clauses, inversion, hedging, nuance.',
    topics: 'Lectures, expert panels, documentaries, debates.',
  ),
  LevelDescriptor(
    code: 'C2',
    name: 'Proficiency',
    speech:
        'Any native speed or style: dense lectures, parliament, '
        'literature read aloud.',
    minWpm: 170,
    maxWpm: 220,
    vocabulary: 'Rare, technical and literary vocabulary; allusions.',
    grammar: 'Full range, including literary and formal registers.',
    topics: 'Abstract and specialised subjects, implied meaning, style.',
  ),
];

/// A word or expression worth learning from the video.
class VocabItem {
  const VocabItem(this.term, this.meaning, {this.example});

  final String term;
  final String meaning;

  /// How it is used in the video.
  final String? example;
}

/// A passage the learner can replay with one tap.
class ClipSegment {
  const ClipSegment(this.label, this.startSeconds, this.endSeconds)
    : assert(endSeconds > startSeconds);

  final String label;
  final int startSeconds;
  final int endSeconds;

  Duration get start => Duration(seconds: startSeconds);
  Duration get end => Duration(seconds: endSeconds);
}

/// Library information of a real video or recording.
class MediaInfo {
  const MediaInfo({
    required this.category,
    required this.accent,
    required this.creator,
    this.track = ContentTrack.general,
    this.vocabulary = const <VocabItem>[],
    this.idioms = const <VocabItem>[],
  });

  final ContentCategory category;
  final ContentTrack track;

  /// Accent of the main speakers.
  final ListeningAccent accent;

  /// Channel, organisation or programme (diversity of sources).
  final String creator;
  final List<VocabItem> vocabulary;
  final List<VocabItem> idioms;
}

/// Filters of the media library; null means "any".
class MediaFilter {
  const MediaFilter({this.accent, this.levelIndex, this.category, this.track});

  final ListeningAccent? accent;
  final int? levelIndex;
  final ContentCategory? category;
  final ContentTrack? track;

  bool matches(MediaInfo info, int lessonLevel) =>
      (accent == null || info.accent == accent) &&
      (levelIndex == null || lessonLevel == levelIndex) &&
      (category == null || info.category == category) &&
      (track == null || info.track == track);
}

/// How many items exist per category, level and accent (content planning).
class MediaCoverage {
  MediaCoverage(Iterable<(MediaInfo, int)> items) {
    for (final (MediaInfo info, int level) in items) {
      final String key = '${info.category.name}|$level|${info.accent.name}';
      _counts[key] = (_counts[key] ?? 0) + 1;
      _creators.putIfAbsent(info.accent, () => <String>{}).add(info.creator);
      _byCategory[info.category] = (_byCategory[info.category] ?? 0) + 1;
    }
  }

  final Map<String, int> _counts = <String, int>{};
  final Map<ListeningAccent, Set<String>> _creators =
      <ListeningAccent, Set<String>>{};
  final Map<ContentCategory, int> _byCategory = <ContentCategory, int>{};

  int count(ContentCategory category, int level, ListeningAccent accent) =>
      _counts['${category.name}|$level|${accent.name}'] ?? 0;

  int inCategory(ContentCategory category) => _byCategory[category] ?? 0;

  /// Different creators heard for an accent.
  Set<String> creatorsFor(ListeningAccent accent) =>
      _creators[accent] ?? const <String>{};

  /// Categories still below the target number of videos.
  List<ContentCategory> missing({int target = 20}) => <ContentCategory>[
    for (final ContentCategory c in ContentCategory.values)
      if (inCategory(c) < target) c,
  ];
}
