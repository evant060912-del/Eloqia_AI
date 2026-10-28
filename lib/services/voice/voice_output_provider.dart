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

/// Voice used while the Cartesia voice is not connected yet.
///
/// It stays silent and reports itself as unavailable, so "Hear Mia" buttons
/// are disabled instead of crashing the screen. It never pretends to be Mia's
/// cloud voice and never switches to a device voice.
class UnconfiguredVoiceProvider implements VoiceProvider {
  UnconfiguredVoiceProvider();

  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  String get description => 'Mia · Cartesia voice not connected yet';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(
    String text, {
    MiaSpeechStyle style = MiaSpeechStyle.warm,
    bool otherSpeaker = false,
    double speedFactor = 1.0,
  }) async {
    debugPrint(
      'MiaVoice: Cartesia voice not configured, skipped speech. '
      'Call MiaVoice.configure(...) at startup.',
    );
  }

  @override
  Future<void> stop() async {}
}

/// Central voice access point.
///
/// Until [configure] (or the [provider] setter) is called, Mia is silent but
/// the app keeps working. Reading [provider] never throws: an exception here
/// is thrown inside widget builds and shows Flutter's red error screen.
class MiaVoice {
  MiaVoice._();

  static final VoiceProvider _unconfigured = UnconfiguredVoiceProvider();

  static VoiceProvider? _provider;

  static VoiceProvider get provider => _provider ?? _unconfigured;

  static set provider(VoiceProvider value) {
    _provider = value;
  }

  static bool get isConfigured => _provider != null;

  /// Connects Mia's Cartesia voice through the Eloqia backend.
  static void configure(CloudSpeechTransport transport) {
    _provider = CartesiaVoiceOutputProvider(transport: transport);
  }
}
