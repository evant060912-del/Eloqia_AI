import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class SkillsPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const SkillsPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<_SkillOption> _skills = const [
    _SkillOption(
      id: 'speaking',
      title: 'Speaking',
      description: 'Expressing myself naturally',
      icon: Icons.record_voice_over_rounded,
    ),
    _SkillOption(
      id: 'listening',
      title: 'Listening',
      description: 'Understanding spoken English',
      icon: Icons.hearing_rounded,
    ),
    _SkillOption(
      id: 'vocabulary',
      title: 'Vocabulary',
      description: 'Knowing and using more words',
      icon: Icons.auto_stories_rounded,
    ),
    _SkillOption(
      id: 'grammar',
      title: 'Grammar',
      description: 'Building accurate sentences',
      icon: Icons.account_tree_rounded,
    ),
    _SkillOption(
      id: 'writing',
      title: 'Writing',
      description: 'Writing clearly and naturally',
      icon: Icons.edit_note_rounded,
    ),
    _SkillOption(
      id: 'pronunciation',
      title: 'Pronunciation',
      description: 'Sounding clear and natural',
      icon: Icons.graphic_eq_rounded,
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _canContinue => widget.profile.strengths.isNotEmpty;

  void _toggleSkill(String skill) {
    setState(() {
      if (widget.profile.strengths.contains(skill)) {
        widget.profile.strengths.remove(skill);
      } else {
        widget.profile.strengths.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;
            final isCompact = constraints.maxHeight < 720;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 22,
                vertical: isCompact ? 18 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      _buildHeader(isCompact),
                      SizedBox(height: isCompact ? 22 : 28),
                      _buildSkillsCard(isWide, isCompact),
                      SizedBox(height: isCompact ? 18 : 22),
                      OnboardingButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        enabled: _canContinue,
                        onPressed: _canContinue
                            ? widget.onContinue
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildHint(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Column(
      children: [
        _buildIcon(
          Icons.auto_awesome_rounded,
          isCompact ? 60 : 68,
        ),
        SizedBox(height: isCompact ? 18 : 22),
        Text(
          'YOUR STRENGTHS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'What are you already good at?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 27 : 31,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Select the areas where you already feel comfortable. '
          'Eloqia will use your strengths to personalize your journey.',
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

  Widget _buildIcon(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            AppColors.secondary.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 34,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.43,
      ),
    );
  }

  Widget _buildSkillsCard(bool isWide, bool isCompact) {
    return GlassCard(
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Choose your strengths',
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
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _skills.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 3.55 : 3.1,
            ),
            itemBuilder: (context, index) {
              final skill = _skills[index];

              return _SkillCard(
                option: skill,
                selected: widget.profile.strengths.contains(skill.id),
                onTap: () => _toggleSkill(skill.id),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        '${widget.profile.strengths.length} selected',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Text(
      'You can choose more than one.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.28),
      ),
    );
  }
}

class _SkillOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _SkillOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _SkillCard extends StatelessWidget {
  final _SkillOption option;
  final bool selected;
  final VoidCallback onTap;

  const _SkillCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.13),
                    AppColors.secondary.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: selected
              ? null
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.055),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.045),
              ),
              child: Icon(
                option.icon,
                size: 20,
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.55),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
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