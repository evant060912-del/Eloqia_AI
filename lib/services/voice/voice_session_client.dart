import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/learning_profile.dart';

typedef OidcAccessTokenProvider = Future<String?> Function();

class VoiceSessionException implements Exception {
  const VoiceSessionException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

class VoiceSessionResponse {
  const VoiceSessionResponse({
    required this.sessionId,
    required this.roomName,
    required this.liveKitUrl,
    required this.participantToken,
    required this.expiresInSeconds,
  });

  final String sessionId;
  final String roomName;
  final String liveKitUrl;
  final String participantToken;
  final int expiresInSeconds;

  factory VoiceSessionResponse.fromJson(Map<String, dynamic> json) {
    final dynamic expiry = json['expires_in_seconds'];
    final String? sessionId = json['session_id'] as String?;
    final String? roomName = json['room_name'] as String?;
    final String? liveKitUrl = json['livekit_url'] as String?;
    final String? participantToken = json['participant_token'] as String?;

    if (sessionId == null ||
        roomName == null ||
        liveKitUrl == null ||
        participantToken == null ||
        expiry is! int ||
        sessionId.isEmpty ||
        roomName.isEmpty ||
        liveKitUrl.isEmpty ||
        participantToken.isEmpty) {
      throw const VoiceSessionException(
        code: 'invalid_voice_session_response',
        message: 'La réponse du service vocal est invalide.',
      );
    }

    return VoiceSessionResponse(
      sessionId: sessionId,
      roomName: roomName,
      liveKitUrl: liveKitUrl,
      participantToken: participantToken,
      expiresInSeconds: expiry,
    );
  }
}

abstract interface class ConversationProvider {
  bool get isConfigured;

  String get configurationStatus;

  Future<VoiceSessionResponse> startSession({
    required LearningProfile profile,
    required bool voiceConsent,
  });

  void close();
}

class VoiceSessionClient implements ConversationProvider {
  VoiceSessionClient({
    required this.apiBaseUri,
    required this.accessTokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient,
       _ownsHttpClient = httpClient == null;

  factory VoiceSessionClient.fromEnvironment({
    required OidcAccessTokenProvider? accessTokenProvider,
    http.Client? httpClient,
  }) {
    const String configuredUrl = String.fromEnvironment('ELOQIA_VOICE_API_URL');

    return VoiceSessionClient(
      apiBaseUri: configuredUrl.isEmpty ? null : Uri.tryParse(configuredUrl),
      accessTokenProvider: accessTokenProvider,
      httpClient: httpClient,
    );
  }

  final Uri? apiBaseUri;
  final OidcAccessTokenProvider? accessTokenProvider;
  http.Client? _httpClient;
  final bool _ownsHttpClient;

  @override
  bool get isConfigured =>
      apiBaseUri != null &&
      _isAllowedApiUri(apiBaseUri!) &&
      accessTokenProvider != null;

  @override
  String get configurationStatus {
    final Uri? baseUri = apiBaseUri;
    if (baseUri == null || !_isAllowedApiUri(baseUri)) {
      return 'CONFIGURATION REQUIRED: set the secure voice backend URL.';
    }
    if (accessTokenProvider == null) {
      return 'CONFIGURATION REQUIRED: secure account sign-in is not connected.';
    }
    return 'CONFIGURED: connection is verified when a session starts.';
  }

  @override
  Future<VoiceSessionResponse> startSession({
    required LearningProfile profile,
    required bool voiceConsent,
  }) async {
    if (!voiceConsent) {
      throw const VoiceSessionException(
        code: 'voice_consent_required',
        message: 'Ton accord est nécessaire pour activer le microphone.',
      );
    }

    final Uri? baseUri = apiBaseUri;
    if (baseUri == null || !_isAllowedApiUri(baseUri)) {
      throw const VoiceSessionException(
        code: 'voice_backend_not_configured',
        message: 'Le service vocal sécurisé n’est pas configuré.',
      );
    }

    final OidcAccessTokenProvider? tokenProvider = accessTokenProvider;
    if (tokenProvider == null) {
      throw const VoiceSessionException(
        code: 'authentication_not_configured',
        message: 'La connexion sécurisée du compte n’est pas configurée.',
      );
    }

    final String? accessToken = await tokenProvider();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const VoiceSessionException(
        code: 'authentication_required',
        message: 'Connecte-toi avant de démarrer une session avec Mia.',
      );
    }

    final Uri endpoint = baseUri.resolve('/v1/voice/sessions');
    final http.Client httpClient = _httpClient ??= http.Client();
    late final http.Response response;

    try {
      response = await httpClient
          .post(
            endpoint,
            headers: <String, String>{
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'voice_consent': true,
              'context': _learningContext(profile),
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const VoiceSessionException(
        code: 'voice_service_timeout',
        message: 'Mia met trop de temps à répondre. Réessaie dans un instant.',
      );
    } on http.ClientException {
      throw const VoiceSessionException(
        code: 'voice_service_unreachable',
        message: 'Le service vocal est momentanément inaccessible.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _readServerError(response);
    }

    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Expected a JSON object');
      }

      return VoiceSessionResponse.fromJson(Map<String, dynamic>.from(decoded));
    } on Object {
      throw const VoiceSessionException(
        code: 'invalid_voice_session_response',
        message: 'La réponse du service vocal est invalide.',
      );
    }
  }

  @override
  void close() {
    if (_ownsHttpClient && _httpClient != null) {
      _httpClient!.close();
      _httpClient = null;
    }
  }

  static bool _isAllowedApiUri(Uri uri) {
    if (!uri.hasAuthority || uri.host.isEmpty) {
      return false;
    }

    if (uri.scheme == 'https') {
      return true;
    }

    return uri.scheme == 'http' &&
        const <String>{'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  static Map<String, dynamic> _learningContext(LearningProfile profile) {
    const Set<String> allowedLevels = <String>{
      'A1',
      'A2',
      'B1',
      'B2',
      'C1',
      'C2',
    };
    const Set<String> allowedGoals = <String>{
      'speaking',
      'school',
      'travel',
      'fluency',
      'academic',
      'career',
      'culture',
    };
    const Set<String> allowedCorrections = <String>{
      'gentle',
      'balanced',
      'direct',
      'deep',
    };
    const Set<String> allowedPaces = <String>{
      'relaxed',
      'regular',
      'intensive',
      'adaptive',
    };
    const Set<String> allowedInterests = <String>{
      'technology',
      'music',
      'movies',
      'gaming',
      'science',
      'travel',
      'sports',
      'business',
      'history',
      'art',
      'psychology',
      'space',
    };

    final String level = profile.currentLevel.trim().toUpperCase();
    final String goal = profile.primaryGoal.trim();
    final String correction = profile.preferredCorrectionStyle.trim();
    final String pace = profile.learningPace.trim();

    return <String, dynamic>{
      if (profile.name.trim().isNotEmpty) 'learner_name': profile.name.trim(),
      'cefr_level': allowedLevels.contains(level) ? level : 'A1',
      if (allowedGoals.contains(goal)) 'primary_goal': goal,
      'correction_style': allowedCorrections.contains(correction)
          ? correction
          : 'balanced',
      'learning_pace': allowedPaces.contains(pace) ? pace : 'adaptive',
      'interests': profile.interests
          .where(allowedInterests.contains)
          .toSet()
          .take(8)
          .toList(growable: false),
    };
  }

  static VoiceSessionException _readServerError(http.Response response) {
    String? code;
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] is Map) {
        code = (decoded['detail'] as Map)['code'] as String?;
      }
    } on Object {
      code = null;
    }

    if (response.statusCode == 401) {
      return const VoiceSessionException(
        code: 'authentication_required',
        message: 'Ta session a expiré. Reconnecte-toi puis réessaie.',
      );
    }

    if (response.statusCode == 503) {
      return const VoiceSessionException(
        code: 'voice_service_not_ready',
        message: 'Le service vocal attend encore sa configuration sécurisée.',
      );
    }

    return VoiceSessionException(
      code: code ?? 'voice_session_failed',
      message: 'Mia ne peut pas démarrer cette session pour le moment.',
    );
  }
}
