import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/voice/speech_input.dart';
import '../../../theme/app_colors.dart';

/// Tap to speak, tap again to stop. Hidden when the device or browser has no
/// speech recognition, so typing always remains possible.
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.onText,
    this.enabled = true,
    this.maxDuration = const Duration(minutes: 2),
    this.size = 48,
  });

  /// Running transcript of the current recording; [isFinal] on the last call.
  final void Function(String text, bool isFinal) onText;
  final bool enabled;
  final Duration maxDuration;
  final double size;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  final SpeechInput _input = SpeechInputs.provider;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _input.isAvailable().then((bool ok) {
        if (mounted) setState(() => _available = ok);
      }),
    );
  }

  @override
  void dispose() {
    if (_input.listening.value) unawaited(_input.cancel());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_input.listening.value) {
      await _input.stop();
      return;
    }
    final bool started = await _input.start(
      onText: widget.onText,
      maxDuration: widget.maxDuration,
    );
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'The microphone could not start. Check the permission, or type '
            'your answer.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: _input.listening,
      builder: (BuildContext context, bool listening, Widget? _) {
        return IconButton.filled(
          key: const Key('mic-button'),
          tooltip: listening ? 'Stop the microphone' : 'Speak',
          iconSize: widget.size * 0.5,
          constraints: BoxConstraints.tightFor(
            width: widget.size,
            height: widget.size,
          ),
          style: IconButton.styleFrom(
            backgroundColor: listening ? AppColors.error : AppColors.surface,
            foregroundColor: listening
                ? AppColors.textPrimary
                : AppColors.primaryBright,
          ),
          onPressed: widget.enabled ? _toggle : null,
          icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
        );
      },
    );
  }
}
