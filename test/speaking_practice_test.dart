import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/exams/exam_formats.dart';
import 'package:eloqia_ai/features/exams/exam_progress.dart';
import 'package:eloqia_ai/features/exams/exam_score_store.dart';
import 'package:eloqia_ai/features/speaking/speaking_analysis.dart';
import 'package:eloqia_ai/features/speaking/speaking_session_screen.dart';
import 'package:eloqia_ai/features/speaking/speaking_tasks.dart';
import 'package:eloqia_ai/features/speaking/widgets/mic_button.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/voice/speech_input.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMic implements SpeechInput {
  final ValueNotifier<bool> _listening = ValueNotifier<bool>(false);
  void Function(String text, bool isFinal)? _onText;
  int starts = 0;

  @override
  ValueListenable<bool> get listening => _listening;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> start({
    required void Function(String text, bool isFinal) onText,
    Duration maxDuration = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    starts++;
    _onText = onText;
    _listening.value = true;
    onText('hello', false);
    return true;
  }

  @override
  Future<void> stop() async {
    _listening.value = false;
    _onText?.call('hello Mia', true);
  }

  @override
  Future<void> cancel() async => _listening.value = false;
}

void main() {
  group('analysis', () {
    test('words are compared in order, with numbers and contractions', () {
      expect(normaliseWords("I'm 3, OK?"), <String>['i', 'am', 'three', 'ok']);
      final RepeatScore exact = RepeatScore.compare(
        'The library closes at ten tonight.',
        'the library closes at 10 tonight',
      );
      expect(exact.correct, isTrue);
      final RepeatScore partial = RepeatScore.compare(
        'Please return the books to the front desk.',
        'please return books to the desk',
      );
      expect(partial.heard, 6);
      expect(partial.correct, isFalse);
      expect(
        partial.words
            .where((RepeatWord w) => !w.heard)
            .map((RepeatWord w) => w.word),
        <String>['the', 'front'],
      );
      expect(
        RepeatScore.compare('See you soon.', 'see you very soon').extra,
        1,
      );
    });

    test('fluency counts words, speed and hesitation words', () {
      final FluencyStats stats = FluencyStats.of(
        'um I think uh the park is nice',
        const Duration(seconds: 30),
      );
      expect(stats.words, 8);
      expect(stats.fillers, 2);
      expect(stats.wordsPerMinute, 16);
      expect(
        FluencyStats.of('Yes', const Duration(seconds: 2)).wordsPerMinute,
        isNull,
      );
    });
  });

  group('content and formats', () {
    test('sets follow the public formats', () {
      final List<SpeakingSet> repeat = SpeakingCatalog.setsFor(
        'toefl_listen_repeat',
      );
      expect(repeat, hasLength(2));
      for (final SpeakingSet s in repeat) {
        expect(s.items, hasLength(7));
      }
      for (final SpeakingSet s in SpeakingCatalog.setsFor('toefl_interview')) {
        expect(s.items, hasLength(4));
        expect(s.items.first.responseTime, const Duration(seconds: 45));
      }
      final List<SpeakingSet> ielts = SpeakingCatalog.setsFor('ielts_speaking');
      final List<SpeakingSet> part2 = ielts
          .where((SpeakingSet s) => s.kind == SpeakingKind.ieltsPart2)
          .toList();
      expect(part2, hasLength(4));
      expect(part2.first.items.single.prepTime, const Duration(minutes: 1));
      expect(part2.first.items.single.bullets, hasLength(4));
      expect(
        repeatWindow('Welcome to the main library.'),
        const Duration(seconds: 8),
      );
      final Set<String> ids = SpeakingCatalog.sets
          .map((SpeakingSet s) => s.id)
          .toSet();
      expect(ids, hasLength(SpeakingCatalog.sets.length));
    });

    test('speaking task types and advice', () {
      expect(ExamTaskType.toeflInterview.isSpeaking, isTrue);
      expect(ExamTaskType.toeflInterview.isWriting, isFalse);
      expect(ExamTaskType.ieltsSpeaking.scaleMax, 9);
      for (final String name in <String>[
        'sentence_repetition',
        'fluency_coherence',
        'relevance_development',
        'coherence',
      ]) {
        expect(examCriterionAdvice[name], isNotNull, reason: name);
      }
      final ExamAttempt attempt = ExamAttempt(
        id: 'lr',
        type: ExamTaskType.toeflListenRepeat,
        taskId: 'lr-library',
        title: 'Listen and Repeat',
        value: 5,
        scaleMax: 7,
        at: DateTime.utc(2026, 10, 30),
      );
      expect(attempt.display, '5/7');
      expect(attempt.criterionRatios.keys, <String>['sentence_repetition']);
    });
  });

  group('screens', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.delete(ExamScoreStore.key);
    });

    testWidgets('the mic button fills the text and hides when unavailable', (
      WidgetTester tester,
    ) async {
      SpeechInputs.provider = UnavailableSpeechInput();
      final List<String> heard = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicButton(onText: (String t, bool _) => heard.add(t)),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('mic-button')), findsNothing);

      final _FakeMic mic = _FakeMic();
      SpeechInputs.provider = mic;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicButton(
              key: const ValueKey<String>('second'),
              onText: (String t, bool _) => heard.add(t),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('mic-button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mic-button')));
      await tester.pump();
      expect(mic.starts, 1);
      expect(heard, <String>['hello', 'hello Mia']);
      SpeechInputs.provider = UnavailableSpeechInput();
    });

    testWidgets('Listen and Repeat can be answered by typing and is scored', (
      WidgetTester tester,
    ) async {
      SpeechInputs.provider = UnavailableSpeechInput();
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final SpeakingSet set = SpeakingCatalog.byId('lr-library')!;
      await tester.pumpWidget(
        MaterialApp(
          home: SpeakingSessionScreen(
            set: set,
            profile: LearningProfile(currentLevel: 'B1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('type your answers'), findsOneWidget);
      await tester.tap(find.text('Start'));
      await tester.pump();
      for (int i = 0; i < set.items.length; i++) {
        await tester.tap(find.text('Answer'));
        await tester.pump();
        await tester.enterText(find.byType(TextField), set.items[i].prompt);
        await tester.tap(find.text('I’ve finished'));
        await tester.pump();
        await tester.tap(
          find.text(i == set.items.length - 1 ? 'See results' : 'Next'),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('7 / 7'), findsOneWidget);
      expect((await ExamScoreStore.attempts()).single.value, 7);
    });
  });
}
