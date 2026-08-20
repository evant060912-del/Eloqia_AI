import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class LevelPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const LevelPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_LevelOption> _levels = const [
    _LevelOption(
      id: 'a1',
      level: 'A1',
      title: 'Just getting started',
      description:
          'I know a few basic words and phrases and I am beginning to build my English.',
      icon: Icons.looks_one_rounded,
    ),
    _LevelOption(
      id: 'a2',
      level: 'A2',
      title: 'Building the basics',
      description:
          'I can understand and use simple English in familiar everyday situations.',
      icon: Icons.looks_two_rounded,
    ),
    _LevelOption(
      id: 'b1',
      level: 'B1',
      title: 'Becoming independent',
      description:
          'I can handle everyday conversations and explain familiar ideas with some confidence.',
      icon: Icons.looks_3_rounded,
    ),
    _LevelOption(
      id: 'b2',
      level: 'B2',
      title: 'Confident communicator',
      description:
          'I can discuss many topics naturally, but I want more fluency, precision and confidence.',
      icon: Icons.looks_4_rounded,
    ),
    _LevelOption(
      id: 'c1',
      level: 'C1',
      title: 'Advanced speaker',
      description:
          'I communicate comfortably and want to refine accuracy, nuance and natural expression.',
      icon: Icons.looks_5_rounded,
    ),
    _LevelOption(
      id: 'c2',
      level: 'C2',
      title: 'Near-native mastery',
      description:
          'I can express complex ideas precisely and communicate with a very high level of fluency.',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  bool get _hasLevel =>
      widget.profile.currentLevel.trim().isNotEmpty;

  void _selectLevel(String level) {
    setState(() {
      widget.profile.currentLevel = level;
    });
  }

  void _continue() {
    if (!_hasLevel) {
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
              final bool isCompact = constraints.maxHeight < 720;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 22,
                  vertical: isCompact ? 18 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 920,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(
                          isCompact: isCompact,
                        ),
                        SizedBox(
                          height: isCompact ? 22 : 28,
                        ),
                        _buildLevelsCard(
                          isWide: isWide,
                          isCompact: isCompact,
                        ),
                        SizedBox(
                          height: isCompact ? 18 : 22,
                        ),
                        _buildContinueButton(),
                        const SizedBox(height: 14),
                        _buildAssessmentHint(),
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

  Widget _buildHeader({
    required bool isCompact,
  }) {
    return Column(
      children: [
        Container(
          width: isCompact ? 60 : 68,
          height: isCompact ? 60 : 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.92),
                AppColors.secondary.withValues(alpha: 0.74),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.22,
                ),
                blurRadius: 34,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: isCompact ? 27 : 30,
          ),
        ),
        SizedBox(
          height: isCompact ? 18 : 22,
        ),
        Text(
          'YOUR CURRENT LEVEL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'How would you describe your English?',
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
          'Choose the level that feels closest to you right now. '
          'There is no perfect answer — Mia will refine your level later.',
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

  Widget _buildLevelsCard({
    required bool isWide,
    required bool isCompact,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(
        isCompact ? 18 : 24,
      ),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select your current level',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildSelectedBadge(),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _levels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 3.45 : 3.05,
            ),
            itemBuilder: (context, index) {
              final option = _levels[index];

              final bool selected =
                  widget.profile.currentLevel == option.id;

              return _LevelCard(
                option: option,
                selected: selected,
                onTap: () => _selectLevel(option.id),
              );
            },
          ),
          const SizedBox(height: 18),
          _buildLevelScale(),
        ],
      ),
    );
  }

  Widget _buildSelectedBadge() {
    final bool selected = _hasLevel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        selected
            ? widget.profile.currentLevel.toUpperCase()
            : 'NOT SET',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildLevelScale() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: Colors.white.withValues(alpha: 0.025),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Text(
            'BEGINNER',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: 0.3,
                        ),
                        AppColors.secondary.withValues(
                          alpha: 0.8,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) {
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: 0.32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'MASTER',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.3),
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
      enabled: _hasLevel,
      onPressed: _hasLevel ? _continue : null,
    );
  }

  Widget _buildAssessmentHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 13,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Mia will refine your level through a short conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelOption {
  final String id;
  final String level;
  final String title;
  final String description;
  final IconData icon;

  const _LevelOption({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _LevelCard extends StatelessWidget {
  final _LevelOption option;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({
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
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    blurRadius: 25,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
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
              child: Center(
                child: selected
                    ? Text(
                        option.level,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        option.icon,
                        size: 20,
                        color: Colors.white.withValues(
                          alpha: 0.58,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.level,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: selected
                              ? AppColors.primary
                              : Colors.white.withValues(
                                  alpha: 0.28,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(
                        alpha: 0.38,
                      ),
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