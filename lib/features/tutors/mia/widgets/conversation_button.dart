import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium primary CTA for Mia's conversation experience.
///
/// Designed as the main entry point into the future real-time voice
/// conversation system.
///
/// The visual system combines:
/// • Liquid Glass
/// • animated ambient glow
/// • breathing microphone core
/// • hover interaction for desktop/web
/// • tactile press feedback
/// • disabled state
/// • semantic accessibility
/// • responsive sizing
///
/// The widget intentionally owns only presentation and interaction.
/// The parent remains responsible for the actual conversation logic.
class ConversationButton extends StatefulWidget {
  const ConversationButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.label = 'Start Conversation',
    this.subtitle = 'Speak naturally with Mia',
  });

  /// Called when the learner activates the button.
  final VoidCallback? onPressed;

  /// Controls whether the CTA is interactive.
  final bool enabled;

  /// Main CTA label.
  final String label;

  /// Supporting CTA label.
  final String subtitle;

  @override
  State<ConversationButton> createState() =>
      _ConversationButtonState();
}

class _ConversationButtonState extends State<ConversationButton>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _pressController;
  late final AnimationController _shimmerController;

  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isInteractive =>
      widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2400,
      ),
    )..repeat(reverse: true);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 120,
      ),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4200,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (!_isInteractive || _isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (!_isInteractive || _isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });

    if (value) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  void _handleTap() {
    if (!_isInteractive) {
      return;
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.label,
      hint: widget.subtitle,
      child: MouseRegion(
        cursor: _isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onTapDown: _isInteractive
              ? (_) => _setPressed(true)
              : null,
          onTapUp: _isInteractive
              ? (_) => _setPressed(false)
              : null,
          onTapCancel: _isInteractive
              ? () => _setPressed(false)
              : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathingController,
              _pressController,
              _shimmerController,
            ]),
            builder: (context, child) {
              return _buildAnimatedButton();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    final double breathing =
        Curves.easeInOut.transform(
      _breathingController.value,
    );

    final double press =
        Curves.easeOutCubic.transform(
      _pressController.value,
    );

    final double scale = _isPressed
        ? 0.972
        : _isHovered
            ? 1.012
            : 1.0;

    final double glowStrength =
        _isInteractive
            ? 0.18 + (breathing * 0.10)
            : 0.035;

    final double glowRadius =
        _isInteractive
            ? 28 + (breathing * 16)
            : 12;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 260,
        ),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0,
          press * 1.5,
          0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildOuterGlow(
              strength: glowStrength,
              radius: glowRadius,
            ),
            _buildGlassSurface(
              breathing: breathing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterGlow({
    required double strength,
    required double radius,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: radius,
            sigmaY: radius,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                25,
              ),
              color: AppColors.primary.withValues(
                alpha: strength,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSurface({
    required double breathing,
  }) {
    final double borderAlpha = !_isInteractive
        ? 0.06
        : _isHovered
            ? 0.28
            : 0.15;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        25,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 82,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              25,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isInteractive
                  ? [
                      AppColors.primary.withValues(
                        alpha: _isHovered
                            ? 0.34
                            : 0.25,
                      ),
                      AppColors.secondary.withValues(
                        alpha: _isHovered
                            ? 0.23
                            : 0.14,
                      ),
                      Colors.white.withValues(
                        alpha: 0.055,
                      ),
                    ]
                  : [
                      Colors.white.withValues(
                        alpha: 0.045,
                      ),
                      Colors.white.withValues(
                        alpha: 0.018,
                      ),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: borderAlpha,
              ),
              width: _isHovered ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: _isInteractive
                      ? 0.16 + (breathing * 0.08)
                      : 0.025,
                ),
                blurRadius: _isInteractive
                    ? 32 + (breathing * 10)
                    : 14,
                spreadRadius: -5,
                offset: const Offset(
                  0,
                  12,
                ),
              ),
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: 0.48,
                ),
                blurRadius: 26,
                offset: const Offset(
                  0,
                  14,
                ),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildTopReflection(),
              _buildShimmer(),
              _buildButtonContent(
                breathing: breathing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopReflection() {
    return Positioned(
      top: 0,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(
                  alpha: 0.26,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    if (!_isInteractive) {
      return const SizedBox.shrink();
    }

    final double position =
        _shimmerController.value;

    return Positioned.fill(
      child: IgnorePointer(
        child: FractionallySizedBox(
          widthFactor: 0.28,
          alignment: Alignment(
            -3.5 + (position * 7),
            0,
          ),
          child: Transform.rotate(
            angle: -0.20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(
                      alpha: 0.055,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent({
    required double breathing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      child: Row(
        children: [
          _buildMicrophoneCore(
            breathing: breathing,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildLabels(),
          ),
          const SizedBox(width: 12),
          _buildArrow(),
        ],
      ),
    );
  }

  Widget _buildMicrophoneCore({
    required double breathing,
  }) {
    final double glow =
        _isInteractive
            ? 0.22 + (breathing * 0.13)
            : 0.035;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 260,
      ),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isInteractive
              ? [
                  AppColors.primaryBright.withValues(
                    alpha: _isHovered
                        ? 0.88
                        : 0.72,
                  ),
                  AppColors.secondary.withValues(
                    alpha: 0.82,
                  ),
                ]
              : [
                  Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  Colors.white.withValues(
                    alpha: 0.04,
                  ),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: _isInteractive
                ? 0.25
                : 0.06,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBright
                .withValues(
              alpha: glow,
            ),
            blurRadius: 24 + (breathing * 8),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInteractive)
            Container(
              width: 38 + (breathing * 4),
              height: 38 + (breathing * 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha:
                        0.055 + (breathing * 0.035),
                  ),
                ),
              ),
            ),
          Icon(
            Icons.mic_rounded,
            color: _isInteractive
                ? Colors.white
                : Colors.white.withValues(
                    alpha: 0.35,
                  ),
            size: 25,
          ),
        ],
      ),
    );
  }

  Widget _buildLabels() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _isInteractive
                ? Colors.white
                : Colors.white.withValues(
                    alpha: 0.42,
                  ),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _isInteractive
                ? Colors.white.withValues(
                    alpha: 0.62,
                  )
                : Colors.white.withValues(
                    alpha: 0.30,
                  ),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha: _isInteractive
              ? _isHovered
                  ? 0.13
                  : 0.07
              : 0.025,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: _isInteractive
                ? 0.09
                : 0.04,
          ),
        ),
      ),
      child: AnimatedSlide(
        offset: _isHovered && _isInteractive
            ? const Offset(
                0.12,
                0,
              )
            : Offset.zero,
        duration: const Duration(
          milliseconds: 220,
        ),
        curve: Curves.easeOutCubic,
        child: Icon(
          Icons.arrow_forward_rounded,
          color: _isInteractive
              ? Colors.white.withValues(
                  alpha: 0.90,
                )
              : Colors.white.withValues(
                  alpha: 0.25,
                ),
          size: 18,
        ),
      ),
    );
  }
}