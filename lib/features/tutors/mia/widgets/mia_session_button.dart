import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium primary action for starting a learning session with Mia.
///
/// Designed as the main CTA of the Mia experience:
/// - Liquid Glass surface
/// - animated ambient glow
/// - hover and press micro-interactions
/// - layered depth
/// - animated microphone icon
/// - optional loading state
/// - optional custom label
/// - reusable outside MiaScreen
///
/// Navigation and conversation logic remain owned by the parent screen.
class MiaSessionButton extends StatefulWidget {
  const MiaSessionButton({
    super.key,
    required this.onPressed,
    this.label = 'Start Conversation',
    this.subtitle = 'Begin your session with Mia',
    this.isLoading = false,
    this.enabled = true,
    this.showSubtitle = true,
    this.height = 78,
  });

  /// Triggered when the learner starts a Mia session.
  final VoidCallback? onPressed;

  /// Main CTA label.
  final String label;

  /// Secondary contextual message.
  final String subtitle;

  /// Displays the animated loading state.
  final bool isLoading;

  /// Controls whether the button can be interacted with.
  final bool enabled;

  /// Allows compact usage without the secondary line.
  final bool showSubtitle;

  /// Button height.
  final double height;

  @override
  State<MiaSessionButton> createState() =>
      _MiaSessionButtonState();
}

class _MiaSessionButtonState
    extends State<MiaSessionButton>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _iconController;
  late final AnimationController _pressController;

  bool _isHovered = false;

  bool get _interactive =>
      widget.enabled &&
      !widget.isLoading &&
      widget.onPressed != null;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2600,
      ),
    )..repeat(reverse: true);

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    )..repeat(reverse: true);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 140,
      ),
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _iconController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (!_interactive || _isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_interactive) {
      return;
    }

    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_interactive) {
      return;
    }

    _pressController.reverse();
  }

  void _handleTapCancel() {
    if (!_interactive) {
      return;
    }

    _pressController.reverse();
  }

  void _handleTap() {
    if (!_interactive) {
      return;
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _ambientController,
            _pressController,
          ]),
          builder: (context, child) {
            return _buildAnimatedButton();
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    final double ambient =
        Curves.easeInOut.transform(
          _ambientController.value,
        );

    final double press =
        Curves.easeOutCubic.transform(
          _pressController.value,
        );

    final double hoverScale =
        _isHovered ? 1.012 : 1.0;

    final double pressScale =
        1.0 - (press * 0.022);

    final double scale =
        hoverScale * pressScale;

    return Transform.scale(
      scale: scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildOuterGlow(
            ambient: ambient,
          ),
          _buildGlassSurface(
            ambient: ambient,
          ),
        ],
      ),
    );
  }

  Widget _buildOuterGlow({
    required double ambient,
  }) {
    final double intensity =
        _isHovered
            ? 0.30
            : 0.18;

    final double blur =
        _isHovered
            ? 46
            : 34;

    return Positioned.fill(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(
                    alpha:
                        intensity +
                        (ambient * 0.08),
                  ),
                  AppColors.secondary.withValues(
                    alpha:
                        intensity * 0.72,
                  ),
                  AppColors.electricBlue.withValues(
                    alpha:
                        intensity * 0.42,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSurface({
    required double ambient,
  }) {
    final double borderAlpha =
        _isHovered ? 0.30 : 0.17;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 26,
          sigmaY: 26,
        ),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha:
                      widget.enabled
                          ? 0.28 +
                              (ambient * 0.045)
                          : 0.10,
                ),
                AppColors.secondary.withValues(
                  alpha:
                      widget.enabled
                          ? 0.18
                          : 0.07,
                ),
                Colors.white.withValues(
                  alpha: 0.045,
                ),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha:
                    widget.enabled
                        ? borderAlpha
                        : 0.08,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withValues(
                  alpha:
                      widget.enabled
                          ? (_isHovered
                              ? 0.25
                          : 0.15)
                        : 0.08,
                  ),
                blurRadius:
                    _isHovered ? 36 : 27,
                spreadRadius: -7,
                offset:
                    const Offset(0, 12),
              ),
              BoxShadow(
                color:
                    AppColors.shadow.withValues(
                  alpha: 0.65,
                ),
                blurRadius: 30,
                offset:
                    const Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildTopReflection(),
              _buildButtonContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopReflection() {
    return Positioned(
      top: 0,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(
                  alpha: 0.30,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          _buildMicrophoneOrb(),
          const SizedBox(width: 15),
          Expanded(
            child: _buildTextContent(),
          ),
          const SizedBox(width: 12),
          _buildArrow(),
        ],
      ),
    );
  }

  Widget _buildMicrophoneOrb() {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        final double pulse =
            Curves.easeInOut.transform(
              _iconController.value,
            );

        return Transform.scale(
          scale:
              widget.isLoading
                  ? 1.0
                  : 1.0 + (pulse * 0.045),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(
                    alpha: 0.19,
                  ),
                  AppColors.primaryBright
                      .withValues(
                    alpha: 0.22,
                  ),
                  AppColors.secondary
                      .withValues(
                    alpha: 0.18,
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.22,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withValues(
                    alpha:
                        0.20 +
                        (pulse * 0.10),
                  ),
                  blurRadius:
                      22 + (pulse * 7),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: _buildOrbIcon(),
          ),
        );
      },
    );
  }

  Widget _buildOrbIcon() {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 19,
          height: 19,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    return const Icon(
      Icons.mic_rounded,
      color: Colors.white,
      size: 23,
    );
  }

  Widget _buildTextContent() {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          child: Text(
            widget.isLoading
                ? 'Preparing Mia...'
                : widget.label,
            key: ValueKey(
              widget.isLoading,
            ),
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha:
                    widget.enabled
                        ? 1.0
                        : 0.45,
              ),
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
        ),
        if (widget.showSubtitle) ...[
          const SizedBox(height: 4),
          AnimatedOpacity(
            opacity:
                widget.enabled
                    ? 0.64
                    : 0.35,
            duration:
                const Duration(
              milliseconds: 200,
            ),
            child: Text(
              widget.subtitle,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w600,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArrow() {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 220,
      ),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha:
              _isHovered
                  ? 0.15
                  : 0.08,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha:
                _isHovered
                    ? 0.19
                    : 0.09,
          ),
        ),
      ),
      child: AnimatedSlide(
        offset:
            _isHovered
                ? const Offset(
                    0.08,
                    0,
                  )
                : Offset.zero,
        duration:
            const Duration(
          milliseconds: 220,
        ),
        curve:
            Curves.easeOutCubic,
        child: Icon(
          Icons.arrow_forward_rounded,
          color:
              Colors.white.withValues(
            alpha:
                widget.enabled
                    ? (_isHovered
                        ? 1.0
                        : 0.78)
                    : 0.35,
          ),
          size: 18,
        ),
      ),
    );
  }
}