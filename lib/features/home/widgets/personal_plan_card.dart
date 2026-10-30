import 'package:flutter/material.dart';

import '../../../services/learning/personal_plan.dart';
import '../../../theme/app_colors.dart';

/// "Your plan" on Home: the focus areas from the onboarding answers, each
/// with the learner's reason, and the daily goal from the chosen pace.
class PersonalPlanCard extends StatelessWidget {
  const PersonalPlanCard({
    super.key,
    required this.plan,
    required this.onOpen,
    this.onExamPrep,
  });

  final PersonalPlan plan;
  final ValueChanged<PlanArea> onOpen;

  /// Shown when the goals point to TOEFL/IELTS-style academic English.
  final VoidCallback? onExamPrep;

  static IconData iconOf(PlanArea area) => switch (area) {
    PlanArea.speaking => Icons.forum_rounded,
    PlanArea.grammar => Icons.auto_fix_high_rounded,
    PlanArea.vocabulary => Icons.psychology_rounded,
    PlanArea.reading => Icons.menu_book_rounded,
    PlanArea.listening => Icons.headphones_rounded,
    PlanArea.writing => Icons.edit_rounded,
  };

  static Color colorOf(PlanArea area) => switch (area) {
    PlanArea.speaking => AppColors.speaking,
    PlanArea.grammar => AppColors.grammar,
    PlanArea.vocabulary => AppColors.vocabulary,
    PlanArea.reading => AppColors.reading,
    PlanArea.listening => AppColors.listening,
    PlanArea.writing => AppColors.writing,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'YOUR PLAN',
            style: TextStyle(
              color: AppColors.primaryBright,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Built from your answers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily goal: ${plan.dailyMinutes} minutes '
            '(pace: ${plan.paceLabel}).',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          for (final PlanFocus f in plan.focus)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onOpen(f.area),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colorOf(f.area).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            iconOf(f.area),
                            color: colorOf(f.area),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                f.area.label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                f.reason,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (onExamPrep != null && plan.examPrep) ...<Widget>[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onExamPrep,
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text('TOEFL and IELTS writing practice'),
            ),
          ],
        ],
      ),
    );
  }
}
