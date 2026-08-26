import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium animated avatar for Mia.
///
/// This widget is intentionally self-contained:
///
/// • animated atmospheric glow
/// • orbital rings
/// • floating particles
/// • Liquid Glass shell
/// • breathing animation
/// • hover interaction on desktop
/// • press interaction on touch
/// • live tutor status
///
/// It does not contain navigation or business logic.
/// The parent screen remains responsible for those concerns.
class MiaAvatar extends StatefulWidget {
  const MiaAvatar({
    super.key,
    this.size = 220,
    this.isActive = true,
    this.showStatus = true,
    this.onTap,
  });

  /// Main visual size of the avatar.
  final double size;

  /// Controls the intensity of the active tutor animation.
  final bool isActive;

  /// Displays the small status indicator below the avatar.
  final bool showStatus;

  /// Optional interaction callback.
  final VoidCallback? onTap;

  @override
  State<MiaAvatar> createState() => _MiaAvatarState();
}

class _MiaAvatarState extends State<MiaAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _orbitController;
  late final AnimationController _particleController;
  late final AnimationController _interactionController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _orbitController.dispose();
    _particleController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });

    if (value) {
      _interactionController.forward();
    } else {
      _interactionController.reverse();
    }
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
    final double visualSize = widget.size.clamp(
      150.0,
      320.0,
    );

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => _setPressed(true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => _setPressed(false),
        onTapCancel: widget.onTap == null
            ? null
            : () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _ambientController,
            _orbitController,
            _particleController,
            _interactionController,
          ]),
          builder: (context, child) {
            final double pulse =
                _ambientController.value;

            final double interaction =
                _interactionController.value;

            final double scale = _isPressed
                ? 0.965
                : 1.0 + (interaction * 0.018);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: visualSize + 80,
                height: visualSize + 100,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildOuterAtmosphere(
                      visualSize,
                      pulse,
                      interaction,
                    ),
                    _buildOrbitalSystem(
                      visualSize,
                    ),
                    _buildParticles(
                      visualSize,
                    ),
                    _buildCoreAvatar(
                      visualSize,
                      pulse,
                      interaction,
                    ),
                    if (widget.showStatus)
                      _buildStatusBadge(
                        visualSize,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // ATMOSPHERE
  // ===========================================================================

  Widget _buildOuterAtmosphere(
    double size,
    double pulse,
    double interaction,
  ) {
    final double base = size * 0.82;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: base * 1.18,
          height: base * 1.18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.12 +
                      (pulse * 0.08) +
                      (interaction * 0.08),
                ),
                blurRadius: 100,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        Container(
          width: base,
          height: base,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.18 +
                      (pulse * 0.07),
                ),
                AppColors.secondary.withValues(
                  alpha: 0.07,
                ),
                Colors.transparent,
              ],
              stops: const [
                0.0,
                0.48,
                1.0,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ORBITAL SYSTEM
  // ===========================================================================

  Widget _buildOrbitalSystem(double size) {
    return Transform.rotate(
      angle: _orbitController.value *
          math.pi *
          2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildOrbit(
            diameter: size * 0.92,
            opacity: 0.18,
            strokeWidth: 1,
            dashCount: 3,
          ),
          Transform.rotate(
            angle: math.pi / 2.4,
            child: _buildOrbit(
              diameter: size * 1.05,
              opacity: 0.10,
              strokeWidth: 1,
              dashCount: 2,
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: _buildOrbit(
              diameter: size * 1.16,
              opacity: 0.075,
              strokeWidth: 0.8,
              dashCount: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbit({
    required double diameter,
    required double opacity,
    required double strokeWidth,
    required int dashCount,
  }) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _OrbitPainter(
          color: AppColors.primaryBright
              .withValues(alpha: opacity),
          strokeWidth: strokeWidth,
          dashCount: dashCount,
        ),
      ),
    );
  }

  // ===========================================================================
  // PARTICLES
  // ===========================================================================

  Widget _buildParticles(double size) {
    return SizedBox(
      width: size * 1.25,
      height: size * 1.25,
      child: CustomPaint(
        painter: _ParticlePainter(
          progress: _particleController.value,
          primary: AppColors.primaryBright,
          secondary: AppColors.secondaryBright,
        ),
      ),
    );
  }

  // ===========================================================================
  // CORE AVATAR
  // ===========================================================================

  Widget _buildCoreAvatar(
    double size,
    double pulse,
    double interaction,
  ) {
    final double avatarSize =
        size * 0.62;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Deep glow.
        Container(
          width: avatarSize * 1.12,
          height: avatarSize * 1.12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.25 +
                      (pulse * 0.10) +
                      (interaction * 0.08),
                ),
                blurRadius: 48,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.secondary.withValues(
                  alpha: 0.14 +
                      (pulse * 0.06),
                ),
                blurRadius: 70,
                spreadRadius: -4,
              ),
            ],
          ),
        ),

        // Glass outer shell.
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16,
              sigmaY: 16,
            ),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(
                      alpha: 0.16,
                    ),
                    AppColors.primary.withValues(
                      alpha: 0.22,
                    ),
                    AppColors.secondary.withValues(
                      alpha: 0.14,
                    ),
                    Colors.white.withValues(
                      alpha: 0.045,
                    ),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.25,
                  ),
                  width: 1.4,
                ),
              ),
              child: _buildAvatarCore(
                avatarSize,
                pulse,
              ),
            ),
          ),
        ),

        // Fine glass highlight.
        Positioned(
          top: avatarSize * 0.085,
          left: avatarSize * 0.16,
          child: Container(
            width: avatarSize * 0.26,
            height: avatarSize * 0.10,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(100),
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCore(
    double size,
    double pulse,
  ) {
    final double iconSize = size * 0.34;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner energy field.
        Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primaryBright.withValues(
                  alpha: 0.38 +
                      (pulse * 0.08),
                ),
                AppColors.primary.withValues(
                  alpha: 0.18,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Central gradient.
        Container(
          width: size * 0.66,
          height: size * 0.66,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBright,
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.55,
                height: size * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ],
          ),
        ),

        // Small AI core.
        Positioned(
          bottom: size * 0.17,
          child: Container(
            width: size * 0.11,
            height: size * 0.11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: 0.65,
                  ),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STATUS
  // ===========================================================================

  Widget _buildStatusBadge(double size) {
    final double badgeWidth =
        math.min(size * 0.72, 155);

    return Positioned(
      bottom: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            width: badgeWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(
                    alpha: 0.10,
                  ),
                  Colors.white.withValues(
                    alpha: 0.045,
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.13,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLiveDot(),
                const SizedBox(width: 8),
                const Text(
                  'MIA IS READY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveDot() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final double pulse =
            _ambientController.value;

        return Container(
          width: 7 + (pulse * 2),
          height: 7 + (pulse * 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(
                  alpha: 0.30 +
                      (pulse * 0.25),
                ),
                blurRadius: 10 +
                    (pulse * 5),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// ORBIT PAINTER
// =============================================================================

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  final Color color;
  final double strokeWidth;
  final int dashCount;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        size.width / 2;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final double segment =
        (math.pi * 2) /
            (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final double start =
          i * segment * 2;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        start,
        segment,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _OrbitPainter oldDelegate,
  ) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashCount != dashCount;
  }
}

// =============================================================================
// PARTICLE PAINTER
// =============================================================================

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  static const List<_Particle> _particles = [
    _Particle(
      angle: 0.15,
      radius: 0.48,
      size: 2.0,
      phase: 0.1,
    ),
    _Particle(
      angle: 0.82,
      radius: 0.58,
      size: 1.5,
      phase: 0.5,
    ),
    _Particle(
      angle: 1.46,
      radius: 0.51,
      size: 2.4,
      phase: 0.25,
    ),
    _Particle(
      angle: 2.18,
      radius: 0.62,
      size: 1.7,
      phase: 0.72,
    ),
    _Particle(
      angle: 2.92,
      radius: 0.50,
      size: 2.1,
      phase: 0.36,
    ),
    _Particle(
      angle: 3.55,
      radius: 0.59,
      size: 1.4,
      phase: 0.84,
    ),
    _Particle(
      angle: 4.24,
      radius: 0.53,
      size: 2.2,
      phase: 0.15,
    ),
    _Particle(
      angle: 4.92,
      radius: 0.61,
      size: 1.6,
      phase: 0.58,
    ),
    _Particle(
      angle: 5.55,
      radius: 0.49,
      size: 2.0,
      phase: 0.92,
    ),
  ];

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        size.width / 2;

    for (int i = 0;
        i < _particles.length;
        i++) {
      final _Particle particle =
          _particles[i];

      final double movement =
          math.sin(
            (progress * math.pi * 2) +
                particle.phase * math.pi * 2,
          );

      final double angle =
          particle.angle +
              (progress * 0.35);

      final double distance =
          radius *
              (particle.radius +
                  movement * 0.025);

      final Offset position = Offset(
        center.dx +
            math.cos(angle) * distance,
        center.dy +
            math.sin(angle) * distance,
      );

      final double opacity =
          0.30 +
              ((movement + 1) / 2) * 0.55;

      final Paint paint = Paint()
        ..color =
            (i.isEven ? primary : secondary)
                .withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2,
        );

      canvas.drawCircle(
        position,
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ParticlePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.phase,
  });

  final double angle;
  final double radius;
  final double size;
  final double phase;
}