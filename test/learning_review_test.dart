import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/learning/learning_hub_screen.dart'
    as learning_hub;
import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_result_service.dart';
import 'package:eloqia_ai/features/lessons/lesson_launcher.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/lessons/review/review_deck.dart';
import 'package:eloqia_ai/features/lessons/review/review_service.dart';
import 'package:eloqia_ai/features/lessons/review/review_session.dart';
import 'package:eloqia_ai/features/lessons/ui/lesson_library_screen.dart';
import 'package:eloqia_ai/features/lessons/ui/lesson_runner_screen.dart'
    show reviewChangeText;
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/models/learning_session.dart';
import 'package:eloqia_ai/models/progress.dart';
import 'package:eloqia_ai/services/learning/learning_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _day0 = DateTime.utc(2026, 10, 30, 15);
final DateTime _day1 = DateTime.utc(2026, 10, 31, 8);

ReviewDeck _deckWith(Map<String, bool> results, {DateTime? now}) => ReviewDeck()
    .record(results, now: now ?? _day0, eligible: ReviewSessions.eligible)
    .deck;

void main() {
  group('content', () {
    test('two lessons per level for grammar, vocabulary and reading', () {
      expect(LessonCatalog.all.length, greaterThanOrEqualTo(36));
      for (final LessonSkill skill in <LessonSkill>[
        LessonSkill.grammar,
        LessonSkill.vocabulary,
        LessonSkill.reading,
      ]) {
        for (int level = 0; level <= 4; level++) {
          expect(
            LessonCatalog.forSkill(
              skill,
            ).where((Lesson l) => l.levelIndex == level).length,
            greaterThanOrEqualTo(2),
            reason: '${skill.name} level $level',
          );
        }
      }
    });

    test('every exercise is indexed and its answer is accepted', () {
      for (final Lesson lesson in LessonCatalog.all) {
        for (final Exercise e in lesson.allExercises) {
          expect(LessonCatalog.exercise(e.id)?.lesson.id, lesson.id);
        }
      }
      expect(LessonCatalog.exercise('missing'), isNull);
    });
  });

  group('spaced review', () {
    test('only missed grammar and vocabulary exercises enter the deck', () {
      final result = ReviewDeck().record(
        <String, bool>{
          'g-a1-be-1': false,
          'g-a1-be-2': true,
          'r-a1-1': false,
          'unknown': false,
        },
        now: _day0,
        eligible: ReviewSessions.eligible,
      );
      expect(result.change.added, 1);
      expect(result.deck.items.keys, <String>['g-a1-be-1']);
      expect(result.deck.due(_day0), isEmpty);
      expect(result.deck.due(_day1), hasLength(1));
    });

    test('correct answers climb the boxes until mastered', () {
      ReviewDeck deck = _deckWith(<String, bool>{'g-a1-be-1': false});
      DateTime now = _day1;
      final List<int> waits = <int>[];
      for (int i = 0; i < ReviewDeck.intervals.length; i++) {
        deck = deck
            .record(
              <String, bool>{'g-a1-be-1': true},
              now: now,
              eligible: ReviewSessions.eligible,
            )
            .deck;
        final ReviewItem? item = deck.items['g-a1-be-1'];
        if (item == null) break;
        waits.add(
          item.dueAt
              .difference(DateTime.utc(now.year, now.month, now.day))
              .inDays,
        );
        now = item.dueAt.add(const Duration(hours: 9));
      }
      expect(waits, <int>[3, 7, 14, 30]);
      expect(deck.items, isEmpty);
      expect(deck.masteredCount, 1);
    });

    test('early answers wait, mistakes come back tomorrow', () {
      final ReviewDeck deck = _deckWith(<String, bool>{'g-a1-be-1': false});
      expect(
        deck
            .record(
              <String, bool>{'g-a1-be-1': true},
              now: _day0,
              eligible: ReviewSessions.eligible,
            )
            .change
            .isEmpty,
        isTrue,
      );
      final lapse = deck.record(
        <String, bool>{'g-a1-be-1': false},
        now: _day1,
        eligible: ReviewSessions.eligible,
      );
      expect(lapse.change.reset, 1);
      expect(lapse.deck.items['g-a1-be-1']!.lapses, 1);
      expect(lapse.deck.items['g-a1-be-1']!.dueAt, DateTime.utc(2026, 11, 1));
    });

    test('the review lesson holds at most ten due exercises', () {
      final Map<String, bool> missed = <String, bool>{
        for (final Lesson l in LessonCatalog.forSkill(LessonSkill.vocabulary))
          for (final Exercise e in l.allExercises) e.id: false,
      };
      final ReviewDeck deck = _deckWith(missed);
      final Lesson lesson = ReviewSessions.build(deck, _day1)!;
      expect(lesson.allExercises, hasLength(ReviewDeck.sessionSize));
      expect(ReviewSessions.isReview(lesson), isTrue);
      expect(lesson.skill, LessonSkill.vocabulary);
      expect(lesson.intro.explanation, isNotEmpty);
      expect(ReviewSessions.build(ReviewDeck(), _day1), isNull);
    });

    test('the deck survives a round-trip and ignores bad entries', () {
      final ReviewDeck deck = _deckWith(<String, bool>{'g-a1-be-1': false});
      final ReviewDeck again = ReviewDeck.fromJson(deck.toJson());
      expect(again.items['g-a1-be-1']!.dueAt, deck.items['g-a1-be-1']!.dueAt);
      expect(
        ReviewDeck.fromJson(<String, dynamic>{
          'items': <Object>[
            1,
            <String, int>{'x': 2},
          ],
        }).length,
        0,
      );
    });

    test('change summary for the results screen', () {
      expect(
        reviewChangeText(const ReviewChange(added: 2, promoted: 1)),
        '2 new exercises to review from tomorrow, 1 moved further away.',
      );
      expect(reviewChangeText(const ReviewChange(mastered: 1)), '1 mastered.');
    });
  });

  group('storage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ReviewService.key);
    });

    test('lesson results are saved in the deck', () async {
      final ReviewChange change = await ReviewService.recordLesson(
        <String, bool>{'v-a1-2': false, 'v-a1-3': true},
        now: _day0,
      );
      expect(change.added, 1);
      expect((await ReviewService.load()).items.keys, <String>['v-a1-2']);
    });
  });

  group('screens', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ReviewService.key);
    });

    testWidgets('library lists every level with the recommendation first', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: LessonLibraryScreen(
            skill: LessonSkill.grammar,
            loader: () async => LessonContext(
              profile: LearningProfile(currentLevel: 'A2'),
              assessment: null,
              sessions: const <LearningSession>[],
              memories: const [],
              progress: const Progress(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('Level A1'), findsOneWidget);
      expect(find.text('Level C1'), findsOneWidget);
      expect(find.text('Comparing things'), findsWidgets);
      expect(find.text('Mixed conditionals'), findsOneWidget);
    });

    testWidgets('Learn shows the review card when the deck has items', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      int opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: learning_hub.LearningScreen(
            profile: LearningProfile(name: 'Evan', currentLevel: 'B1'),
            recommendation: LearningRecommendation(
              activity: LessonResultService.activityFor(LessonSkill.grammar),
              title: 'Present perfect',
              reason: 'Test',
              targetLevel: 'B1',
              minutes: 8,
            ),
            completedSessions: 3,
            learningMinutes: 20,
            onStartRecommended: () {},
            onActivitySelected: (_) {},
            reviewDue: 3,
            reviewTotal: 5,
            onReview: () => opened++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Spaced review: 3 due'), findsOneWidget);
      await tester.tap(find.text('Spaced review: 3 due'));
      expect(opened, 1);
    });
  });
}
