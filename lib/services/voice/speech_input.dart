import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech recognition for the microphone: the learner speaks, reads the
/// recognised text, and only then sends it. Uses the free recogniser of the
/// device or browser (Chrome, Android, iOS); nothing is recorded or stored.
abstract class SpeechInput {
  ValueListenable<bool> get listening;

  Future<bool> isAvailable();

  /// Starts listening. [onText] receives the running transcript of this
  /// session and is called a last time with `isFinal: true`.
  Future<bool> start({
    required void Function(String text, bool isFinal) onText,
    Duration maxDuration = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 5),
  });

  /// Stops and delivers the final text.
  Future<void> stop();

  /// Stops without a final result.
  Future<void> cancel();
}

/// Entry point. Until [useDevice] is called (in `main.dart`) the microphone
/// is reported as unavailable, so tests and unsupported platforms degrade to
/// typing.
class SpeechInputs {
  SpeechInputs._();

  static SpeechInput provider = UnavailableSpeechInput();

  static void useDevice() => provider = DeviceSpeechInput();
}

class UnavailableSpeechInput implements SpeechInput {
  final ValueNotifier<bool> _listening = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get listening => _listening;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> start({
    required void Function(String text, bool isFinal) onText,
    Duration maxDuration = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 5),
  }) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

/// `speech_to_text`: the platform recogniser (Web Speech API in Chrome).
class DeviceSpeechInput implements SpeechInput {
  DeviceSpeechInput({SpeechToText? engine}) : _injected = engine;

  final SpeechToText? _injected;
  SpeechToText? _engine;
  Future<bool>? _ready;
  final ValueNotifier<bool> _listening = ValueNotifier<bool>(false);
  void Function(String text, bool isFinal)? _onText;
  String _last = '';
  bool _finalSent = true;

  SpeechToText get _speech => _engine ??= _injected ?? SpeechToText();

  @override
  ValueListenable<bool> get listening => _listening;

  Future<bool> _init() => _ready ??= () async {
    try {
      return await _speech.initialize(
        onStatus: _onStatus,
        onError: (SpeechRecognitionError error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _finish();
        },
      );
    } on Object catch (error) {
      debugPrint('Speech recognition unavailable: $error');
      return false;
    }
  }();

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _finish();
    }
  }

  /// Sends the final text once per session.
  void _finish() {
    _listening.value = false;
    if (_finalSent) return;
    _finalSent = true;
    _onText?.call(_last, true);
  }

  @override
  Future<bool> isAvailable() => _init();

  @override
  Future<bool> start({
    required void Function(String text, bool isFinal) onText,
    Duration maxDuration = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    if (!await _init()) return false;
    if (_listening.value) await cancel();
    _onText = onText;
    _last = '';
    _finalSent = false;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _last = result.recognizedWords;
          if (result.finalResult) {
            _finish();
          } else {
            onText(_last, false);
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: maxDuration,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          localeId: 'en_US',
        ),
      );
      _listening.value = true;
      return true;
    } on Object catch (error) {
      debugPrint('Speech recognition failed to start: $error');
      _finalSent = true;
      _listening.value = false;
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object {
      // Already stopped.
    }
    _finish();
  }

  @override
  Future<void> cancel() async {
    _finalSent = true;
    _listening.value = false;
    try {
      await _speech.cancel();
    } on Object {
      // Already stopped.
    }
  }
}
