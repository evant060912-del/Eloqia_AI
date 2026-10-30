import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/voice/listening_accents.dart';
import '../../../services/voice/listening_voices.dart';
import '../../../theme/app_colors.dart';
import '../models/lesson_models.dart';

/// Plays a dialogue with the shared text-to-speech provider.
class ListeningPlayer extends StatefulWidget {
  const ListeningPlayer({
    super.key,
    required this.lines,
    required this.showTranscript,
  });

  final List<AudioLine> lines;
  final bool showTranscript;

  @override
  State<ListeningPlayer> createState() => _ListeningPlayerState();
}

class _ListeningPlayerState extends State<ListeningPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  bool? _available;
  Set<ListeningAccent> _installed = <ListeningAccent>{};
  late final ListeningVoice _voice = ListeningVoices.provider;
  bool _playing = false;
  int _line = -1;
  int _token = 0;
  int _plays = 0;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_checkVoices());
  }

  Future<void> _checkVoices() async {
    bool ok;
    Set<ListeningAccent> installed;
    try {
      ok = await _voice.isAvailable();
      installed = await _voice.accents();
    } on Object {
      ok = false;
      installed = <ListeningAccent>{};
    }
    if (mounted) {
      setState(() {
        _available = ok;
        _installed = installed;
      });
    }
  }

  @override
  void dispose() {
    _token++;
    _wave.dispose();
    unawaited(_voice.stop());
    super.dispose();
  }

  /// Accents of the dialogue with no matching voice on this device.
  List<ListeningAccent> get _missingAccents {
    if (_voice is! DeviceListeningVoice) return const <ListeningAccent>[];
    return <ListeningAccent>{
      for (final AudioLine line in widget.lines)
        if (line.accent != null && !_installed.contains(line.accent))
          line.accent!,
    }.toList();
  }

  Future<void> _play({required bool slow}) async {
    final int token = ++_token;
    await _voice.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _playing = true;
      _plays++;
    });
    _wave.repeat(reverse: true);

    for (int i = 0; i < widget.lines.length; i++) {
      if (token != _token || !mounted) {
        return;
      }
      setState(() => _line = i);
      final AudioLine line = widget.lines[i];
      await _voice.speakLine(
        speaker: line.speaker,
        text: line.text,
        accent: line.accent,
        slow: slow,
      );
    }
    if (token == _token && mounted) {
      _wave.stop();
      setState(() {
        _playing = false;
        _line = -1;
      });
    }
  }

  Future<void> _stop() async {
    _token++;
    await _voice.stop();
    if (mounted) {
      _wave.stop();
      setState(() {
        _playing = false;
        _line = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool unavailable = _available == false;
    final bool transcript = widget.showTranscript || unavailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.headphones_rounded,
                color: AppColors.electricBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'LISTEN',
                style: TextStyle(
                  color: AppColors.electricBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              if (_plays > 0)
                Text(
                  'Played $_plays×',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (unavailable)
            const Text(
              'Audio is not available on this device, so the transcript is shown instead.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _available == null
                      ? null
                      : () => _play(slow: false),
                  icon: Icon(
                    _plays == 0
                        ? Icons.play_arrow_rounded
                        : Icons.replay_rounded,
                  ),
                  label: Text(_plays == 0 ? 'Play' : 'Replay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(48, 48),
                  ),
                ),
                OutlinedButton(
                  onPressed: _available == null
                      ? null
                      : () => _play(slow: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Slow'),
                ),
                IconButton.outlined(
                  onPressed: _playing ? _stop : null,
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop_rounded),
                ),
              ],
            ),
          if (!unavailable) ...<Widget>[
            const SizedBox(height: 10),
            _waveform(),
          ],
          if (!unavailable) ...<Widget>[
            if (_speakers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final MapEntry<String, ListeningAccent> s
                        in _speakers.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s.key} · ${s.value.label}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _missingAccents.isEmpty
                    ? _voice.description
                    : '${_voice.description} No '
                          '${_missingAccents.map((ListeningAccent a) => a.label).join(' or ')} '
                          'voice is installed: a standard English voice reads '
                          'those lines.',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          if (transcript) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.glassBorder),
            const SizedBox(height: 10),
            for (int i = 0; i < widget.lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: i == _line
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text:
                            '${widget.lines[i].speaker}'
                            '${widget.lines[i].accent == null ? '' : ' (${widget.lines[i].accent!.label})'}: ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: widget.lines[i].text),
                    ],
                  ),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'The transcript appears after you check your answer.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  /// Each speaker with an accent, in order of appearance.
  Map<String, ListeningAccent> get _speakers => <String, ListeningAccent>{
    for (final AudioLine line in widget.lines)
      if (line.accent != null) line.speaker: line.accent!,
  };

  Widget _waveform() {
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              for (int i = 0; i < 12; i++)
                Container(
                  width: 3,
                  height: _playing
                      ? 6 +
                            20 *
                                ((i * 37 % 11) / 11) *
                                (0.4 + 0.6 * _wave.value)
                      : 5,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(
                      alpha: _playing ? 0.9 : 0.3,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
