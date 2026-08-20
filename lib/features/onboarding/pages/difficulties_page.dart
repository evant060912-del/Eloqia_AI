import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class DifficultiesPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const DifficultiesPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<DifficultiesPage> createState() => _DifficultiesPageState();
}

class _DifficultiesPageState extends State<DifficultiesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_DifficultyOption> _options = const [
    _DifficultyOption(
      id: 'speaking',
      title: 'Speaking',
      subtitle: 'I know what I want to say, but speaking feels difficult',
      icon: Icons.record_voice_over_rounded,
    ),
    _DifficultyOption(
      id: 'vocabulary',
      title: 'Vocabulary',
      subtitle: 'I sometimes cannot find the right words',
      icon: Icons.menu_book_rounded,
    ),
    _DifficultyOption(
      id: 'grammar',
      title: 'Grammar',
      subtitle: 'I am not always sure how to build sentences correctly',
      icon: Icons.auto_fix_high_rounded,
    ),
    _DifficultyOption(
      id: 'pronunciation',
      title: 'Pronunciation',
      subtitle: 'I want to sound clearer and more natural',
      icon: Icons.graphic_eq_rounded,
    ),
    _DifficultyOption(
      id: 'listening',
      title: 'Listening',
      subtitle: 'Native speakers can be difficult to understand',
      icon: Icons.hearing_rounded,
    ),
    _DifficultyOption(
      id: 'confidence',
      title: 'Confidence',
      subtitle: 'I understand English but hesitate when using it',
      icon: Icons.favorite_outline_rounded,
    ),
    _DifficultyOption(
      id: 'fluency',
      title: 'Fluency',
      subtitle: 'I want to speak more smoothly and naturally',
      icon: Icons.bolt_rounded,
    ),
    _DifficultyOption(
      id: 'writing',
      title: 'Writing',
      subtitle: 'I want my written English to feel more precise',
      icon: Icons.edit_note_rounded,
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

  bool get _canContinue => widget.profile.difficulties.isNotEmpty;

  void _toggleDifficulty(String id) {
    setState(() {
      if (widget.profile.difficulties.contains(id)) {
        widget.profile.difficulties.remove(id);
      } else {
        widget.profile.difficulties.add(id);
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
                        _buildDifficultyCard(isWide),
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
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'YOUR CHALLENGES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'What feels difficult right now?',
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
          'Be honest. There is nothing to get wrong here. Your answers help Eloqia focus on the areas where you need the most support.',
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

  Widget _buildDifficultyCard(bool isWide) {
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
                  'Select everything that applies',
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
                  widget.profile.difficulties.contains(option.id);

              return _DifficultyCard(
                option: option,
                selected: selected,
                onTap: () => _toggleDifficulty(option.id),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildHint(),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    final count = widget.profile.difficulties.length;

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
            Icons.psychology_rounded,
            size: 17,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Eloqia will use these challenges to adapt practice, explanations, corrections and future recommendations.',
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
      enabled: _canContinue,
      onPressed: _canContinue ? _continue : null,
    );
  }
}

class _DifficultyOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _DifficultyOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DifficultyCard extends StatelessWidget {
  final _DifficultyOption option;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(selected),
                size: 22,
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}