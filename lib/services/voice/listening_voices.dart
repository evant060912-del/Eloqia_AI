import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'listening_accents.dart';
import 'voice_output_provider.dart';

/// Voices for listening practice (dialogues with several speakers and
/// accents). Mia's own voice stays [MiaVoice]; listening uses the free voices
/// installed on the device, so dialogues cost nothing to play.
abstract class ListeningVoice {
  ValueListenable<bool> get speaking;

  Future<bool> isAvailable();

  /// Accents with an installed voice (others fall back to a default English
  /// voice of the engine).
  Future<Set<ListeningAccent>> accents();

  /// Speaks one line; returns when it is finished (or stopped).
  Future<void> speakLine({
    required String speaker,
    required String text,
    ListeningAccent? accent,
    bool slow = false,
  });

  Future<void> stop();

  /// Says where the audio comes from, for the player.
  String get description;
}

/// Entry point used by the listening player.
class ListeningVoices {
  ListeningVoices._();

  static ListeningVoice? _provider;

  /// Falls back to Mia's voice (the behaviour before device voices), which
  /// also lets tests inject a fake through [MiaVoice.provider].
  static ListeningVoice get provider => _provider ?? MiaListeningVoice();

  static set provider(ListeningVoice value) => _provider = value;

  /// Free voices of the device (Chrome, Android, iOS, desktop).
  static void useDeviceVoices() => _provider = DeviceListeningVoice();
}

/// Listening through Mia's configured voice (no accents).
class MiaListeningVoice implements ListeningVoice {
  @override
  ValueListenable<bool> get speaking => MiaVoice.provider.speaking;

  @override
  String get description => MiaVoice.provider.description;

  @override
  Future<bool> isAvailable() => MiaVoice.provider.isAvailable();

  @override
  Future<Set<ListeningAccent>> accents() async => <ListeningAccent>{};

  @override
  Future<void> speakLine({
    required String speaker,
    required String text,
    ListeningAccent? accent,
    bool slow = false,
  }) => MiaVoice.provider.speak(
    text,
    otherSpeaker: speaker != 'Mia',
    speedFactor: slow ? 0.78 : 1.0,
  );

  @override
  Future<void> stop() => MiaVoice.provider.stop();
}

/// Text-to-speech voices installed on the device, through `flutter_tts`.
/// Each speaker keeps one voice; speakers who share an accent get different
/// voices when several are installed.
class DeviceListeningVoice implements ListeningVoice {
  DeviceListeningVoice({FlutterTts? tts}) : _injected = tts;

  final FlutterTts? _injected;
  FlutterTts? _tts;
  Future<VoiceCasting>? _casting;
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);
  int _generation = 0;

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  String get description =>
      'Voices installed on this device (free text-to-speech). Their quality '
      'and the accents available depend on the device.';

  FlutterTts get _engine => _tts ??= _injected ?? FlutterTts();

  Future<VoiceCasting> _load() => _casting ??= () async {
    try {
      await _engine.awaitSpeakCompletion(true);
      return VoiceCasting(DeviceVoice.parse(await _engine.getVoices));
    } on Object {
      return VoiceCasting(const <DeviceVoice>[]);
    }
  }();

  @override
  Future<bool> isAvailable() async => (await _load()).hasEnglish;

  @override
  Future<Set<ListeningAccent>> accents() async => (await _load()).accents;

  @override
  Future<void> speakLine({
    required String speaker,
    required String text,
    ListeningAccent? accent,
    bool slow = false,
  }) async {
    final int generation = ++_generation;
    final VoiceCasting casting = await _load();
    final ListeningAccent chosen = accent ?? ListeningAccent.american;
    final DeviceVoice? voice = casting.voiceFor(speaker, chosen);
    if (generation != _generation) return;
    try {
      if (voice != null) {
        await _engine.setVoice(voice.toMap());
      } else {
        await _engine.setLanguage(chosen.locale);
      }
      // flutter_tts rates: about 1.0 is normal on the web, 0.5 on mobile.
      final double normal = kIsWeb ? 1.0 : 0.5;
      await _engine.setSpeechRate(slow ? normal * 0.75 : normal);
      if (generation != _generation) return;
      _speaking.value = true;
      await _engine.speak(text);
    } on Object catch (error) {
      debugPrint('Listening voice failed: $error');
    } finally {
      if (generation == _generation) _speaking.value = false;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    _speaking.value = false;
    try {
      await _engine.stop();
    } on Object {
      // Nothing is playing.
    }
  }
}
