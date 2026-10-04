enum MiaVoiceState {
  initializing,
  idle,
  listening,
  thinking,
  speaking;

  static const String liveKitTopic = 'mia.voice-state';

  static MiaVoiceState? fromWireValue(String value) {
    for (final MiaVoiceState state in values) {
      if (state.name == value) {
        return state;
      }
    }

    return null;
  }

  String get label => switch (this) {
    MiaVoiceState.initializing => 'CONNECTING',
    MiaVoiceState.idle => 'READY',
    MiaVoiceState.listening => 'LISTENING',
    MiaVoiceState.thinking => 'THINKING',
    MiaVoiceState.speaking => 'MIA SPEAKING',
  };

  String get message => switch (this) {
    MiaVoiceState.initializing => 'Mia is joining the room…',
    MiaVoiceState.idle => 'Mia is ready.',
    MiaVoiceState.listening => 'Mia is listening.',
    MiaVoiceState.thinking => 'Mia is thinking…',
    MiaVoiceState.speaking => 'Mia is speaking.',
  };
}
