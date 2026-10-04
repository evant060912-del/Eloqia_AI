import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../mia_emotion_engine.dart';

class MiaCompanionCard extends StatefulWidget {
  const MiaCompanionCard({super.key, required this.reaction});

  final MiaReaction reaction;

  @override
  State<MiaCompanionCard> createState() => _MiaCompanionCardState();
}

class _MiaCompanionCardState extends State<MiaCompanionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _presenceController;

  @override
  void initState() {
    super.initState();
    _presenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _presenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(widget.reaction.emotion);
    final double amplitude = switch (widget.reaction.intensity) {
      MiaEmotionIntensity.subtle => 0.012,
      MiaEmotionIntensity.warm => 0.022,
      MiaEmotionIntensity.vivid => 0.035,
    };

    return AnimatedBuilder(
      animation: _presenceController,
      builder: (BuildContext context, Widget? child) {
        final double scale =
            1 + ((_presenceController.value - 0.5) * amplitude);
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.8)),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/tutors/mia/mia.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) => Container(
                        width: 42,
                        height: 42,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'MIA / ${widget.reaction.emotion.name.replaceAllMapped(RegExp(r'[A-Z]'), (Match m) => ' ${m[0]}').toUpperCase()}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.reaction.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.reaction.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.reaction.explanation,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(MiaEmotion emotion) => switch (emotion) {
    MiaEmotion.curious => AppColors.electricBlue,
    MiaEmotion.warm || MiaEmotion.proud => AppColors.primary,
    MiaEmotion.excited || MiaEmotion.celebrating => AppColors.warmth,
    MiaEmotion.gentleCorrection || MiaEmotion.empathetic => AppColors.secondary,
    MiaEmotion.focused || MiaEmotion.thinking => AppColors.vocabulary,
    MiaEmotion.playfulFrustration => AppColors.writing,
    MiaEmotion.listening => AppColors.primaryBright,
    MiaEmotion.speaking => AppColors.success,
  };
}
