import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/lessons/ui/lesson_runner_screen.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/learning/learning_progress_service.dart';
import 'package:eloqia_ai/services/voice/voice_output_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeVoice implements VoiceOutputProvider {
  @override
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
  final List<String> spoken = <String>[];
  bool available = true;

  @override
  String get description => 'Fake voice';

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(
    String text, {
    MiaSpeechStyle style = MiaSpeechStyle.warm,
    bool otherSpeaker = false,
    double speedFactor = 1.0,
  }) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

Future<void> _pump(WidgetTester tester, [int ms = 700]) async {
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _open(WidgetTester tester, Lesson lesson, {Size? size}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: LessonRunnerScreen(
        lesson: lesson,
        profile: LearningProfile(currentLevel: 'A1'),
        reason: 'Matched to your declared A1 level.',
      ),
    ),
  );
  await _pump(tester);
}

Future<void> _tap(WidgetTester tester, String text) async {
  final Finder finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder, warnIfMissed: false);
  await _pump(tester, 200);
}

void main() {
  late FakeVoice voice;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.clearEloqiaData();
    voice = FakeVoice();
    MiaVoice.provider = voice;
  });

  testWidgets('intro shows Mia, the reason and the lesson explanation', (
    WidgetTester tester,
  ) async {
    await _open(tester, LessonCatalog.byId('grammar-a1-be')!);

    expect(find.text('Am, is and are'), findsOneWidget);
    expect(find.text('WHY THIS LESSON'), findsOneWidget);
    expect(find.textContaining('declared A1'), findsOneWidget);
    expect(find.textContaining('I → am'), findsOneWidget);
    expect(find.text('START LESSON'), findsOneWidget);

    await _tap(tester, 'Hear Mia');
    expect(voice.spoken.single, contains('Let\'s work on the verb be'));
  });

  testWidgets(
    'wrong answer gives staged specific feedback, retry mutes the miss',
    (WidgetTester tester) async {
      await _open(tester, LessonCatalog.byId('grammar-a1-be')!);
      await _tap(tester, 'START LESSON');

      expect(find.text('I ___ a student.'), findsOneWidget);
      await _tap(tester, 'is');
      await _tap(tester, 'CHECK ANSWER');
      await _pump(tester, 1600);

      expect(find.text('Almost'), findsOneWidget);
      expect(find.textContaining('You answered "is"'), findsOneWidget);
      expect(
        find.textContaining('"is" goes with he, she and it'),
        findsOneWidget,
      );
      expect(find.text('RULE'), findsOneWidget);
      expect(find.text('HINT'), findsOneWidget);
      expect(find.text('MIA'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.text('SHOW ANSWER'), findsNothing);
      expect(find.text('Show answer'), findsOneWidget);

      await _tap(tester, 'TRY AGAIN');
      await _tap(tester, 'am');
      await _tap(tester, 'CHECK ANSWER');
      await _pump(tester, 1600);

      expect(find.text('Correct'), findsOneWidget);
      expect(find.textContaining('+1 XP'), findsWidgets);
      expect(find.text('CONTINUE'), findsOneWidget);
    },
  );

  testWidgets(
    'a full lesson across every exercise type completes and saves progress',
    (WidgetTester tester) async {
      await _open(tester, LessonCatalog.byId('grammar-a1-be')!);
      await _tap(tester, 'START LESSON');

      // multiple choice x2
      await _tap(tester, 'am');
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      await _tap(tester, 'are');
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      // fill in the blank
      await tester.enterText(find.byType(TextField), 'is');
      await tester.pump();
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      // ordering
      for (final String word in <String>['We', 'are', 'not', 'late']) {
        await _tap(tester, word);
      }
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      // true / false
      await _tap(tester, 'False');
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      // challenge (accuracy 100% unlocks it)
      expect(find.textContaining('CHALLENGE'), findsWidgets);
      await _tap(tester, 'are');
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      await tester.enterText(find.byType(TextField), 'Are');
      await tester.pump();
      await _tap(tester, 'CHECK ANSWER');
      await _tap(tester, 'CONTINUE');
      await _pump(tester, 1500);

      expect(find.text('Okay, that was seriously good.'), findsOneWidget);
      expect(find.textContaining('Saved to your progress'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Back to Learn'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Back to Learn'), findsOneWidget);

      final progress = await LearningProgressService.getProgress();
      expect(progress.xp, greaterThan(20));
      expect(progress.skills['grammar'], 100);
      expect(progress.statistics.completedLessons, 1);
    },
  );

  testWidgets('matching and ordering inputs work and report wrong pairs', (
    WidgetTester tester,
  ) async {
    final Lesson vocab = LessonCatalog.byId('vocab-a1-daily-life')!;
    await _open(tester, vocab);
    await _tap(tester, 'START LESSON');

    // Pair in a wrong way first.
    await _tap(tester, 'bakery');
    await _tap(tester, 'the room where you cook');
    await _tap(tester, 'breakfast');
    await _tap(tester, 'the first meal of the day');
    await _tap(tester, 'kitchen');
    await _tap(tester, 'a shop that sells bread');
    await _tap(tester, 'CHECK ANSWER');
    await _pump(tester, 1600);

    expect(find.text('Almost'), findsOneWidget);
    expect(
      find.textContaining('These pairs need another look'),
      findsOneWidget,
    );
  });

  testWidgets(
    'listening plays the dialogue and reveals the transcript after checking',
    (WidgetTester tester) async {
      final Lesson lesson = LessonCatalog.byId('listening-a1-meeting')!;
      await _open(tester, lesson);
      await _tap(tester, 'START LESSON');

      expect(find.text('LISTEN'), findsOneWidget);
      expect(find.textContaining('transcript appears after'), findsOneWidget);
      await _tap(tester, 'Play');
      expect(voice.spoken, hasLength(lesson.audio.length));
      expect(voice.spoken.first, contains('What\'s your name'));

      await _tap(tester, 'Texas');
      await _tap(tester, 'CHECK ANSWER');
      await _pump(tester, 1600);
      expect(find.textContaining('Sam: '), findsWidgets);
      expect(find.textContaining('Nice listening'), findsOneWidget);
    },
  );

  testWidgets(
    'listening falls back to the transcript when audio is unavailable',
    (WidgetTester tester) async {
      voice.available = false;
      await _open(tester, LessonCatalog.byId('listening-a1-meeting')!);
      await _tap(tester, 'START LESSON');

      expect(find.textContaining('Audio is not available'), findsOneWidget);
      expect(find.textContaining('Mia: '), findsWidgets);
    },
  );

  testWidgets('reading shows the passage and evidence-based feedback', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      LessonCatalog.byId('reading-a2-market')!,
      size: const Size(1100, 800),
    );
    await _tap(tester, 'START LESSON');

    expect(find.textContaining('Every Saturday morning'), findsOneWidget);
    await _tap(tester, 'A school lesson');
    await _tap(tester, 'CHECK ANSWER');
    await _pump(tester, 1600);
    expect(
      find.textContaining('Think about what both paragraphs'),
      findsWidgets,
    );
  });

  test('catalog selection is stable for a fresh learner', () {
    final LessonChoice choice = LessonEngine.recommend(
      profile: LearningProfile(currentLevel: 'B1'),
    );
    expect(choice.lesson.id, isNotEmpty);
  });
}
