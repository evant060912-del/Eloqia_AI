import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium conversation entry point for Mia.
///
/// This widget is intentionally UI-focused:
/// - it does not contain AI logic;
/// - it does not depend on audio services;
/// - it exposes callbacks for future voice integration.
///
/// Future architecture:
///
///     MiaConversationCard
///             ↓
///     Voice / Conversation Controller
///             ↓
///     Whisper + LLM + TTS
///
/// The visual component can therefore remain stable while
/// the conversational engine evolves underneath it.
class MiaConversationCard extends StatefulWidget {
  const MiaConversationCard({
    super.key,
    this.onStartConversation,
    this.onPracticeSpeaking,
    this.isAvailable = true,
  });

  final VoidCallback? onStartConversation;
  final VoidCallback? onPracticeSpeaking;
  final bool isAvailable;

  @override
  State<MiaConversationCard> createState() =>
      _MiaConversationCardState();
}

class _MiaConversationCardState extends State<MiaConversationCard>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 4200,
      ),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
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
    _pulseController.dispose();
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

  void _handleTap() {
    if (!widget.isAvailable) {
      return;
    }

    widget.onStartConversation?.call();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed
        ? 0.985
        : _isHovered
            ? 1.008
            : 1.0;

    return MouseRegion(
      cursor: widget.isAvailable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isAvailable
            ? (_) => _setPressed(true)
            : null,
        onTapUp: widget.isAvailable
            ? (_) => _setPressed(false)
            : null,
        onTapCancel: widget.isAvailable
            ? () => _setPressed(false)
            : null,
        onTap: _handleTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(
            milliseconds: 190,
          ),
          curve: Curves.easeOutCubic,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ambientController,
        _pulseController,
        _entryController,
      ]),
      builder: (context, child) {
        final double ambient =
            Curves.easeInOut.transform(
          _ambientController.value,
        );

        final double pulse =
            Curves.easeInOut.transform(
          _pulseController.value,
        );

        final double entry =
            Curves.easeOutCubic.transform(
          _entryController.value,
        );

        return Opacity(
          opacity: entry,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - entry),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 30,
                  sigmaY: 30,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(
                          alpha: _isHovered
                              ? 0.16
                              : 0.105,
                        ),
                        AppColors.secondary.withValues(
                          alpha:
                              0.07 +
                              (ambient * 0.025),
                        ),
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
                        alpha: _isHovered
                            ? 0.20
                            : 0.105,
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(
                          alpha:
                              (_isHovered
                                      ? 0.24
                                      : 0.13) +
                                  (pulse * 0.035),
                        ),
                        blurRadius:
                            _isHovered ? 55 : 42,
                        spreadRadius: -8,
                        offset: const Offset(
                          0,
                          18,
                        ),
                      ),
                      BoxShadow(
                        color:
                            AppColors.shadow.withValues(
                          alpha: 0.62,
                        ),
                        blurRadius: 42,
                        offset: const Offset(
                          0,
                          22,
                        ),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      _buildBackgroundOrb(
                        alignment:
                            Alignment.topRight,
                        size: 190,
                        color:
                            AppColors.primaryBright,
                        opacity:
                            0.075 +
                            (ambient * 0.035),
                        offset:
                            const Offset(55, -65),
                      ),
                      _buildBackgroundOrb(
                        alignment:
                            Alignment.bottomLeft,
                        size: 170,
                        color:
                            AppColors.secondary,
                        opacity: 0.055,
                        offset:
                            const Offset(-50, 55),
                      ),
                      child!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: _buildContent(),
    );
  }

  Widget _buildBackgroundOrb({
    required Alignment alignment,
    required double size,
    required Color color,
    required double opacity,
    required Offset offset,
  }) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 50,
              sigmaY: 50,
            ),
            child: Container(
              width: size,
              height: size,
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
    return Padding(
      padding: const EdgeInsets.all(23),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 24),
          _buildHeadline(),
          const SizedBox(height: 21),
          _buildVoiceOrb(),
          const SizedBox(height: 21),
          _buildExperienceHint(),
          const SizedBox(height: 20),
          _buildStartButton(),
          const SizedBox(height: 12),
          _buildSecondaryAction(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        _buildMiniMiaIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'MIA LIVE',
                style: TextStyle(
                  color:
                      AppColors.primaryBright.withValues(
                    alpha: 0.82,
                  ),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.9,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Speak with Mia',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                ),
              ),
            ],
          ),
        ),
        _buildLiveBadge(),
      ],
    );
  }

  Widget _buildMiniMiaIcon() {
    return Container(
      width: 46,
      height: 46,
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
            alpha: 0.17,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primary.withValues(
              alpha: 0.27,
            ),
            blurRadius: 28,
            spreadRadius: -3,
          ),
        ],
      ),
      child: const Icon(
        Icons.mic_rounded,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 250,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: widget.isAvailable
            ? AppColors.success.withValues(
                alpha: 0.075,
              )
            : Colors.white.withValues(
                alpha: 0.045,
              ),
        border: Border.all(
          color: widget.isAvailable
              ? AppColors.success.withValues(
                  alpha: 0.19,
                )
              : Colors.white.withValues(
                  alpha: 0.08,
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
              color: widget.isAvailable
                  ? AppColors.success
                  : AppColors.textSecondary,
              boxShadow: widget.isAvailable
                  ? [
                      BoxShadow(
                        color:
                            AppColors.success
                                .withValues(
                          alpha: 0.45,
                        ),
                        blurRadius: 9,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isAvailable
                ? 'READY'
                : 'SOON',
            style: TextStyle(
              color: widget.isAvailable
                  ? AppColors.success
                  : AppColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Your English.\nYour voice. Your moment.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.05,
          ),
        ),
        const SizedBox(height: 11),
        Text(
          'Have a natural conversation with Mia, '
          'practice real English, and grow your confidence '
          'one exchange at a time.',
          style: TextStyle(
            color:
                AppColors.textSecondary.withValues(
              alpha: 0.73,
            ),
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceOrb() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final double pulse =
              Curves.easeInOut.transform(
            _pulseController.value,
          );

          return SizedBox(
            width: 138,
            height: 138,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width:
                      112 + (pulse * 10),
                  height:
                      112 + (pulse * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        AppColors.primary.withValues(
                      alpha:
                          0.045 +
                          (pulse * 0.025),
                    ),
                  ),
                ),
                Container(
                  width:
                      91 + (pulse * 5),
                  height:
                      91 + (pulse * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBright,
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    border: Border.all(
                      color:
                          Colors.white.withValues(
                        alpha: 0.20,
                      ),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(
                          alpha:
                              0.24 +
                              (pulse * 0.08),
                        ),
                        blurRadius:
                            32 + (pulse * 10),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                ..._buildSoundWaves(pulse),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSoundWaves(
    double pulse,
  ) {
    return [
      Positioned(
        top: 8,
        child: _SoundWave(
          width: 34 + (pulse * 6),
          opacity: 0.24,
        ),
      ),
      Positioned(
        bottom: 8,
        child: _SoundWave(
          width: 28 + (pulse * 5),
          opacity: 0.16,
        ),
      ),
    ];
  }

  Widget _buildExperienceHint() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBright,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mia adapts the conversation to your '
              'level, goals, and learning style.',
              style: TextStyle(
                color:
                    AppColors.textSecondary
                        .withValues(
                  alpha: 0.70,
                ),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.primary,
              AppColors.primaryBright,
              AppColors.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.primary.withValues(
                alpha: _isHovered
                    ? 0.34
                    : 0.20,
              ),
              blurRadius:
                  _isHovered ? 34 : 25,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: widget.isAvailable
              ? _handleTap
              : null,
          style: FilledButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            disabledBackgroundColor:
                Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor:
                Colors.white.withValues(
              alpha: 0.42,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_rounded,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                widget.isAvailable
                    ? 'Start conversation'
                  : 'Voice setup required',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.isAvailable) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: widget.isAvailable
            ? widget.onPracticeSpeaking
            : null,
        style: TextButton.styleFrom(
          foregroundColor:
              AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              size: 15,
              color: AppColors.textSecondary
                  .withValues(
                alpha: 0.70,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Practice speaking',
              style: TextStyle(
                color:
                    AppColors.textSecondary
                        .withValues(
                  alpha: 0.72,
                ),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative audio wave used inside the Mia voice orb.
class _SoundWave extends StatelessWidget {
  const _SoundWave({
    required this.width,
    required this.opacity,
  });

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10),
        color: Colors.white.withValues(
          alpha: opacity,
        ),
      ),
    );
  }
}