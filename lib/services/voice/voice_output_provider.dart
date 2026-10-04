import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum MiaSpeechStyle { warm, excited, encouraging, playful, serious, calm }

/// Text-to-speech seam. Providers must never hold secrets inside the client;
/// cloud voices belong behind the backend.
abstract class VoiceProvider {
  ValueListenable<bool> get speaking;

  /// Short, honest description of the voice that will actually be heard.
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

/// Uses the browser or operating system speech engine. Voice quality, accent
/// and availability depend on the device; it is not a studio-quality voice.
class DeviceVoiceOutputProvider implements VoiceProvider {
  FlutterTts? _tts;
  Future<bool>? _setup;
  String _voiceName = '';
  int _generation = 0;

  @override
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  @override
  String get description => _voiceName.isEmpty
      ? 'US English device voice unavailable'
      : '$_voiceName · US English · California-specific accent unverified';

  @visibleForTesting
  static Map<String, String>? selectUnitedStatesVoice(
    List<Map<String, String>> voices,
  ) {
    final List<Map<String, String>> candidates = voices.where((
      Map<String, String> voice,
    ) {
      return voice['locale']?.toLowerCase().replaceAll('_', '-') == 'en-us';
    }).toList();
    if (candidates.isEmpty) return null;

    int score(Map<String, String> voice) {
      final String name = voice['name']!.toLowerCase();
      return (name.contains('natural') || name.contains('neural') ? 100 : 0) +
          (name.contains('aria') ? 40 : 0) +
          (name.contains('jenny') ? 35 : 0) +
          (name.contains('zira') ? 32 : 0) +
          (name.contains('google us english') ? 30 : 0) +
          (name.contains('samantha') ? 20 : 0) +
          (name.contains('online') ? 10 : 0);
    }

    candidates.sort((Map<String, String> a, Map<String, String> b) {
      return score(b).compareTo(score(a));
    });
    return candidates.first;
  }

  @override
  Future<bool> isAvailable() => _setup ??= _initialise();

  Future<bool> _initialise() async {
    try {
      final FlutterTts tts = _tts ??= FlutterTts();
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage('en-US');
      await tts.setVolume(1.0);
      if (kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      final dynamic raw = await tts.getVoices;
      Map<String, String>? selectedVoice;
      if (raw is List) {
        final List<Map<String, String>> voices = <Map<String, String>>[
          for (final dynamic v in raw)
            if (v is Map && v['name'] is String && v['locale'] is String)
              <String, String>{
                'name': v['name'] as String,
                'locale': v['locale'] as String,
              },
        ];
        selectedVoice = selectUnitedStatesVoice(voices);
      }
      if (selectedVoice == null) return false;
      await tts.setVoice(selectedVoice);
      _voiceName = selectedVoice['name']!;
      return true;
    } on Object {
      return false;
    }
  }

  static String clean(String text) => text
      .replaceAll(
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
        '',
      )
      .replaceAll(RegExp(r'[*_`#>]'), '')
      .replaceAll(RegExp(r'_{3,}'), ' blank ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Future<void> speak(
    String text, {
    MiaSpeechStyle style = MiaSpeechStyle.warm,
    bool otherSpeaker = false,
    double speedFactor = 1.0,
  }) async {
    final String spoken = clean(text);
    if (spoken.isEmpty || !await isAvailable()) {
      return;
    }
    final FlutterTts tts = _tts!;
    final int generation = ++_generation;

    final double base = kIsWeb ? 1.0 : 0.5;
    final (double rate, double pitch) = switch (style) {
      MiaSpeechStyle.excited => (1.04, 1.02),
      MiaSpeechStyle.encouraging => (0.98, 1.0),
      MiaSpeechStyle.playful => (1.02, 1.01),
      MiaSpeechStyle.serious => (0.96, 0.98),
      MiaSpeechStyle.calm => (0.97, 1.0),
      MiaSpeechStyle.warm => (1.0, 1.0),
    };

    try {
      await tts.stop();
      await tts.setSpeechRate(base * rate * speedFactor);
      await tts.setPitch(otherSpeaker ? 0.92 : pitch);
      speaking.value = true;
      await tts
          .speak(spoken)
          .timeout(
            Duration(seconds: 20 + spoken.length ~/ 8),
            onTimeout: () => null,
          );
    } on Object {
      // Playback errors leave the app silent but usable.
    } finally {
      if (generation == _generation) {
        speaking.value = false;
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    speaking.value = false;
    try {
      await _tts?.stop();
    } on Object {
      // Nothing to stop when no engine exists.
    }
  }
}

/// App-wide access point so tests and future cloud voices can replace it.
class MiaVoice {
  MiaVoice._();

  static VoiceProvider provider = DeviceVoiceOutputProvider();
}
