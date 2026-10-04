import 'package:flutter/material.dart';

import '../../../services/voice/voice_output_provider.dart';
import '../../../theme/app_colors.dart';
import '../../tutors/mia/mia_emotion_engine.dart';
import '../../tutors/mia/widgets/mia_presence.dart';
import '../engine/lesson_session.dart';
import 'exercise_widgets.dart';

MiaSpeechStyle speechStyleFor(MiaEmotion emotion) => switch (emotion) {
  MiaEmotion.excited || MiaEmotion.celebrating => MiaSpeechStyle.excited,
  MiaEmotion.proud || MiaEmotion.warm => MiaSpeechStyle.warm,
  MiaEmotion.gentleCorrection ||
  MiaEmotion.empathetic => MiaSpeechStyle.encouraging,
  MiaEmotion.playfulFrustration => MiaSpeechStyle.playful,
  MiaEmotion.focused => MiaSpeechStyle.serious,
  _ => MiaSpeechStyle.calm,
};

/// Staged feedback: result, why, rule, example, Mia, then rewards.
class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({super.key, required this.outcome, required this.totalXp});

  final ExerciseOutcome outcome;
  final int totalXp;

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _stage(int index, int count, Widget child) {
    final double start = index / (count + 1);
    final Animation<double> curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExerciseOutcome o = widget.outcome;
    final f = o.feedback;
    final Color accent = f.correct ? AppColors.success : kCorrectionColor;
    final List<Widget> sections = <Widget>[
      _section(
        label: 'RESULT',
        color: accent,
        child: Row(
          children: <Widget>[
            Icon(
              f.correct ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded,
              color: accent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    f.resultTitle,
                    style: TextStyle(
                      color: accent,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.yourAnswer,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _section(
        label: 'WHY',
        color: AppColors.textSecondary,
        child: Text(f.why, style: _body),
      ),
      if (f.rule != null)
        _section(
          label: 'RULE',
          color: AppColors.primary,
          child: Text(
            f.rule!,
            style: _body.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      if (f.example != null)
        _section(
          label: 'EXAMPLE',
          color: AppColors.electricBlue,
          child: Text(
            f.example!,
            style: _body.copyWith(fontStyle: FontStyle.italic, color: AppColors.textPrimary),
          ),
        ),
      if (f.hint != null)
        _section(
          label: 'HINT',
          color: AppColors.electricBlue,
          child: Text(f.hint!, style: _body),
        ),
      _miaSection(f.mia),
      _rewardSection(o),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < sections.length; i++)
            _stage(i, sections.length, Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: sections[i],
            )),
        ],
      ),
    );
  }

  static const TextStyle _body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.5,
  );

  Widget _section({
    required String label,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _miaSection(MiaReaction mia) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          MiaPresence(
            size: 52,
            showLabel: false,
            state: MiaPresenceState.fromEmotion(mia.emotion),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'MIA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${mia.title} ${mia.message}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                _HearMiaButton(
                  text: '${mia.title} ${mia.message}',
                  style: speechStyleFor(mia.emotion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardSection(ExerciseOutcome o) {
    final List<Widget> chips = <Widget>[
      if (o.totalXp > 0)
        _chip(Icons.bolt_rounded, '+${o.totalXp} XP', AppColors.xp,
            sub: o.comboBonus > 0 ? 'includes +${o.comboBonus} combo' : null)
      else
        _chip(Icons.bolt_rounded, 'No XP this time', AppColors.textMuted),
      if (o.combo >= 2) _chip(Icons.local_fire_department_rounded, '${o.combo}x combo', AppColors.warmth),
      _chip(Icons.stars_rounded, '${widget.totalXp} XP this lesson', AppColors.textSecondary),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _chip(IconData icon, String text, Color color, {String? sub}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              sub == null ? text : '$text · $sub',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _HearMiaButton extends StatelessWidget {
  const _HearMiaButton({required this.text, required this.style});

  final String text;
  final MiaSpeechStyle style;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MiaVoice.provider.speaking,
      builder: (BuildContext context, bool speaking, Widget? child) {
        return TextButton.icon(
          onPressed: () => speaking
              ? MiaVoice.provider.stop()
              : MiaVoice.provider.speak(text, style: style),
          icon: Icon(
            speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
            size: 16,
          ),
          label: Text(speaking ? 'Stop' : 'Hear Mia'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(44, 32),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}
