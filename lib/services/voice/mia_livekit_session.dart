import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import 'voice_session_client.dart';

enum MiaLiveKitState {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  disconnected,
  failed,
}

enum MiaVoiceState { idle, listening, thinking, speaking }

/// Manages Mia's realtime LiveKit connection and media state.
class MiaLiveKitSession extends ChangeNotifier {
  MiaLiveKitSession();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VoiceSessionResponse? _session;

  MiaLiveKitState _state = MiaLiveKitState.idle;
  MiaVoiceState _voiceState = MiaVoiceState.idle;

  RemoteParticipant? _mia;
  RemoteVideoTrack? _miaVideo;

  bool _microphoneEnabled = false;
  bool _disposed = false;
  bool _disconnecting = false;

  int _generation = 0;
  String? _errorMessage;

  // Public state

  MiaLiveKitState get state => _state;
  MiaVoiceState get miaVoiceState => _voiceState;

  Room? get room => _room;
  VoiceSessionResponse? get session => _session;

  RemoteParticipant? get miaParticipant => _mia;
  RemoteVideoTrack? get miaVideoTrack => _miaVideo;

  bool get microphoneEnabled => _microphoneEnabled;
  bool get isConnected => _state == MiaLiveKitState.connected;

  bool get isConnecting =>
      _state == MiaLiveKitState.connecting ||
      _state == MiaLiveKitState.reconnecting;

  bool get isSpeaking => _voiceState == MiaVoiceState.speaking;
  bool get isListening => _voiceState == MiaVoiceState.listening;
  bool get isThinking => _voiceState == MiaVoiceState.thinking;

  String? get errorMessage => _errorMessage;
  String? get sessionId => _session?.sessionId;
  String? get roomName => _session?.roomName;

  // Connection

  Future<void> connect(VoiceSessionResponse session) async {
    if (_disposed) {
      throw StateError('MiaLiveKitSession has been disposed.');
    }

    if (_room != null ||
        _state == MiaLiveKitState.connecting ||
        _state == MiaLiveKitState.reconnecting ||
        _state == MiaLiveKitState.disconnecting) {
      return;
    }

    final generation = ++_generation;
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );

    _session = session;
    _room = room;
    _errorMessage = null;
    _microphoneEnabled = false;
    _mia = null;
    _miaVideo = null;
    _voiceState = MiaVoiceState.idle;
    _disconnecting = false;

    _setState(MiaLiveKitState.connecting);

    final listener = _attachListeners(room);
    _listener = listener;

    try {
      await room.prepareConnection(
        session.liveKitUrl,
        session.participantToken,
      );

      if (!_isCurrent(room, generation)) {
        await _disposeRoomInstance(room, listener);
        return;
      }

      await room.connect(session.liveKitUrl, session.participantToken);

      if (!_isCurrent(room, generation)) {
        await _disposeRoomInstance(room, listener);
        return;
      }

      _setState(MiaLiveKitState.connected);
      _discoverMia(room);

      await _setMicrophoneForRoom(room, true);
    } catch (error) {
      if (!_isCurrent(room, generation)) {
        await _disposeRoomInstance(room, listener);
        return;
      }

      _errorMessage = _connectionError(error);
      _setState(MiaLiveKitState.failed);

      _room = null;
      _listener = null;
      _resetSession();

      await _disposeRoomInstance(room, listener);
      rethrow;
    }
  }

  bool _isCurrent(Room room, int generation) {
    return !_disposed &&
        !_disconnecting &&
        generation == _generation &&
        identical(_room, room);
  }

  bool _isCurrentRoom(Room room) {
    return !_disposed && !_disconnecting && identical(_room, room);
  }

  // LiveKit events

  EventsListener<RoomEvent> _attachListeners(Room room) {
    final listener = room.createListener();

    listener
      ..on<RoomConnectedEvent>((_) {
        if (!_isCurrentRoom(room)) return;

        _setState(MiaLiveKitState.connected);
        _discoverMia(room);
      })
      ..on<RoomReconnectingEvent>((_) {
        if (_isCurrentRoom(room)) {
          _setState(MiaLiveKitState.reconnecting);
        }
      })
      ..on<RoomResumingEvent>((_) {
        if (_isCurrentRoom(room)) {
          _setState(MiaLiveKitState.reconnecting);
        }
      })
      ..on<RoomReconnectedEvent>((_) {
        if (!_isCurrentRoom(room)) return;

        _setState(MiaLiveKitState.connected);
        _discoverMia(room);
      })
      ..on<RoomDisconnectedEvent>((_) {
        if (_isCurrentRoom(room)) {
          unawaited(_handleRoomDisconnected(room));
        }
      })
      ..on<ParticipantConnectedEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _handleParticipantConnected(event.participant);
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _handleParticipantDisconnected(event.participant);
      })
      ..on<TrackPublishedEvent>((event) {
        if (!_isCurrentRoom(room)) return;

        _handleTrackPublished(event.participant, event.publication);
      })
      ..on<TrackUnpublishedEvent>((event) {
        if (!_isCurrentRoom(room)) return;

        _handleTrackUnpublished(event.participant, event.publication);
      })
      ..on<TrackSubscribedEvent>((event) {
        if (!_isCurrentRoom(room)) return;

        _handleTrackSubscribed(event.participant, event.track);
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (!_isCurrentRoom(room)) return;

        _handleTrackUnsubscribed(event.participant, event.track);
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _handleActiveSpeakers(event.speakers);
      })
      ..on<DataReceivedEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _handleDataReceived(event);
      })
      ..on<ParticipantMetadataUpdatedEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _notifySafely();
      })
      ..on<ParticipantAttributesChanged>((event) {
        if (!_isCurrentRoom(room)) return;
        _notifySafely();
      })
      ..on<TrackSubscriptionExceptionEvent>((event) {
        if (!_isCurrentRoom(room)) return;
        _handleSubscriptionError(event);
      });

    return listener;
  }

  Future<void> _handleRoomDisconnected(Room room) async {
    if (!_isCurrentRoom(room)) return;

    ++_generation;

    final listener = _listener;

    _room = null;
    _listener = null;

    _resetSession();
    _setState(MiaLiveKitState.disconnected);

    await _disposeRoomInstance(room, listener, disconnectFirst: false);
  }

  // Mia participant and video

  void _handleParticipantConnected(RemoteParticipant participant) {
    if (!_isMia(participant)) return;

    _mia = participant;
    _discoverMiaVideo(participant);
    _notifySafely();
  }

  void _handleParticipantDisconnected(RemoteParticipant participant) {
    if (_mia?.identity != participant.identity) return;

    _mia = null;
    _miaVideo = null;
    _voiceState = MiaVoiceState.idle;

    _notifySafely();
  }

  void _handleTrackPublished(
    RemoteParticipant participant,
    RemoteTrackPublication publication,
  ) {
    if (!_isMia(participant)) return;

    final track = publication.track;

    if (track is RemoteVideoTrack) {
      _mia = participant;
      _miaVideo = track;
      _notifySafely();
    }
  }

  void _handleTrackSubscribed(RemoteParticipant participant, Track track) {
    if (!_isMia(participant)) return;

    _mia = participant;

    if (track is RemoteVideoTrack) {
      _miaVideo = track;
      _notifySafely();
    }
  }

  void _handleTrackUnsubscribed(RemoteParticipant participant, Track track) {
    if (!_isMia(participant)) return;

    if (track is RemoteVideoTrack && identical(_miaVideo, track)) {
      _miaVideo = null;
      _notifySafely();
    }
  }

  void _handleTrackUnpublished(
    RemoteParticipant participant,
    RemoteTrackPublication publication,
  ) {
    if (!_isMia(participant)) return;

    // Never clear the video because an unrelated track was unpublished.
    final track = publication.track;

    if (track is RemoteVideoTrack && identical(_miaVideo, track)) {
      _miaVideo = null;
      _notifySafely();
    }
  }

  void _discoverMia(Room room) {
    if (!_isCurrentRoom(room)) return;

    _mia = null;
    _miaVideo = null;

    for (final participant in room.remoteParticipants.values) {
      if (!_isMia(participant)) continue;

      _mia = participant;
      _discoverMiaVideo(participant);
      break;
    }

    _notifySafely();
  }

  void _discoverMiaVideo(RemoteParticipant participant) {
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;

      if (track != null) {
        _miaVideo = track;
        return;
      }
    }
  }

  bool _isMia(RemoteParticipant participant) {
    final identity = participant.identity.toLowerCase();
    final name = participant.name.toLowerCase();

    return identity == 'mia' ||
        identity.contains('mia') ||
        name == 'mia' ||
        name.contains('mia');
  }

  // Mia voice-state messages

  void _handleDataReceived(DataReceivedEvent event) {
    final participant = event.participant;

    if (participant == null || !_isMia(participant)) return;

    final List<int> data = event.data;

    if (data.isEmpty) return;

    try {
      final decoded = jsonDecode(utf8.decode(data));

      if (decoded is! Map<String, dynamic>) return;
      if (decoded['type'] != 'mia_voice_state') return;

      final value = decoded['state'];

      if (value is! String) return;

      switch (value.toLowerCase()) {
        case 'listening':
          _voiceState = MiaVoiceState.listening;
        case 'thinking':
          _voiceState = MiaVoiceState.thinking;
        case 'speaking':
          _voiceState = MiaVoiceState.speaking;
        default:
          _voiceState = MiaVoiceState.idle;
      }

      _notifySafely();
    } on Object {
      // Invalid messages must never terminate the LiveKit session.
    }
  }

  void _handleActiveSpeakers(List<Participant> speakers) {
    final mia = _mia;

    if (mia == null) return;

    // Explicit agent states take precedence over speaker activity.
    if (_voiceState == MiaVoiceState.thinking ||
        _voiceState == MiaVoiceState.listening) {
      return;
    }

    final isSpeaking = speakers.any(
      (participant) => participant.identity == mia.identity,
    );

    final nextState = isSpeaking ? MiaVoiceState.speaking : MiaVoiceState.idle;

    if (_voiceState != nextState) {
      _voiceState = nextState;
      _notifySafely();
    }
  }

  void _handleSubscriptionError(TrackSubscriptionExceptionEvent event) {
    final participant = event.participant;

    if (participant == null || !_isMia(participant)) return;

    _errorMessage = 'Mia could not load a realtime media track.';
    _notifySafely();
  }

  // Microphone

  Future<void> setMicrophoneEnabled(bool enabled) async {
    final room = _room;

    if (room == null) return;

    await _setMicrophoneForRoom(room, enabled);
  }

  Future<void> toggleMicrophone() {
    return setMicrophoneEnabled(!_microphoneEnabled);
  }

  Future<void> _setMicrophoneForRoom(Room room, bool enabled) async {
    if (!_isCurrentRoom(room) ||
        room.connectionState != ConnectionState.connected) {
      return;
    }

    final participant = room.localParticipant;

    if (participant == null) return;

    try {
      await participant.setMicrophoneEnabled(enabled);

      if (!_isCurrentRoom(room)) return;

      _microphoneEnabled = enabled;
      _errorMessage = null;
      _notifySafely();
    } catch (error) {
      if (!_isCurrentRoom(room)) return;

      _microphoneEnabled = false;
      _errorMessage = _microphoneError(error);
      _notifySafely();

      rethrow;
    }
  }

  // Disconnect and cleanup

  Future<void> disconnect() async {
    if (_disposed || _disconnecting) return;

    final room = _room;
    final listener = _listener;

    if (room == null && listener == null) {
      _resetSession();
      _setState(MiaLiveKitState.disconnected);
      return;
    }

    _disconnecting = true;
    ++_generation;

    _setState(MiaLiveKitState.disconnecting);

    _room = null;
    _listener = null;

    try {
      await _disposeRoomInstance(room, listener);
      _resetSession();
      _errorMessage = null;
    } finally {
      _disconnecting = false;

      if (!_disposed) {
        _setState(MiaLiveKitState.disconnected);
      }
    }
  }

  Future<void> _disposeRoomInstance(
    Room? room,
    EventsListener<RoomEvent>? listener, {
    bool disconnectFirst = true,
  }) async {
    if (listener != null) {
      try {
        await listener.dispose();
      } on Object {
        // Best-effort listener cleanup.
      }
    }

    if (room == null) return;

    if (disconnectFirst) {
      try {
        await room.disconnect();
      } on Object {
        // Continue releasing resources even if disconnect fails.
      }
    }

    try {
      await room.dispose();
    } on Object {
      // Best-effort final cleanup.
    }
  }

  void _resetSession() {
    _session = null;
    _mia = null;
    _miaVideo = null;
    _microphoneEnabled = false;
    _voiceState = MiaVoiceState.idle;
  }

  // State and errors

  void _setState(MiaLiveKitState next) {
    if (_disposed || _state == next) return;

    _state = next;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  String _connectionError(Object error) {
    if (error is ConnectException) {
      return 'Mia could not establish a secure realtime connection.';
    }

    return 'Mia could not start the realtime session.';
  }

  String _microphoneError(Object error) {
    if (error is TrackCreateException) {
      return 'Microphone access is unavailable on this device.';
    }

    if (error is TrackPublishException) {
      return 'Mia could not activate your microphone.';
    }

    return 'Microphone access could not be enabled.';
  }

  // Lifecycle

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _disconnecting = true;
    ++_generation;

    final room = _room;
    final listener = _listener;

    _room = null;
    _listener = null;

    unawaited(_disposeRoomInstance(room, listener));

    super.dispose();
  }
}
