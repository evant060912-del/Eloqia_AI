import 'dart:ui';

import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../theme/app_colors.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _animationController;

  static const List<Widget> _pages = [
    HomeScreen(),
    _TalkPlaceholder(),
    _LearnPlaceholder(),
    _ProgressPlaceholder(),
    _ProfilePlaceholder(),
  ];

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
                child: _pages[_currentIndex],
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
    _NavigationItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavigationItem(
      icon: Icons.graphic_eq_rounded,
      label: 'Talk',
    ),
    _NavigationItem(
      icon: Icons.auto_stories_rounded,
      label: 'Learn',
    ),
    _NavigationItem(
      icon: Icons.insights_rounded,
      label: 'Progress',
    ),
    _NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 28,
            sigmaY: 28,
          ),
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
              children: List.generate(
                _items.length,
                (index) {
                  return Expanded(
                    child: _NavigationButton(
                      item: _items[index],
                      selected: currentIndex == index,
                      onTap: () => onTap(index),
                    ),
                  );
                },
              ),
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
          margin: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
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
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.22,
                      ),
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
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w500,
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

  const _NavigationItem({
    required this.icon,
    required this.label,
  });
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
          child: _GlowOrb(
            color: AppColors.primary,
            size: 420,
          ),
        ),
        Positioned(
          top: 260,
          left: -220,
          child: _GlowOrb(
            color: AppColors.secondary,
            size: 430,
          ),
        ),
        Positioned(
          bottom: -180,
          right: -100,
          child: _GlowOrb(
            color: AppColors.electricBlue,
            size: 360,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 90,
        sigmaY: 90,
      ),
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

class _TalkPlaceholder extends StatelessWidget {
  const _TalkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.graphic_eq_rounded,
      eyebrow: 'ELOQIA CONVERSATION',
      title: 'Talk with Mia',
      description:
          'Your immersive AI conversation experience is coming next.',
    );
  }
}

class _LearnPlaceholder extends StatelessWidget {
  const _LearnPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.auto_stories_rounded,
      eyebrow: 'LEARNING HUB',
      title: 'Your learning universe',
      description:
          'Vocabulary, grammar, listening, writing and more.',
    );
  }
}

class _ProgressPlaceholder extends StatelessWidget {
  const _ProgressPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.insights_rounded,
      eyebrow: 'YOUR EVOLUTION',
      title: 'Progress intelligence',
      description:
          'Your English evolution will become measurable and adaptive.',
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.person_rounded,
      eyebrow: 'YOUR IDENTITY',
      title: 'Learning profile',
      description:
          'Your Eloqia profile, preferences and personalization.',
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;

  const _ComingSoonPage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 24,
              sigmaY: 24,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                color: Colors.white.withValues(alpha: 0.055),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
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
                          blurRadius: 35,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    eyebrow,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}