import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class MotivationPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const MotivationPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<MotivationPage> createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  late final TextEditingController _controller;

  final List<_MotivationOption> _options = const [
    _MotivationOption(
      id: 'confidence',
      title: 'Build confidence',
      icon: Icons.bolt_rounded,
    ),
    _MotivationOption(
      id: 'school',
      title: 'Improve at school',
      icon: Icons.school_rounded,
    ),
    _MotivationOption(
      id: 'travel',
      title: 'Travel & communicate',
      icon: Icons.flight_takeoff_rounded,
    ),
    _MotivationOption(
      id: 'career',
      title: 'Future & career',
      icon: Icons.rocket_launch_rounded,
    ),
    _MotivationOption(
      id: 'culture',
      title: 'Understand culture',
      icon: Icons.public_rounded,
    ),
    _MotivationOption(
      id: 'personal',
      title: 'Personal growth',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.profile.motivation,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.profile.motivation.trim().isNotEmpty;

  void _selectMotivation(String motivation) {
    _controller.text = motivation;

    setState(() {
      widget.profile.motivation = motivation;
    });
  }

  void _updateMotivation(String value) {
    widget.profile.motivation = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildMotivationCard(),
                  const SizedBox(height: 22),
                  OnboardingButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    enabled: _canContinue,
                    onPressed: _canContinue
                        ? widget.onContinue
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildIcon(),
        const SizedBox(height: 22),
        Text(
          'YOUR MOTIVATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'What keeps you moving forward?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Your motivation helps Eloqia understand what really matters to you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            AppColors.secondary.withValues(alpha: 0.72),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 34,
          ),
        ],
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: Colors.white,
        size: 31,
      ),
    );
  }

  Widget _buildMotivationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose what feels closest',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((option) {
              final selected =
                  widget.profile.motivation == option.id;

              return _MotivationChip(
                option: option,
                selected: selected,
                onTap: () => _selectMotivation(option.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          Text(
            'Or tell Eloqia in your own words',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            onChanged: _updateMotivation,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'For example: I want to feel more confident speaking English...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.22),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.025),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationOption {
  final String id;
  final String title;
  final IconData icon;

  const _MotivationOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _MotivationChip extends StatelessWidget {
  final _MotivationOption option;
  final bool selected;
  final VoidCallback onTap;

  const _MotivationChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 17,
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.48),
            ),
            const SizedBox(width: 8),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}