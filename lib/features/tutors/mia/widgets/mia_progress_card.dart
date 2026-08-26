import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium progression panel for Mia.
///
/// Displays the learner's current progress with:
/// - animated XP progression
/// - level identity
/// - learning streak
/// - completed sessions
/// - learning time
/// - glassmorphism depth
/// - responsive layout
/// - subtle ambient animations
///
/// The widget is intentionally data-driven so it can later be connected
/// directly to ProgressService without changing the visual architecture.
class MiaProgressCard extends StatefulWidget {
  const MiaProgressCard({
    super.key,
    this.xp = 700,
    this.xpGoal = 1000,
    this.level = 1,
    this.currentStreak = 0,
    this.totalSessions = 0,
    this.learningMinutes = 0,
    this.onViewProgress,
  });

  final int xp;
  final int xpGoal;
  final int level;
  final int currentStreak;
  final int totalSessions;
  final int learningMinutes;
  final VoidCallback? onViewProgress;

  @override
  State<MiaProgressCard> createState() => _MiaProgressCardState();
}

class _MiaProgressCardState extends State<MiaProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  double get _progress {
    if (widget.xpGoal <= 0) {
      return 0;
    }

    return (widget.xp / widget.xpGoal).clamp(0.0, 1.0);
  }

  int get _remainingXp {
    if (widget.xpGoal <= widget.xp) {
      return 0;
    }

    return widget.xpGoal - widget.xp;
  }

  String get _levelName {
    switch (widget.level.clamp(1, 6)) {
      case 1:
        return 'A1 Explorer';
      case 2:
        return 'A2 Builder';
      case 3:
        return 'B1 Communicator';
      case 4:
        return 'B2 Speaker';
      case 5:
        return 'C1 Advanced';
      case 6:
        return 'C2 Master';
      default:
        return 'A1 Explorer';
    }
  }

  String get _levelCode {
    switch (widget.level.clamp(1, 6)) {
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
      default:
        return 'A1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed
        ? 0.985
        : _isHovered
            ? 1.008
            : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onViewProgress,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double pulse = Curves.easeInOut.transform(
          _animationController.value,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 28,
              sigmaY: 28,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(
                      alpha: _isHovered ? 0.085 : 0.060,
                    ),
                    AppColors.primary.withValues(
                      alpha: _isHovered ? 0.105 : 0.065,
                    ),
                    AppColors.secondary.withValues(
                      alpha: 0.035,
                    ),
                    Colors.white.withValues(
                      alpha: 0.018,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: _isHovered ? 0.19 : 0.105,
                  ),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha:
                          (_isHovered ? 0.20 : 0.11) +
                              (pulse * 0.035),
                    ),
                    blurRadius: _isHovered ? 48 : 36,
                    spreadRadius: -8,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: AppColors.shadow.withValues(
                      alpha: 0.58,
                    ),
                    blurRadius: 38,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildAmbientGlow(
                    alignment: Alignment.topRight,
                    color: AppColors.primary,
                    opacity: 0.12 + (pulse * 0.035),
                  ),
                  _buildAmbientGlow(
                    alignment: Alignment.bottomLeft,
                    color: AppColors.secondary,
                    opacity: 0.08,
                  ),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildAmbientGlow({
    required Alignment alignment,
    required Color color,
    required double opacity,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: const Offset(45, -35),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 42,
              sigmaY: 42,
            ),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(
                  alpha: opacity,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopSection(),
        const SizedBox(height: 26),
        _buildXpSection(),
        const SizedBox(height: 24),
        _buildMetrics(),
        const SizedBox(height: 20),
        _buildFooter(),
      ],
    );
  }

  Widget _buildTopSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProgressOrb(),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR EVOLUTION',
                style: TextStyle(
                  color: AppColors.primaryBright.withValues(
                    alpha: 0.78,
                  ),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.9,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _levelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep building your English mastery.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildLevelBadge(),
      ],
    );
  }

  Widget _buildProgressOrb() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double pulse = _animationController.value;

        return Container(
          width: 58,
          height: 58,
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
                  alpha: 0.25 + (pulse * 0.08),
                ),
                blurRadius: 30 + (pulse * 8),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _levelCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.primary.withValues(
          alpha: 0.085,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBright,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            'LEVEL ${widget.level}',
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpSection() {
    final int percentage = (_progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'XP PROGRESS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.xp}',
                    style: const TextStyle(
                      color: AppColors.xp,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${widget.xpGoal} XP',
                    style: TextStyle(
                      color: AppColors.textSecondary
                          .withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildProgressBar(),
        const SizedBox(height: 9),
        Row(
          children: [
            Text(
              widget.xp >= widget.xpGoal
                  ? 'Level goal completed'
                  : 'Keep going — $_remainingXp XP to go',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(
                  alpha: 0.65,
                ),
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 10,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(
          alpha: 0.055,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.045,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryBright,
                  AppColors.secondaryBright,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.55,
                  ),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.local_fire_department_rounded,
            value: '${widget.currentStreak}',
            label: 'DAY STREAK',
            accent: AppColors.streak,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            icon: Icons.forum_rounded,
            value: '${widget.totalSessions}',
            label: 'SESSIONS',
            accent: AppColors.primaryBright,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            icon: Icons.schedule_rounded,
            value: _formatMinutes(
              widget.learningMinutes,
            ),
            label: 'LEARNING',
            accent: AppColors.secondaryBright,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(
                  alpha: 0.45,
                ),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.currentStreak > 0
                ? 'Your momentum is building. Keep your streak alive.'
                : 'Start your first session and begin your streak.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: 0.66,
              ),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(
              alpha: _isHovered ? 0.09 : 0.055,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _isHovered ? 0.14 : 0.07,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: _isHovered ? 0.95 : 0.72,
                  ),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedSlide(
                offset: _isHovered
                    ? const Offset(0.16, 0)
                    : Offset.zero,
                duration: const Duration(
                  milliseconds: 200,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Colors.white.withValues(
                    alpha: _isHovered ? 1.0 : 0.65,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }

    if (minutes < 60) {
      return '${minutes}m';
    }

    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remaining}m';
  }
}

/// Compact metric used by [MiaProgressCard].
class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(
              alpha: 0.055,
            ),
            Colors.white.withValues(
              alpha: 0.022,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.065,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: accent,
            size: 17,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: 0.55,
              ),
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}