import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/learning_profile.dart';

typedef OidcAccessTokenProvider = Future<String?> Function();

/// A safe, user-facing exception raised by the voice-session service.
class VoiceSessionException implements Exception {
  const VoiceSessionException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Validated response returned by the Eloqia voice backend.
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
    final dynamic rawSessionId = json['session_id'];
    final dynamic rawRoomName = json['room_name'];
    final dynamic rawLiveKitUrl = json['livekit_url'];
    final dynamic rawParticipantToken = json['participant_token'];

    if (rawSessionId is! String ||
        rawRoomName is! String ||
        rawLiveKitUrl is! String ||
        rawParticipantToken is! String ||
        expiry is! int ||
        rawSessionId.trim().isEmpty ||
        rawRoomName.trim().isEmpty ||
        rawParticipantToken.trim().isEmpty ||
        expiry <= 0) {
      throw const VoiceSessionException(
        code: 'invalid_voice_session_response',
        message: 'La réponse du service vocal est invalide.',
      );
    }

    final Uri? liveKitUri = Uri.tryParse(rawLiveKitUrl);

    if (liveKitUri == null ||
        liveKitUri.scheme != 'wss' ||
        !liveKitUri.hasAuthority ||
        liveKitUri.host.isEmpty ||
        liveKitUri.userInfo.isNotEmpty) {
      throw const VoiceSessionException(
        code: 'invalid_voice_session_response',
        message: 'L’adresse du service vocal est invalide.',
      );
    }

    return VoiceSessionResponse(
      sessionId: rawSessionId,
      roomName: rawRoomName,
      liveKitUrl: rawLiveKitUrl,
      participantToken: rawParticipantToken,
      expiresInSeconds: expiry,
    );
  }
}

/// Common interface for conversational session providers.
abstract interface class ConversationProvider {
  bool get isConfigured;

  String get configurationStatus;

  Future<VoiceSessionResponse> startSession({
    required LearningProfile profile,
    required bool voiceConsent,
  });

  void close();
}

/// Creates authenticated voice sessions through the Eloqia API.
///
/// The client never stores provider API keys.
/// LiveKit credentials are received only from the backend.
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

  static const Duration _requestTimeout = Duration(seconds: 20);

  final Uri? apiBaseUri;
  final OidcAccessTokenProvider? accessTokenProvider;

  http.Client? _httpClient;

  final bool _ownsHttpClient;

  bool _closed = false;

  @override
  bool get isConfigured {
    final Uri? uri = apiBaseUri;

    return !_closed &&
        uri != null &&
        _isAllowedApiUri(uri) &&
        accessTokenProvider != null;
  }

  @override
  String get configurationStatus {
    if (_closed) {
      return 'DISCONNECTED: the voice client has been closed.';
    }

    final Uri? uri = apiBaseUri;

    if (uri == null || !_isAllowedApiUri(uri)) {
      return 'CONFIGURATION REQUIRED: set the secure voice backend URL.';
    }

    if (accessTokenProvider == null) {
      return 'CONFIGURATION REQUIRED: secure account sign-in is not connected.';
    }

    return 'CONFIGURED: connection is verified when a session starts.';
  }

  // ---------------------------------------------------------------------------
  // Start session
  // ---------------------------------------------------------------------------

  @override
  Future<VoiceSessionResponse> startSession({
    required LearningProfile profile,
    required bool voiceConsent,
  }) async {
    if (_closed) {
      throw const VoiceSessionException(
        code: 'voice_client_closed',
        message: 'Le service vocal a été fermé. Redémarre la connexion.',
      );
    }

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

    final String? accessToken;

    try {
      accessToken = await tokenProvider().timeout(_requestTimeout);
    } on TimeoutException {
      throw const VoiceSessionException(
        code: 'authentication_timeout',
        message: 'La vérification du compte prend trop de temps.',
      );
    } on VoiceSessionException {
      rethrow;
    } on Object {
      throw const VoiceSessionException(
        code: 'authentication_failed',
        message: 'Impossible de vérifier ton compte pour le moment.',
      );
    }

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const VoiceSessionException(
        code: 'authentication_required',
        message: 'Connecte-toi avant de démarrer une session avec Mia.',
      );
    }

    final Uri endpoint = baseUri.resolve('/v1/voice/sessions');

    final http.Client client = _httpClient ??= http.Client();

    late final http.Response response;

    try {
      response = await client
          .post(
            endpoint,
            headers: <String, String>{
              'Authorization': 'Bearer ${accessToken.trim()}',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },

            // FastAPI expects LearningContext fields at the root.
            // Voice consent is enforced locally before making the request.
            body: jsonEncode(_learningContext(profile)),
          )
          .timeout(_requestTimeout);
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
    } on VoiceSessionException {
      rethrow;
    } on Object {
      throw const VoiceSessionException(
        code: 'voice_request_failed',
        message: 'Impossible de préparer la session vocale.',
      );
    }

    if (_closed) {
      throw const VoiceSessionException(
        code: 'voice_client_closed',
        message: 'Le service vocal a été fermé.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _readServerError(response);
    }

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException('Expected a JSON object.');
      }

      return VoiceSessionResponse.fromJson(Map<String, dynamic>.from(decoded));
    } on VoiceSessionException {
      rethrow;
    } on Object {
      throw const VoiceSessionException(
        code: 'invalid_voice_session_response',
        message: 'La réponse du service vocal est invalide.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HTTP lifecycle
  // ---------------------------------------------------------------------------

  @override
  void close() {
    if (_closed) {
      return;
    }

    _closed = true;

    if (_ownsHttpClient) {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  // ---------------------------------------------------------------------------
  // API URL validation
  // ---------------------------------------------------------------------------

  static bool _isAllowedApiUri(Uri uri) {
    if (!uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }

    if (uri.scheme == 'https') {
      return true;
    }

    return uri.scheme == 'http' &&
        const <String>{
          'localhost',
          '127.0.0.1',
          '10.0.2.2',
          '::1',
        }.contains(uri.host);
  }

  // ---------------------------------------------------------------------------
  // Learning context
  // ---------------------------------------------------------------------------

  /// Learning context shared with Mia's chat (same validated fields).
  static Map<String, dynamic> learningContextFor(LearningProfile profile) =>
      _learningContext(profile);

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

    final String name = profile.name.trim();
    final String level = profile.currentLevel.trim().toUpperCase();
    final String goal = profile.primaryGoal.trim();
    final String correction = profile.preferredCorrectionStyle.trim();
    final String pace = profile.learningPace.trim();

    final List<String> interests = profile.interests
        .where(allowedInterests.contains)
        .toSet()
        .take(8)
        .toList(growable: false);

    return <String, dynamic>{
      if (name.isNotEmpty) 'learner_name': name,
      'cefr_level': allowedLevels.contains(level) ? level : 'A1',
      if (allowedGoals.contains(goal)) 'primary_goal': goal,
      'correction_style': allowedCorrections.contains(correction)
          ? correction
          : 'balanced',
      'learning_pace': allowedPaces.contains(pace) ? pace : 'adaptive',
      'interests': interests,
    };
  }

  // ---------------------------------------------------------------------------
  // Server error handling
  // ---------------------------------------------------------------------------

  static VoiceSessionException _readServerError(http.Response response) {
    String? code;

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final dynamic detail = decoded['detail'];

        if (detail is Map && detail['code'] is String) {
          code = (detail['code'] as String).trim();
        }
      }
    } on Object {
      // Never expose raw server responses to the UI.
    }

    switch (response.statusCode) {
      case 401:
        return const VoiceSessionException(
          code: 'authentication_required',
          message: 'Ta session a expiré. Reconnecte-toi puis réessaie.',
        );

      case 403:
        return const VoiceSessionException(
          code: 'voice_access_forbidden',
          message: 'Tu n’as pas accès à ce service vocal.',
        );

      case 422:
        return const VoiceSessionException(
          code: 'invalid_voice_session_request',
          message: 'Les informations de la session vocale sont invalides.',
        );

      case 429:
        return const VoiceSessionException(
          code: 'voice_rate_limited',
          message:
              'Trop de demandes vocales. Attends un instant avant de réessayer.',
        );

      case 503:
        return const VoiceSessionException(
          code: 'voice_service_not_ready',
          message: 'Le service vocal attend encore sa configuration sécurisée.',
        );

      default:
        return VoiceSessionException(
          code: code ?? 'voice_session_failed',
          message: 'Mia ne peut pas démarrer cette session pour le moment.',
        );
    }
  }
}
