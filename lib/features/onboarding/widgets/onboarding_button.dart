import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class OnboardingButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  State<OnboardingButton> createState() =>
      _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton> {
  bool _pressed = false;

  bool get _active {
    return widget.enabled && widget.onPressed != null;
  }

  void _setPressed(bool value) {
    if (!mounted || !_active) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _active ? widget.onPressed : null,
      onTapDown: _active ? (_) => _setPressed(true) : null,
      onTapUp: _active ? (_) => _setPressed(false) : null,
      onTapCancel: _active ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: _active
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  )
                : null,
            color: _active
                ? null
                : Colors.white.withValues(alpha: 0.055),
            border: Border.all(
              color: _active
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.075),
            ),
            boxShadow: _active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppColors.secondary.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 42,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: _active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.32),
                ),
              ),
              const SizedBox(width: 11),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.icon),
                  size: 20,
                  color: _active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}