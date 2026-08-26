import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium preview of the learning session that Mia is about to start.
///
/// This widget presents the session as an intentional learning experience
/// rather than a simple microphone screen.
///
/// It is independent from the AI engine and can later receive real values
/// generated from:
/// - LearningProfile
/// - selected conversation mode
/// - current level
/// - daily goal
/// - progression
/// - adaptive lesson engine
class MiaSessionPreview extends StatefulWidget {
  const MiaSessionPreview({
    super.key,
    this.level = 'B2',
    this.duration = 10,
    this.focus = 'Speaking confidence',
    this.mode = 'Free Talk',
    this.onStart,
  });

  final String level;
  final int duration;
  final String focus;
  final String mode;
  final VoidCallback? onStart;

  @override
  State<MiaSessionPreview> createState() =>
      _MiaSessionPreviewState();
}

class _MiaSessionPreviewState
    extends State<MiaSessionPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.085,
                ),
                Colors.white.withValues(
                  alpha: 0.035,
                ),
                AppColors.secondary.withValues(
                  alpha: 0.045,
                ),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 32,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildFocus(),
              const SizedBox(height: 18),
              _buildDetails(),
              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 18),
              _buildAdaptiveMessage(),
              const SizedBox(height: 20),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT SESSION',
                style: TextStyle(
                  color:
                      AppColors.primaryBright.withValues(
                    alpha: 0.70,
                  ),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Your session is ready',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        _buildLevelBadge(),
      ],
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double glow =
            16 + (_animationController.value * 10);

        return Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withValues(
                  alpha: 0.18 +
                      (_animationController.value *
                          0.08),
                ),
                blurRadius: glow,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 21,
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
          alpha: 0.09,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.17,
          ),
        ),
      ),
      child: Text(
        widget.level,
        style: const TextStyle(
          color: AppColors.primaryBright,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ===========================================================================
  // FOCUS
  // ===========================================================================

  Widget _buildFocus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(
              alpha: 0.055,
            ),
            Colors.white.withValues(
              alpha: 0.018,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(
                alpha: 0.10,
              ),
              border: Border.all(
                color: AppColors.secondary.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.secondaryBright,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY’S FOCUS',
                  style: TextStyle(
                    color: AppColors.textSecondary
                        .withValues(
                      alpha: 0.52,
                    ),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.focus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DETAILS
  // ===========================================================================

  Widget _buildDetails() {
    return Row(
      children: [
        Expanded(
          child: _DetailItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Mode',
            value: widget.mode,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DetailItem(
            icon: Icons.schedule_rounded,
            label: 'Duration',
            value: '${widget.duration} min',
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DIVIDER
  // ===========================================================================

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.white.withValues(
        alpha: 0.055,
      ),
    );
  }

  // ===========================================================================
  // ADAPTIVE MESSAGE
  // ===========================================================================

  Widget _buildAdaptiveMessage() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.primaryBright,
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Mia will adapt the conversation to your level '
            'and gently adjust the challenge as you progress.',
            style: TextStyle(
              color:
                  AppColors.textSecondary.withValues(
                alpha: 0.70,
              ),
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // START
  // ===========================================================================

  Widget _buildStartButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      onTap: widget.onStart,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(
          milliseconds: 150,
        ),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(
                  alpha: 0.20,
                ),
                blurRadius: 28,
                spreadRadius: -5,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Begin session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DETAIL ITEM
// =============================================================================

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.055,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary
                .withValues(
              alpha: 0.72,
            ),
            size: 16,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textSecondary
                        .withValues(
                      alpha: 0.43,
                    ),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}