import 'dart:convert';

import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/models/mia_voice_state.dart';
import 'package:eloqia_ai/services/voice/voice_session_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Mia voice states map to the LiveKit state contract', () {
    expect(MiaVoiceState.fromWireValue('listening'), MiaVoiceState.listening);
    expect(MiaVoiceState.fromWireValue('thinking'), MiaVoiceState.thinking);
    expect(MiaVoiceState.fromWireValue('speaking'), MiaVoiceState.speaking);
    expect(MiaVoiceState.fromWireValue('unknown'), isNull);
  });

  group('VoiceSessionClient', () {
    test(
      'reports secure conversation readiness without probing the network',
      () {
        final ConversationProvider missingBackend = VoiceSessionClient(
          apiBaseUri: null,
          accessTokenProvider: () async => 'token',
        );
        expect(missingBackend.isConfigured, isFalse);
        expect(
          missingBackend.configurationStatus,
          contains('CONFIGURATION REQUIRED'),
        );

        final ConversationProvider missingIdentity = VoiceSessionClient(
          apiBaseUri: Uri.parse('https://api.example'),
          accessTokenProvider: null,
        );
        expect(missingIdentity.isConfigured, isFalse);
        expect(missingIdentity.configurationStatus, contains('sign-in'));

        final ConversationProvider configured = VoiceSessionClient(
          apiBaseUri: Uri.parse('https://api.example'),
          accessTokenProvider: () async => 'token',
        );
        expect(configured.isConfigured, isTrue);
        expect(
          configured.configurationStatus,
          contains('verified when a session starts'),
        );
      },
    );

    test(
      'sends consent, OIDC bearer token and bounded learner context',
      () async {
        final MockClient client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/voice/sessions');
          expect(request.headers['Authorization'], 'Bearer oidc-access-token');

          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          final Map<String, dynamic> context =
              body['context'] as Map<String, dynamic>;

          expect(body['voice_consent'], isTrue);
          expect(context['learner_name'], 'Evan');
          expect(context['cefr_level'], 'B1');
          expect(context['primary_goal'], 'speaking');
          expect(context['interests'], ['music', 'technology']);
          expect(context.containsKey('oidc_subject'), isFalse);

          return http.Response(
            jsonEncode(<String, dynamic>{
              'session_id': 'session-123',
              'room_name': 'room-123',
              'livekit_url': 'wss://livekit.example',
              'participant_token': 'short-lived-room-token',
              'expires_in_seconds': 900,
            }),
            201,
          );
        });
        final VoiceSessionClient service = VoiceSessionClient(
          apiBaseUri: Uri.parse('https://api.example'),
          accessTokenProvider: () async => 'oidc-access-token',
          httpClient: client,
        );

        final VoiceSessionResponse response = await service.startSession(
          profile: LearningProfile(
            name: 'Evan',
            currentLevel: 'B1',
            primaryGoal: 'speaking',
            preferredCorrectionStyle: 'gentle',
            learningPace: 'adaptive',
            interests: ['music', 'technology', 'unexpected-value'],
          ),
          voiceConsent: true,
        );

        expect(response.sessionId, 'session-123');
        expect(response.participantToken, 'short-lived-room-token');
        expect(response.expiresInSeconds, 900);
        service.close();
      },
    );

    test('requires explicit voice consent before requesting a token', () async {
      bool tokenRequested = false;
      final VoiceSessionClient service = VoiceSessionClient(
        apiBaseUri: Uri.parse('https://api.example'),
        accessTokenProvider: () async {
          tokenRequested = true;
          return 'oidc-access-token';
        },
        httpClient: MockClient((_) async => http.Response('', 500)),
      );

      await expectLater(
        service.startSession(profile: LearningProfile(), voiceConsent: false),
        throwsA(
          isA<VoiceSessionException>().having(
            (VoiceSessionException error) => error.code,
            'code',
            'voice_consent_required',
          ),
        ),
      );

      expect(tokenRequested, isFalse);
      service.close();
    });

    test(
      'refuses to start when no OIDC token provider is configured',
      () async {
        bool requestSent = false;
        final VoiceSessionClient service = VoiceSessionClient(
          apiBaseUri: Uri.parse('https://api.example'),
          accessTokenProvider: null,
          httpClient: MockClient((_) async {
            requestSent = true;
            return http.Response('', 201);
          }),
        );

        await expectLater(
          service.startSession(profile: LearningProfile(), voiceConsent: true),
          throwsA(
            isA<VoiceSessionException>().having(
              (VoiceSessionException error) => error.code,
              'code',
              'authentication_not_configured',
            ),
          ),
        );

        expect(requestSent, isFalse);
        service.close();
      },
    );
  });
}
