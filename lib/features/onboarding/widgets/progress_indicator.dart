import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 0) {
      return const SizedBox.shrink();
    }

    final int safePage = currentPage.clamp(
      0,
      totalPages - 1,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        totalPages,
        (index) {
          final bool active = index == safePage;
          final bool completed = index < safePage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            width: active ? 32 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active || completed
                  ? LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    )
                  : null,
              color: active || completed
                  ? null
                  : Colors.white.withValues(alpha: 0.13),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}