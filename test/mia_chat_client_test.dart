import 'dart:convert';

import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/services/mia/mia_chat_client.dart';
import 'package:eloqia_ai/services/mia/mia_learning_notes.dart';
import 'package:eloqia_ai/services/voice/voice_output_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _answer() => <String, dynamic>{
  'reply': 'Nice! What did you do next?',
  'tone': 'encouraging',
  'corrections': <Map<String, String>>[
    <String, String>{
      'original': 'I goed home',
      'suggestion': 'I went home',
      'explanation': 'Go is irregular.',
      'category': 'grammar',
    },
  ],
  'useful_expressions': <String>['to head home'],
  'observations': <Map<String, String>>[
    <String, String>{'skill': 'grammar', 'observation': 'Irregular past.'},
  ],
  'writing_score': null,
  'scenario_complete': false,
  'safety_redirect': false,
};

void main() {
  test('only HTTPS or local HTTP API addresses are accepted', () {
    expect(
      MiaChatClient.isAllowedApiUri(Uri.parse('https://api.x.com')),
      isTrue,
    );
    expect(
      MiaChatClient.isAllowedApiUri(Uri.parse('http://localhost:8000')),
      isTrue,
    );
    expect(
      MiaChatClient.isAllowedApiUri(Uri.parse('http://evil.com')),
      isFalse,
    );
  });

  test(
    'request keeps the last 20 turns and the scenario only in role-play',
    () {
      final List<MiaChatTurn> history = List<MiaChatTurn>.generate(
        25,
        (int i) => MiaChatTurn(fromLearner: i.isEven, text: 'turn $i'),
      );

      final Map<String, dynamic> roleplay = MiaChatClient.buildRequest(
        message: '  Hello  ',
        mode: MiaChatMode.roleplay,
        context: const <String, dynamic>{'cefr_level': 'B1'},
        history: history,
        scenario: MiaScenario.airport,
      );
      expect(roleplay['message'], 'Hello');
      expect(roleplay['scenario'], 'airport');
      expect((roleplay['history'] as List).length, 20);
      expect((roleplay['history'] as List).first['text'], 'turn 5');

      final Map<String, dynamic> talk = MiaChatClient.buildRequest(
        message: 'Hi',
        mode: MiaChatMode.conversation,
        context: const <String, dynamic>{},
        scenario: MiaScenario.airport,
      );
      expect(talk.containsKey('scenario'), isFalse);
    },
  );

  test('long messages are cut except in writing mode', () {
    final String long = 'a' * 3000;
    expect(
      (MiaChatClient.buildRequest(
                message: long,
                mode: MiaChatMode.ask,
                context: const <String, dynamic>{},
              )['message']
              as String)
          .length,
      MiaChatClient.maxTurnChars,
    );
    expect(
      (MiaChatClient.buildRequest(
                message: long,
                mode: MiaChatMode.writing,
                context: const <String, dynamic>{},
              )['message']
              as String)
          .length,
      3000,
    );
  });

  test('send parses Mia reply, tone and corrections', () async {
    late Map<String, dynamic> sent;
    final MiaChatClient client = MiaChatClient(
      apiBaseUri: Uri.parse('http://localhost:8000'),
      accessTokenProvider: () async => 'token-123',
      httpClient: MockClient((http.Request request) async {
        expect(request.url.path, '/v1/mia/chat');
        expect(request.headers['Authorization'], 'Bearer token-123');
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(_answer()), 200);
      }),
    );

    final MiaChatReply reply = await client.send(
      message: 'Yesterday I goed home',
      mode: MiaChatMode.conversation,
      profile: LearningProfile(),
    );

    expect(sent['mode'], 'conversation');
    expect(sent['context'], isA<Map<String, dynamic>>());
    expect(reply.tone, MiaSpeechStyle.encouraging);
    expect(reply.corrections.single.suggestion, 'I went home');
    expect(reply.usefulExpressions, <String>['to head home']);
  });

  test('server errors become readable MiaChatException codes', () async {
    final MiaChatClient client = MiaChatClient(
      apiBaseUri: Uri.parse('http://localhost:8000'),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'detail': <String, String>{'code': 'mia_chat_rate_limited'},
          }),
          429,
        ),
      ),
    );

    await expectLater(
      client.send(
        message: 'Hi',
        mode: MiaChatMode.ask,
        profile: LearningProfile(),
      ),
      throwsA(
        isA<MiaChatException>().having(
          (MiaChatException e) => e.code,
          'code',
          'mia_chat_rate_limited',
        ),
      ),
    );
  });

  test('unknown tones fall back to warm and empty replies are rejected', () {
    final Map<String, dynamic> odd = _answer()..['tone'] = 'angry';
    expect(MiaChatReply.fromJson(odd).tone, MiaSpeechStyle.warm);
    expect(
      () => MiaChatReply.fromJson(_answer()..['reply'] = ''),
      throwsA(isA<MiaChatException>()),
    );
  });

  group('MiaLearningNotes', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test(
      'keeps short notes, counts repeats and forgets after 30 days',
      () async {
        DateTime now = DateTime(2026, 11, 1);
        final MiaLearningNotes notes = MiaLearningNotes(clock: () => now);
        final MiaChatReply reply = MiaChatReply.fromJson(_answer());

        await notes.rememberFrom(reply);
        await notes.rememberFrom(reply);
        final List<MiaLearningNote> saved = await notes.load();
        expect(saved.length, 2);
        expect(saved.every((MiaLearningNote n) => n.count == 2), isTrue);
        expect(await notes.difficultiesForMia(), hasLength(2));

        now = now.add(const Duration(days: 31));
        expect(await notes.load(), isEmpty);
      },
    );

    test('safety replies are never remembered and clear erases all', () async {
      final MiaLearningNotes notes = MiaLearningNotes();
      await notes.rememberFrom(
        MiaChatReply.fromJson(_answer()..['safety_redirect'] = true),
      );
      expect(await notes.load(), isEmpty);

      await notes.rememberFrom(MiaChatReply.fromJson(_answer()));
      await notes.clear();
      expect(await notes.load(), isEmpty);
    });
  });
}
