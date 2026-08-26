import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../theme/app_colors.dart';

class LearningScreen extends StatefulWidget {
  final LearningProfile profile;

  const LearningScreen({
    super.key,
    required this.profile,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  int _selectedCategory = 0;

  final List<_LearningCategory> _categories = const [
    _LearningCategory(
      title: 'Conversation',
      subtitle: 'Speak with confidence',
      icon: Icons.forum_rounded,
      accent: AppColors.speaking,
    ),
    _LearningCategory(
      title: 'Writing',
      subtitle: 'Express your ideas',
      icon: Icons.edit_note_rounded,
      accent: AppColors.writing,
    ),
    _LearningCategory(
      title: 'Reading',
      subtitle: 'Understand deeply',
      icon: Icons.menu_book_rounded,
      accent: AppColors.vocabulary,
    ),
    _LearningCategory(
      title: 'Listening',
      subtitle: 'Train your ear',
      icon: Icons.headphones_rounded,
      accent: AppColors.electricBlue,
    ),
    _LearningCategory(
      title: 'Grammar',
      subtitle: 'Master the structure',
      icon: Icons.auto_fix_high_rounded,
      accent: AppColors.grammar,
    ),
    _LearningCategory(
      title: 'Vocabulary',
      subtitle: 'Expand your language',
      icon: Icons.psychology_rounded,
      accent: AppColors.secondary,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    final name = profile.name.trim().isEmpty
        ? 'Learner'
        : profile.name.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _AnimatedBackground(
            controller: _ambientController,
          ),

          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        48,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _buildTopBar(name),
                            const SizedBox(height: 30),
                            _buildHero(profile),
                            const SizedBox(height: 22),
                            _buildDailyMission(profile),
                            const SizedBox(height: 22),
                            _buildProgressOverview(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'Your learning universe',
                              'Explore an experience designed around you.',
                            ),
                            const SizedBox(height: 16),
                            _buildCategorySelector(),
                            const SizedBox(height: 22),
                            _buildRecommendedExperience(profile),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'Explore more',
                              'Every session can become a new challenge.',
                            ),
                            const SizedBox(height: 16),
                            _buildLearningGrid(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String name) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELOQIA AI',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PERSONAL LANGUAGE ACADEMY',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.52),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.1,
                ),
              ),
            ],
          ),
        ),
        _GlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ProfileOrb(
          name: name,
        ),
      ],
    );
  }

  Widget _buildHero(LearningProfile profile) {
    final name = profile.name.trim().isEmpty
        ? 'there'
        : profile.name.trim();

    final level = profile.currentLevel.trim().isEmpty
        ? 'Your current level'
        : profile.currentLevel.trim();

    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: _MiniGlow(
              color: AppColors.primary,
              size: 150,
            ),
          ),
          Positioned(
            right: 25,
            bottom: -80,
            child: _MiniGlow(
              color: AppColors.secondary,
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusOrb(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'YOUR PERSONAL LEARNING SPACE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Good to see you, $name.',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Your learning environment evolves with your goals, '
                'your progress and the way you learn best.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ProfileChip(
                    icon: Icons.school_rounded,
                    label: level,
                  ),
                  _ProfileChip(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Adaptive',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission(LearningProfile profile) {
    return _HeroMissionCard(
      profile: profile,
      onStart: () {},
    );
  }

  Widget _buildProgressOverview() {
    return _GlassPanel(
      padding: const EdgeInsets.all(21),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your evolution',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'THIS WEEK',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProgressMetric(
                  value: '64%',
                  label: 'Learning path',
                  progress: 0.64,
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProgressMetric(
                  value: '4',
                  label: 'Sessions',
                  progress: 0.57,
                  accent: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProgressMetric(
                  value: '240',
                  label: 'XP earned',
                  progress: 0.72,
                  accent: AppColors.xp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.62),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? category.accent.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.045),
                border: Border.all(
                  color: selected
                      ? category.accent.withValues(alpha: 0.38)
                      : Colors.white.withValues(alpha: 0.075),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: selected
                        ? category.accent
                        : Colors.white.withValues(alpha: 0.58),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedExperience(
    LearningProfile profile,
  ) {
    final category = _categories[_selectedCategory];

    return _RecommendedCard(
      category: category,
      profile: profile,
      onTap: () {},
    );
  }

  Widget _buildLearningGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];

        return _LearningExperienceCard(
          category: category,
          index: index,
          onTap: () {
            setState(() {
              _selectedCategory = index;
            });
          },
        );
      },
    );
  }
}

/* ================================================================
   DAILY MISSION
   ================================================================ */

class _HeroMissionCard extends StatelessWidget {
  final LearningProfile profile;
  final VoidCallback onStart;

  const _HeroMissionCard({
    required this.profile,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 50,
            spreadRadius: -10,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.13),
                  AppColors.secondary.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.045),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.25),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY INTELLIGENT MISSION',
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: 0.50),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your next step',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DifficultyBadge(
                      label: 'ADAPTIVE',
                    ),
                  ],
                ),
                const SizedBox(height: 23),
                const Text(
                  'Express yourself.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A personalized challenge selected from your '
                  'goals, interests, current level and learning history.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    _MissionPill(
                      icon: Icons.schedule_rounded,
                      label: '10 min',
                    ),
                    const SizedBox(width: 8),
                    _MissionPill(
                      icon: Icons.bolt_rounded,
                      label: '+40 XP',
                    ),
                    const SizedBox(width: 8),
                    _MissionPill(
                      icon: Icons.psychology_rounded,
                      label: 'Personalized',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'Begin my mission',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 9),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================================================================
   RECOMMENDED EXPERIENCE
   ================================================================ */

class _RecommendedCard extends StatelessWidget {
  final _LearningCategory category;
  final LearningProfile profile;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.category,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            color: Colors.white.withValues(alpha: 0.052),
            border: Border.all(
              color: category.accent.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: category.accent.withValues(alpha: 0.11),
                  border: Border.all(
                    color: category.accent.withValues(alpha: 0.17),
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOMMENDED FOR YOU',
                      style: TextStyle(
                        color: category.accent
                            .withValues(alpha: 0.78),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.subtitle,
                      style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: 0.46),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================================================================
   LEARNING CARDS
   ================================================================ */

class _LearningExperienceCard extends StatelessWidget {
  final _LearningCategory category;
  final int index;
  final VoidCallback onTap;

  const _LearningExperienceCard({
    required this.category,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withValues(alpha: 0.043),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.075),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: category.accent.withValues(alpha: 0.10),
                ),
                child: Icon(
                  category.icon,
                  color: category.accent,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================================================================
   SUPPORTING WIDGETS
   ================================================================ */

class _ProgressMetric extends StatelessWidget {
  final String value;
  final String label;
  final double progress;
  final Color accent;

  const _ProgressMetric({
    required this.value,
    required this.label,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.43),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor:
                Colors.white.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(
              accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MissionPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Colors.white.withValues(alpha: 0.055),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String label;

  const _DifficultyBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.055),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.45),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _ProfileOrb extends StatelessWidget {
  final String name;

  const _ProfileOrb({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty
        ? 'E'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Colors.white.withValues(alpha: 0.055),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.78),
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.048),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.095),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _MiniGlow({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 55,
        sigmaY: 55,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

/* ================================================================
   BACKGROUND
   ================================================================ */

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> controller;

  const _AnimatedBackground({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shift = controller.value;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.backgroundSecondary,
                    AppColors.background,
                  ],
                ),
              ),
            ),
            Positioned(
              top: -150 + (shift * 25),
              right: -120,
              child: _MiniGlow(
                color: AppColors.primary,
                size: 390,
              ),
            ),
            Positioned(
              top: 350 - (shift * 35),
              left: -180,
              child: _MiniGlow(
                color: AppColors.secondary,
                size: 420,
              ),
            ),
            Positioned(
              bottom: -220 + (shift * 20),
              right: 30,
              child: _MiniGlow(
                color: AppColors.electricBlue,
                size: 350,
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ================================================================
   DATA
   ================================================================ */

class _LearningCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _LearningCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}/* ================================================================
   DAILY MISSION — ADAPTIVE TOPIC EXPERIENCE
   ================================================================ */

class _DailyMissionTopic {
  final String title;
  final String description;
  final String category;
  final String level;
  final String duration;
  final String xp;
  final IconData icon;
  final Color accent;
  final List<String> tags;

  const _DailyMissionTopic({
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.duration,
    required this.xp,
    required this.icon,
    required this.accent,
    required this.tags,
  });
}

class _DailyMissionTopics extends StatefulWidget {
  final LearningProfile profile;

  const _DailyMissionTopics({
    required this.profile,
  });

  @override
  State<_DailyMissionTopics> createState() =>
      _DailyMissionTopicsState();
}

class _DailyMissionTopicsState extends State<_DailyMissionTopics>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _selectedIndex = 0;

  final List<_DailyMissionTopic> _topics = const [
    _DailyMissionTopic(
      title: 'The art of conversation',
      description:
          'Explore how confident speakers keep conversations natural, engaging and effortless.',
      category: 'Conversation',
      level: 'Adaptive',
      duration: '10 min',
      xp: '+40 XP',
      icon: Icons.forum_rounded,
      accent: AppColors.speaking,
      tags: [
        'Speaking',
        'Confidence',
        'Fluency',
      ],
    ),
    _DailyMissionTopic(
      title: 'Your perfect argument',
      description:
          'Build a convincing argument around a topic that matters to you.',
      category: 'Writing',
      level: 'Adaptive',
      duration: '15 min',
      xp: '+55 XP',
      icon: Icons.edit_note_rounded,
      accent: AppColors.writing,
      tags: [
        'Writing',
        'Arguments',
        'Expression',
      ],
    ),
    _DailyMissionTopic(
      title: 'Decode a modern text',
      description:
          'Read an authentic English passage and uncover its meaning, tone and hidden ideas.',
      category: 'Reading',
      level: 'Adaptive',
      duration: '12 min',
      xp: '+45 XP',
      icon: Icons.menu_book_rounded,
      accent: AppColors.vocabulary,
      tags: [
        'Reading',
        'Analysis',
        'Vocabulary',
      ],
    ),
    _DailyMissionTopic(
      title: 'Train your English ear',
      description:
          'Work with natural English and learn to recognize expressions, rhythm and meaning.',
      category: 'Listening',
      level: 'Adaptive',
      duration: '10 min',
      xp: '+40 XP',
      icon: Icons.headphones_rounded,
      accent: AppColors.electricBlue,
      tags: [
        'Listening',
        'Pronunciation',
        'Natural English',
      ],
    ),
    _DailyMissionTopic(
      title: 'Grammar in context',
      description:
          'Master an important grammar concept through practical situations instead of isolated rules.',
      category: 'Grammar',
      level: 'Adaptive',
      duration: '12 min',
      xp: '+45 XP',
      icon: Icons.auto_fix_high_rounded,
      accent: AppColors.grammar,
      tags: [
        'Grammar',
        'Accuracy',
        'Practice',
      ],
    ),
    _DailyMissionTopic(
      title: 'Upgrade your vocabulary',
      description:
          'Discover precise and natural expressions you can immediately use in real conversations.',
      category: 'Vocabulary',
      level: 'Adaptive',
      duration: '8 min',
      xp: '+35 XP',
      icon: Icons.psychology_rounded,
      accent: AppColors.secondary,
      tags: [
        'Vocabulary',
        'Expressions',
        'Fluency',
      ],
    ),
    _DailyMissionTopic(
      title: 'Speak about your world',
      description:
          'Describe your interests, opinions and experiences while Eloqia adapts the challenge to you.',
      category: 'Conversation',
      level: 'Adaptive',
      duration: '10 min',
      xp: '+40 XP',
      icon: Icons.public_rounded,
      accent: AppColors.primary,
      tags: [
        'Speaking',
        'Personal',
        'Fluency',
      ],
    ),
    _DailyMissionTopic(
      title: 'Think like a native speaker',
      description:
          'Move beyond direct translation and discover how ideas are naturally expressed in English.',
      category: 'Advanced',
      level: 'Adaptive',
      duration: '15 min',
      xp: '+60 XP',
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.secondary,
      tags: [
        'Advanced',
        'Thinking',
        'Natural English',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
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
        final progress = Curves.easeOutCubic.transform(
          _controller.value,
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - progress),
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 17),
          _buildFeaturedTopic(),
          const SizedBox(height: 18),
          _buildTopicRail(),
          const SizedBox(height: 18),
          _buildPersonalizationInsight(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHOOSE YOUR NEXT EXPERIENCE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'More ways to grow.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppColors.primary.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 5),
              Text(
                '${_topics.length} EXPERIENCES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedTopic() {
    final topic = _topics[_selectedIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _FeaturedTopicCard(
        key: ValueKey(topic.title),
        topic: topic,
        profile: widget.profile,
        onStart: () {},
      ),
    );
  }

  Widget _buildTopicRail() {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          final selected = index == _selectedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 152,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: selected
                    ? topic.accent.withValues(alpha: 0.11)
                    : Colors.white.withValues(alpha: 0.035),
                border: Border.all(
                  color: selected
                      ? topic.accent.withValues(alpha: 0.34)
                      : Colors.white.withValues(alpha: 0.065),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: topic.accent.withValues(alpha: 0.09),
                          blurRadius: 24,
                          spreadRadius: -8,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: topic.accent.withValues(
                            alpha: selected ? 0.16 : 0.08,
                          ),
                        ),
                        child: Icon(
                          topic.icon,
                          size: 15,
                          color: selected
                              ? topic.accent
                              : Colors.white.withValues(alpha: 0.48),
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: topic.accent,
                            boxShadow: [
                              BoxShadow(
                                color: topic.accent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    topic.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    topic.duration,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.36),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalizationInsight() {
    final profile = widget.profile;

    final goal = profile.primaryGoal.trim().isEmpty
        ? 'your goals'
        : profile.primaryGoal.trim();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        color: Colors.white.withValues(alpha: 0.032),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.065),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.11),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: AppColors.secondary,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontSize: 11,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(
                    text: 'Eloqia is looking at ',
                  ),
                  TextSpan(
                    text: goal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' to help prioritize the experience that can create the most useful progress for you.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================================================================
   FEATURED TOPIC CARD
   ================================================================ */

class _FeaturedTopicCard extends StatelessWidget {
  final _DailyMissionTopic topic;
  final LearningProfile profile;
  final VoidCallback onStart;

  const _FeaturedTopicCard({
    super.key,
    required this.topic,
    required this.profile,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: topic.accent.withValues(alpha: 0.12),
            blurRadius: 50,
            spreadRadius: -12,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  topic.accent.withValues(alpha: 0.13),
                  AppColors.secondary.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.035),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.115),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TopicIcon(
                      icon: topic.icon,
                      accent: topic.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADAPTIVE EXPERIENCE',
                            style: TextStyle(
                              color: topic.accent.withValues(alpha: 0.80),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topic.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.46),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AdaptiveBadge(
                      accent: topic.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  topic.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topic.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.52,
                  ),
                ),
                const SizedBox(height: 17),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: topic.tags
                      .map(
                        (tag) => _TopicTag(
                          label: tag,
                          accent: topic.accent,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: _TopicStat(
                        icon: Icons.schedule_rounded,
                        label: topic.duration,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopicStat(
                        icon: Icons.bolt_rounded,
                        label: topic.xp,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopicStat(
                        icon: Icons.tune_rounded,
                        label: topic.level,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Start this experience',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: topic.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================================================================
   TOPIC SUPPORTING WIDGETS
   ================================================================ */

class _TopicIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _TopicIcon({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.90),
            AppColors.secondary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.24),
            blurRadius: 25,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}

class _AdaptiveBadge extends StatelessWidget {
  final Color accent;

  const _AdaptiveBadge({
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: accent.withValues(alpha: 0.10),
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 10,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            'ADAPTIVE',
            style: TextStyle(
              color: accent,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTag extends StatelessWidget {
  final String label;
  final Color accent;

  const _TopicTag({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(
          color: accent.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TopicStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopicStat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.055),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.58),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}