// StreamAudioSource is the just_audio API for playing in-memory audio.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'voice_output_provider.dart';
import 'voice_session_client.dart' show OidcAccessTokenProvider;

/// Plays audio bytes. Abstracted so tests do not need a real audio engine.
abstract interface class SpeechAudioPlayer {
  /// Plays [audio] and completes when playback ends or is stopped.
  Future<void> play(Uint8List audio, String mimeType);

  Future<void> stop();

  Future<void> dispose();
}

class _BytesAudioSource extends StreamAudioSource {
  _BytesAudioSource(this._bytes, this._mimeType);

  final Uint8List _bytes;
  final String _mimeType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final int from = start ?? 0;
    final int to = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream<List<int>>.value(_bytes.sublist(from, to)),
      contentType: _mimeType,
    );
  }
}

/// just_audio playback; works on web (data URL) and on mobile/desktop.
class JustAudioSpeechPlayer implements SpeechAudioPlayer {
  AudioPlayer? _player;

  @override
  Future<void> play(Uint8List audio, String mimeType) async {
    final AudioPlayer player = _player ??= AudioPlayer();
    await player.stop();
    await player.setAudioSource(_BytesAudioSource(audio, mimeType));
    // Completes once playback reaches the end or is stopped/paused.
    await player.play();
  }

  @override
  Future<void> stop() async => _player?.stop();

  @override
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}

class CloudSpeechException implements Exception {
  const CloudSpeechException(this.code);

  final String code;

  @override
  String toString() => 'CloudSpeechException($code)';
}

/// [CloudSpeechTransport] backed by Eloqia's `POST /v1/voice/speech`.
///
/// The backend holds the Cartesia key and returns WAV audio.
class BackendCloudSpeechTransport implements CloudSpeechTransport {
  BackendCloudSpeechTransport({
    required this.apiBaseUri,
    required this.accessTokenProvider,
    SpeechAudioPlayer? player,
    http.Client? httpClient,
  }) : _player = player ?? JustAudioSpeechPlayer(),
       _httpClient = httpClient ?? http.Client();

  /// Uses `--dart-define=ELOQIA_VOICE_API_URL=...`; returns null when unset.
  static BackendCloudSpeechTransport? fromEnvironment({
    required OidcAccessTokenProvider? accessTokenProvider,
  }) {
    const String url = String.fromEnvironment('ELOQIA_VOICE_API_URL');
    final Uri? uri = url.isEmpty ? null : Uri.tryParse(url);
    if (uri == null || !isAllowedApiUri(uri)) return null;
    return BackendCloudSpeechTransport(
      apiBaseUri: uri,
      accessTokenProvider: accessTokenProvider,
    );
  }

  final Uri apiBaseUri;

  /// Optional: the backend decides whether speech requires sign-in.
  final OidcAccessTokenProvider? accessTokenProvider;
  final SpeechAudioPlayer _player;
  final http.Client _httpClient;

  @visibleForTesting
  static bool isAllowedApiUri(Uri uri) {
    if (!uri.hasAuthority || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        const <String>{'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

  Future<Map<String, String>> _headers({required bool json}) async {
    final Map<String, String> headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
    };
    final OidcAccessTokenProvider? tokens = accessTokenProvider;
    if (tokens != null) {
      final String? token = await tokens();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final http.Response response = await _httpClient
          .get(
            apiBaseUri.resolve('/v1/voice/speech/status'),
            headers: await _headers(json: false),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final Object? body = jsonDecode(response.body);
      return body is Map && body['available'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> speak(
    String text, {
    required MiaSpeechStyle style,
    required bool otherSpeaker,
    required double speedFactor,
  }) async {
    final http.Response response = await _httpClient
        .post(
          apiBaseUri.resolve('/v1/voice/speech'),
          headers: await _headers(json: true),
          body: jsonEncode(<String, Object>{
            'text': text.length > 600 ? text.substring(0, 600) : text,
            'style': style.name,
            'other_speaker': otherSpeaker,
            'speed_factor': speedFactor,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      String code = 'speech_failed_${response.statusCode}';
      try {
        final Object? body = jsonDecode(response.body);
        if (body is Map && body['detail'] is Map) {
          code = '${(body['detail'] as Map)['code'] ?? code}';
        }
      } on Object {
        // Keep the status-based code.
      }
      throw CloudSpeechException(code);
    }

    await _player.play(response.bodyBytes, 'audio/wav');
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _httpClient.close();
  }
}
