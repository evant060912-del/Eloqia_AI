import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/learning/learning_hub_screen.dart' as learning_hub;
import '../features/lessons/engine/lesson_engine.dart';
import '../features/lessons/engine/lesson_result_service.dart';
import '../features/lessons/lesson_launcher.dart';
import '../features/lessons/models/lesson_models.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/tutors/mia/mia_chat_screen.dart';
import '../features/tutors/mia/mia_screen.dart';
import '../features/writing/writing_studio_screen.dart';
import '../models/learning_profile.dart';
import '../services/learning/learning_engine.dart';
import '../theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavigationChanged(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _animationController
      ..reset()
      ..forward();
  }

  Widget _buildPage() {
    return switch (_currentIndex) {
      0 => const HomeScreen(),
      1 => const MiaScreen(showBackButton: false),
      2 => const _LearningTab(),
      3 => const ProgressScreen(),
      _ => const ProfileScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          const _AppShellBackground(),

          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );

                return FadeTransition(
                  opacity: curvedAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _buildPage(),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PremiumNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavigationChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              PREMIUM NAV BAR                               */
/* -------------------------------------------------------------------------- */

class _PremiumNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavigationItem> _items = [
    _NavigationItem(icon: Icons.home_rounded, label: 'Home'),
    _NavigationItem(icon: Icons.graphic_eq_rounded, label: 'Talk'),
    _NavigationItem(icon: Icons.auto_stories_rounded, label: 'Learn'),
    _NavigationItem(icon: Icons.insights_rounded, label: 'Progress'),
    _NavigationItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.055),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 35,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 50,
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                return Expanded(
                  child: _NavigationButton(
                    item: _items[index],
                    selected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.28),
                      AppColors.secondary.withValues(alpha: 0.18),
                    ],
                  )
                : null,
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.10))
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 22,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  item.icon,
                  size: 23,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.42),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;

  const _NavigationItem({required this.icon, required this.label});
}

class _LearningTab extends StatefulWidget {
  const _LearningTab();

  @override
  State<_LearningTab> createState() => _LearningTabState();
}

class _LearningTabState extends State<_LearningTab> {
  LearningProfile? _profile;
  LearningRecommendation? _recommendation;
  int _completedSessions = 0;
  int _learningMinutes = 0;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final LessonContext data = await LessonContext.load();
      final LessonChoice choice = data.recommend();

      if (!mounted) return;
      setState(() {
        _profile = data.profile;
        _recommendation = LearningRecommendation(
          activity: LessonResultService.activityFor(choice.lesson.skill),
          title: choice.lesson.title,
          reason: choice.reason,
          targetLevel: choice.lesson.level,
          minutes: choice.lesson.estimatedMinutes,
        );
        _completedSessions = data.progress.statistics.completedLessons;
        _learningMinutes = data.progress.statistics.learningMinutes;
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openRecommended() async {
    await LessonLauncher.openRecommended(context);
    if (mounted) await _load();
  }

  Future<void> _openWritingPractice() async {
    final LearningProfile? profile = _profile;
    if (profile == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WritingStudioScreen(profile: profile),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openConversation() async {
    final LearningProfile? profile = _profile;
    if (profile == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => MiaChatScreen(profile: profile)),
    );
    if (mounted) await _load();
  }

  Future<void> _openActivity(String activity) async {
    final LessonSkill? skill = switch (activity) {
      'Grammar' => LessonSkill.grammar,
      'Vocabulary' => LessonSkill.vocabulary,
      'Reading' => LessonSkill.reading,
      'Listening' => LessonSkill.listening,
      _ => null,
    };
    if (skill != null) {
      await LessonLauncher.openSkill(context, skill);
      if (mounted) await _load();
      return;
    }
    if (activity == 'Writing') {
      await _openWritingPractice();
      return;
    }
    if (activity == 'Conversation') {
      await _openConversation();
      return;
    }
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const MiaScreen()));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_error != null || _profile == null || _recommendation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: TextButton(onPressed: _load, child: const Text('Retry')),
        ),
      );
    }

    return learning_hub.LearningScreen(
      profile: _profile!,
      recommendation: _recommendation!,
      completedSessions: _completedSessions,
      learningMinutes: _learningMinutes,
      onStartRecommended: _openRecommended,
      onActivitySelected: _openActivity,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              BACKGROUND                                    */
/* -------------------------------------------------------------------------- */

class _AppShellBackground extends StatelessWidget {
  const _AppShellBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -180,
          right: -140,
          child: _GlowOrb(color: AppColors.primary, size: 420),
        ),
        Positioned(
          top: 260,
          left: -220,
          child: _GlowOrb(color: AppColors.secondary, size: 430),
        ),
        Positioned(
          bottom: -180,
          right: -100,
          child: _GlowOrb(color: AppColors.electricBlue, size: 360),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              PLACEHOLDERS                                  */
/* -------------------------------------------------------------------------- */
