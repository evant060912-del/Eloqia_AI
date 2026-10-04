import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../app/persistent_app_controller.dart';
import '../../app/persistent_app_state.dart';
import '../onboarding/mia_welcome_screen.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final AnimationController _orbitalController;
  late final AnimationController _pulseController;
  late final AnimationController _particleController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final Animation<double> _logoSweep;
  late final Animation<double> _contentFade;
  late final Animation<double> _contentSlide;
  late final Animation<double> _ringFade;
  late final Animation<double> _ringScale;

  final List<_SplashParticle> _particles = <_SplashParticle>[];

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _createParticles();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _logoSweep = Tween<double>(begin: -1.45, end: 1.45).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.28, 0.76, curve: Curves.easeInOutCubic),
      ),
    );

    _ringFade = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.08, 0.55, curve: Curves.easeOut),
    );

    _ringScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
    );

    _contentSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.42, 0.86, curve: Curves.easeOutCubic),
      ),
    );

    _masterController.forward();

    _scheduleNavigation();
  }

  void _createParticles() {
    final math.Random random = math.Random(42);

    for (int i = 0; i < 38; i++) {
      _particles.add(
        _SplashParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: 0.7 + random.nextDouble() * 2.0,
          opacity: 0.12 + random.nextDouble() * 0.42,
          speed: 0.25 + random.nextDouble() * 0.75,
          phase: random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _scheduleNavigation() {
    _navigationTimer = Timer(
      const Duration(milliseconds: 5200),
      _resolveDestination,
    );
  }

  void _resolveDestination() {
    if (!mounted || _hasNavigated) {
      return;
    }

    final PersistentAppState state = PersistentAppController.instance.state;

    switch (state.status) {
      case PersistentAppStatus.ready:
        _openHome();
        break;

      case PersistentAppStatus.firstLaunch:
        _openMiaWelcome();
        break;

      case PersistentAppStatus.onboardingRequired:
      case PersistentAppStatus.unknown:
        _openOnboarding();
        break;
    }
  }

  void _openHome() {
    _navigateTo(const AppShell());
  }

  void _openOnboarding() {
    _navigateTo(const OnboardingScreen());
  }

  void _openMiaWelcome() {
    _navigateTo(const MiaWelcomeScreen());
  }

  void _navigateTo(Widget destination) {
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 1100),
        reverseTransitionDuration: const Duration(milliseconds: 700),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return destination;
            },
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return Opacity(
                opacity: 0.65 + 0.35 * curvedAnimation.value,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 1.035,
                    end: 1.0,
                  ).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _masterController.dispose();
    _orbitalController.dispose();
    _pulseController.dispose();
    _particleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final bool isDesktop = width >= 900;

          final double logoSize = isDesktop
              ? math.min(width * 0.42, 390)
              : math.min(width * 0.72, 330);

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _buildBackground(width, height),
              _buildParticles(),
              _buildAmbientGlow(width, height),
              _buildOrbitalSystem(logoSize),
              _buildMainContent(logoSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(double width, double height) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.12),
          radius: 1.15,
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.075),
            AppColors.background,
            Colors.black.withValues(alpha: 0.22),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ),
      ),
      child: CustomPaint(painter: _BackgroundGridPainter()),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildAmbientGlow(double width, double height) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _pulseController,
        _masterController,
      ]),
      builder: (BuildContext context, Widget? child) {
        final double pulse = 0.88 + (_pulseController.value * 0.12);

        final double glow = _logoGlow.value * pulse;

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: width * 0.62 * pulse,
              height: width * 0.62 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.primary.withValues(alpha: 0.12 * glow),
                    AppColors.secondary.withValues(alpha: 0.055 * glow),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.42, 1.0],
                ),
              ),
            ),
            Container(
              width: width * 0.38 * pulse,
              height: width * 0.38 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16 * glow),
                    blurRadius: 110,
                    spreadRadius: 30,
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.08 * glow),
                    blurRadius: 160,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrbitalSystem(double logoSize) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _orbitalController,
        _ringFade,
        _ringScale,
      ]),
      builder: (BuildContext context, Widget? child) {
        final double baseSize = logoSize * 1.22 * _ringScale.value;

        return Center(
          child: Opacity(
            opacity: _ringFade.value,
            child: Transform.rotate(
              angle: _orbitalController.value * math.pi * 2,
              child: SizedBox(
                width: baseSize,
                height: baseSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _buildRing(size: baseSize, opacity: 0.16, strokeWidth: 1.0),
                    _buildRing(
                      size: baseSize * 0.86,
                      opacity: 0.10,
                      strokeWidth: 1.0,
                    ),
                    Transform.rotate(
                      angle: math.pi / 2,
                      child: _buildRing(
                        size: baseSize * 0.70,
                        opacity: 0.08,
                        strokeWidth: 1.0,
                      ),
                    ),
                    _buildOrbitalDot(
                      size: baseSize,
                      angle: _orbitalController.value * math.pi * 2,
                    ),
                    _buildOrbitalDot(
                      size: baseSize * 0.86,
                      angle: -_orbitalController.value * math.pi * 4 + 1.4,
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

  Widget _buildRing({
    required double size,
    required double opacity,
    required double strokeWidth,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: strokeWidth,
        ),
      ),
    );
  }

  Widget _buildOrbitalDot({required double size, required double angle}) {
    final double radius = size / 2;

    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.8),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double logoSize) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _masterController,
          _pulseController,
        ]),
        builder: (BuildContext context, Widget? child) {
          final double pulse =
              1.0 + math.sin(_pulseController.value * math.pi * 2) * 0.018;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Opacity(
                key: const ValueKey<String>('splash-logo-visible'),
                opacity: 0.42 + 0.58 * _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value * pulse,
                  child: Hero(
                    tag: 'eloqia-brand-mark',
                    child: _buildLogo(logoSize),
                  ),
                ),
              ),
              const SizedBox(height: 38),
              Opacity(
                opacity: 0.55 + 0.45 * _contentFade.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: _buildBranding(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.28 * _logoGlow.value,
                  ),
                  blurRadius: 64,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(
                    alpha: 0.15 * _logoGlow.value,
                  ),
                  blurRadius: 96,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          ClipOval(
            child: AnimatedBuilder(
              animation: _logoSweep,
              builder: (BuildContext context, Widget? child) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    child!,
                    Align(
                      alignment: Alignment(_logoSweep.value, 0),
                      child: Transform.rotate(
                        angle: -0.32,
                        child: Container(
                          width: size * 0.18,
                          height: size * 1.2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0.30),
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                              stops: const <double>[0.0, 0.28, 0.5, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: Image.asset(
                'assets/branding/logo/eloqia_logo_concept_v1.png',
                key: const ValueKey<String>('eloqia-logo-full'),
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 28,
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 13),
            Text(
              'YOUR AI LANGUAGE ACADEMY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(width: 13),
            Container(
              width: 28,
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _masterController.value,
              minHeight: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashParticle {
  const _SplashParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double opacity;
  final double speed;
  final double phase;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.particles, required this.progress});

  final List<_SplashParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _SplashParticle particle in particles) {
      final double drift =
          math.sin(progress * math.pi * 2 * particle.speed + particle.phase) *
          10;

      final double vertical = (progress * 32 * particle.speed) % size.height;

      final double x = particle.x * size.width + drift;

      final double y = (particle.y * size.height + vertical) % size.height;

      final Paint paint = Paint()
        ..color = Colors.white.withValues(alpha: particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.012)
      ..strokeWidth = 0.5;

    const double spacing = 72;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundGridPainter oldDelegate) {
    return false;
  }
}
