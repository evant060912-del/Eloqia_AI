import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class OnboardingBackground extends StatefulWidget {
  final Widget child;

  const OnboardingBackground({
    super.key,
    required this.child,
  });

  @override
  State<OnboardingBackground> createState() =>
      _OnboardingBackgroundState();
}

class _OnboardingBackgroundState
    extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
        return Stack(
          fit: StackFit.expand,
          children: [
            const _BaseBackground(),

            _AnimatedGlow(
              alignment: Alignment.topLeft,
              color: AppColors.primary,
              size: 460,
              animationValue: _controller.value,
              offset: const Offset(-170, -150),
            ),

            _AnimatedGlow(
              alignment: Alignment.bottomRight,
              color: AppColors.secondary,
              size: 500,
              animationValue: _controller.value,
              offset: const Offset(180, 160),
            ),

            _AnimatedGlow(
              alignment: Alignment.center,
              color: AppColors.primary,
              size: 280,
              animationValue: _controller.value,
              offset: Offset(
                math.sin(
                      _controller.value * math.pi * 2,
                    ) *
                    100,
                math.cos(
                      _controller.value * math.pi * 2,
                    ) *
                    70,
              ),
            ),

            Positioned.fill(
              child: CustomPaint(
                painter: _ParticlePainter(
                  progress: _controller.value,
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 0.25,
                    sigmaY: 0.25,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _BaseBackground extends StatelessWidget {
  const _BaseBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            Color.lerp(
              AppColors.background,
              AppColors.primary,
              0.045,
            )!,
            AppColors.background,
            Color.lerp(
              AppColors.background,
              AppColors.secondary,
              0.04,
            )!,
          ],
          stops: const [
            0,
            0.3,
            0.68,
            1,
          ],
        ),
      ),
    );
  }
}

class _AnimatedGlow extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double animationValue;
  final Offset offset;

  const _AnimatedGlow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.animationValue,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final double pulse =
        1 + math.sin(animationValue * math.pi * 2) * 0.055;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: pulse,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                  stops: const [
                    0,
                    0.42,
                    1,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(19);

    for (int i = 0; i < 45; i++) {
      final double baseX = random.nextDouble() * size.width;
      final double baseY = random.nextDouble() * size.height;

      final double movementX =
          math.sin(
                progress * math.pi * 2 + i * 0.7,
              ) *
              12;

      final double movementY =
          math.cos(
                progress * math.pi * 2 + i * 0.5,
              ) *
              9;

      final double radius =
          0.5 + random.nextDouble() * 1.6;

      final double opacity =
          0.035 + random.nextDouble() * 0.11;

      final Paint paint = Paint()
        ..color = (i.isEven
                ? AppColors.primary
                : AppColors.secondary)
            .withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(
          baseX + movementX,
          baseY + movementY,
        ),
        radius,
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