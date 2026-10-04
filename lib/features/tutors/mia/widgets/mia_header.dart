import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium header for Mia's learning environment.
///
/// The header is intentionally self-contained:
/// - premium Liquid Glass presentation
/// - responsive layout
/// - online / ready state
/// - tutor identity
/// - contextual learning status
/// - animated interaction feedback
///
/// The widget does not own navigation. The parent screen remains responsible
/// for routing and session orchestration.
class MiaHeader extends StatefulWidget {
  const MiaHeader({
    super.key,
    this.onBack,
    this.onSettings,
    this.isOnline = true,
    this.isThinking = false,
    this.showBackButton = true,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  /// Whether Mia is currently available.
  final bool isOnline;

  /// Displays a subtle thinking state instead of the normal ready state.
  final bool isThinking;

  /// Controls whether the back button is displayed.
  final bool showBackButton;

  @override
  State<MiaHeader> createState() => _MiaHeaderState();
}

class _MiaHeaderState extends State<MiaHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool _isBackPressed = false;
  bool _isSettingsPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setBackPressed(bool value) {
    if (_isBackPressed == value) {
      return;
    }

    setState(() {
      _isBackPressed = value;
    });
  }

  void _setSettingsPressed(bool value) {
    if (_isSettingsPressed == value) {
      return;
    }

    setState(() {
      _isSettingsPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.showBackButton) ...[
          _buildGlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            isPressed: _isBackPressed,
            onPressedChanged: _setBackPressed,
            onTap: widget.onBack,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildIdentity(),
        ),
        const SizedBox(width: 12),
        _buildGlassButton(
          icon: Icons.tune_rounded,
          isPressed: _isSettingsPressed,
          onPressedChanged: _setSettingsPressed,
          onTap: widget.onSettings,
        ),
      ],
    );
  }

  Widget _buildIdentity() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.075),
                AppColors.primary.withValues(alpha: 0.055),
                Colors.white.withValues(alpha: 0.018),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.09,
                ),
                blurRadius: 30,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 25,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildMiniAvatar(),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mia',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildVerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildStatusLine(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulse =
            0.82 + (_pulseController.value * 0.18);

        return Container(
          width: 45,
          height: 45,
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
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.20 * pulse,
                ),
                blurRadius: 20,
                spreadRadius: -2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 23,
          ),
          Positioned(
            right: 3,
            bottom: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: SizedBox(
                width: 10,
                height: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(
          alpha: 0.15,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.primaryBright,
        size: 10,
      ),
    );
  }

  Widget _buildStatusLine() {
    final String label;

    if (widget.isThinking) {
      label = 'Preparing your next lesson';
    } else if (widget.isOnline) {
      label = 'Ready to practice English';
    } else {
      label = 'Currently unavailable';
    }

    final Color statusColor = widget.isOnline
        ? AppColors.success
        : AppColors.textSecondary;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: widget.isOnline
                ? [
                    BoxShadow(
                      color: statusColor.withValues(
                        alpha: 0.55,
                      ),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: 0.72,
              ),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required bool isPressed,
    required ValueChanged<bool> onPressedChanged,
    required VoidCallback? onTap,
  }) {
    final double scale = isPressed ? 0.92 : 1.0;

    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTap == null
            ? null
            : (_) => onPressedChanged(true),
        onTapUp: onTap == null
            ? null
            : (_) {
                onPressedChanged(false);
                onTap();
              },
        onTapCancel: onTap == null
            ? null
            : () => onPressedChanged(false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(
                        alpha: isPressed ? 0.12 : 0.075,
                      ),
                      AppColors.primary.withValues(
                        alpha: isPressed ? 0.09 : 0.035,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isPressed ? 0.18 : 0.09,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isPressed ? 0.14 : 0.06,
                      ),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: onTap == null
                      ? AppColors.textSecondary
                          .withValues(alpha: 0.35)
                      : AppColors.textPrimary
                          .withValues(alpha: 0.88),
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}