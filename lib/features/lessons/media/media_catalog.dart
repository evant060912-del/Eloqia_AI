import '../../../services/voice/listening_accents.dart';
import '../engine/lesson_engine.dart';
import '../models/lesson_models.dart';

/// Lessons built on real media, with library filters and recommendations.
class MediaCatalog {
  MediaCatalog._();

  static List<Lesson> get lessons => <Lesson>[
    for (final Lesson lesson in LessonCatalog.all)
      if (lesson.media != null) lesson,
  ];

  static List<Lesson> filter(MediaFilter filter) => <Lesson>[
    for (final Lesson lesson in lessons)
      if (filter.matches(lesson.media!, lesson.levelIndex)) lesson,
  ];

  static MediaCoverage get coverage => MediaCoverage(<(MediaInfo, int)>[
    for (final Lesson lesson in lessons) (lesson.media!, lesson.levelIndex),
  ]);

  /// Best next media lesson: the preferred accent first, then the closest
  /// level (a little above is better than below), lessons not done first.
  static Lesson? recommend({
    required int levelIndex,
    ListeningAccent? accent,
    Set<String> done = const <String>{},
    Iterable<Lesson>? from,
  }) {
    final List<Lesson> pool = (from ?? lessons).toList();
    if (pool.isEmpty) return null;
    int score(Lesson l) {
      final int gap = l.levelIndex - levelIndex;
      return (done.contains(l.id) ? 1000 : 0) +
          (accent != null && l.media?.accent != accent ? 100 : 0) +
          (gap < 0 ? -gap * 3 : gap * 2);
    }

    pool.sort((Lesson a, Lesson b) => score(a).compareTo(score(b)));
    return pool.first;
  }

  /// Orders lessons so the preferred accent comes first (stable).
  static List<Lesson> preferAccent(
    List<Lesson> lessons,
    ListeningAccent? accent,
  ) {
    if (accent == null) return lessons;
    bool heard(Lesson l) =>
        l.media?.accent == accent || l.accents.contains(accent);
    return <Lesson>[
      ...lessons.where(heard),
      ...lessons.where((l) => !heard(l)),
    ];
  }
}
