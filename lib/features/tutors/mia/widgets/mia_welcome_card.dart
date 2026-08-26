import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../models/learning_profile.dart';
import '../../../../theme/app_colors.dart';

/// Premium personalized welcome card for Mia.
///
/// This component transforms the learner profile into a concise,
/// emotionally engaging welcome experience.
///
/// The widget intentionally contains presentation logic only.
/// Profile persistence and navigation remain owned by the parent layer.
class MiaWelcomeCard extends StatefulWidget {
  const MiaWelcomeCard({
    super.key,
    required this.profile,
    this.onContinue,
  });

  final LearningProfile profile;

  /// Optional action triggered when the learner continues.
  final VoidCallback? onContinue;

  @override
  State<MiaWelcomeCard> createState() =>
      _MiaWelcomeCardState();
}

class _MiaWelcomeCardState extends State<MiaWelcomeCard>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _entryController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3600,
      ),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entryController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final String name = widget.profile.name.trim();

    final double entryValue = Curves.easeOutCubic.transform(
      _entryController.value,
    );

    final double scale = _isPressed
        ? 0.988
        : _isHovered
            ? 1.008
            : 1.0;

    return AnimatedOpacity(
      opacity: entryValue,
      duration: const Duration(
        milliseconds: 300,
      ),
      child: Transform.translate(
        offset: Offset(
          0,
          20 * (1 - entryValue),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onContinue,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(
                milliseconds: 240,
              ),
              curve: Curves.easeOutCubic,
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  return _buildCard(
                    name: name,
                    pulse: _ambientController.value,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String name,
    required double pulse,
  }) {
    final double glow =
        0.10 + (pulse * 0.07);

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 30,
          sigmaY: 30,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: _isHovered
                      ? 0.17
                      : 0.125,
                ),
                AppColors.secondary.withValues(
                  alpha: _isHovered
                      ? 0.105
                      : 0.065,
                ),
                Colors.white.withValues(
                  alpha: 0.035,
                ),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _isHovered
                    ? 0.24
                    : 0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: glow,
                ),
                blurRadius:
                    48 + (pulse * 16),
                spreadRadius: -8,
                offset: const Offset(
                  0,
                  15,
                ),
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 34,
                offset: Offset(
                  0,
                  20,
                ),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildAmbientLight(
                pulse: pulse,
              ),
              _buildContent(
                name: name,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientLight({
    required double pulse,
  }) {
    return Positioned(
      top: -95,
      right: -85,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 42,
            sigmaY: 42,
          ),
          child: Container(
            width: 210 + (pulse * 25),
            height: 210 + (pulse * 25),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(
                    alpha: 0.20,
                  ),
                  AppColors.secondary.withValues(
                    alpha: 0.07,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required String name,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(),
        const SizedBox(height: 25),
        _buildGreeting(name),
        const SizedBox(height: 12),
        _buildMessage(name),
        const SizedBox(height: 23),
        _buildProfileSummary(),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        _buildMiaMiniOrb(),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR AI TUTOR',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.48,
                  ),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.9,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Mia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _buildOnlineBadge(),
      ],
    );
  }

  Widget _buildMiaMiniOrb() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBright,
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
              alpha: 0.32,
            ),
            blurRadius: 25,
            spreadRadius: -3,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color: AppColors.success.withValues(
          alpha: 0.085,
        ),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.19,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success
                      .withValues(
                    alpha: 0.55,
                  ),
                  blurRadius: 9,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'ONLINE',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final String greeting = name.isEmpty
        ? 'Welcome to your\nMia experience.'
        : 'Welcome back,\n$name.';

    return Text(
      greeting,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 31,
        height: 1.05,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
    );
  }

  Widget _buildMessage(String name) {
    final String message = name.isEmpty
        ? 'I’m here to help you speak more naturally, '
            'think in English and become more confident.'
        : 'I remember what you are working toward. '
            'Let’s make today another step forward.';

    return Text(
      message,
      style: TextStyle(
        color: AppColors.textSecondary.withValues(
          alpha: 0.76,
        ),
        fontSize: 13.5,
        height: 1.55,
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ProfilePill(
          icon: Icons.flag_rounded,
          label: _primaryGoalLabel(),
        ),
        _ProfilePill(
          icon: Icons.trending_up_rounded,
          label: _levelLabel(),
        ),
        _ProfilePill(
          icon: Icons.psychology_rounded,
          label: _paceLabel(),
        ),
      ],
    );
  }

  String _primaryGoalLabel() {
    final String goal =
        widget.profile.primaryGoal.trim();

    if (goal.isEmpty) {
      return 'Personalized';
    }

    return _shorten(goal);
  }

  String _levelLabel() {
    final String level =
        widget.profile.currentLevel.trim();

    return level.isEmpty
        ? 'Adaptive level'
        : level;
  }

  String _paceLabel() {
    final String pace =
        widget.profile.learningPace.trim();

    if (pace.isEmpty) {
      return 'Adaptive pace';
    }

    return _shorten(pace);
  }

  String _shorten(String value) {
    const int maxLength = 18;

    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength - 1)}…';
  }
}

/// Premium compact profile information pill.
class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(15),
        color: Colors.white.withValues(
          alpha: 0.045,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.075,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.primaryBright
                .withValues(
              alpha: 0.9,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}