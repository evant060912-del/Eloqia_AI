import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../services/voice/voice_output_provider.dart';
import '../../../../theme/app_colors.dart';
import '../mia_emotion_engine.dart';

enum MiaPresenceState {
  idle,
  listening,
  thinking,
  speaking,
  happy,
  encouraging,
  surprised,
  playful,
  correcting,
  celebrating,
  serious,
  empathetic;

  String get label => switch (this) {
    idle => 'READY',
    listening => 'LISTENING',
    thinking => 'THINKING',
    speaking => 'SPEAKING',
    happy => 'HAPPY',
    encouraging => 'ENCOURAGING',
    surprised => 'SURPRISED',
    playful => 'PLAYFUL',
    correcting => 'CORRECTING',
    celebrating => 'CELEBRATING',
    serious => 'FOCUSED',
    empathetic => 'WITH YOU',
  };

  Color get color => switch (this) {
    idle => AppColors.primary,
    listening => AppColors.electricBlue,
    thinking => AppColors.secondary,
    speaking => AppColors.primaryBright,
    happy => AppColors.success,
    encouraging => AppColors.primary,
    surprised => AppColors.warmth,
    playful => AppColors.writing,
    correcting => AppColors.secondary,
    celebrating => AppColors.xp,
    serious => AppColors.vocabulary,
    empathetic => AppColors.secondary,
  };

  static MiaPresenceState fromEmotion(MiaEmotion emotion) => switch (emotion) {
    MiaEmotion.curious => MiaPresenceState.surprised,
    MiaEmotion.warm => MiaPresenceState.happy,
    MiaEmotion.proud => MiaPresenceState.happy,
    MiaEmotion.excited => MiaPresenceState.celebrating,
    MiaEmotion.celebrating => MiaPresenceState.celebrating,
    MiaEmotion.gentleCorrection => MiaPresenceState.correcting,
    MiaEmotion.focused => MiaPresenceState.serious,
    MiaEmotion.playfulFrustration => MiaPresenceState.playful,
    MiaEmotion.empathetic => MiaPresenceState.empathetic,
    MiaEmotion.listening => MiaPresenceState.listening,
    MiaEmotion.thinking => MiaPresenceState.thinking,
    MiaEmotion.speaking => MiaPresenceState.speaking,
  };
}

/// Visual source for Mia. A live avatar (for example LiveAvatar over LiveKit)
/// can implement this without changing any screen.
abstract class AvatarProvider {
  bool get supportsLipSync;

  Widget build(BuildContext context, MiaPresenceState state, double size);
}

typedef MiaAvatarProvider = AvatarProvider;

/// Static portrait: it conveys state through light and motion around Mia, not
/// through facial animation, and it does not lip-sync.
class StaticMiaAvatarProvider implements AvatarProvider {
  const StaticMiaAvatarProvider();

  @override
  bool get supportsLipSync => false;

  @override
  Widget build(BuildContext context, MiaPresenceState state, double size) {
    return ClipOval(
      child: Image.asset(
        'assets/tutors/mia/mia.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.medium,
        cacheWidth: (size * 2).round(),
        errorBuilder: (BuildContext c, Object e, StackTrace? s) => Container(
          width: size,
          height: size,
          color: AppColors.surface,
          child: Icon(
            Icons.person_rounded,
            color: state.color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class MiaAvatar {
  MiaAvatar._();

  static AvatarProvider provider = const StaticMiaAvatarProvider();
}

/// Mia's reusable presence: one component for every screen she appears on.
class MiaPresence extends StatefulWidget {
  const MiaPresence({
    super.key,
    this.state = MiaPresenceState.idle,
    this.size = 96,
    this.showLabel = true,
    this.followVoice = true,
  });

  final MiaPresenceState state;
  final double size;
  final bool showLabel;

  /// Switches to speaking while the shared voice provider is speaking.
  final bool followVoice;

  @override
  State<MiaPresence> createState() => _MiaPresenceState();
}

class _MiaPresenceState extends State<MiaPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ValueListenable<bool> voice = MiaVoice.provider.speaking;
    return ValueListenableBuilder<bool>(
      valueListenable: voice,
      builder: (BuildContext context, bool speaking, Widget? child) {
        final MiaPresenceState state = widget.followVoice && speaking
            ? MiaPresenceState.speaking
            : widget.state;
        return Semantics(
          label: 'Mia, ${state.label.toLowerCase()}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _portrait(state),
              if (widget.showLabel) ...<Widget>[
                const SizedBox(height: 8),
                _stateChip(state),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _portrait(MiaPresenceState state) {
    final double size = widget.size;
    final Color color = state.color;
    final bool active =
        state == MiaPresenceState.speaking ||
        state == MiaPresenceState.listening ||
        state == MiaPresenceState.celebrating;

    return RepaintBoundary(
      child: SizedBox(
        width: size * 1.35,
        height: size * 1.35,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = _controller.value;
            final double breathe = 1 + math.sin(t * math.pi * 2) * 0.012;
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (active)
                  for (int i = 0; i < 2; i++)
                    _pulseRing(size, color, (t + i * 0.5) % 1),
                if (state == MiaPresenceState.thinking)
                  Transform.rotate(
                    angle: t * math.pi * 2,
                    child: _arc(size, color),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.85),
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: active ? 0.38 : 0.2),
                        blurRadius: active ? 34 : 22,
                        spreadRadius: active ? 4 : 0,
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: breathe,
                  child: MiaAvatar.provider.build(context, state, size),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pulseRing(double size, Color color, double phase) {
    final double scale = 1.0 + phase * 0.32;
    return Opacity(
      opacity: (1 - phase) * 0.5,
      child: Container(
        width: (size + 8) * scale,
        height: (size + 8) * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }

  Widget _arc(double size, Color color) {
    return SizedBox(
      width: size + 22,
      height: size + 22,
      child: CircularProgressIndicator(
        value: 0.25,
        strokeWidth: 2.5,
        color: color,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _stateChip(MiaPresenceState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: state.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          color: state.color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
