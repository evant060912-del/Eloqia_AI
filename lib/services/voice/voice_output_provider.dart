import 'dart:async';

import 'package:flutter/foundation.dart';

/// Emotional delivery requested for Mia's speech.
///
/// These styles are hints for the voice backend. The backend must translate
/// them into supported Cartesia parameters or appropriate text delivery.
enum MiaSpeechStyle {
  warm,
  excited,
  encouraging,
  playful,
  serious,
  calm,
}

/// Contract shared by Mia's voice output implementations.
abstract class VoiceProvider {
  ValueListenable<bool> get speaking;

  /// Describes the actual voice provider, not an assumed voice.
  String get description;

  Future<bool> isAvailable();

  Future<void> speak(
    String text, {
    MiaSpeechStyle style = MiaSpeechStyle.warm,
    bool otherSpeaker = false,
    double speedFactor = 1.0,
  });

  Future<void> stop();
}

typedef VoiceOutputProvider = VoiceProvider;

/// Generates and plays speech through the configured secure cloud service.
///
/// This provider intentionally does not use FlutterTts or another local
/// speech engine. It requires an implementation of [CloudSpeechTransport]
/// that requests audio from Eloqia's authenticated backend and plays it.
///
/// Cartesia credentials must remain on the backend.
class CartesiaVoiceOutputProvider implements VoiceProvider {
  CartesiaVoiceOutputProvider({
    required CloudSpeechTransport transport,
  }) : _transport = transport;

  final CloudSpeechTransport _transport;

  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);

  Future<void> _queue = Future<void>.value();

  int _generation = 0;
  bool _disposed = false;

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  String get description => 'Mia · Cartesia Sonic 3.6 · Cloud voice';

  @override
  Future<bool> isAvailable() async {
    if (_disposed) return false;

    try {
      return await _transport.isAvailable();
    } on Object {
      return false;
    }
  }

  /// Removes common Markdown formatting before speech synthesis.
  static String clean(String text) {
    return text
        .replaceAll(
          RegExp(r'```[\s\S]*?```'),
          ' ',
        )
        .replaceAll(
          RegExp(r'`([^`]*)`'),
          r'$1',
        )
        .replaceAll(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          r'$1',
        )
        .replaceAll(
          RegExp(r'https?://\S+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'[*_~#>]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final Future<void> next = _queue.then((_) => operation());

    // Keep the queue usable after an individual request fails.
    _queue = next.catchError((Object _) {});

    return next;
  }

  @override
  Future<void> speak(
    String text, {
    MiaSpeechStyle style = MiaSpeechStyle.warm,
    bool otherSpeaker = false,
    double speedFactor = 1.0,
  }) async {
    if (_disposed) return;

    final String spoken = clean(text);

    if (spoken.isEmpty) return;

    if (!speedFactor.isFinite ||
        speedFactor < 0.6 ||
        speedFactor > 2.0) {
      throw ArgumentError.value(
        speedFactor,
        'speedFactor',
        'Must be between 0.6 and 2.0.',
      );
    }

    final int requestGeneration = ++_generation;

    await _enqueue(() async {
      if (_disposed || requestGeneration != _generation) return;

      _speaking.value = true;

      try {
        await _transport.speak(
          spoken,
          style: style,
          otherSpeaker: otherSpeaker,
          speedFactor: speedFactor,
        );
      } finally {
        if (!_disposed && requestGeneration == _generation) {
          _speaking.value = false;
        }
      }
    });
  }

  @override
  Future<void> stop() async {
    ++_generation;

    if (_disposed) return;

    _speaking.value = false;

    // Stop immediately rather than waiting behind queued speech.
    try {
      await _transport.stop();
    } on Object {
      // Keep the UI responsive if the audio engine fails to stop.
    }
  }

  /// Releases provider resources.
  ///
  /// Call this when the owning voice service is permanently disposed.
  Future<void> disposeProvider() async {
    if (_disposed) return;

    await stop();

    _disposed = true;

    await _transport.dispose();

    _speaking.dispose();
  }
}

/// Adapter contract for Eloqia's authenticated backend and audio player.
///
/// Implementations must:
/// - obtain audio from Eloqia's backend;
/// - keep Cartesia credentials off the client;
/// - play the returned audio;
/// - stop active playback when [stop] is called;
/// - report backend or playback failures instead of switching to local TTS.
abstract class CloudSpeechTransport {
  Future<bool> isAvailable();

  Future<void> speak(
    String text, {
    required MiaSpeechStyle style,
    required bool otherSpeaker,
    required double speedFactor,
  });

  Future<void> stop();

  Future<void> dispose();
}

/// Central voice access point.
///
/// Configure this with the real backend transport during app initialization.
/// It deliberately starts unconfigured: it will not silently use a device
/// voice if the Cartesia transport has not been connected.
class MiaVoice {
  MiaVoice._();

  static VoiceProvider? _provider;

  static VoiceProvider get provider {
    final VoiceProvider? current = _provider;

    if (current == null) {
      throw StateError(
        'MiaVoice is not configured. '
        'Register CartesiaVoiceOutputProvider with an authenticated '
        'CloudSpeechTransport during application startup.',
      );
    }

    return current;
  }

  static set provider(VoiceProvider value) {
    _provider = value;
  }

  static bool get isConfigured => _provider != null;
}