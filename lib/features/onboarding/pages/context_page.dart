import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class ContextPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const ContextPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<ContextPage> createState() => _ContextPageState();
}

class _ContextPageState extends State<ContextPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_ContextOption> _options = const [
    _ContextOption(
      id: 'everyday',
      title: 'Everyday conversations',
      subtitle: 'Talk naturally in daily situations',
      icon: Icons.chat_bubble_rounded,
    ),
    _ContextOption(
      id: 'travel',
      title: 'Travel',
      subtitle: 'Feel comfortable speaking while travelling',
      icon: Icons.flight_takeoff_rounded,
    ),
    _ContextOption(
      id: 'school',
      title: 'School & studies',
      subtitle: 'Use English confidently for school and learning',
      icon: Icons.school_rounded,
    ),
    _ContextOption(
      id: 'work',
      title: 'Work & career',
      subtitle: 'Communicate professionally in English',
      icon: Icons.work_outline_rounded,
    ),
    _ContextOption(
      id: 'friends',
      title: 'Friends & social life',
      subtitle: 'Connect naturally with English speakers',
      icon: Icons.people_alt_rounded,
    ),
    _ContextOption(
      id: 'media',
      title: 'Movies, series & content',
      subtitle: 'Understand authentic English more easily',
      icon: Icons.movie_rounded,
    ),
    _ContextOption(
      id: 'public',
      title: 'Public speaking',
      subtitle: 'Express ideas clearly in front of others',
      icon: Icons.mic_rounded,
    ),
    _ContextOption(
      id: 'personal',
      title: 'Personal growth',
      subtitle: 'Improve English simply because it matters to me',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.profile.speakingSituations.isNotEmpty;

  void _toggleOption(String id) {
    setState(() {
      if (widget.profile.speakingSituations.contains(id)) {
        widget.profile.speakingSituations.remove(id);
      } else {
        widget.profile.speakingSituations.add(id);
      }
    });
  }

  void _continue() {
    if (!_canContinue) {
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 22,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 900,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildOptionsCard(isWide),
                        const SizedBox(height: 22),
                        _buildContinueButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
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
          'YOUR WORLD',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Where will you use English?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 31,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Select every situation that matters to you. Eloqia will use these choices to make your practice more relevant.',
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.secondary.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.public_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildOptionsCard(bool isWide) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Choose your situations',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildCounter(),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 3.7 : 3.2,
            ),
            itemBuilder: (context, index) {
              final option = _options[index];
              final selected =
                  widget.profile.speakingSituations.contains(option.id);

              return _ContextCard(
                option: option,
                selected: selected,
                onTap: () => _toggleOption(option.id),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    final count = widget.profile.speakingSituations.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: count > 0
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: count > 0
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        '$count selected',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: count > 0
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return OnboardingButton(
      label: 'Continue',
      icon: Icons.arrow_forward_rounded,
      enabled: _canContinue,
      onPressed: _canContinue ? _continue : null,
    );
  }
}

class _ContextOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ContextOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ContextCard extends StatelessWidget {
  final _ContextOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ContextCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.secondary.withValues(alpha: 0.055),
                  ],
                )
              : null,
          color: selected
              ? null
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.055),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      )
                    : null,
                color: selected
                    ? null
                    : Colors.white.withValues(alpha: 0.045),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Icon(
                option.icon,
                size: 21,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.58),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ],
        ),
      ),
    );
  }
}