import 'dart:convert';

import 'package:eloqia_ai/services/voice/backend_speech_transport.dart';
import 'package:eloqia_ai/services/voice/voice_output_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakePlayer implements SpeechAudioPlayer {
  final List<Uint8List> played = <Uint8List>[];

  @override
  Future<void> play(Uint8List audio, String mimeType) async =>
      played.add(audio);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  test('an unconfigured MiaVoice never throws (no red screen)', () async {
    expect(() => MiaVoice.provider, returnsNormally);
    expect(MiaVoice.provider.speaking.value, isFalse);
    expect(await MiaVoice.provider.isAvailable(), isFalse);
    await MiaVoice.provider.speak('Hello');
    await MiaVoice.provider.stop();
  });

  test('plays the Cartesia audio returned by the backend', () async {
    late http.Request sent;
    final _FakePlayer player = _FakePlayer();
    final BackendCloudSpeechTransport transport = BackendCloudSpeechTransport(
      apiBaseUri: Uri.parse('http://localhost:8000'),
      accessTokenProvider: () async => 'token',
      player: player,
      httpClient: MockClient((http.Request request) async {
        sent = request;
        return http.Response.bytes(<int>[82, 73, 70, 70], 200);
      }),
    );

    await transport.speak(
      'Hi there',
      style: MiaSpeechStyle.excited,
      otherSpeaker: false,
      speedFactor: 1.0,
    );

    expect(sent.url.path, '/v1/voice/speech');
    expect(sent.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(sent.body)['style'], 'excited');
    expect(player.played.single, <int>[82, 73, 70, 70]);
  });

  test('reports the backend error code instead of failing silently', () {
    final BackendCloudSpeechTransport transport = BackendCloudSpeechTransport(
      apiBaseUri: Uri.parse('http://localhost:8000'),
      accessTokenProvider: null,
      player: _FakePlayer(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object>{
            'detail': <String, String>{'code': 'speech_not_configured'},
          }),
          503,
        ),
      ),
    );

    expect(
      transport.speak(
        'Hi',
        style: MiaSpeechStyle.warm,
        otherSpeaker: false,
        speedFactor: 1.0,
      ),
      throwsA(
        isA<CloudSpeechException>().having(
          (CloudSpeechException e) => e.code,
          'code',
          'speech_not_configured',
        ),
      ),
    );
  });

  test('availability follows the backend status endpoint', () async {
    final BackendCloudSpeechTransport transport = BackendCloudSpeechTransport(
      apiBaseUri: Uri.parse('http://localhost:8000'),
      accessTokenProvider: null,
      player: _FakePlayer(),
      httpClient: MockClient(
        (_) async => http.Response('{"available": true}', 200),
      ),
    );

    expect(await transport.isAvailable(), isTrue);
  });

  test('refuses plain http outside local development', () {
    expect(
      BackendCloudSpeechTransport.isAllowedApiUri(Uri.parse('http://x.com')),
      isFalse,
    );
    expect(
      BackendCloudSpeechTransport.isAllowedApiUri(
        Uri.parse('https://api.eloqia.app'),
      ),
      isTrue,
    );
  });
}
