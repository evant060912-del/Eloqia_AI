import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../models/mia_voice_state.dart';
import '../../../services/voice/speech_provider.dart';
import '../../../services/voice/voice_session_client.dart';
import '../../../theme/app_colors.dart';

class MiaLiveSessionScreen extends StatefulWidget {
  const MiaLiveSessionScreen({super.key, required this.session});

  final VoiceSessionResponse session;

  @override
  State<MiaLiveSessionScreen> createState() => _MiaLiveSessionScreenState();
}

class _MiaLiveSessionScreenState extends State<MiaLiveSessionScreen> {
  final Room _room = Room();
  late final SpeechProvider _speechProvider = _LiveKitSpeechProvider(_room);

  late final EventsListener<RoomEvent> _roomListener;

  VideoTrack? _miaVideoTrack;
  MiaVoiceState _voiceState = MiaVoiceState.initializing;
  bool _isConnecting = true;
  bool _isEnding = false;
  bool _microphoneEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _roomListener = _room.createListener()
      ..on<TrackSubscribedEvent>(_onTrackSubscribed)
      ..on<TrackUnsubscribedEvent>(_onTrackUnsubscribed)
      ..on<TrackUnpublishedEvent>(_onTrackUnpublished)
      ..on<ParticipantDisconnectedEvent>(_onParticipantDisconnected)
      ..on<DataReceivedEvent>(_onDataReceived)
      ..on<RoomDisconnectedEvent>(_onRoomDisconnected);

    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      await _room
          .connect(widget.session.liveKitUrl, widget.session.participantToken)
          .timeout(const Duration(seconds: 25));

      final LocalParticipant? participant = _room.localParticipant;
      if (participant == null) {
        throw StateError('LiveKit did not create a local participant.');
      }

      await _speechProvider.setListening(true);
      _refreshMiaVideoTrack();

      if (!mounted) {
        return;
      }

      setState(() {
        _isConnecting = false;
        _microphoneEnabled = true;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConnecting = false;
        _errorMessage =
            'Connexion impossible. Vérifie le réseau et les permissions du microphone.';
      });

      await _room.disconnect();
    }
  }

  void _onTrackSubscribed(TrackSubscribedEvent event) {
    final Track track = event.track;
    if (track is VideoTrack) {
      _refreshMiaVideoTrack();
    }
  }

  void _onTrackUnsubscribed(TrackUnsubscribedEvent event) {
    if (identical(event.track, _miaVideoTrack)) {
      _refreshMiaVideoTrack();
    }
  }

  void _onTrackUnpublished(TrackUnpublishedEvent event) {
    if (identical(event.publication.track, _miaVideoTrack)) {
      _refreshMiaVideoTrack();
    }
  }

  void _onParticipantDisconnected(ParticipantDisconnectedEvent event) {
    _refreshMiaVideoTrack();
  }

  void _onDataReceived(DataReceivedEvent event) {
    if (event.topic != MiaVoiceState.liveKitTopic || event.data.length > 256) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(event.data));
      if (decoded is! Map ||
          decoded['type'] != 'mia_voice_state' ||
          decoded['state'] is! String) {
        return;
      }

      final MiaVoiceState? state = MiaVoiceState.fromWireValue(
        decoded['state'] as String,
      );
      if (state == null || !mounted) {
        return;
      }

      setState(() {
        _voiceState = state;
      });
    } on Object {
      return;
    }
  }

  void _onRoomDisconnected(RoomDisconnectedEvent event) {
    if (!mounted || _isEnding || _errorMessage != null) {
      return;
    }

    setState(() {
      _isConnecting = false;
      _microphoneEnabled = false;
      _errorMessage = 'La session avec Mia est terminée.';
    });
  }

  void _refreshMiaVideoTrack() {
    VideoTrack? nextTrack;

    for (final RemoteParticipant participant
        in _room.remoteParticipants.values) {
      if (participant.name.trim().toLowerCase() != 'mia') {
        continue;
      }
      for (final RemoteTrackPublication<RemoteVideoTrack> publication
          in participant.videoTrackPublications) {
        final RemoteVideoTrack? track = publication.track;
        if (publication.subscribed && track != null) {
          nextTrack = track;
          break;
        }
      }

      if (nextTrack != null) {
        break;
      }
    }

    _setMiaVideoTrack(nextTrack);
  }

  void _setMiaVideoTrack(VideoTrack? track) {
    if (!mounted || identical(_miaVideoTrack, track)) {
      return;
    }

    setState(() {
      _miaVideoTrack = track;
    });
  }

  Future<void> _toggleMicrophone() async {
    final LocalParticipant? participant = _room.localParticipant;
    if (participant == null || _isEnding) {
      return;
    }

    final bool nextEnabled = !_microphoneEnabled;
    try {
      await _speechProvider.setListening(nextEnabled);
      if (!mounted) {
        return;
      }

      setState(() {
        _microphoneEnabled = nextEnabled;
      });
    } on Object {
      _showMessage('Impossible de modifier le microphone.');
    }
  }

  Future<void> _endSession() async {
    if (_isEnding) {
      return;
    }

    setState(() {
      _isEnding = true;
    });

    try {
      await _room.disconnect();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }

  @override
  void dispose() {
    _roomListener.dispose();
    unawaited(_room.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_endSession());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                Expanded(child: _buildAvatarStage()),
                const SizedBox(height: 14),
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.graphic_eq_rounded,
          color: AppColors.primaryBright,
          size: 20,
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'MIA · LIVE SESSION',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    final bool connected = !_isConnecting && _errorMessage == null;
    final bool ended = !connected && !_isConnecting;
    final Color color = connected ? AppColors.success : AppColors.warmth;
    final String label = _isConnecting
        ? MiaVoiceState.initializing.label
        : ended
        ? 'ENDED'
        : !_microphoneEnabled
        ? 'MIC MUTED'
        : _voiceState.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStage() {
    final VideoTrack? videoTrack = _miaVideoTrack;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoTrack != null)
            VideoTrackRenderer(videoTrack, fit: VideoViewFit.cover)
          else
            Image.asset(
              'assets/tutors/mia/mia.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: AppColors.backgroundElevated,
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 72,
                    ),
                  ),
                );
              },
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33060912),
                  Colors.transparent,
                  Color(0xCC060912),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage ?? _voiceState.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (_errorMessage == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _microphoneEnabled
                        ? 'Your microphone is on'
                        : 'Your microphone is muted',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final bool canToggleMicrophone =
        !_isConnecting && _errorMessage == null && !_isEnding;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canToggleMicrophone ? _toggleMicrophone : null,
            icon: Icon(
              _microphoneEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              size: 18,
            ),
            label: Text(_microphoneEnabled ? 'Mute' : 'Unmute'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isEnding ? null : _endSession,
            icon: const Icon(Icons.call_end_rounded, size: 18),
            label: const Text('End session'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveKitSpeechProvider implements SpeechProvider {
  const _LiveKitSpeechProvider(this.room);

  final Room room;

  @override
  Future<void> setListening(bool listening) async {
    final LocalParticipant? participant = room.localParticipant;
    if (participant == null) {
      throw StateError('LiveKit has no local participant.');
    }
    await participant.setMicrophoneEnabled(listening);
  }
}
