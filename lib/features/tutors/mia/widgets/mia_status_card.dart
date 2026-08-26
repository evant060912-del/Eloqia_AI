import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../models/learning_profile.dart';
import '../../../../services/learning/learning_profile_service.dart';
import '../../../../services/progress_service.dart';
import '../../../../theme/app_colors.dart';

/// Premium intelligent status panel for Mia.
///
/// This widget acts as the visual bridge between:
/// - Mia's current availability
/// - the learner's profile
/// - the learner's current level
/// - today's progression
/// - the next recommended action
///
/// The visual language follows Eloqia's Liquid Glass system:
/// - layered glass
/// - atmospheric gradients
/// - controlled glow
/// - depth
/// - animated status indicators
/// - responsive information hierarchy
class MiaStatusCard extends StatefulWidget {
  const MiaStatusCard({
    super.key,
    this.profile,
    this.progress,
    this.onStartSession,
  });

  final LearningProfile? profile;
  final ProgressSnapshot? progress;
  final VoidCallback? onStartSession;

  @override
  State<MiaStatusCard> createState() => _MiaStatusCardState();
}

class _MiaStatusCardState extends State<MiaStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  LearningProfile? _profile;
  ProgressSnapshot? _progress;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _resolveData();
  }

  Future<void> _resolveData() async {
    try {
      final LearningProfile? profile =
          widget.profile ??
          await _loadProfileSafely();

      final ProgressSnapshot? progress =
          widget.progress ??
          await _loadProgressSafely();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _progress = progress;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<LearningProfile?> _loadProfileSafely() async {
    try {
      return await LearningProfileService.getProfile();
    } catch (_) {
      return null;
    }
  }

  Future<ProgressSnapshot?> _loadProgressSafely() async {
    try {
      return await ProgressService.getSnapshot();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LearningProfile? profile =
        _profile ?? widget.profile;

    final ProgressSnapshot? progress =
        _progress ?? widget.progress;

    final String level =
        _resolveLevel(profile, progress);

    final String goal =
        _resolveGoal(profile);

    final int dailyGoal =
        progress?.dailyGoal ?? 20;

    final int completed =
        progress?.dailyGoalProgress ?? 0;

    final double dailyProgress =
        dailyGoal <= 0
            ? 0
            : (completed / dailyGoal)
                .clamp(0.0, 1.0);

    final bool isComplete =
        dailyProgress >= 1.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double pulse =
            0.82 +
            (_animationController.value * 0.18);

        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 28,
              sigmaY: 28,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(
                      alpha: 0.125,
                    ),
                    AppColors.secondary.withValues(
                      alpha: 0.055,
                    ),
                    Colors.white.withValues(
                      alpha: 0.028,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.105,
                  ),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.105 * pulse,
                    ),
                    blurRadius: 50,
                    spreadRadius: -10,
                    offset: const Offset(0, 12),
                  ),
                  const BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 36,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildAtmosphere(pulse),

                  Padding(
                    padding: const EdgeInsets.all(21),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildTopRow(
                          level: level,
                          isComplete: isComplete,
                        ),

                        const SizedBox(height: 22),

                        _buildMainMessage(
                          goal: goal,
                          level: level,
                          isComplete: isComplete,
                        ),

                        const SizedBox(height: 21),

                        _buildProgress(
                          completed: completed,
                          dailyGoal: dailyGoal,
                          progress: dailyProgress,
                        ),

                        const SizedBox(height: 18),

                        _buildMetrics(
                          level: level,
                          progress: progress,
                        ),

                        const SizedBox(height: 18),

                        _buildRecommendation(
                          goal: goal,
                          isComplete: isComplete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAtmosphere(double pulse) {
    return Positioned(
      top: -85,
      right: -75,
      child: IgnorePointer(
        child: Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.12 * pulse,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow({
    required String level,
    required bool isComplete,
  }) {
    return Row(
      children: [
        _buildMiaIndicator(),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MIA INTELLIGENCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.65,
                    ),
                  ),
                  const SizedBox(width: 7),
                  _buildLiveBadge(),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _isLoading
                    ? 'Personalizing your experience…'
                    : 'Your learning companion is ready.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary
                      .withValues(alpha: 0.68),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _buildLevelBadge(level),
      ],
    );
  }

  Widget _buildMiaIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double scale =
            1.0 +
            (_animationController.value * 0.045);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBright,
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 25,
                  spreadRadius: -3,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.success.withValues(
          alpha: 0.085,
        ),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success,
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(
              alpha: 0.15,
            ),
            AppColors.secondary.withValues(
              alpha: 0.08,
            ),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            level,
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'LEVEL',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.40,
              ),
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMessage({
    required String goal,
    required String level,
    required bool isComplete,
  }) {
    final String title = isComplete
        ? 'You’ve completed today’s goal.'
        : 'Mia has a plan for you.';

    final String subtitle = isComplete
        ? 'You can keep going or come back tomorrow.'
        : 'A focused session designed around your progress.';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.65,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary
                .withValues(alpha: 0.72),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.flag_rounded,
              size: 13,
              color: AppColors.primaryBright
                  .withValues(alpha: 0.82),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                goal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.58,
                  ),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgress({
    required int completed,
    required int dailyGoal,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'TODAY’S MOMENTUM',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.45,
                ),
              ),
            ),
            Text(
              '$completed / $dailyGoal min',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 9,
                width: double.infinity,
                color: Colors.white.withValues(
                  alpha: 0.055,
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryBright,
                        AppColors.secondaryBright,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.48),
                        blurRadius: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics({
    required String level,
    required ProgressSnapshot? progress,
  }) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.local_fire_department_rounded,
            value:
                '${progress?.currentStreak ?? 0}',
            label: 'STREAK',
            iconColor: AppColors.streak,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            icon: Icons.bolt_rounded,
            value: '${progress?.xp ?? 0}',
            label: 'TOTAL XP',
            iconColor: AppColors.xp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            icon: Icons.auto_graph_rounded,
            value: level,
            label: 'LEVEL',
            iconColor: AppColors.primaryBright,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation({
    required String goal,
    required bool isComplete,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.065,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(
                alpha: 0.10,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: 0.13,
                ),
              ),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: AppColors.primaryBright,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete
                      ? 'Mia’s recommendation'
                      : 'Mia’s next move',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isComplete
                      ? 'Excellent momentum. Try a conversation to go deeper.'
                      : 'Focus on $goal in your next session.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary
                        .withValues(alpha: 0.60),
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (widget.onStartSession != null)
            _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: widget.onStartSession,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: 0.28,
              ),
              blurRadius: 18,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }

  String _resolveLevel(
    LearningProfile? profile,
    ProgressSnapshot? progress,
  ) {
    final String profileLevel =
        profile?.currentLevel.trim() ?? '';

    if (profileLevel.isNotEmpty) {
      return profileLevel.toUpperCase();
    }

    final int level =
        progress?.level ?? 1;

    switch (level.clamp(1, 6)) {
      case 1:
        return 'A1';
      case 2:
        return 'A2';
      case 3:
        return 'B1';
      case 4:
        return 'B2';
      case 5:
        return 'C1';
      case 6:
        return 'C2';
    }

    return 'A1';
  }

  String _resolveGoal(
    LearningProfile? profile,
  ) {
    final String primaryGoal =
        profile?.primaryGoal.trim() ?? '';

    if (primaryGoal.isNotEmpty) {
      return primaryGoal;
    }

    return 'Build your English confidence';
  }
}

/// Small premium metric used inside [MiaStatusCard].
class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.055,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary
                  .withValues(alpha: 0.48),
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}