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

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                final progress = Curves.easeOutCubic.transform(
                  _entranceController.value,
                );

                return Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      28 * (1 - progress),
                    ),
                    child: child,
                  ),
                );
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      50,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildHeader(name),
                          const SizedBox(height: 28),
                          _buildHero(profile),
                          const SizedBox(height: 20),
                          _buildDailyMission(profile),
                          const SizedBox(height: 18),
                          _buildProgressCard(),
                          const SizedBox(height: 32),
                          _buildLearningHeader(),
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
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELOQIA AI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Good to see you, $name.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _GlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildHero(LearningProfile profile) {
    final goal = profile.primaryGoal.trim().isEmpty
        ? 'Build your English confidence'
        : profile.primaryGoal.trim();

    return _GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: _SoftOrb(
              color: AppColors.primary,
              size: 150,
              opacity: 0.10,
            ),
          ),
          Positioned(
            left: -50,
            bottom: -65,
            child: _SoftOrb(
              color: AppColors.secondary,
              size: 140,
              opacity: 0.08,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.28,
                          ),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PERSONAL ACADEMY',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.46,
                            ),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your journey starts here.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                goal,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Eloqia will progressively adapt your learning experience to your goals, level and progress.',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.58,
                  ),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission(LearningProfile profile) {
    return _GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your mission for today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: AppColors.xp,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+40 XP',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.82,
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(
                alpha: 0.035,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.07,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: AppColors.writing.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.writing,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Writing warm-up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Express your ideas naturally.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MissionBadge(
                icon: Icons.schedule_rounded,
                label: '10 min',
              ),
              const SizedBox(width: 9),
              _MissionBadge(
                icon: Icons.auto_graph_rounded,
                label: 'Adaptive',
              ),
              const SizedBox(width: 9),
              _MissionBadge(
                icon: Icons.stars_rounded,
                label: 'Beginner',
              ),
            ],
          ),
          const SizedBox(height: 19),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    'Begin today\'s session',
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
    );
  }

  Widget _buildProgressCard() {
    return _GlassPanel(
      padding: const EdgeInsets.all(21),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: 0.64,
                    strokeWidth: 6,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.07,
                    ),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const Text(
                  '64%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 17),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your English evolution',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Keep building your rhythm. Every session moves you forward.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Learning experiences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Choose an area to explore.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
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
            color: Colors.white.withValues(
              alpha: 0.04,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          child: const Text(
            '6 areas',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningGrid() {
    const activities = [
      _LearningActivity(
        title: 'Conversation',
        subtitle: 'Speak naturally',
        icon: Icons.forum_rounded,
        color: AppColors.speaking,
      ),
      _LearningActivity(
        title: 'Writing',
        subtitle: 'Express yourself',
        icon: Icons.edit_rounded,
        color: AppColors.writing,
      ),
      _LearningActivity(
        title: 'Reading',
        subtitle: 'Understand more',
        icon: Icons.menu_book_rounded,
        color: AppColors.electricBlue,
      ),
      _LearningActivity(
        title: 'Listening',
        subtitle: 'Train your ear',
        icon: Icons.headphones_rounded,
        color: AppColors.secondary,
      ),
      _LearningActivity(
        title: 'Grammar',
        subtitle: 'Master the structure',
        icon: Icons.auto_fix_high_rounded,
        color: AppColors.grammar,
      ),
      _LearningActivity(
        title: 'Vocabulary',
        subtitle: 'Grow your words',
        icon: Icons.psychology_rounded,
        color: AppColors.vocabulary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, index) {
        return _LearningActivityCard(
          activity: activities[index],
          index: index,
          onTap: () {},
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final movement = controller.value;

        return Stack(
          children: [
            Positioned(
              top: -170 + (movement * 30),
              left: -130,
              child: _SoftOrb(
                color: AppColors.primary,
                size: 380,
                opacity: 0.11,
              ),
            ),
            Positioned(
              top: 280 - (movement * 25),
              right: -170,
              child: _SoftOrb(
                color: AppColors.secondary,
                size: 400,
                opacity: 0.09,
              ),
            ),
            Positioned(
              bottom: -190 + (movement * 35),
              left: 20,
              child: _SoftOrb(
                color: AppColors.electricBlue,
                size: 360,
                opacity: 0.07,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _SoftOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 75,
        sigmaY: 75,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(
            alpha: opacity,
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
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withValues(
              alpha: 0.052,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.105,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.24,
                ),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
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
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Colors.white.withValues(
              alpha: 0.055,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(
              alpha: 0.82,
            ),
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _MissionBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MissionBadge({
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
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(
            alpha: 0.035,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.065,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(
                alpha: 0.60,
              ),
              size: 14,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.66,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningActivity {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LearningActivity({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _LearningActivityCard extends StatefulWidget {
  final _LearningActivity activity;
  final int index;
  final VoidCallback onTap;

  const _LearningActivityCard({
    required this.activity,
    required this.index,
    required this.onTap,
  });

  @override
  State<_LearningActivityCard> createState() =>
      _LearningActivityCardState();
}

class _LearningActivityCardState
    extends State<_LearningActivityCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() {
              _isPressed = value;
            });
          },
          borderRadius: BorderRadius.circular(25),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withValues(
                alpha: 0.045,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.085,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: activity.color.withValues(
                    alpha: 0.055,
                  ),
                  blurRadius: 25,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -45,
                  right: -45,
                  child: _SoftOrb(
                    color: activity.color,
                    size: 120,
                    opacity: 0.07,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(15),
                          color:
                              activity.color.withValues(
                            alpha: 0.12,
                          ),
                          border: Border.all(
                            color:
                                activity.color.withValues(
                              alpha: 0.13,
                            ),
                          ),
                        ),
                        child: Icon(
                          activity.icon,
                          color: activity.color,
                          size: 21,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        activity.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        activity.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.43,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activity.color,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      activity.color
                                          .withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Explore',
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.52,
                              ),
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white
                                .withValues(
                              alpha: 0.35,
                            ),
                            size: 15,
                          ),
                        ],
                      ),
                    ],
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