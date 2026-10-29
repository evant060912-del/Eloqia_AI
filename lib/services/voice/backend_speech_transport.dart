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

  /// Server limit for one speech request (see backend SpeechRequest).
  static const int maxChunkChars = 600;

  /// Recently generated clips kept in memory so "replay" costs nothing.
  static const int maxCachedClips = 24;

  final Map<String, Uint8List> _cache = <String, Uint8List>{};
  bool? _available;
  DateTime? _availableCheckedAt;
  int _playToken = 0;

  @override
  Future<bool> isAvailable() async {
    final DateTime now = DateTime.now();
    final DateTime? checked = _availableCheckedAt;
    if (_available != null &&
        checked != null &&
        now.difference(checked) < const Duration(minutes: 1)) {
      return _available!;
    }
    bool available = false;
    try {
      final http.Response response = await _httpClient
          .get(
            apiBaseUri.resolve('/v1/voice/speech/status'),
            headers: await _headers(json: false),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Object? body = jsonDecode(response.body);
        available = body is Map && body['available'] == true;
      }
    } on Object {
      available = false;
    }
    _available = available;
    _availableCheckedAt = now;
    return available;
  }

  /// Splits long text at sentence boundaries into chunks the server accepts.
  @visibleForTesting
  static List<String> splitForSpeech(String text, {int limit = maxChunkChars}) {
    final String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return const <String>[];
    if (cleaned.length <= limit) return <String>[cleaned];

    final List<String> sentences = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    final List<String> chunks = <String>[];
    String current = '';
    for (final String sentence in sentences) {
      final List<String> pieces = <String>[];
      if (sentence.length > limit) {
        // Very long sentence: cut at the last space before the limit.
        String rest = sentence;
        while (rest.length > limit) {
          int cut = rest.lastIndexOf(' ', limit);
          if (cut <= 0) cut = limit;
          pieces.add(rest.substring(0, cut).trim());
          rest = rest.substring(cut).trim();
        }
        if (rest.isNotEmpty) pieces.add(rest);
      } else {
        pieces.add(sentence);
      }
      for (final String piece in pieces) {
        if (current.isEmpty) {
          current = piece;
        } else if (current.length + 1 + piece.length <= limit) {
          current = '$current $piece';
        } else {
          chunks.add(current);
          current = piece;
        }
      }
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  Future<Uint8List> _audioFor(
    String text,
    MiaSpeechStyle style,
    bool otherSpeaker,
    double speedFactor,
  ) async {
    final String key = '${style.name}|$otherSpeaker|$speedFactor|$text';
    final Uint8List? cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // Most recently used goes last.
      return cached;
    }

    final http.Response response = await _httpClient
        .post(
          apiBaseUri.resolve('/v1/voice/speech'),
          headers: await _headers(json: true),
          body: jsonEncode(<String, Object>{
            'text': text,
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

    _cache[key] = response.bodyBytes;
    while (_cache.length > maxCachedClips) {
      _cache.remove(_cache.keys.first);
    }
    return response.bodyBytes;
  }

  @override
  Future<void> speak(
    String text, {
    required MiaSpeechStyle style,
    required bool otherSpeaker,
    required double speedFactor,
  }) async {
    final int token = ++_playToken;
    final List<String> chunks = splitForSpeech(text);
    // Fetch the next chunk while the current one plays.
    Future<Uint8List>? next = chunks.isEmpty
        ? null
        : _audioFor(chunks.first, style, otherSpeaker, speedFactor);
    for (int i = 0; i < chunks.length; i++) {
      final Uint8List audio = await next!;
      if (token != _playToken) return; // Stopped or replaced.
      next = i + 1 < chunks.length
          ? _audioFor(chunks[i + 1], style, otherSpeaker, speedFactor)
          : null;
      // Avoid an unhandled error if playback stops before it is awaited.
      next?.ignore();
      await _player.play(audio, 'audio/wav');
      if (token != _playToken) return;
    }
  }

  @override
  Future<void> stop() {
    _playToken++;
    return _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _httpClient.close();
  }
}
