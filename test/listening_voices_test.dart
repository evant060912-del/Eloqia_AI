import 'package:eloqia_ai/features/lessons/engine/lesson_engine.dart';
import 'package:eloqia_ai/features/lessons/lesson_launcher.dart';
import 'package:eloqia_ai/features/lessons/models/lesson_models.dart';
import 'package:eloqia_ai/features/lessons/ui/lesson_library_screen.dart';
import 'package:eloqia_ai/features/lessons/ui/listening_player.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/models/learning_session.dart';
import 'package:eloqia_ai/models/progress.dart';
import 'package:eloqia_ai/services/voice/listening_accents.dart';
import 'package:eloqia_ai/services/voice/listening_voices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

const List<Map<String, String>> _voices = <Map<String, String>>[
  <String, String>{'name': 'UK Female', 'locale': 'en-GB'},
  <String, String>{'name': 'UK Male', 'locale': 'en_GB'},
  <String, String>{'name': 'US English', 'locale': 'en-US'},
  <String, String>{'name': 'Amélie', 'locale': 'fr-FR'},
];

class _FakeTts extends FlutterTts {
  final List<String> log = <String>[];

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> get getVoices async => _voices;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    log.add('voice ${voice['name']}');
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    log.add('language $language');
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    log.add('say $text');
    return 1;
  }

  @override
  Future<dynamic> stop() async => 1;
}

class _FakeListening implements ListeningVoice {
  final List<String> lines = <String>[];

  @override
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  @override
  String get description => 'Fake voices.';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<Set<ListeningAccent>> accents() async => <ListeningAccent>{
    ListeningAccent.british,
  };

  @override
  Future<void> speakLine({
    required String speaker,
    required String text,
    ListeningAccent? accent,
    bool slow = false,
  }) async {
    lines.add('$speaker/${accent?.name}: $text');
  }

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('voices', () {
    test('device voices are parsed and cast per speaker', () {
      final VoiceCasting casting = VoiceCasting(DeviceVoice.parse(_voices));
      expect(casting.accents, <ListeningAccent>{
        ListeningAccent.american,
        ListeningAccent.british,
      });
      expect(
        casting.voiceFor('Tom', ListeningAccent.british)!.name,
        'UK Female',
      );
      expect(casting.voiceFor('Ana', ListeningAccent.british)!.name, 'UK Male');
      expect(
        casting.voiceFor('Tom', ListeningAccent.british)!.name,
        'UK Female',
      );
      // No Australian voice: another English voice nobody uses yet.
      expect(
        casting.voiceFor('Jo', ListeningAccent.australian)!.name,
        'US English',
      );
      expect(
        VoiceCasting(
          const <DeviceVoice>[],
        ).voiceFor('Jo', ListeningAccent.british),
        isNull,
      );
      expect(normaliseLocale('en_au'), 'en-AU');
      expect(DeviceVoice.parse('nope'), isEmpty);
    });

    test(
      'the device voice switches voices and falls back by language',
      () async {
        final _FakeTts tts = _FakeTts();
        final DeviceListeningVoice voice = DeviceListeningVoice(tts: tts);
        expect(await voice.isAvailable(), isTrue);
        await voice.speakLine(
          speaker: 'Barista',
          text: 'Hello!',
          accent: ListeningAccent.british,
        );
        await voice.speakLine(
          speaker: 'Local',
          text: 'No worries.',
          accent: ListeningAccent.australian,
        );
        expect(tts.log, <String>[
          'voice UK Female',
          'say Hello!',
          'voice UK Male',
          'say No worries.',
        ]);
        expect(DeviceVoice.parse(_voices)[1].toMap(), <String, String>{
          'name': 'UK Male',
          'locale': 'en_GB',
        });
      },
    );
  });

  group('content', () {
    test('dialogues cover the three accents and the new question types', () {
      final List<Lesson> listening = LessonCatalog.forSkill(
        LessonSkill.listening,
      );
      expect(listening.length, greaterThanOrEqualTo(12));
      expect(
        listening.expand((Lesson l) => l.accents).toSet(),
        ListeningAccent.values.toSet(),
      );
      final List<Exercise> exercises = listening
          .expand((Lesson l) => l.allExercises)
          .toList();
      expect(
        exercises.where((Exercise e) => e.prompt.startsWith('Who says it?')),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(
        exercises.where((Exercise e) => e.prompt.startsWith('Dictation')),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });
  });

  testWidgets('the player speaks each line with its accent', (
    WidgetTester tester,
  ) async {
    final _FakeListening fake = _FakeListening();
    ListeningVoices.provider = fake;
    final Lesson lesson = LessonCatalog.byId('listening-a1-cafe')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListeningPlayer(lines: lesson.audio, showTranscript: true),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Leo · American'), findsOneWidget);
    expect(find.text('Barista · British'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(fake.lines.first, 'Barista/british: Hello! What can I get you?');
    expect(fake.lines, hasLength(lesson.audio.length));
    expect(find.textContaining('Leo (American): '), findsWidgets);
  });

  testWidgets('the listening library filters by accent', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LessonLibraryScreen(
          skill: LessonSkill.listening,
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
    expect(find.text('Meeting Sam'), findsWidgets);
    await tester.tap(find.text('Australian'));
    await tester.pumpAndSettle();
    expect(find.text('Finding the station'), findsOneWidget);
    expect(find.text('Meeting Sam'), findsNothing);
  });
}
