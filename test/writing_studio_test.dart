import 'dart:convert';

import 'package:eloqia_ai/core/storage/local_storage.dart';
import 'package:eloqia_ai/features/writing/writing_catalog.dart';
import 'package:eloqia_ai/features/writing/writing_checks.dart';
import 'package:eloqia_ai/features/writing/writing_review_screen.dart';
import 'package:eloqia_ai/features/writing/writing_rewards.dart';
import 'package:eloqia_ai/features/writing/writing_store.dart';
import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/mia/mia_chat_client.dart';
import 'package:eloqia_ai/services/mia/writing_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _review() => <String, dynamic>{
  'overall': 'A clear, polite email. Two verb patterns need fixing.',
  'score_percent': 72,
  'criteria': <Map<String, dynamic>>[
    <String, dynamic>{
      'criterion': 'register',
      'label': 'Register',
      'score': 5,
      'weight': 3,
      'comment': 'Polite.',
    },
  ],
  'strengths': <String>['Clear greeting.'],
  'weaknesses': <String>['Verb patterns.'],
  'corrections': <Map<String, dynamic>>[
    <String, dynamic>{
      'original': 'I want come',
      'suggestion': 'I want to come',
      'category': 'grammar',
      'certainty': 'definite',
      'priority': 'essential',
      'explanation': '"want" is followed by "to".',
      'rule': 'want + to-infinitive',
      'example': 'I want to learn.',
      'next_step': 'Review verbs + to-infinitive.',
    },
    <String, dynamic>{
      'original': 'Hi',
      'suggestion': 'Hello',
      'category': 'register',
      'certainty': 'variation',
      'priority': 'optional',
      'explanation': 'Both are fine for a friend.',
      'rule': '',
      'example': '',
      'next_step': '',
    },
  ],
  'revision_plan': <String>['Fix the verb.'],
  'revised_version': 'Hi Alex, I want to come.',
  'next_activity': <String, String>{'skill': 'grammar', 'focus': 'infinitive'},
  'word_count': 4,
  'estimate_note': 'Practice estimate from Mia, not an official exam score.',
  'safety_redirect': false,
};

void main() {
  group('catalog', () {
    test('13 genres, each with a task at every level band', () {
      expect(WritingGenre.studio, hasLength(13));
      expect(WritingGenre.values, hasLength(18));
      for (final WritingGenre genre in WritingGenre.studio) {
        for (final WritingBand band in WritingBand.values) {
          expect(
            WritingCatalog.tasksFor(genre, band: band),
            isNotEmpty,
            reason: '${genre.label} has no ${band.label} task',
          );
        }
      }
    });

    test('task ids are unique and accepted by the server', () {
      final Set<String> ids = <String>{};
      for (final WritingTask task in WritingCatalog.tasks) {
        expect(ids.add(task.id), isTrue, reason: 'duplicate ${task.id}');
        expect(RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(task.id), isTrue);
        expect(task.prompt.length, lessThanOrEqualTo(1200));
        if (task.maxWords > 0) {
          expect(task.maxWords, greaterThan(task.minWords));
        }
        if (task.genre == WritingGenre.summary) {
          expect(task.sourceText, isNotNull);
        }
        expect(task.reviewSource?.length ?? 0, lessThanOrEqualTo(3000));
      }
    });

    test('learner level selects the band', () {
      expect(WritingBand.forLevel('a2'), WritingBand.foundation);
      expect(WritingBand.forLevel('B2'), WritingBand.intermediate);
      expect(WritingBand.forLevel('C1'), WritingBand.advanced);
      expect(WritingBand.forLevel(''), WritingBand.foundation);
    });
  });

  group('automatic checks', () {
    String kinds(String text) => mechanicalIssues(
      text,
    ).map((MechanicalIssue i) => '${i.kind.name}:${i.excerpt}').join(',');

    test('word count follows the server rule', () {
      expect(countWords("I'm here, well-known... 3 times!"), 5);
    });

    test('finds certain mechanical issues', () {
      expect(kinds("i think i'm ok"), 'lowercaseI:i,lowercaseI:i');
      expect(kinds('It was fun. then we left.'), 'sentenceStart:t');
      expect(kinds('I saw the the cat.'), 'repeatedWord:the the');
      expect(
        kinds('Hello ! How are you ?'),
        'spaceBeforePunctuation: !,spaceBeforePunctuation: ?',
      );
      expect(kinds('Two  spaces.'), 'extraSpaces:  ');
    });

    test('does not flag correct English', () {
      expect(kinds('Yes, i.e. fine. He said that that was fine.'), isEmpty);
      expect(kinds('Meet Mr. smith e.g. tomorrow. Wait... what?'), isEmpty);
      expect(
        kinds('Dear Ms Carter,\n\nThank you.\n\nBest wishes,\nSam'),
        isEmpty,
      );
      expect(kinds('It costs 3.5 or 1,000 euros.'), isEmpty);
    });

    test('length status against the target', () {
      expect(lengthStatus(0, 10, 20), LengthStatus.empty);
      expect(lengthStatus(5, 10, 20), LengthStatus.tooShort);
      expect(lengthStatus(15, 10, 20), LengthStatus.inRange);
      expect(lengthStatus(25, 10, 20), LengthStatus.tooLong);
      expect(lengthStatus(25, 10, 0), LengthStatus.inRange);
    });
  });

  group('review model', () {
    test('parses, keeps variations apart and round-trips', () {
      final WritingReview review = WritingReview.tryParse(_review())!;
      expect(review.scorePercent, 72);
      expect(review.corrections, hasLength(2));
      expect(review.corrections.first.certainty.isMistake, isTrue);
      expect(review.corrections.last.certainty, CorrectionCertainty.variation);
      expect(review.corrections.last.certainty.isMistake, isFalse);

      final WritingReview again = WritingReview.tryParse(
        jsonDecode(jsonEncode(review.toJson())),
      )!;
      expect(again.corrections.first.nextStep, 'Review verbs + to-infinitive.');
      expect(again.nextActivity!.skill, 'grammar');
    });

    test('rejects a review without an overall assessment', () {
      expect(WritingReview.tryParse(<String, dynamic>{'overall': ''}), isNull);
      expect(WritingReview.tryParse('nope'), isNull);
    });
  });

  group('client', () {
    test('sends the task, the text and the learner context', () async {
      late Map<String, dynamic> sent;
      final MiaChatClient client = MiaChatClient(
        apiBaseUri: Uri.parse('http://localhost:8000'),
        httpClient: MockClient((http.Request request) async {
          expect(request.url.path, '/v1/writing/review');
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_review()), 200);
        }),
      );
      final WritingTask task = WritingCatalog.byId('summary-bees')!;
      final WritingReview review = await client.reviewWriting(
        genre: task.genre.apiValue,
        taskId: task.id,
        taskTitle: task.title,
        prompt: task.prompt,
        minWords: task.minWords,
        maxWords: task.maxWords,
        text: '  Bees carry pollen.  ',
        profile: LearningProfile(currentLevel: 'B1'),
        sourceText: task.sourceText,
      );
      expect(sent['genre'], 'summary');
      expect(sent['task_id'], 'summary-bees');
      expect(sent['text'], 'Bees carry pollen.');
      expect(sent['source_text'], isNotEmpty);
      expect((sent['context'] as Map)['cefr_level'], 'B1');
      expect(review.overall, startsWith('A clear'));
    });

    test('server errors keep a readable message', () async {
      final MiaChatClient client = MiaChatClient(
        apiBaseUri: Uri.parse('http://localhost:8000'),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, dynamic>{
              'detail': <String, String>{'code': 'writing_review_unavailable'},
            }),
            502,
          ),
        ),
      );
      expect(
        () => client.reviewWriting(
          genre: 'free',
          taskId: 'free-my-week',
          taskTitle: 'My week',
          prompt: 'Write about your week.',
          minWords: 40,
          maxWords: 0,
          text: 'I went to the park.',
          profile: LearningProfile(),
        ),
        throwsA(
          isA<MiaChatException>().having(
            (MiaChatException e) => e.code,
            'code',
            'writing_review_unavailable',
          ),
        ),
      );
    });
  });

  group('storage and rewards', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('drafts are saved, listed and cleared', () async {
      await WritingStore.saveDraft('free-my-week', 'Monday I went out.');
      expect(
        (await WritingStore.draftFor('free-my-week'))!.text,
        'Monday I went out.',
      );
      expect(await WritingStore.drafts(), hasLength(1));
      await WritingStore.clearDraft('free-my-week');
      expect(await WritingStore.draftFor('free-my-week'), isNull);
    });

    test('history keeps the review and survives malformed entries', () async {
      await WritingStore.addToHistory(
        WritingHistoryEntry(
          id: 'w-1',
          taskId: 'free-my-week',
          genre: 'free',
          taskTitle: 'My week',
          text: 'Text',
          submittedAt: DateTime.utc(2026, 10, 30),
          review: WritingReview.tryParse(_review()),
          xpAwarded: 15,
        ),
      );
      final List<WritingHistoryEntry> history = await WritingStore.history();
      expect(history.single.review!.corrections, hasLength(2));
      expect(history.single.xpAwarded, 15);

      // LocalStorage keeps its SharedPreferences instance: write through it.
      await LocalStorage.saveString(
        WritingStore.historyKey,
        '{"version":1,"items":[42,{"id":1}]}',
      );
      expect(await WritingStore.history(), isEmpty);
    });

    test('XP once per task and day, only for a real text', () async {
      final WritingTask task = WritingCatalog.byId('free-my-week')!;
      final LearningProfile profile = LearningProfile(currentLevel: 'A2');
      expect(WritingRewards.counts(task, 'Too short.'), isFalse);

      final String text = List<String>.filled(30, 'word').join(' ');
      final first = await WritingRewards.record(
        task: task,
        text: text,
        profile: profile,
        duration: const Duration(minutes: 8),
      );
      expect(first.xpAwarded, greaterThan(0));
      final second = await WritingRewards.record(
        task: task,
        text: '$text again',
        profile: profile,
        duration: const Duration(minutes: 3),
      );
      expect(second.xpAwarded, 0);
    });
  });

  testWidgets('review screen shows numbered corrections and criteria', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const String text = 'Hi Alex, I want come to your party.';

    await tester.pumpWidget(
      MaterialApp(
        home: WritingReviewScreen(
          taskTitle: 'Invite a friend',
          genreLabel: 'Email',
          text: text,
          review: WritingReview.tryParse(_review()),
          issues: mechanicalIssues(text),
          submittedAt: DateTime.utc(2026, 10, 30),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mia’s review'), findsOneWidget);
    expect(find.text('Polite.'), findsOneWidget);
    expect(find.text('I want to come'), findsOneWidget);
    expect(find.text('Also correct'), findsOneWidget);
    expect(find.text('Revise my text'), findsOneWidget);
  });
}
