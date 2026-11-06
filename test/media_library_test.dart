import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/lessons/lesson_launcher.dart';
import 'package:eloqia_ai/features/lessons/media/media_catalog.dart';
import 'package:eloqia_ai/features/lessons/media/media_library_screen.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_data.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/models/learning_session.dart';
import 'package:eloqia_ai/models/progress.dart';
import 'package:eloqia_ai/services/voice/accent_preference.dart';
import 'package:eloqia_ai/services/voice/listening_accents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('content', () {
    test('every media lesson is a real video with vocabulary and idioms', () {
      expect(MediaCatalog.lessons, isNotEmpty);
      for (final Lesson lesson in MediaCatalog.lessons) {
        expect(lesson.video, isNotNull, reason: lesson.id);
        expect(lesson.media!.vocabulary, isNotEmpty, reason: lesson.id);
        expect(lesson.media!.idioms, isNotEmpty, reason: lesson.id);
        expect(lesson.media!.creator, isNotEmpty, reason: lesson.id);
        for (final ClipSegment s in lesson.video!.segments) {
          expect(s.endSeconds, greaterThan(s.startSeconds));
        }
      }
    });

    test('one descriptor per CEFR level, speech getting faster', () {
      expect(
        levelDescriptors.map((LevelDescriptor d) => d.code),
        assessmentLevels,
      );
      for (int i = 1; i < levelDescriptors.length; i++) {
        expect(
          levelDescriptors[i].maxWpm,
          greaterThan(levelDescriptors[i - 1].maxWpm),
        );
      }
    });

    test('coverage shows what is missing', () {
      final MediaCoverage coverage = MediaCatalog.coverage;
      expect(
        coverage.count(
          ContentCategory.everydayEnglish,
          0,
          ListeningAccent.american,
        ),
        greaterThan(0),
      );
      expect(coverage.creatorsFor(ListeningAccent.american), isNotEmpty);
      expect(coverage.missing(), contains(ContentCategory.technology));
    });
  });

  group('recommendations', () {
    test('the closest level comes first, done lessons last', () {
      final Lesson a1 = MediaCatalog.recommend(levelIndex: 0)!;
      expect(a1.levelIndex, 0);
      final Set<String> doneA1 = <String>{
        for (final Lesson l in MediaCatalog.lessons)
          if (l.levelIndex == 0) l.id,
      };
      final Lesson next = MediaCatalog.recommend(levelIndex: 0, done: doneA1)!;
      expect(doneA1, isNot(contains(next.id)));
    });

    test('the preferred accent comes first', () {
      final List<Lesson> ordered = MediaCatalog.preferAccent(
        MediaCatalog.lessons,
        ListeningAccent.american,
      );
      expect(ordered.first.media!.accent, ListeningAccent.american);
      expect(
        MediaCatalog.preferAccent(MediaCatalog.lessons, null),
        MediaCatalog.lessons,
      );
    });

    test('filters combine', () {
      const MediaFilter british = MediaFilter(accent: ListeningAccent.british);
      const MediaFilter a1 = MediaFilter(levelIndex: 0);
      final Lesson lesson = MediaCatalog.lessons.firstWhere(
        (Lesson l) => l.levelIndex == 0,
      );
      expect(a1.matches(lesson.media!, lesson.levelIndex), isTrue);
      expect(
        british.matches(lesson.media!, lesson.levelIndex),
        lesson.media!.accent == ListeningAccent.british,
      );
    });
  });

  group('accent preference and screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(AccentPreference.key);
    });

    test('the accent is saved and cleared', () async {
      await AccentPreference.save(ListeningAccent.australian);
      expect(await AccentPreference.load(), ListeningAccent.australian);
      await AccentPreference.save(null);
      expect(await AccentPreference.load(), isNull);
    });

    testWidgets('choosing an accent filters the videos and is kept', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaLibraryScreen(
            loader: () async => LessonContext(
              profile: LearningProfile(currentLevel: 'A1'),
              assessment: null,
              sessions: const <LearningSession>[],
              memories: const [],
              progress: const Progress(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accent-british')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('media-empty')), findsOneWidget);
      expect(await AccentPreference.load(), ListeningAccent.british);
    });
  });
}
