import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class GoalsPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const GoalsPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_GoalOption> _goals = const [
    _GoalOption(
      id: 'speaking',
      title: 'Speak with confidence',
      subtitle: 'Express myself naturally in real conversations',
      icon: Icons.record_voice_over_rounded,
    ),
    _GoalOption(
      id: 'fluency',
      title: 'Become more fluent',
      subtitle: 'Speak faster, more naturally and without hesitation',
      icon: Icons.bolt_rounded,
    ),
    _GoalOption(
      id: 'vocabulary',
      title: 'Expand my vocabulary',
      subtitle: 'Discover, understand and remember more words',
      icon: Icons.menu_book_rounded,
    ),
    _GoalOption(
      id: 'grammar',
      title: 'Master grammar',
      subtitle: 'Speak and write with greater accuracy',
      icon: Icons.auto_fix_high_rounded,
    ),
    _GoalOption(
      id: 'pronunciation',
      title: 'Improve pronunciation',
      subtitle: 'Sound clearer and more natural when I speak',
      icon: Icons.graphic_eq_rounded,
    ),
    _GoalOption(
      id: 'listening',
      title: 'Understand native speakers',
      subtitle: 'Follow conversations, accents and natural speech',
      icon: Icons.hearing_rounded,
    ),
    _GoalOption(
      id: 'writing',
      title: 'Improve my writing',
      subtitle: 'Write clearly, naturally and confidently',
      icon: Icons.edit_note_rounded,
    ),
    _GoalOption(
      id: 'school',
      title: 'Succeed at school',
      subtitle: 'Improve my English for classes, exams and projects',
      icon: Icons.school_rounded,
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
      begin: const Offset(0, 0.05),
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

  bool get _hasGoal =>
      widget.profile.primaryGoal.trim().isNotEmpty;

  void _selectGoal(String id) {
    setState(() {
      if (widget.profile.primaryGoal == id) {
        return;
      }

      widget.profile.primaryGoal = id;

      widget.profile.secondaryGoals.remove(id);
    });
  }

  void _toggleSecondaryGoal(String id) {
    if (id == widget.profile.primaryGoal) {
      return;
    }

    setState(() {
      if (widget.profile.secondaryGoals.contains(id)) {
        widget.profile.secondaryGoals.remove(id);
      } else {
        widget.profile.secondaryGoals.add(id);
      }
    });
  }

  void _continue() {
    if (!_hasGoal) {
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
                        const SizedBox(height: 26),
                        _buildGoalsCard(
                          isWide: isWide,
                        ),
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
        Container(
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
                color: AppColors.primary.withValues(
                  alpha: 0.2,
                ),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'YOUR GOALS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'What do you want to achieve?',
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
          'Choose one main goal. You can also add other areas you would like Eloqia to work on with you.',
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

  Widget _buildGoalsCard({
    required bool isWide,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Choose your main focus',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildSelectionCount(),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 3.8 : 3.25,
            ),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final bool isPrimary =
                  widget.profile.primaryGoal == goal.id;
              final bool isSecondary =
                  widget.profile.secondaryGoals.contains(goal.id);

              return _GoalCard(
                goal: goal,
                primary: isPrimary,
                secondary: isSecondary,
                onTap: () {
                  if (isPrimary) {
                    _toggleSecondaryGoal(goal.id);
                  } else {
                    _selectGoal(goal.id);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 18),
          _buildHint(),
        ],
      ),
    );
  }

  Widget _buildSelectionCount() {
    final int count =
        (widget.profile.primaryGoal.isNotEmpty ? 1 : 0) +
        widget.profile.secondaryGoals.length;

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

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your main goal will guide your personalized learning path. Your other selections help Eloqia understand the bigger picture.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return OnboardingButton(
      label: 'Continue',
      icon: Icons.arrow_forward_rounded,
      enabled: _hasGoal,
      onPressed: _hasGoal ? _continue : null,
    );
  }
}

class _GoalOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _GoalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _GoalCard extends StatelessWidget {
  final _GoalOption goal;
  final bool primary;
  final bool secondary;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.primary,
    required this.secondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = primary || secondary;

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
            color: primary
                ? AppColors.primary.withValues(alpha: 0.42)
                : secondary
                    ? AppColors.secondary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.055),
            width: primary ? 1.2 : 1,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.1,
                    ),
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
                gradient: primary
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      )
                    : null,
                color: primary
                    ? null
                    : Colors.white.withValues(alpha: 0.045),
                border: Border.all(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Icon(
                goal.icon,
                size: 21,
                color: primary
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
                    goal.title,
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
                    goal.subtitle,
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                primary
                    ? Icons.star_rounded
                    : secondary
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                key: ValueKey(
                  '$primary-$secondary',
                ),
                size: 22,
                color: primary
                    ? AppColors.primary
                    : secondary
                        ? AppColors.secondary
                        : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}