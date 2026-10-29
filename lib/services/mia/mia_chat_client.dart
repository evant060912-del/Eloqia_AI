import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/learning_profile.dart';
import '../voice/voice_output_provider.dart' show MiaSpeechStyle;
import '../voice/voice_session_client.dart'
    show OidcAccessTokenProvider, VoiceSessionClient;

/// What the learner wants to do with Mia.
enum MiaChatMode {
  /// Free conversation.
  conversation('conversation', 'Talk', 'Chat freely about anything'),

  /// "Ask Mia Anything": questions about English.
  ask('ask', 'Ask Mia', 'Questions about grammar, words, usage'),

  /// Real-life role-play (airport, café, interview...).
  roleplay('roleplay', 'Role-play', 'Practise a real-life situation'),

  /// Writing coach that teaches instead of rewriting.
  writing('writing', 'Writing coach', 'Get feedback on a text');

  const MiaChatMode(this.apiValue, this.label, this.description);

  final String apiValue;
  final String label;
  final String description;
}

enum MiaScenario {
  airport('airport', 'At the airport', '✈️'),
  cafe('cafe', 'Café in San Francisco', '☕'),
  restaurant('restaurant', 'At the restaurant', '🍽️'),
  hotel('hotel', 'At the hotel', '🏨'),
  jobInterview('job_interview', 'Job interview', '💼'),
  universityInterview('university_interview', 'University interview', '🎓');

  const MiaScenario(this.apiValue, this.label, this.emoji);

  final String apiValue;
  final String label;
  final String emoji;
}

enum MiaWritingMode {
  learn('learn', 'Learn'),
  improve('improve', 'Improve'),
  exam('exam', 'Exam');

  const MiaWritingMode(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum MiaImmersion {
  soft('soft', 'Soft'),
  guided('guided', 'Guided'),
  total('total', 'Total');

  const MiaImmersion(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// One message of the conversation, kept on the device.
@immutable
class MiaChatTurn {
  const MiaChatTurn({required this.fromLearner, required this.text});

  final bool fromLearner;
  final String text;

  Map<String, String> toJson() => <String, String>{
    'role': fromLearner ? 'learner' : 'mia',
    'text': text.length > MiaChatClient.maxTurnChars
        ? text.substring(0, MiaChatClient.maxTurnChars)
        : text,
  };
}

@immutable
class MiaCorrection {
  const MiaCorrection({
    required this.original,
    required this.suggestion,
    required this.explanation,
    required this.category,
  });

  factory MiaCorrection.fromJson(Map<String, dynamic> json) => MiaCorrection(
    original: _string(json['original']),
    suggestion: _string(json['suggestion']),
    explanation: _string(json['explanation']),
    category: _string(json['category'], fallback: 'grammar'),
  );

  final String original;
  final String suggestion;
  final String explanation;
  final String category;
}

@immutable
class MiaSkillObservation {
  const MiaSkillObservation({required this.skill, required this.observation});

  factory MiaSkillObservation.fromJson(Map<String, dynamic> json) =>
      MiaSkillObservation(
        skill: _string(json['skill']),
        observation: _string(json['observation']),
      );

  final String skill;
  final String observation;
}

@immutable
class MiaWritingScore {
  const MiaWritingScore(this.criteria);

  /// Criterion -> score from 0 to 5.
  final Map<String, int> criteria;

  int get total => criteria.values.fold(0, (int a, int b) => a + b);

  int get maximum => criteria.length * 5;
}

/// Mia's answer for one turn.
@immutable
class MiaChatReply {
  const MiaChatReply({
    required this.reply,
    required this.tone,
    this.corrections = const <MiaCorrection>[],
    this.usefulExpressions = const <String>[],
    this.observations = const <MiaSkillObservation>[],
    this.writingScore,
    this.scenarioComplete = false,
    this.safetyRedirect = false,
  });

  factory MiaChatReply.fromJson(Map<String, dynamic> json) {
    final String reply = _string(json['reply']);
    if (reply.isEmpty) {
      throw const MiaChatException('invalid_reply');
    }

    MiaWritingScore? score;
    final Object? rawScore = json['writing_score'];
    if (rawScore is Map) {
      score = MiaWritingScore(<String, int>{
        for (final MapEntry<Object?, Object?> entry in rawScore.entries)
          if (entry.value is num)
            entry.key.toString(): (entry.value! as num).toInt().clamp(0, 5),
      });
    }

    return MiaChatReply(
      reply: reply,
      tone: _tone(json['tone']),
      corrections: _list(json['corrections'], MiaCorrection.fromJson),
      usefulExpressions: _strings(json['useful_expressions']),
      observations: _list(json['observations'], MiaSkillObservation.fromJson),
      writingScore: score,
      scenarioComplete: json['scenario_complete'] == true,
      safetyRedirect: json['safety_redirect'] == true,
    );
  }

  final String reply;
  final MiaSpeechStyle tone;
  final List<MiaCorrection> corrections;
  final List<String> usefulExpressions;
  final List<MiaSkillObservation> observations;
  final MiaWritingScore? writingScore;
  final bool scenarioComplete;
  final bool safetyRedirect;
}

/// One improvement point quoted from what the learner really wrote.
@immutable
class MiaEvidenceItem {
  const MiaEvidenceItem({
    required this.evidence,
    required this.suggestion,
    required this.explanation,
  });

  factory MiaEvidenceItem.fromJson(Map<String, dynamic> json) =>
      MiaEvidenceItem(
        evidence: _string(json['evidence']),
        suggestion: _string(json['suggestion']),
        explanation: _string(json['explanation']),
      );

  final String evidence;
  final String suggestion;
  final String explanation;
}

/// End-of-session review returned by `POST /v1/mia/chat/summary`.
@immutable
class MiaSessionSummary {
  const MiaSessionSummary({
    required this.summary,
    this.practiced = const <String>[],
    this.strengths = const <String>[],
    this.improvements = const <MiaEvidenceItem>[],
    this.usefulExpressions = const <String>[],
    this.nextStep = '',
  });

  factory MiaSessionSummary.fromJson(Map<String, dynamic> json) {
    final String summary = _string(json['summary']);
    if (summary.isEmpty) throw const MiaChatException('invalid_reply');
    return MiaSessionSummary(
      summary: summary,
      practiced: _strings(json['practiced']),
      strengths: _strings(json['strengths']),
      improvements: _list(json['improvements'], MiaEvidenceItem.fromJson),
      usefulExpressions: _strings(json['useful_expressions']),
      nextStep: _string(json['next_step']),
    );
  }

  final String summary;
  final List<String> practiced;
  final List<String> strengths;
  final List<MiaEvidenceItem> improvements;
  final List<String> usefulExpressions;
  final String nextStep;
}

class MiaChatException implements Exception {
  const MiaChatException(this.code);

  final String code;

  /// Message shown to the learner (French, like the rest of the errors).
  String get message => switch (code) {
    'not_configured' =>
      'Le cerveau de Mia n\'est pas configuré (adresse du serveur manquante).',
    'mia_chat_not_configured' =>
      'Le serveur n\'a pas de clé OpenAI : Mia ne peut pas encore répondre.',
    'mia_chat_rate_limited' =>
      'Tu as beaucoup discuté avec Mia ! Fais une petite pause puis réessaie.',
    'authentication_not_configured' ||
    'bearer_token_required' => 'Connexion requise pour discuter avec Mia.',
    'network' => 'Impossible de joindre le serveur de Mia.',
    'mia_summary_unavailable' =>
      'Le bilan de séance n\'a pas pu être préparé. Réessaie dans un instant.',
    _ => 'Mia ne peut pas répondre pour le moment. Réessaie dans un instant.',
  };

  @override
  String toString() => 'MiaChatException($code)';
}

/// Talks to the backend route `POST /v1/mia/chat`.
class MiaChatClient {
  MiaChatClient({
    required this.apiBaseUri,
    this.accessTokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  static const int maxTurnChars = 1200;
  static const int maxWritingChars = 4000;
  static const int maxHistoryTurns = 20;
  static const int maxSummaryTurns = 60;

  /// Uses `--dart-define=ELOQIA_API_URL=...`, or the voice URL already used
  /// for "Hear Mia" (`ELOQIA_VOICE_API_URL`). Returns null when unset.
  static MiaChatClient? fromEnvironment({
    OidcAccessTokenProvider? accessTokenProvider,
  }) {
    const String apiUrl = String.fromEnvironment('ELOQIA_API_URL');
    const String voiceUrl = String.fromEnvironment('ELOQIA_VOICE_API_URL');
    final String url = apiUrl.isNotEmpty ? apiUrl : voiceUrl;
    final Uri? uri = url.isEmpty ? null : Uri.tryParse(url);
    if (uri == null || !isAllowedApiUri(uri)) return null;
    return MiaChatClient(
      apiBaseUri: uri,
      accessTokenProvider: accessTokenProvider,
    );
  }

  final Uri apiBaseUri;
  final OidcAccessTokenProvider? accessTokenProvider;
  final http.Client _httpClient;

  /// HTTPS everywhere, plain HTTP only for local development.
  @visibleForTesting
  static bool isAllowedApiUri(Uri uri) {
    if (!uri.hasAuthority || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        const <String>{'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  Uri _endpoint(String path) {
    final String base = apiBaseUri.path.endsWith('/')
        ? apiBaseUri.path.substring(0, apiBaseUri.path.length - 1)
        : apiBaseUri.path;
    return apiBaseUri.replace(path: '$base$path');
  }

  Future<Map<String, String>> _headers() async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final OidcAccessTokenProvider? tokens = accessTokenProvider;
    if (tokens != null) {
      final String? token = await tokens();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Builds the JSON body. Public for tests.
  @visibleForTesting
  static Map<String, dynamic> buildRequest({
    required String message,
    required MiaChatMode mode,
    required Map<String, dynamic> context,
    List<MiaChatTurn> history = const <MiaChatTurn>[],
    MiaScenario? scenario,
    MiaWritingMode writingMode = MiaWritingMode.learn,
    MiaImmersion immersion = MiaImmersion.guided,
    List<String> knownDifficulties = const <String>[],
  }) {
    final int limit = mode == MiaChatMode.writing
        ? maxWritingChars
        : maxTurnChars;
    final String trimmed = message.trim();
    final List<MiaChatTurn> recent = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;

    return <String, dynamic>{
      'message': trimmed.length > limit ? trimmed.substring(0, limit) : trimmed,
      'mode': mode.apiValue,
      if (mode == MiaChatMode.roleplay && scenario != null)
        'scenario': scenario.apiValue,
      'writing_mode': writingMode.apiValue,
      'immersion': immersion.apiValue,
      'context': context,
      'history': recent
          .where((MiaChatTurn t) => t.text.trim().isNotEmpty)
          .map((MiaChatTurn t) => t.toJson())
          .toList(growable: false),
      'known_difficulties': knownDifficulties
          .map((String d) => d.trim())
          .where((String d) => d.isNotEmpty)
          .map((String d) => d.length > 120 ? d.substring(0, 120) : d)
          .toSet()
          .take(8)
          .toList(growable: false),
    };
  }

  Future<MiaChatReply> send({
    required String message,
    required MiaChatMode mode,
    required LearningProfile profile,
    List<MiaChatTurn> history = const <MiaChatTurn>[],
    MiaScenario? scenario,
    MiaWritingMode writingMode = MiaWritingMode.learn,
    MiaImmersion immersion = MiaImmersion.guided,
    List<String> knownDifficulties = const <String>[],
  }) async {
    final Map<String, dynamic> body = buildRequest(
      message: message,
      mode: mode,
      context: VoiceSessionClient.learningContextFor(profile),
      history: history,
      scenario: scenario,
      writingMode: writingMode,
      immersion: immersion,
      knownDifficulties: knownDifficulties,
    );

    final Object? decoded = await _post('/v1/mia/chat', body);

    if (decoded is! Map) throw const MiaChatException('invalid_reply');
    return MiaChatReply.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// Asks Mia for an end-of-session review (last [maxSummaryTurns] turns).
  Future<MiaSessionSummary> summarize({
    required List<MiaChatTurn> history,
    required MiaChatMode mode,
    required LearningProfile profile,
    MiaScenario? scenario,
  }) async {
    final List<MiaChatTurn> recent = history.length > maxSummaryTurns
        ? history.sublist(history.length - maxSummaryTurns)
        : history;
    final Object? decoded =
        await _post('/v1/mia/chat/summary', <String, dynamic>{
          'mode': mode.apiValue,
          if (mode == MiaChatMode.roleplay && scenario != null)
            'scenario': scenario.apiValue,
          'context': VoiceSessionClient.learningContextFor(profile),
          'history': recent
              .where((MiaChatTurn t) => t.text.trim().isNotEmpty)
              .map((MiaChatTurn t) => t.toJson())
              .toList(growable: false),
        });
    if (decoded is! Map) throw const MiaChatException('invalid_reply');
    return MiaSessionSummary.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<Object?> _post(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await _httpClient
          .post(
            _endpoint(path),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const MiaChatException('network');
    } on http.ClientException {
      throw const MiaChatException('network');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const MiaChatException('invalid_reply');
    }

    if (response.statusCode != 200) {
      String code = 'mia_chat_unavailable';
      if (decoded is Map && decoded['detail'] is Map) {
        final Object? raw = (decoded['detail'] as Map)['code'];
        if (raw is String && raw.isNotEmpty) code = raw;
      }
      throw MiaChatException(code);
    }
    return decoded;
  }

  void close() => _httpClient.close();
}

String _string(Object? value, {String fallback = ''}) {
  final String text = value is String ? value.trim() : '';
  return text.isEmpty ? fallback : text;
}

MiaSpeechStyle _tone(Object? value) {
  for (final MiaSpeechStyle style in MiaSpeechStyle.values) {
    if (style.name == value) return style;
  }
  return MiaSpeechStyle.warm;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((Object? e) => e is String ? e.trim() : '')
      .where((String e) => e.isNotEmpty)
      .toList(growable: false);
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return List<T>.empty();
  return raw
      .whereType<Map>()
      .map((Map item) => parse(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}
