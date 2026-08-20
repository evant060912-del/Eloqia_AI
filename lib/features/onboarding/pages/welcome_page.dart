import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomePage({
    super.key,
    required this.onContinue,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _orbController;
  late final AnimationController _buttonController;

  late final Animation<double> _logoAnimation;
  late final Animation<double> _contentAnimation;
  late final Animation<double> _buttonAnimation;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _logoAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(
        0.0,
        0.45,
        curve: Curves.easeOutCubic,
      ),
    );

    _contentAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(
        0.2,
        0.72,
        curve: Curves.easeOutCubic,
      ),
    );

    _buttonAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(
        0.58,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _orbController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!mounted) {
      return;
    }

    setState(() {
      _pressed = value;
    });

    if (value) {
      _buttonController.forward();
    } else {
      _buttonController.reverse();
    }
  }

  void _continue() {
    if (_pressed) {
      _setPressed(false);
    }

    FocusScope.of(context).unfocus();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 800;
        final bool isCompact = constraints.maxHeight < 720;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _entryController,
            _orbController,
          ]),
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildAtmosphere(),

                _buildOrb(
                  size: isWide ? 480 : 380,
                  alignment: Alignment.topRight,
                  offset: const Offset(130, -120),
                  phase: 0,
                ),

                _buildOrb(
                  size: isWide ? 390 : 300,
                  alignment: Alignment.bottomLeft,
                  offset: const Offset(-110, 120),
                  phase: math.pi,
                ),

                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 48 : 24,
                        vertical: isCompact ? 24 : 42,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 920 : 620,
                        ),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: _buildContent(
            isWide: isWide,
            isCompact: isCompact,
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required bool isWide,
    required bool isCompact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrandMark(
          isCompact: isCompact,
        ),
        SizedBox(
          height: isCompact ? 28 : 42,
        ),
        _buildGlassPanel(
          isWide: isWide,
          isCompact: isCompact,
        ),
        SizedBox(
          height: isCompact ? 22 : 30,
        ),
        _buildButton(),
        const SizedBox(height: 18),
        _buildPrivacyHint(),
      ],
    );
  }

  Widget _buildBrandMark({
    required bool isCompact,
  }) {
    final double scale = 0.72 + (_logoAnimation.value * 0.28);
    final double opacity = _logoAnimation.value;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(
          0,
          22 * (1 - _logoAnimation.value),
        ),
        child: Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Container(
                width: isCompact ? 70 : 82,
                height: isCompact ? 70 : 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.secondary.withValues(alpha: 0.72),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.24,
                      ),
                      blurRadius: 38,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'ELOQIA AI',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({
    required bool isWide,
    required bool isCompact,
  }) {
    final double opacity = _contentAnimation.value;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(
          0,
          30 * (1 - _contentAnimation.value),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            isWide ? 38 : 32,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 26,
              sigmaY: 26,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 58 : 28,
                vertical: isCompact ? 30 : 42,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  isWide ? 38 : 32,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.095),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.018),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.11),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 50,
                    offset: const Offset(0, 25),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.055,
                    ),
                    blurRadius: 70,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEyebrow(),
                  const SizedBox(height: 18),
                  _buildTitle(
                    isWide: isWide,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 18),
                  _buildDescription(
                    isWide: isWide,
                  ),
                  const SizedBox(height: 28),
                  _buildPromiseRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEyebrow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.65,
                ),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'A NEW WAY TO LEARN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
            color: AppColors.primary.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle({
    required bool isWide,
    required bool isCompact,
  }) {
    return Text(
      'Welcome to Eloqia AI.\nYour journey starts here.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isWide
            ? 42
            : isCompact
                ? 30
                : 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDescription({
    required bool isWide,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 620,
      ),
      child: Text(
        'An intelligent learning companion designed to understand '
        'your goals, overcome your challenges, and help you become '
        'the English speaker you want to be.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isWide ? 15 : 14,
          height: 1.65,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.52),
        ),
      ),
    );
  }

  Widget _buildPromiseRow() {
    const items = [
      (
        Icons.track_changes_rounded,
        'Your goals',
      ),
      (
        Icons.psychology_rounded,
        'Your challenges',
      ),
      (
        Icons.auto_awesome_rounded,
        'Your journey',
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: items.map((item) {
        return _PromiseChip(
          icon: item.$1,
          label: item.$2,
        );
      }).toList(),
    );
  }

  Widget _buildButton() {
    final double opacity = _buttonAnimation.value;
    final double scale =
        1 - (_buttonController.value * 0.025);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(
          0,
          24 * (1 - _buttonAnimation.value),
        ),
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _continue,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxWidth: 620,
              ),
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.17),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.24,
                    ),
                    blurRadius: 32,
                    offset: const Offset(0, 13),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 45,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Begin my journey',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    transform: Matrix4.translationValues(
                      _pressed ? 3 : 0,
                      0,
                      0,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyHint() {
    return Opacity(
      opacity: _buttonAnimation.value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 7),
          Text(
            'Personalized for you • Always in your control',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphere() {
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
              0.055,
            )!,
            AppColors.background,
            Color.lerp(
              AppColors.background,
              AppColors.secondary,
              0.045,
            )!,
          ],
          stops: const [
            0,
            0.32,
            0.68,
            1,
          ],
        ),
      ),
    );
  }

  Widget _buildOrb({
    required double size,
    required Alignment alignment,
    required Offset offset,
    required double phase,
  }) {
    final double progress = _orbController.value;

    final double movementX =
        math.sin(
              progress * math.pi * 2 + phase,
            ) *
            24;

    final double movementY =
        math.cos(
              progress * math.pi * 2 + phase,
            ) *
            18;

    final double scale =
        1 + math.sin(
              progress * math.pi * 2 + phase,
            ) *
            0.045;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset +
            Offset(
              movementX,
              movementY,
            ),
        child: Transform.scale(
          scale: scale,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    AppColors.secondary.withValues(alpha: 0.045),
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

class _PromiseChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PromiseChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.065),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}