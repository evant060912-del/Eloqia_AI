import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium primary conversation action for Mia.
///
/// This component is intentionally prepared for the future voice engine.
/// The visual states already support:
/// - idle
/// - connecting
/// - listening
/// - speaking
/// - disabled
///
/// The parent remains responsible for the actual voice/session logic.
class MiaConversationButton extends StatefulWidget {
  const MiaConversationButton({
    super.key,
    required this.onPressed,
    this.state = MiaConversationState.idle,
    this.label = 'Start conversation',
  });

  final VoidCallback? onPressed;
  final MiaConversationState state;
  final String label;

  @override
  State<MiaConversationButton> createState() =>
      _MiaConversationButtonState();
}

enum MiaConversationState {
  idle,
  connecting,
  listening,
  speaking,
  disabled,
}

class _MiaConversationButtonState
    extends State<MiaConversationButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shineController;

  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      widget.onPressed != null &&
      widget.state != MiaConversationState.disabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_isInteractive) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _isInteractive
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: _isInteractive
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: _isInteractive
            ? () => setState(() => _pressed = false)
            : null,
        onTap: _isInteractive ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed
              ? 0.975
              : _hovered
                  ? 1.012
                  : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseController,
              _shineController,
            ]),
            builder: (context, child) {
              return _buildButton();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final double pulse =
        Curves.easeInOut.transform(_pulseController.value);

    final double glowStrength =
        widget.state == MiaConversationState.listening ||
                widget.state == MiaConversationState.speaking
            ? 0.30 + pulse * 0.18
            : 0.16 + pulse * 0.08;

    final bool active =
        widget.state == MiaConversationState.listening ||
        widget.state == MiaConversationState.speaking;

    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: _hovered ? 0.92 : 0.82,
                ),
                AppColors.secondary.withValues(
                  alpha: _hovered ? 0.88 : 0.72,
                ),
                AppColors.electricBlue.withValues(
                  alpha: 0.50,
                ),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _hovered ? 0.30 : 0.18,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: glowStrength,
                ),
                blurRadius: active ? 42 : 30,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.secondary.withValues(
                  alpha: glowStrength * 0.65,
                ),
                blurRadius: 50,
                spreadRadius: -10,
                offset: const Offset(8, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildGlassReflection(),
              _buildButtonContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassReflection() {
    final double position =
        (_shineController.value * 2.4) - 0.7;

    return Positioned.fill(
      child: FractionallySizedBox(
        widthFactor: 0.32,
        alignment: Alignment(
          position.clamp(-1.0, 1.0),
          0,
        ),
        child: Transform.rotate(
          angle: -0.25,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    final _ConversationVisual visual =
        _visualForState();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          _buildIconContainer(visual),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visual.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  visual.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildArrow(),
        ],
      ),
    );
  }

  Widget _buildIconContainer(
    _ConversationVisual visual,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha: _hovered ? 0.18 : 0.12,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(
        visual.icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  Widget _buildArrow() {
    return AnimatedSlide(
      offset: _hovered
          ? const Offset(0.12, 0)
          : Offset.zero,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(
            alpha: 0.09,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.12,
            ),
          ),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  _ConversationVisual _visualForState() {
    switch (widget.state) {
      case MiaConversationState.connecting:
        return const _ConversationVisual(
          icon: Icons.sync_rounded,
          title: 'Connecting to Mia',
          subtitle: 'Preparing your conversation…',
        );

      case MiaConversationState.listening:
        return const _ConversationVisual(
          icon: Icons.graphic_eq_rounded,
          title: 'Mia is listening',
          subtitle: 'Speak naturally — I’m here.',
        );

      case MiaConversationState.speaking:
        return const _ConversationVisual(
          icon: Icons.volume_up_rounded,
          title: 'Mia is speaking',
          subtitle: 'Listen and continue when ready.',
        );

      case MiaConversationState.disabled:
        return const _ConversationVisual(
          icon: Icons.lock_outline_rounded,
          title: 'Conversation unavailable',
          subtitle: 'Mia will be back soon.',
        );

      case MiaConversationState.idle:
        return _ConversationVisual(
          icon: Icons.mic_none_rounded,
          title: widget.label,
          subtitle: 'Practice real English with Mia.',
        );
    }
  }
}

class _ConversationVisual {
  const _ConversationVisual({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}