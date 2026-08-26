import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../services/learning/learning_profile_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../features/tutors/mia/mia_screen.dart';
import '../../features/home/widgets/quick_actions_section.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({
    super.key,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
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
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _loadData();
  }

  Future<void> _loadData() async {
    final LearningProfile profile =
        await LearningProfileService.getProfile();

    final ProgressSnapshot progress =
        await ProgressService.getSnapshot();

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _progress = progress;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openMia() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MiaScreen(),
      ),
    );
  }

  void _onActionSelected(QuickActionData action) {
    switch (action.title) {
      case 'Conversation':
        _openMia();
        break;

      case 'Vocabulary':
      case 'Grammar':
      case 'Listening':
      case 'Writing':
      case 'Academic':
        _showComingSoon(action);
        break;
    }
  }

  void _showComingSoon(QuickActionData action) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _ComingSoonSheet(
          action: action,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LearningAmbientBackground(),

          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final double animationValue =
                    Curves.easeOutCubic.transform(
                  _animationController.value,
                );

                return Opacity(
                  opacity: animationValue,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      24 * (1 - animationValue),
                    ),
                    child: child,
                  ),
                );
              },
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    50,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 30),
                      _buildHero(),
                      const SizedBox(height: 26),
                      _buildProgressOverview(),
                      const SizedBox(height: 34),
                      QuickActionsSection(
                        onActionSelected:
                            _onActionSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const _LoadingOverlay(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildBackButton(),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ELOQIA AI',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'LEARNING HUB',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
        _buildMiaButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return _GlassIconButton(
      icon: Icons.arrow_back_rounded,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }

  Widget _buildMiaButton() {
    return GestureDetector(
      onTap: _openMia,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(
                    alpha: 0.16,
                  ),
                  AppColors.secondary.withValues(
                    alpha: 0.07,
                  ),
                ],
              ),
              border: Border.all(
                color: AppColors.glassBorderStrong,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryBright,
                  size: 16,
                ),
                SizedBox(width: 7),
                Text(
                  'Mia',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero() {
    final String name =
        _profile?.name.trim() ?? '';

    final String level =
        _profile?.currentLevel.trim() ?? 'A1';

    final String greeting = name.isEmpty
        ? 'Your learning universe.'
        : 'Your learning universe,\n$name.';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBright,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.55,
                    ),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'PERSONALIZED FOR YOU',
              style: TextStyle(
                color: AppColors.primaryBright.withValues(
                  alpha: 0.82,
                ),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          greeting,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 38,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Everything you need to build confident, '
          'natural English — in one intelligent space.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(
              alpha: 0.76,
            ),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        _buildLevelBadge(level),
      ],
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(
              alpha: 0.16,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.school_rounded,
            color: AppColors.primaryBright,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            'CURRENT LEVEL  •  $level',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  Widget _buildProgressOverview() {
    final ProgressSnapshot progress =
        _progress ??
        const ProgressSnapshot(
          xp: 0,
          level: 1,
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: null,
          skills: <String, double>{},
          dailyGoal: 20,
          dailyGoalProgress: 0,
          totalSessions: 0,
          learningMinutes: 0,
          completedLessons: 0,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(
                  alpha: 0.07,
                ),
                Colors.white.withValues(
                  alpha: 0.025,
                ),
                AppColors.primary.withValues(
                  alpha: 0.035,
                ),
              ],
            ),
            border: Border.all(
              color: AppColors.glassBorderStrong,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: 0.7,
                ),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your momentum',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.xp} XP',
                    style: const TextStyle(
                      color: AppColors.xp,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDailyProgress(progress),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.local_fire_department_rounded,
                      value:
                          '${progress.currentStreak}',
                      label: 'DAY STREAK',
                      color: AppColors.streak,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.timer_outlined,
                      value:
                          '${progress.learningMinutes}m',
                      label: 'LEARNED',
                      color: AppColors.primaryBright,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      icon: Icons.check_circle_outline_rounded,
                      value:
                          '${progress.completedLessons}',
                      label: 'LESSONS',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyProgress(
    ProgressSnapshot progress,
  ) {
    final double ratio =
        progress.dailyGoalRatio;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Today’s learning goal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${progress.dailyGoalProgress} / '
              '${progress.dailyGoal}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                color: Colors.white.withValues(
                  alpha: 0.065,
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryBright,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===============================================================================
// GLASS BUTTON
// ===============================================================================

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
          ),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: Colors.white.withValues(
                alpha: 0.045,
              ),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================================
// MINI METRIC
// ===============================================================================

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
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
            color: color,
            size: 17,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary
                  .withValues(alpha: 0.58),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================================
// COMING SOON
// ===============================================================================

class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({
    required this.action,
  });

  final QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 24,
              sigmaY: 24,
            ),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.gradient.first.withValues(
                      alpha: 0.22,
                    ),
                    action.gradient.last.withValues(
                      alpha: 0.09,
                    ),
                    AppColors.surface.withValues(
                      alpha: 0.92,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.13,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: action.gradient,
                      ),
                    ),
                    child: Icon(
                      action.icon,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This learning experience is being '
                    'prepared for your Eloqia journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary
                          .withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.textPrimary,
                        foregroundColor:
                            AppColors.textOnPrimary,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================================
// AMBIENT BACKGROUND
// ===============================================================================

class _LearningAmbientBackground
    extends StatelessWidget {
  const _LearningAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -170,
          right: -120,
          child: _AmbientGlow(
            color: AppColors.primary,
            size: 390,
          ),
        ),
        Positioned(
          top: 340,
          left: -190,
          child: _AmbientGlow(
            color: AppColors.secondary,
            size: 400,
          ),
        ),
        Positioned(
          bottom: -190,
          right: -100,
          child: _AmbientGlow(
            color: AppColors.electricBlue,
            size: 350,
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 85,
        sigmaY: 85,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(
            alpha: 0.10,
          ),
        ),
      ),
    );
  }
}

// ===============================================================================
// LOADING
// ===============================================================================

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppColors.background.withValues(
            alpha: 0.35,
          ),
          child: const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBright,
              ),
            ),
          ),
        ),
      ),
    );
  }
}