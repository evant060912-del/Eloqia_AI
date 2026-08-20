import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/learning_profile.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'widgets/glass_card.dart';
import 'widgets/onboarding_background.dart';
import 'widgets/onboarding_button.dart';
import 'widgets/progress_indicator.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Single source of truth for the entire onboarding.
  ///
  /// Every answer collected throughout the experience is stored here.
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
      duration: const Duration(milliseconds: 700),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

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

    // Final page.
    if (_currentPage == _totalPages - 1) {
      _finishOnboarding();
      return;
    }

    setState(() {
      _isTransitioning = true;
    });

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
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
      curve: Curves.easeOutCubic,
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

  void _toggleSelection(
    List<String> list,
    String value,
  ) {
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

  void _finishOnboarding() {
    if (!_canContinue || _isTransitioning) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 1100,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 700,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return _OnboardingCompletionScreen(
            profile: _profile,
          );
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final Animation<double> curvedAnimation =
              CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.045,
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
          children: [
            _buildAmbientGlow(),

            SafeArea(
              child: LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final bool compact =
                      constraints.maxHeight < 720;

                  final bool wide =
                      constraints.maxWidth >= 900;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide ? 1100 : 760,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 42 : 20,
                          vertical: compact ? 12 : 22,
                        ),
                        child: Column(
                          children: [
                            _buildTopBar(
                              compact: compact,
                            ),

                            SizedBox(
                              height: compact ? 12 : 22,
                            ),

                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                onPageChanged:
                                    _onPageChanged,
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
                              ),
                            ),

                            SizedBox(
                              height: compact ? 10 : 18,
                            ),

                            _buildBottomControls(
                              compact: compact,
                            ),
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
  // AMBIENT ATMOSPHERE
  // ===========================================================================

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (
        context,
        child,
      ) {
        final double value =
            _ambientController.value;

        final double pulse =
            0.94 + (0.06 * (1 - (value * 2 - 1).abs()));

        final double rotation =
            value * 0.08;

        return IgnorePointer(
          child: Center(
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: pulse,
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: 0.075,
                        ),
                        AppColors.secondary.withValues(
                          alpha: 0.030,
                        ),
                        Colors.transparent,
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

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar({
    required bool compact,
  }) {
    final double progress =
        (_currentPage + 1) / _totalPages;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          _buildBackButton(),

          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'ELOQIA AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.5,
                    ),
                  ),
                ),

                if (!compact) ...[
                  const SizedBox(height: 5),

                  Text(
                    _currentPage ==
                            _totalPages - 1
                        ? 'FINAL STEP'
                        : 'CREATING YOUR LEARNING PROFILE',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.28,
                      ),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: 9),

                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor:
                            Colors.white.withValues(
                          alpha: 0.055,
                        ),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(
            width: 48,
            child: Text(
              '${(_currentPage + 1).toString().padLeft(2, '0')}/'
              '${_totalPages.toString().padLeft(2, '0')}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.38,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
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
        duration: const Duration(
          milliseconds: 250,
        ),
        opacity: _currentPage == 0 ? 0 : 1,
        child: IgnorePointer(
          ignoring: _currentPage == 0,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 18,
                sigmaY: 18,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.075,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 20,
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
                  color: Colors.white.withValues(
                    alpha: 0.78,
                  ),
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
        title: 'Your experience will be unique.',
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
      child: TextField(
        onChanged: (value) {
          setState(() {
            _profile.name = value;
          });
        },
        textCapitalization:
            TextCapitalization.words,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Your first name',
          hintStyle: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.25,
            ),
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: 0.045,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 21,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(22),
            borderSide: BorderSide(
              color: AppColors.primary
                  .withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
        ),
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
            height: compact ? 10 : 16,
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double opacity =
            Curves.easeOut.transform(
          controller.value,
        );

        final double scale =
            0.97 +
                (0.03 * controller.value);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 700,
                  ),
                  child: GlassCard(
                    padding:
                        const EdgeInsets.all(30),
                    borderRadius:
                        BorderRadius.circular(36),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,
                      children: [
                        _PremiumIcon(
                          icon: icon,
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        Text(
                          eyebrow,
                          style: TextStyle(
                            color:
                                AppColors.primary,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          title,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 30,
                            height: 1.12,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),

                        const SizedBox(
                          height: 13,
                        ),

                        Text(
                          description,
                          style: TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha: 0.48,
                            ),
                            fontSize: 14,
                            height: 1.55,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        child,
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
}

// =============================================================================
// PREMIUM ICON
// =============================================================================

class _PremiumIcon extends StatelessWidget {
  final IconData icon;

  const _PremiumIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(
              alpha: 0.24,
            ),
            AppColors.secondary.withValues(
              alpha: 0.10,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.10,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary
                .withValues(
              alpha: 0.16,
            ),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}

// =============================================================================
// CHOICE DATA
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
        for (int index = 0;
            index < options.length;
            index++) ...[
          _ChoiceCard(
            data: options[index],
            selected:
                selected == options[index].value,
            onTap: () {
              onSelected(
                options[index].value,
              );
            },
          ),
          if (index < options.length - 1)
            const SizedBox(height: 10),
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
      builder: (
        context,
        constraints,
      ) {
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
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (
            context,
            index,
          ) {
            final _ChoiceData option =
                options[index];

            return _ChoiceCard(
              data: option,
              selected:
                  selected == option.value,
              onTap: () {
                onSelected(
                  option.value,
                );
              },
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
      builder: (
        context,
        constraints,
      ) {
        final bool twoColumns =
            constraints.maxWidth >= 540;

        final int columns =
            twoColumns ? 2 : 1;

        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio:
                    twoColumns ? 1.55 : 3.8,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final _ChoiceData option =
                    options[index];

                return _ChoiceCard(
                  data: option,
                  selected:
                      selected.contains(
                    option.value,
                  ),
                  onTap: () {
                    onToggle(
                      option.value,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds: 220,
                ),
                child: Text(
                  '${selected.length} selected',
                  key: ValueKey(
                    selected.length,
                  ),
                  style: TextStyle(
                    color: AppColors.primary
                        .withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
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
// CHOICE CARD
// =============================================================================

class _ChoiceCard extends StatelessWidget {
  final _ChoiceData data;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(23),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary
                        .withValues(
                      alpha: 0.13,
                    ),
                    AppColors.secondary
                        .withValues(
                      alpha: 0.055,
                    ),
                  ],
                )
              : null,
          color: selected
              ? null
              : Colors.white.withValues(
                  alpha: 0.028,
                ),
          border: Border.all(
            color: selected
                ? AppColors.primary
                    .withValues(
                    alpha: 0.34,
                  )
                : Colors.white.withValues(
                    alpha: 0.065,
                  ),
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
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
                    : Colors.white
                        .withValues(
                        alpha: 0.045,
                      ),
                border: Border.all(
                  color: selected
                      ? Colors.white
                          .withValues(
                          alpha: 0.20,
                        )
                      : Colors.white
                          .withValues(
                          alpha: 0.065,
                        ),
                ),
              ),
              child: Icon(
                data.icon,
                color: selected
                    ? Colors.white
                    : Colors.white
                        .withValues(
                        alpha: 0.56,
                      ),
                size: 20,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white
                          .withValues(
                        alpha: 0.40,
                      ),
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds: 220,
              ),
              transitionBuilder: (
                child,
                animation,
              ) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                selected
                    ? Icons
                        .check_circle_rounded
                    : Icons
                        .radio_button_unchecked_rounded,
                key: ValueKey(selected),
                color: selected
                    ? AppColors.primary
                    : Colors.white
                        .withValues(
                        alpha: 0.16,
                      ),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM INFO CARD
// =============================================================================

class _PremiumInfoCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
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
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary
                  .withValues(
                alpha: 0.08,
              ),
              border: Border.all(
                color: AppColors.primary
                    .withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
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
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.40,
                    ),
                    fontSize: 11,
                    height: 1.35,
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
      transitionDuration: const Duration(
        milliseconds: 900,
      ),
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
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
        children: [
          const OnboardingBackground(
            child: SizedBox.expand(),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (
                context,
                child,
              ) {
                final double progress =
                    Curves.easeOutCubic.transform(
                  _controller.value,
                );

                return Opacity(
                  opacity: progress.clamp(
                    0.0,
                    1.0,
                  ),
                  child: Transform.scale(
                    scale: 0.88 +
                        (progress * 0.12),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _CompletionOrb(
                          progress: progress,
                        ),

                        const SizedBox(
                          height: 34,
                        ),

                        const Text(
                          'Your Eloqia experience',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          widget.profile.name
                                  .trim()
                                  .isEmpty
                              ? 'is being prepared ✨'
                              : 'is being prepared for ${widget.profile.name.trim()} ✨',
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

                        const SizedBox(
                          height: 26,
                        ),

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

class _CompletionOrb extends StatelessWidget {
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
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.12 * progress,
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Container(
          width: 120,
          height: 120,
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
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(
                  alpha: 0.35 * progress,
                ),
                blurRadius: 70,
                spreadRadius: 12,
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
      width: 150,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor:
              Colors.white.withValues(
            alpha: 0.06,
          ),
          valueColor:
              AlwaysStoppedAnimation<Color>(
            AppColors.primary.withValues(
              alpha: 0.75,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TEMPORARY HOME TARGET
// =============================================================================
//
// This is intentionally kept as a safe navigation target until we connect
// the onboarding directly to the existing HomeScreen.
//
// The real LearningProfile is already passed here and preserved.
//

