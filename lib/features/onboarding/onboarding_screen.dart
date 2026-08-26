import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/persistent_app_controller.dart';
import '../../models/learning_profile.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_button.dart';
import 'widgets/progress_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Single source of truth for the complete onboarding experience.
  final LearningProfile _profile = LearningProfile();

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  final PageController _pageController = PageController();

  // ===========================================================================
  // ANIMATIONS
  // ===========================================================================

  late final AnimationController _contentController;
  late final AnimationController _ambientController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;

  // ===========================================================================
  // STATE
  // ===========================================================================

  int _currentPage = 0;

  bool _isTransitioning = false;

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  static const int _totalPages = 15;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    _ambientController.dispose();
    _pulseController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  bool get _canContinue {
    switch (_currentPage) {
      case 0:
        return true;

      case 1:
        return _profile.name.trim().isNotEmpty;

      case 2:
        return _profile.primaryGoal.isNotEmpty;

      case 3:
        return _profile.secondaryGoals.isNotEmpty;

      case 4:
        return _profile.difficulties.isNotEmpty;

      case 5:
        return _profile.strengths.isNotEmpty;

      case 6:
        return _profile.confidenceLevel.isNotEmpty;

      case 7:
        return _profile.speakingSituations.isNotEmpty;

      case 8:
        return _profile.learningPreferences.isNotEmpty;

      case 9:
        return _profile.preferredCorrectionStyle.isNotEmpty;

      case 10:
        return _profile.motivation.trim().isNotEmpty;

      case 11:
        return _profile.learningPace.isNotEmpty;

      case 12:
        return _profile.interests.isNotEmpty;

      case 13:
        return _profile.preferredTutorStyle.isNotEmpty;

      case 14:
        return _profile.currentLevel.isNotEmpty;

      default:
        return false;
    }
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  Future<void> _nextPage() async {
    if (!_canContinue || _isTransitioning) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentPage == _totalPages - 1) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _isTransitioning = true;
    });

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );

    if (!mounted) {
      return;
    }

    _contentController
      ..reset()
      ..forward();

    setState(() {
      _isTransitioning = false;
    });
  }

  Future<void> _previousPage() async {
    if (_currentPage <= 0 || _isTransitioning) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isTransitioning = true;
    });

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );

    if (!mounted) {
      return;
    }

    _contentController
      ..reset()
      ..forward();

    setState(() {
      _isTransitioning = false;
    });
  }

  void _onPageChanged(int page) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPage = page;
    });
  }

  // ===========================================================================
  // SELECTION
  // ===========================================================================

  void _toggleSelection(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  // ===========================================================================
  // FINISH
  // ===========================================================================

  Future<void> _finishOnboarding() async {
    if (!_canContinue || _isTransitioning) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool completed =
        await PersistentAppController.instance.completeOnboarding();

    if (!mounted || !completed) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 1100),
        reverseTransitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _OnboardingCompletionScreen(profile: _profile);
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final Animation<double> curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.035,
                end: 1.0,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: OnboardingBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAmbientGlow(),
            _buildSecondaryGlow(),
            _buildAtmosphericLight(),
            _buildEdgeVignette(),
            _buildTopLightBeam(),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool compact = constraints.maxHeight < 720;
                  final bool veryCompact = constraints.maxHeight < 620;
                  final bool wide = constraints.maxWidth >= 900;

                  final double horizontalPadding = wide
                      ? 34
                      : constraints.maxWidth < 380
                      ? 14
                      : 18;

                  final double verticalPadding = veryCompact
                      ? 6
                      : compact
                      ? 10
                      : 18;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide ? 1180 : 820,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          children: [
                            _buildTopBar(compact: compact),

                            SizedBox(
                              height: veryCompact
                                  ? 6
                                  : compact
                                  ? 10
                                  : 18,
                            ),

                            Expanded(
                              child: _buildPageViewport(),
                            ),

                            SizedBox(
                              height: veryCompact
                                  ? 5
                                  : compact
                                  ? 8
                                  : 14,
                            ),

                            _buildBottomControls(compact: compact),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE VIEWPORT
  // ===========================================================================

  Widget _buildPageViewport() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: [
        _buildWelcomePage(),
        _buildNamePage(),
        _buildPrimaryGoalPage(),
        _buildSecondaryGoalsPage(),
        _buildDifficultiesPage(),
        _buildStrengthsPage(),
        _buildConfidencePage(),
        _buildSpeakingPage(),
        _buildLearningStylePage(),
        _buildCorrectionPage(),
        _buildMotivationPage(),
        _buildPacePage(),
        _buildInterestsPage(),
        _buildTutorStylePage(),
        _buildLevelPage(),
      ],
    );
  }

  // ===========================================================================
  // AMBIENT ATMOSPHERE
  // ===========================================================================

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final double rotation = _ambientController.value * math.pi * 2;

        final double horizontalShift =
            math.sin(rotation * 0.72) * 52.0;

        final double verticalShift =
            math.cos(rotation * 0.48) * 34.0;

        final double pulse =
            0.96 + (math.sin(rotation) + 1.0) * 0.018;

        return IgnorePointer(
          child: Center(
            child: Transform.translate(
              offset: Offset(horizontalShift, verticalShift),
              child: Transform.scale(
                scale: pulse,
                child: Container(
                  width: 720,
                  height: 720,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.18, -0.20),
                      radius: 0.72,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.095),
                        AppColors.secondary.withValues(alpha: 0.045),
                        AppColors.primary.withValues(alpha: 0.014),
                        Colors.transparent,
                      ],
                      stops: const [
                        0.0,
                        0.32,
                        0.62,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryGlow() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double value = Curves.easeInOut.transform(
          _pulseController.value,
        );

        return IgnorePointer(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Transform.translate(
              offset: Offset(
                18.0 * value,
                -20.0 * value,
              ),
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(
                        alpha: 0.035 + (value * 0.018),
                      ),
                      AppColors.primary.withValues(
                        alpha: 0.012,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [
                      0.0,
                      0.48,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAtmosphericLight() {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0.92, -0.78),
            child: Container(
              width: 430,
              height: 430,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.052),
                    AppColors.secondary.withValues(alpha: 0.015),
                    Colors.transparent,
                  ],
                  stops: const [
                    0.0,
                    0.42,
                    1.0,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.90, 0.82),
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.032),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLightBeam() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 80),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.12),
                AppColors.secondary.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeVignette() {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.18,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.16),
              Colors.black.withValues(alpha: 0.32),
            ],
            stops: const [
              0.0,
              0.56,
              0.84,
              1.0,
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar({required bool compact}) {
    final double progress = (_currentPage + 1) / _totalPages;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: compact ? 48 : 58,
        child: Row(
          children: [
            _buildBackButton(),

            Expanded(
              child: _buildBrandCenter(
                progress: progress,
                compact: compact,
              ),
            ),

            _buildPageCounter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCenter({
    required double progress,
    required bool compact,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primary,
                Colors.white,
                Colors.white.withValues(alpha: 0.92),
                AppColors.secondary,
              ],
              stops: const [
                0.0,
                0.38,
                0.58,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'ELOQIA AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.8,
              height: 1,
            ),
          ),
        ),

        if (!compact) ...[
          const SizedBox(height: 5),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Text(
              _currentPage == _totalPages - 1
                  ? 'FINAL STEP'
                  : 'CRAFTING YOUR LEARNING PROFILE',
              key: ValueKey<bool>(
                _currentPage == _totalPages - 1,
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.28),
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildPremiumProgressBar(progress),
        ],
      ],
    );
  }

  Widget _buildPremiumProgressBar(double progress) {
    return Container(
      width: 156,
      height: 5,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.48),
                      blurRadius: 9,
                    ),
                  ],
                ),
              ),
            ),

            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.34),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCounter() {
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            (_currentPage + 1).toString().padLeft(2, '0'),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${_totalPages.toString().padLeft(2, '0')}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.22),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _currentPage == 0 ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: _currentPage == 0,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 22,
                sigmaY: 22,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.085),
                      Colors.white.withValues(alpha: 0.022),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.11),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 26,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.045),
                      blurRadius: 20,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _previousPage,
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                  ),
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 00 — WELCOME
  // ===========================================================================

  Widget _buildWelcomePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.auto_awesome_rounded,
      eyebrow: 'WELCOME TO ELOQIA',
      title: 'Let’s build your\nEnglish journey.',
      description:
          'A few thoughtful questions will help Eloqia understand how you learn, what you want to achieve, and how your AI tutor should guide you.',
      child: const _PremiumInfoCard(
        icon: Icons.psychology_alt_rounded,
        title: 'Your experience will be uniquely yours.',
        subtitle:
            'There are no right or wrong answers. Choose what feels most like you.',
      ),
    );
  }

  // ===========================================================================
  // PAGE 01 — NAME
  // ===========================================================================

  Widget _buildNamePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.person_rounded,
      eyebrow: '01 · ABOUT YOU',
      title: 'What should we\ncall you?',
      description:
          'Your name makes every interaction with Eloqia feel a little more personal.',
      child: _PremiumTextField(
        initialValue: _profile.name,
        onChanged: (value) {
          setState(() {
            _profile.name = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 02 — PRIMARY GOAL
  // ===========================================================================

  Widget _buildPrimaryGoalPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.track_changes_rounded,
      eyebrow: '02 · YOUR DIRECTION',
      title: 'What matters most\nto you?',
      description:
          'Choose the one goal you want Eloqia to prioritize above everything else.',
      child: _SingleChoiceGrid(
        options: const [
          _ChoiceData(
            'speaking',
            'Speak confidently',
            'Feel natural in real conversations',
            Icons.record_voice_over_rounded,
          ),
          _ChoiceData(
            'school',
            'Excel at school',
            'Strengthen your academic English',
            Icons.school_rounded,
          ),
          _ChoiceData(
            'travel',
            'Travel confidently',
            'Communicate naturally around the world',
            Icons.public_rounded,
          ),
          _ChoiceData(
            'fluency',
            'Become fluent',
            'Reach a truly advanced level',
            Icons.auto_awesome_rounded,
          ),
        ],
        selected: _profile.primaryGoal,
        onSelected: (value) {
          setState(() {
            _profile.primaryGoal = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 03 — SECONDARY GOALS
  // ===========================================================================

  Widget _buildSecondaryGoalsPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.layers_rounded,
      eyebrow: '03 · MORE GOALS',
      title: 'What else would you\nlike to improve?',
      description:
          'Select everything that sounds useful to you.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'vocabulary',
            'Vocabulary',
            'Express yourself with richer words',
            Icons.menu_book_rounded,
          ),
          _ChoiceData(
            'grammar',
            'Grammar',
            'Speak and write more accurately',
            Icons.auto_fix_high_rounded,
          ),
          _ChoiceData(
            'pronunciation',
            'Pronunciation',
            'Sound clearer and more natural',
            Icons.graphic_eq_rounded,
          ),
          _ChoiceData(
            'listening',
            'Listening',
            'Understand people more effortlessly',
            Icons.headphones_rounded,
          ),
          _ChoiceData(
            'writing',
            'Writing',
            'Write naturally and confidently',
            Icons.edit_note_rounded,
          ),
          _ChoiceData(
            'confidence',
            'Confidence',
            'Stop overthinking when speaking',
            Icons.favorite_rounded,
          ),
        ],
        selected: _profile.secondaryGoals,
        onToggle: (value) {
          _toggleSelection(
            _profile.secondaryGoals,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 04 — DIFFICULTIES
  // ===========================================================================

  Widget _buildDifficultiesPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.insights_rounded,
      eyebrow: '04 · YOUR CHALLENGES',
      title: 'Where do you feel\nstuck?',
      description:
          'Be honest. This helps Eloqia know where to focus first.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'speaking',
            'Speaking spontaneously',
            'Finding words quickly',
            Icons.mic_rounded,
          ),
          _ChoiceData(
            'grammar',
            'Grammar',
            'Knowing which structure to use',
            Icons.rule_rounded,
          ),
          _ChoiceData(
            'vocabulary',
            'Vocabulary',
            'Knowing enough words',
            Icons.library_books_rounded,
          ),
          _ChoiceData(
            'listening',
            'Understanding accents',
            'Fast or unfamiliar English',
            Icons.hearing_rounded,
          ),
          _ChoiceData(
            'pronunciation',
            'Pronunciation',
            'Feeling comfortable with my accent',
            Icons.record_voice_over_rounded,
          ),
          _ChoiceData(
            'confidence',
            'Confidence',
            'Fear of making mistakes',
            Icons.psychology_rounded,
          ),
        ],
        selected: _profile.difficulties,
        onToggle: (value) {
          _toggleSelection(
            _profile.difficulties,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 05 — STRENGTHS
  // ===========================================================================

  Widget _buildStrengthsPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.bolt_rounded,
      eyebrow: '05 · YOUR STRENGTHS',
      title: 'What are you already\ngood at?',
      description:
          'Knowing your strengths lets Eloqia challenge you without wasting your time.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'speaking',
            'Speaking',
            'I can express my ideas',
            Icons.mic_none_rounded,
          ),
          _ChoiceData(
            'vocabulary',
            'Vocabulary',
            'I know many useful words',
            Icons.auto_stories_rounded,
          ),
          _ChoiceData(
            'grammar',
            'Grammar',
            'I understand structures well',
            Icons.account_tree_rounded,
          ),
          _ChoiceData(
            'listening',
            'Listening',
            'I understand spoken English',
            Icons.headphones_rounded,
          ),
          _ChoiceData(
            'writing',
            'Writing',
            'I can communicate clearly',
            Icons.draw_rounded,
          ),
          _ChoiceData(
            'pronunciation',
            'Pronunciation',
            'People understand me easily',
            Icons.graphic_eq_rounded,
          ),
        ],
        selected: _profile.strengths,
        onToggle: (value) {
          _toggleSelection(
            _profile.strengths,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 06 — CONFIDENCE
  // ===========================================================================

  Widget _buildConfidencePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.favorite_border_rounded,
      eyebrow: '06 · CONFIDENCE',
      title: 'How comfortable do\nyou feel in English?',
      description:
          'There is no judgment here. Eloqia adapts to where you are today.',
      child: _SingleChoiceList(
        options: const [
          _ChoiceData(
            'low',
            'I feel nervous',
            'I often hesitate before speaking',
            Icons.cloud_rounded,
          ),
          _ChoiceData(
            'developing',
            'I am getting there',
            'I can communicate but still hesitate',
            Icons.trending_up_rounded,
          ),
          _ChoiceData(
            'comfortable',
            'I feel comfortable',
            'I can usually express myself',
            Icons.check_circle_outline_rounded,
          ),
          _ChoiceData(
            'very_confident',
            'I feel very confident',
            'I rarely struggle to communicate',
            Icons.verified_rounded,
          ),
        ],
        selected: _profile.confidenceLevel,
        onSelected: (value) {
          setState(() {
            _profile.confidenceLevel = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 07 — SPEAKING SITUATIONS
  // ===========================================================================

  Widget _buildSpeakingPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.forum_rounded,
      eyebrow: '07 · REAL LIFE',
      title: 'Where do you want\nto speak English?',
      description:
          'Select all the situations where you would like to feel confident.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'friends',
            'With friends',
            'Casual conversations',
            Icons.people_rounded,
          ),
          _ChoiceData(
            'travel',
            'While travelling',
            'Hotels, airports and cities',
            Icons.flight_takeoff_rounded,
          ),
          _ChoiceData(
            'school',
            'At school',
            'Classes, presentations and exams',
            Icons.school_rounded,
          ),
          _ChoiceData(
            'online',
            'Online',
            'Games, communities and social media',
            Icons.public_rounded,
          ),
          _ChoiceData(
            'work',
            'Professionally',
            'Meetings and future opportunities',
            Icons.business_center_rounded,
          ),
          _ChoiceData(
            'everyday',
            'Everyday life',
            'Make English part of my life',
            Icons.wb_sunny_rounded,
          ),
        ],
        selected: _profile.speakingSituations,
        onToggle: (value) {
          _toggleSelection(
            _profile.speakingSituations,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 08 — LEARNING STYLE
  // ===========================================================================

  Widget _buildLearningStylePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.auto_awesome_rounded,
      eyebrow: '08 · HOW YOU LEARN',
      title: 'What makes learning\nclick for you?',
      description:
          'Select the learning experiences that keep you engaged.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'conversation',
            'Real conversations',
            'Learn by actually speaking',
            Icons.chat_bubble_rounded,
          ),
          _ChoiceData(
            'visual',
            'Visual learning',
            'Examples, images and context',
            Icons.visibility_rounded,
          ),
          _ChoiceData(
            'challenges',
            'Challenges',
            'Games, goals and progression',
            Icons.emoji_events_rounded,
          ),
          _ChoiceData(
            'explanations',
            'Clear explanations',
            'Understand why something works',
            Icons.lightbulb_rounded,
          ),
          _ChoiceData(
            'practice',
            'Practice',
            'Learn by doing repeatedly',
            Icons.replay_rounded,
          ),
          _ChoiceData(
            'immersion',
            'Immersion',
            'Surround myself with English',
            Icons.language_rounded,
          ),
        ],
        selected: _profile.learningPreferences,
        onToggle: (value) {
          _toggleSelection(
            _profile.learningPreferences,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 09 — CORRECTION STYLE
  // ===========================================================================

  Widget _buildCorrectionPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.tune_rounded,
      eyebrow: '09 · FEEDBACK',
      title: 'How should your tutor\ncorrect you?',
      description:
          'Choose the balance between encouragement and precision.',
      child: _SingleChoiceList(
        options: const [
          _ChoiceData(
            'gentle',
            'Gentle & encouraging',
            'Correct me softly and keep the conversation flowing',
            Icons.favorite_rounded,
          ),
          _ChoiceData(
            'balanced',
            'Balanced',
            'Correct important mistakes without interrupting too much',
            Icons.balance_rounded,
          ),
          _ChoiceData(
            'direct',
            'Direct & precise',
            'Point out mistakes clearly so I improve faster',
            Icons.flash_on_rounded,
          ),
        ],
        selected: _profile.preferredCorrectionStyle,
        onSelected: (value) {
          setState(() {
            _profile.preferredCorrectionStyle = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 10 — MOTIVATION
  // ===========================================================================

  Widget _buildMotivationPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.local_fire_department_rounded,
      eyebrow: '10 · YOUR WHY',
      title: 'Why does English\nmatter to you?',
      description:
          'Choose the reason that genuinely motivates you.',
      child: _SingleChoiceList(
        options: const [
          _ChoiceData(
            'confidence',
            'I want to feel confident',
            'Speak without fear or overthinking',
            Icons.favorite_rounded,
          ),
          _ChoiceData(
            'school',
            'I want to succeed at school',
            'Reach my academic goals',
            Icons.school_rounded,
          ),
          _ChoiceData(
            'future',
            'I am building my future',
            'Open doors for studies and opportunities',
            Icons.rocket_launch_rounded,
          ),
          _ChoiceData(
            'languages',
            'I love languages',
            'I want to become genuinely fluent',
            Icons.language_rounded,
          ),
        ],
        selected: _profile.motivation,
        onSelected: (value) {
          setState(() {
            _profile.motivation = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 11 — PACE
  // ===========================================================================

  Widget _buildPacePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.speed_rounded,
      eyebrow: '11 · YOUR PACE',
      title: 'How do you want\nto progress?',
      description:
          'Eloqia can adapt the intensity of your learning experience.',
      child: _SingleChoiceList(
        options: const [
          _ChoiceData(
            'relaxed',
            'Relaxed',
            'A calm rhythm that fits naturally into my life',
            Icons.spa_rounded,
          ),
          _ChoiceData(
            'regular',
            'Consistent',
            'A steady rhythm with regular progress',
            Icons.calendar_month_rounded,
          ),
          _ChoiceData(
            'intensive',
            'Intensive',
            'Push me and help me progress quickly',
            Icons.bolt_rounded,
          ),
        ],
        selected: _profile.learningPace,
        onSelected: (value) {
          setState(() {
            _profile.learningPace = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 12 — INTERESTS
  // ===========================================================================

  Widget _buildInterestsPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.explore_rounded,
      eyebrow: '12 · YOUR WORLD',
      title: 'What are you\ninterested in?',
      description:
          'Eloqia can use your interests to make conversations feel relevant to you.',
      child: _MultiChoiceGrid(
        options: const [
          _ChoiceData(
            'technology',
            'Technology',
            'AI, computers & innovation',
            Icons.memory_rounded,
          ),
          _ChoiceData(
            'music',
            'Music',
            'Artists, songs & culture',
            Icons.music_note_rounded,
          ),
          _ChoiceData(
            'movies',
            'Movies & series',
            'Stories, characters & cinema',
            Icons.movie_rounded,
          ),
          _ChoiceData(
            'gaming',
            'Gaming',
            'Games, worlds & communities',
            Icons.sports_esports_rounded,
          ),
          _ChoiceData(
            'science',
            'Science',
            'Discovery & how things work',
            Icons.science_rounded,
          ),
          _ChoiceData(
            'travel',
            'Travel',
            'Places, cultures & adventures',
            Icons.travel_explore_rounded,
          ),
          _ChoiceData(
            'sports',
            'Sports',
            'Competition, teams & performance',
            Icons.sports_soccer_rounded,
          ),
          _ChoiceData(
            'business',
            'Business',
            'Entrepreneurship & the future',
            Icons.business_rounded,
          ),
        ],
        selected: _profile.interests,
        onToggle: (value) {
          _toggleSelection(
            _profile.interests,
            value,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 13 — TUTOR STYLE
  // ===========================================================================

  Widget _buildTutorStylePage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.psychology_rounded,
      eyebrow: '13 · YOUR AI TUTOR',
      title: 'What should your\ntutor feel like?',
      description:
          'Select the qualities you would love your AI tutor to have.',
      child: _SingleChoiceList(
        options: const [
          _ChoiceData(
            'warm',
            'Warm & supportive',
            'Patient, kind and always encouraging',
            Icons.favorite_border_rounded,
          ),
          _ChoiceData(
            'energetic',
            'Energetic & motivating',
            'Keep me moving and challenge me',
            Icons.local_fire_department_rounded,
          ),
          _ChoiceData(
            'calm',
            'Calm & patient',
            'Give me space to think and improve',
            Icons.self_improvement_rounded,
          ),
          _ChoiceData(
            'challenging',
            'Challenging & precise',
            'Push me toward a higher level',
            Icons.trending_up_rounded,
          ),
        ],
        selected: _profile.preferredTutorStyle,
        onSelected: (value) {
          setState(() {
            _profile.preferredTutorStyle = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // PAGE 14 — LEVEL
  // ===========================================================================

  Widget _buildLevelPage() {
    return _QuestionPage(
      controller: _contentController,
      icon: Icons.stars_rounded,
      eyebrow: '14 · YOUR LEVEL',
      title: 'Where do you think\nyou are today?',
      description:
          'Your starting point helps Eloqia choose the right level of challenge.',
      child: _SingleChoiceGrid(
        options: const [
          _ChoiceData(
            'A1',
            'A1 · Beginner',
            'I know the basics',
            Icons.looks_one_rounded,
          ),
          _ChoiceData(
            'A2',
            'A2 · Elementary',
            'I can handle simple conversations',
            Icons.looks_two_rounded,
          ),
          _ChoiceData(
            'B1',
            'B1 · Intermediate',
            'I can communicate independently',
            Icons.looks_3_rounded,
          ),
          _ChoiceData(
            'B2',
            'B2 · Upper intermediate',
            'I communicate fairly comfortably',
            Icons.looks_4_rounded,
          ),
          _ChoiceData(
            'C1',
            'C1 · Advanced',
            'I express complex ideas naturally',
            Icons.looks_5_rounded,
          ),
          _ChoiceData(
            'C2',
            'C2 · Mastery',
            'I use English at an exceptional level',
            Icons.workspace_premium_rounded,
          ),
        ],
        selected: _profile.currentLevel,
        onSelected: (value) {
          setState(() {
            _profile.currentLevel = value;
          });
        },
      ),
    );
  }

  // ===========================================================================
  // BOTTOM CONTROLS
  // ===========================================================================

  Widget _buildBottomControls({
    required bool compact,
  }) {
    final bool isLastPage =
        _currentPage == _totalPages - 1;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          OnboardingProgressIndicator(
            currentPage: _currentPage,
            totalPages: _totalPages,
          ),

          SizedBox(
            height: compact ? 8 : 13,
          ),

          OnboardingButton(
            label: _currentPage == 0
                ? 'Begin my journey'
                : isLastPage
                ? 'Create my Eloqia experience'
                : 'Continue',
            icon: _currentPage == 0
                ? Icons.arrow_forward_rounded
                : isLastPage
                ? Icons.auto_awesome_rounded
                : Icons.arrow_forward_rounded,
            enabled: _canContinue,
            onPressed: _canContinue
                ? _nextPage
                : null,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUESTION PAGE
// =============================================================================

class _QuestionPage extends StatelessWidget {
  final AnimationController controller;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  const _QuestionPage({
    required this.controller,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> entrance = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: entrance,
      builder: (context, pageChild) {
        final double opacity =
            entrance.value.clamp(0.0, 1.0);

        final double verticalOffset =
            24.0 * (1.0 - entrance.value);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, verticalOffset),
            child: pageChild,
          ),
        );
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroIcon(),
            const SizedBox(height: 22),

            Text(
              eyebrow,
              style: TextStyle(
                color: AppColors.primary.withValues(
                  alpha: 0.92,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.15,
                height: 1,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 31,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.85,
              ),
            ),

            const SizedBox(height: 13),

            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 13,
                height: 1.52,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.02,
              ),
            ),

            const SizedBox(height: 27),

            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.16,
                ),
                AppColors.secondary.withValues(
                  alpha: 0.045,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.075),
                Colors.white.withValues(alpha: 0.022),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.15,
                ),
                blurRadius: 30,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(
                    alpha: 0.20,
                  ),
                  AppColors.secondary.withValues(
                    alpha: 0.07,
                  ),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(
                alpha: 0.94,
              ),
              size: 25,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PREMIUM TEXT FIELD
// =============================================================================

class _PremiumTextField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _PremiumTextField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_PremiumTextField> createState() =>
      _PremiumTextFieldState();
}

class _PremiumTextFieldState
    extends State<_PremiumTextField> {
  late final TextEditingController _controller;

  bool _focused = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (!mounted) {
          return;
        }

        setState(() {
          _focused = focused;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            if (_focused)
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.14,
                ),
                blurRadius: 34,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(
                      alpha: _focused ? 0.065 : 0.045,
                    ),
                    Colors.white.withValues(
                      alpha: _focused ? 0.024 : 0.015,
                    ),
                  ],
                ),
                border: Border.all(
                  color: _focused
                      ? AppColors.primary.withValues(
                          alpha: 0.52,
                        )
                      : Colors.white.withValues(
                          alpha: 0.075,
                        ),
                  width: _focused ? 1.2 : 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                textCapitalization:
                    TextCapitalization.words,
                cursorColor: AppColors.primary,
                cursorWidth: 1.5,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Your first name',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.24,
                    ),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 4,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: _focused
                          ? AppColors.primary
                          : Colors.white.withValues(
                              alpha: 0.40,
                            ),
                      size: 21,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 21,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(27),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(27),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(27),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// =============================================================================
// PREMIUM CHOICE SYSTEM
// =============================================================================

class _ChoiceData {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ChoiceData(
    this.value,
    this.title,
    this.subtitle,
    this.icon,
  );
}

// =============================================================================
// SINGLE CHOICE LIST
// =============================================================================

class _SingleChoiceList extends StatelessWidget {
  final List<_ChoiceData> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SingleChoiceList({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < options.length; index++) ...[
          _ChoiceCard(
            data: options[index],
            selected: selected == options[index].value,
            onTap: () => onSelected(options[index].value),
          ),
          if (index < options.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// =============================================================================
// SINGLE CHOICE GRID
// =============================================================================

class _SingleChoiceGrid extends StatelessWidget {
  final List<_ChoiceData> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SingleChoiceGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns =
            constraints.maxWidth >= 540;

        if (!twoColumns) {
          return _SingleChoiceList(
            options: options,
            selected: selected,
            onSelected: onSelected,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.62,
          ),
          itemBuilder: (context, index) {
            final _ChoiceData option = options[index];

            return _ChoiceCard(
              data: option,
              selected:
                  selected == option.value,
              onTap: () =>
                  onSelected(option.value),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// MULTI CHOICE GRID
// =============================================================================

class _MultiChoiceGrid extends StatelessWidget {
  final List<_ChoiceData> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiChoiceGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns =
            constraints.maxWidth >= 540;

        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    twoColumns ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio:
                    twoColumns ? 1.62 : 3.9,
              ),
              itemBuilder: (context, index) {
                final _ChoiceData option =
                    options[index];

                return _ChoiceCard(
                  data: option,
                  selected:
                      selected.contains(option.value),
                  onTap: () =>
                      onToggle(option.value),
                );
              },
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Align(
                key: ValueKey<int>(selected.length),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selected.isEmpty
                          ? 'Select at least one option'
                          : '${selected.length} selected',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: 0.42),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// PREMIUM CHOICE CARD
// =============================================================================

class _ChoiceCard extends StatefulWidget {
  final _ChoiceData data;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ChoiceCard> createState() =>
      _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_pressController.isAnimating) {
      return;
    }

    await _pressController.forward();

    if (!mounted) {
      return;
    }

    await _pressController.reverse();

    if (!mounted) {
      return;
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        final double scale =
            1.0 - (_pressController.value * 0.018);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(24),
            gradient: widget.selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary
                          .withValues(alpha: 0.16),
                      AppColors.secondary
                          .withValues(alpha: 0.075),
                      Colors.white
                          .withValues(alpha: 0.025),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white
                          .withValues(alpha: 0.045),
                      Colors.white
                          .withValues(alpha: 0.018),
                    ],
                  ),
            border: Border.all(
              color: widget.selected
                  ? AppColors.primary
                      .withValues(alpha: 0.42)
                  : Colors.white
                      .withValues(alpha: 0.075),
              width:
                  widget.selected ? 1.2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.13),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              _ChoiceIcon(
                icon: widget.data.icon,
                selected: widget.selected,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _ChoiceText(
                  data: widget.data,
                  selected: widget.selected,
                ),
              ),
              const SizedBox(width: 8),
              _ChoiceSelectionIndicator(
                selected: widget.selected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CHOICE ICON
// =============================================================================

class _ChoiceIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _ChoiceIcon({
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
              ? Colors.white
                  .withValues(alpha: 0.22)
              : Colors.white
                  .withValues(alpha: 0.075),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary
                      .withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.94,
        duration:
            const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Icon(
          icon,
          color: selected
              ? Colors.white
              : Colors.white
                  .withValues(alpha: 0.58),
          size: 20,
        ),
      ),
    );
  }
}

// =============================================================================
// CHOICE TEXT
// =============================================================================

class _ChoiceText extends StatelessWidget {
  final _ChoiceData data;
  final bool selected;

  const _ChoiceText({
    required this.data,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        AnimatedDefaultTextStyle(
          duration:
              const Duration(milliseconds: 250),
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: selected ? 0.98 : 0.88,
            ),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
          child: Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: selected ? 0.52 : 0.37,
            ),
            fontSize: 10.5,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CHOICE SELECTION INDICATOR
// =============================================================================

class _ChoiceSelectionIndicator
    extends StatelessWidget {
  final bool selected;

  const _ChoiceSelectionIndicator({
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder:
          (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: selected
          ? Container(
              key: const ValueKey<String>(
                'selected',
              ),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(alpha: 0.30),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
            )
          : Container(
              key: const ValueKey<String>(
                'unselected',
              ),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: 0.025),
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: 0.12),
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// PREMIUM INFO CARD
// =============================================================================

class _PremiumInfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PremiumInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white
                .withValues(alpha: 0.055),
            Colors.white
                .withValues(alpha: 0.018),
          ],
        ),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.075),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary
                      .withValues(alpha: 0.18),
                  AppColors.secondary
                      .withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.primary
                    .withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white
                  .withValues(alpha: 0.88),
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: 0.40),
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPLETION SCREEN
// =============================================================================

class _OnboardingCompletionScreen
    extends StatefulWidget {
  final LearningProfile profile;

  const _OnboardingCompletionScreen({
    required this.profile,
  });

  @override
  State<_OnboardingCompletionScreen>
      createState() =>
          _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState
    extends State<_OnboardingCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1800),
    )..forward();

    Future.delayed(
      const Duration(milliseconds: 2300),
      _openHome,
    );
  }

  void _openHome() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 900),
        pageBuilder:
            (context, animation, secondaryAnimation) {
          return const HomeScreen();
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final Animation<double> curved =
              CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.985,
                end: 1.0,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OnboardingBackground(
            child: SizedBox.expand(),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double progress =
                    Curves.easeOutCubic.transform(
                  _controller.value,
                );

                return Opacity(
                  opacity:
                      progress.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale:
                        0.88 + (progress * 0.12),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _CompletionOrb(
                          progress: progress,
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Your Eloqia experience',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.profile.name
                                  .trim()
                                  .isEmpty
                              ? 'is being prepared ✨'
                              : 'is being prepared for '
                                  '${widget.profile.name.trim()} ✨',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white
                                .withValues(
                              alpha: 0.45,
                            ),
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _CompletionIndicator(
                          progress: progress,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPLETION ORB
// =============================================================================

class _CompletionOrb
    extends StatelessWidget {
  final double progress;

  const _CompletionOrb({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary
                    .withValues(
                  alpha: 0.14 * progress,
                ),
                AppColors.secondary
                    .withValues(
                  alpha: 0.045 * progress,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 154,
          height: 154,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.055),
            ),
          ),
        ),
        Container(
          width: 122,
          height: 122,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(
                  alpha: 0.38 * progress,
                ),
                blurRadius: 70,
                spreadRadius: 12,
              ),
              BoxShadow(
                color: AppColors.secondary
                    .withValues(
                  alpha: 0.16 * progress,
                ),
                blurRadius: 100,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// COMPLETION INDICATOR
// =============================================================================

class _CompletionIndicator
    extends StatelessWidget {
  final double progress;

  const _CompletionIndicator({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(999),
        child: Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: 0.055),
                borderRadius:
                    BorderRadius.circular(999),
              ),
            ),
            FractionallySizedBox(
              widthFactor:
                  progress.clamp(0.0, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}