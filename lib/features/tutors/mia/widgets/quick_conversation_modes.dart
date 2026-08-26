import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium conversational hero for Mia.
///
/// This component is intentionally UI-first:
/// - idle state
/// - listening state
/// - thinking state
/// - speaking state
///
/// The actual microphone / speech engine can be connected later without
/// changing the visual architecture.
class MiaConversationHero extends StatefulWidget {
  const MiaConversationHero({
    super.key,
    this.onStartConversation,
    this.isListening = false,
    this.isThinking = false,
    this.isSpeaking = false,
  });

  final VoidCallback? onStartConversation;

  final bool isListening;
  final bool isThinking;
  final bool isSpeaking;

  @override
  State<MiaConversationHero> createState() =>
      _MiaConversationHeroState();
}

class _MiaConversationHeroState extends State<MiaConversationHero>
    with TickerProviderStateMixin {
  late final AnimationController _orbController;
  late final AnimationController _waveController;
  late final AnimationController _entryController;

  bool _isPressed = false;

  bool get _isActive =>
      widget.isListening ||
      widget.isThinking ||
      widget.isSpeaking;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _waveController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final double progress =
            Curves.easeOutCubic.transform(
          _entryController.value,
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              24 * (1 - progress),
            ),
            child: child,
          ),
        );
      },
      child: _buildHero(),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 30,
          sigmaY: 30,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            22,
            24,
            22,
            22,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.105,
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
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: _isActive ? 0.15 : 0.08,
                ),
                blurRadius: _isActive ? 55 : 42,
                spreadRadius: -10,
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 38,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTopLabel(),
              const SizedBox(height: 24),
              _buildOrb(),
              const SizedBox(height: 22),
              _buildStateText(),
              const SizedBox(height: 20),
              _buildWaveform(),
              const SizedBox(height: 24),
              _buildMainButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopLabel() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBright,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.55,
                ),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'MIA CONVERSATION',
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.52,
            ),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const Spacer(),
        _buildDurationBadge(),
      ],
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            Icons.schedule_rounded,
            size: 12,
            color: AppColors.textSecondary.withValues(
              alpha: 0.78,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '5–15 MIN',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: 0.78,
              ),
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        final double pulse =
            Curves.easeInOut.transform(
          _orbController.value,
        );

        final double scale =
            0.97 + (pulse * 0.045);

        return Transform.scale(
          scale: _isPressed ? 0.94 : scale,
          child: SizedBox(
            width: 184,
            height: 184,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildOuterGlow(pulse),
                _buildOrbit(pulse),
                _buildOrbCore(pulse),
                _buildOrbIcon(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOuterGlow(double pulse) {
    return Container(
      width: 168 + (pulse * 12),
      height: 168 + (pulse * 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: _isActive
                  ? 0.30 + (pulse * 0.10)
                  : 0.18 + (pulse * 0.05),
            ),
            blurRadius: _isActive
                ? 48 + (pulse * 18)
                : 34 + (pulse * 10),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: AppColors.secondary.withValues(
              alpha: _isActive
                  ? 0.18
                  : 0.10,
            ),
            blurRadius: 70,
            spreadRadius: -12,
          ),
        ],
      ),
    );
  }

  Widget _buildOrbit(double pulse) {
    return Transform.rotate(
      angle: pulse * math.pi * 0.16,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
          gradient: SweepGradient(
            colors: [
              AppColors.primaryBright.withValues(
                alpha: 0.45,
              ),
              Colors.transparent,
              AppColors.secondaryBright.withValues(
                alpha: 0.32,
              ),
              Colors.transparent,
              AppColors.primary.withValues(
                alpha: 0.30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbCore(double pulse) {
    return Container(
      width: 132 + (pulse * 5),
      height: 132 + (pulse * 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            AppColors.primaryBright,
            AppColors.primary,
            AppColors.secondary,
          ],
          stops: [
            0.0,
            0.55,
            1.0,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.18,
          ),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.34,
            ),
            blurRadius: 34,
            spreadRadius: -3,
          ),
          BoxShadow(
            color: AppColors.secondary.withValues(
              alpha: 0.22,
            ),
            blurRadius: 45,
            spreadRadius: -10,
          ),
        ],
      ),
    );
  }

  Widget _buildOrbIcon() {
    final IconData icon;

    if (widget.isListening) {
      icon = Icons.mic_rounded;
    } else if (widget.isThinking) {
      icon = Icons.auto_awesome_rounded;
    } else if (widget.isSpeaking) {
      icon = Icons.graphic_eq_rounded;
    } else {
      icon = Icons.smart_toy_rounded;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Icon(
        icon,
        key: ValueKey<IconData>(icon),
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildStateText() {
    final String title;
    final String subtitle;

    if (widget.isListening) {
      title = 'I’m listening';
      subtitle = 'Take your time. Speak naturally.';
    } else if (widget.isThinking) {
      title = 'Mia is thinking';
      subtitle = 'I’m finding the best way to help you.';
    } else if (widget.isSpeaking) {
      title = 'Mia is speaking';
      subtitle = 'Listen, then jump back in whenever you’re ready.';
    } else {
      title = 'Ready when you are';
      subtitle = 'Start a conversation and practice real English.';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Column(
        key: ValueKey<String>(title),
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: 0.70,
              ),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              25,
              (index) {
                final double phase =
                    (_waveController.value *
                            math.pi *
                            2) +
                        (index * 0.38);

                final double wave =
                    (math.sin(phase) + 1) / 2;

                final double base =
                    _isActive ? 4 : 2.5;

                final double amplitude =
                    _isActive ? 20 : 7;

                final double height =
                    base + (wave * amplitude);

                return AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 120,
                  ),
                  width: 2.5,
                  height: height,
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryBright
                            .withValues(
                          alpha: _isActive
                              ? 0.85
                              : 0.35,
                        ),
                        AppColors.secondary
                            .withValues(
                          alpha: _isActive
                              ? 0.55
                              : 0.18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onTap: widget.onStartConversation,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1,
          duration: const Duration(
            milliseconds: 160,
          ),
          curve: Curves.easeOutCubic,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
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
                    alpha: 0.25,
                  ),
                  blurRadius: 28,
                  spreadRadius: -5,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isListening
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isListening
                      ? 'Finish speaking'
                      : 'Start conversation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(width: 9),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}