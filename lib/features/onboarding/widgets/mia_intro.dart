import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class MiaIntro extends StatefulWidget {
  const MiaIntro({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  State<MiaIntro> createState() => _MiaIntroState();
}

class _MiaIntroState extends State<MiaIntro> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _particleController;
  late final AnimationController _buttonController;

  late final Animation<double> _imageOpacity;
  late final Animation<double> _imageScale;
  late final Animation<double> _imageBlur;
  late final Animation<Offset> _imageSlide;

  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final CurvedAnimation entranceCurve = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _imageOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.84, curve: Curves.easeOut),
      ),
    );

    _imageScale = Tween<double>(begin: 1.075, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _imageBlur = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.40, 0.82, curve: Curves.easeOut),
      ),
    );

    _imageSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(entranceCurve);

    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.62, 0.98, curve: Curves.easeOut),
      ),
    );

    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.58, 0.98, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _particleController.dispose();
    _buttonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool compact = height < 720;
          final bool veryCompact = height < 620;
          final bool wide = width >= 900;

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildCinematicBackdrop(),

              _buildAtmosphericParticles(),

              SafeArea(
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return _buildMainExperience(
                      width: width,
                      height: height,
                      compact: compact,
                      veryCompact: veryCompact,
                      wide: wide,
                    );
                  },
                ),
              ),

              _buildTopInterface(),

              _buildBottomGlow(),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // CINEMATIC BACKGROUND
  // ===========================================================================

  Widget _buildCinematicBackdrop() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final double t = _ambientController.value * math.pi * 2;

        final double x = math.sin(t * 0.72) * 35;
        final double y = math.cos(t * 0.48) * 28;

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF070912),
                    const Color(0xFF090B17),
                    const Color(0xFF05060C),
                  ],
                ),
              ),
            ),

            Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6EE7F9).withValues(alpha: 0.18),
                      const Color(0xFF8B7CFF).withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            Align(
              alignment: const Alignment(0.85, -0.35),
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B7CFF).withValues(alpha: 0.11),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.50, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // PARTICLES
  // ===========================================================================

  Widget _buildAtmosphericParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _MiaParticlesPainter(progress: _particleController.value),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MAIN EXPERIENCE
  // ===========================================================================

  Widget _buildMainExperience({
    required double width,
    required double height,
    required bool compact,
    required bool veryCompact,
    required bool wide,
  }) {
    final double horizontalPadding = wide ? 56 : 20;
    final double availableWidth = width - (horizontalPadding * 2);
    final double imageWidth = wide
        ? math.min(availableWidth * 0.46, 560)
        : math.min(width * 0.82, 500);

    final double imageHeight = veryCompact
        ? height * 0.42
        : compact
        ? height * 0.50
        : wide
        ? math.min(height * 0.74, 620)
        : height * 0.59;

    final double dialogueWidth = wide
        ? math.min(availableWidth - imageWidth - 32, 600)
        : math.min(width - 36, 720);
    final double buttonWidth = wide
        ? math.min(dialogueWidth, 390)
        : math.min(width - 36, 390);

    final Widget hero = SlideTransition(
      position: _imageSlide,
      child: FadeTransition(
        opacity: _imageOpacity,
        child: _buildMiaHero(width: imageWidth, height: imageHeight),
      ),
    );

    final Widget introduction = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SlideTransition(
          position: _contentSlide,
          child: FadeTransition(
            opacity: _contentOpacity,
            child: _buildDialogue(width: dialogueWidth, compact: compact),
          ),
        ),
        SizedBox(
          height: wide
              ? 24
              : veryCompact
              ? 14
              : compact
              ? 18
              : 26,
        ),
        FadeTransition(
          opacity: _contentOpacity,
          child: _buildContinueButton(width: buttonWidth),
        ),
      ],
    );

    final Widget content = wide
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hero,
              const SizedBox(width: 32),
              SizedBox(width: dialogueWidth, child: introduction),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              hero,
              SizedBox(
                height: veryCompact
                    ? 16
                    : compact
                    ? 20
                    : 28,
              ),
              introduction,
            ],
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              veryCompact ? 46 : 58,
              horizontalPadding,
              24,
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MIA HERO
  // ===========================================================================

  Widget _buildMiaHero({required double width, required double height}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ambientController, _buttonController]),
      builder: (context, child) {
        final double ambient =
            math.sin(_ambientController.value * math.pi * 2) * 3;

        final double pulse =
            1.0 + math.sin(_buttonController.value * math.pi) * 0.006;

        return Transform.translate(
          offset: Offset(0, ambient),
          child: Transform.scale(
            scale: pulse * _imageScale.value,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: width * 0.86,
                    height: height * 0.92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(46),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6EE7F9,
                          ).withValues(alpha: 0.18),
                          blurRadius: 90,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF8B7CFF,
                          ).withValues(alpha: 0.13),
                          blurRadius: 120,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(46),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _imageBlur.value,
                        sigmaY: _imageBlur.value,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/tutors/mia/mia.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                          ),

                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.02),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.12),
                                  Colors.black.withValues(alpha: 0.54),
                                ],
                                stops: const [0.0, 0.30, 0.70, 1.0],
                              ),
                            ),
                          ),

                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.18),
                                radius: 0.72,
                                colors: [
                                  Colors.white.withValues(alpha: 0.055),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 18,
                            left: 22,
                            right: 22,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.42),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(46),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(top: 22, left: 22, child: _buildLiveBadge()),

                  Positioned(right: 22, top: 22, child: _buildAiIndicator()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulsingDot(),
              SizedBox(width: 7),
              Text(
                'MIA · YOUR TUTOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiIndicator() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF8BE9F7),
        size: 17,
      ),
    );
  }

  // ===========================================================================
  // DIALOGUE
  // ===========================================================================

  Widget _buildDialogue({required double width, required bool compact}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 26,
            compact ? 18 : 22,
            compact ? 20 : 26,
            compact ? 19 : 23,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.095),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 45,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: const Color(0xFF6EE7F9).withValues(alpha: 0.035),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6EE7F9), Color(0xFF8B7CFF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    'MIA',
                    style: TextStyle(
                      color: const Color(0xFF8BE9F7),
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'YOUR AI ENGLISH TUTOR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.27),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                "Hey! I'm Mia. 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.08,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Welcome to Eloqia. First, I’ll learn what matters to you '
                'and how you learn best. Then, we’ll shape a path that feels like yours.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: compact ? 12 : 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 9),

              Container(
                padding: const EdgeInsets.only(top: 9),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.055),
                    ),
                  ),
                ),
                child: Text(
                  '« Bienvenue sur Eloqia. On va construire ton parcours ensemble. »',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CTA
  // ===========================================================================

  Widget _buildContinueButton({required double width}) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        final double glow = 0.18 + (_buttonController.value * 0.08);

        return Container(
          width: width,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6EE7F9).withValues(alpha: glow),
                blurRadius: 34,
                spreadRadius: -5,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF58DDF1),
                  Color(0xFF7D8CFF),
                  Color(0xFF9B72FF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: widget.onContinue,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "LET'S BEGIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TOP UI
  // ===========================================================================

  Widget _buildTopInterface() {
    return Positioned(
      top: 18,
      left: 22,
      right: 22,
      child: IgnorePointer(
        child: Row(
          children: [
            Hero(tag: 'eloqia-brand-mark', child: _buildGlassMark()),
            const Spacer(),
            _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassMark() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFF8BE9F7),
        size: 18,
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        'PERSONALIZED EXPERIENCE',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildBottomGlow() {
    return Positioned(
      bottom: -100,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6EE7F9).withValues(alpha: 0.09),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PARTICLE PAINTER
// ============================================================================

class _MiaParticlesPainter extends CustomPainter {
  static const List<_Particle> _particles = [
    _Particle(0.12, 0.25, 0.8, 2.0, 0.0),
    _Particle(0.82, 0.20, 1.1, 1.7, 0.12),
    _Particle(0.17, 0.68, 0.7, 2.2, 0.24),
    _Particle(0.89, 0.72, 0.9, 1.5, 0.36),
    _Particle(0.72, 0.47, 0.55, 2.5, 0.48),
    _Particle(0.28, 0.40, 0.65, 1.8, 0.60),
    _Particle(0.60, 0.17, 0.5, 2.1, 0.72),
    _Particle(0.42, 0.82, 0.8, 1.6, 0.84),
  ];

  _MiaParticlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final _Particle particle in _particles) {
      final double phase =
          (progress * particle.speed + particle.phaseOffset) % 1.0;

      final double opacity = 0.10 + (math.sin(phase * math.pi * 2) + 1) * 0.10;

      paint.color = const Color(0xFF8BE9F7).withValues(alpha: opacity);

      final double x = size.width * particle.x;
      final double y = size.height * ((particle.y + phase * 0.05) % 1.0);

      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiaParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  const _Particle(this.x, this.y, this.radius, this.speed, this.phaseOffset);

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phaseOffset;
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 6 + (_controller.value * 2),
          height: 6 + (_controller.value * 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6EE7F9),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6EE7F9).withValues(alpha: 0.5),
                blurRadius: 9,
              ),
            ],
          ),
        );
      },
    );
  }
}
