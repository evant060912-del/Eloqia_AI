import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/lessons/engine/lesson_engine.dart';
import '../../features/lessons/lesson_launcher.dart';
import '../../features/lessons/models/lesson_models.dart';
import '../../models/learning_profile.dart';
import '../../services/learning/learning_profile_service.dart';
import '../../services/learning/personal_plan.dart';
import '../../services/learning/personal_plan_service.dart';
import '../../services/progress_service.dart';
import '../../services/voice/voice_output_provider.dart';
import '../../theme/app_colors.dart';
import '../tutors/mia/mia_chat_screen.dart';
import '../tutors/mia/mia_screen.dart';
import '../tutors/mia/widgets/mia_presence.dart';
import '../writing/writing_studio_screen.dart';
import 'widgets/personal_plan_card.dart';
import 'widgets/quick_actions_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  LearningProfile? _profile;
  ProgressSnapshot? _progress;
  LessonContext? _lessonContext;
  LessonChoice? _lessonChoice;
  PersonalPlan? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      // The daily goal follows the onboarding pace, once.
      await PersonalPlanService.applyDailyGoalOnce(
        PersonalPlan.from(await LearningProfileService.getProfile()),
      );
      final List<Object?> loaded = await Future.wait<Object?>(<Future<Object?>>[
        LearningProfileService.getProfile(),
        ProgressService.getSnapshot(),
        LessonContext.load(),
      ]);
      final LearningProfile profile = loaded[0]! as LearningProfile;
      final ProgressSnapshot progress = loaded[1]! as ProgressSnapshot;
      final LessonContext lessonContext = loaded[2]! as LessonContext;
      final LessonChoice lessonChoice = lessonContext.recommend();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _progress = progress;
        _lessonContext = lessonContext;
        _lessonChoice = lessonChoice;
        _plan = PersonalPlan.from(profile);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openMia() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MiaScreen()));

    if (!mounted) {
      return;
    }

    await _loadHomeData();
  }

  Future<void> _handleLearningAction(QuickActionData action) =>
      _openActivity(action.title);

  Future<void> _openActivity(String title) async {
    switch (title) {
      case 'Conversation':
        final LearningProfile? talker = _profile;
        if (talker == null) {
          await _openMia();
          return;
        }
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => MiaChatScreen(profile: talker),
          ),
        );
        if (mounted) await _loadHomeData();
        return;
      case 'Vocabulary':
        await _openLesson(LessonSkill.vocabulary);
        return;
      case 'Grammar':
        await _openLesson(LessonSkill.grammar);
        return;
      case 'Reading':
        await _openLesson(LessonSkill.reading);
        return;
      case 'Listening':
        await _openLesson(LessonSkill.listening);
        return;
      case 'Writing':
        final LearningProfile? profile = _profile;
        if (profile == null) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => WritingStudioScreen(profile: profile),
          ),
        );
        if (mounted) await _loadHomeData();
        return;
    }
  }

  Future<void> _openLesson(LessonSkill skill) async {
    await LessonLauncher.openSkill(context, skill);
    if (mounted) await _loadHomeData();
  }

  Future<void> _openRecommendedLesson() async {
    final LessonContext? data = _lessonContext;
    final LessonChoice? choice = _lessonChoice;
    if (data == null || choice == null) {
      await LessonLauncher.openRecommended(context);
    } else {
      await LessonLauncher.openLesson(context, choice, data);
    }
    if (mounted) await _loadHomeData();
  }

  Future<void> _speakMiaGreeting() async {
    final String name = _profile?.name.trim() ?? '';
    final String greeting = name.isEmpty
        ? "Hi, I'm Mia. Ready to work on your English together?"
        : "Hi, $name. Ready to work on your English together?";
    await MiaVoice.provider.speak(greeting, style: MiaSpeechStyle.warm);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _HomeAmbientBackground(),

          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final double animationProgress = Curves.easeOutCubic.transform(
                  _animationController.value,
                );

                return Opacity(
                  opacity: animationProgress,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - animationProgress)),
                    child: child,
                  ),
                );
              },
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadHomeData,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 34),
                      _buildHeroGreeting(),
                      const SizedBox(height: 22),
                      _buildMiaCompanion(),
                      const SizedBox(height: 24),
                      _buildDailyIntelligence(),
                      if (_plan != null && !_plan!.isEmpty) ...[
                        const SizedBox(height: 22),
                        PersonalPlanCard(
                          plan: _plan!,
                          onOpen: (PlanArea area) =>
                              _openActivity(area.activity),
                          onExamPrep: () => _openActivity('Writing'),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _buildStats(),
                      const SizedBox(height: 34),
                      _buildSectionHeader(
                        eyebrow: 'YOUR EVOLUTION',
                        title: 'Learning progress',
                        subtitle: 'Every session moves you forward.',
                      ),
                      const SizedBox(height: 14),
                      _buildEvolutionCard(),
                      const SizedBox(height: 34),
                      QuickActionsSection(
                        onActionSelected: _handleLearningAction,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoadingOverlay() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _isLoading ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: AppColors.background.withValues(alpha: 0.28),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primaryBright,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [
                      AppColors.primaryBright,
                      AppColors.primary,
                      AppColors.secondaryBright,
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  'ELOQIA AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.2,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'YOUR PERSONAL AI LANGUAGE ACADEMY',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.62),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.9,
                ),
              ),
            ],
          ),
        ),
        _buildProfileButton(),
      ],
    );
  }

  Widget _buildProfileButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(alpha: 0.12),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.primaryBright,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHeroGreeting() {
    final String name = _profile?.name.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBright,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.65),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'WELCOME BACK',
              style: TextStyle(
                color: AppColors.primaryBright.withValues(alpha: 0.88),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(width: 6),
            const Text('👋', style: TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          name.isEmpty
              ? 'Ready for your\nnext evolution?'
              : 'Ready for your\nnext evolution, $name?',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 38,
            height: 1.01,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Your journey continues today. '
          'Let’s make every minute count.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildMiaCompanion() {
    final LessonChoice? choice = _lessonChoice;
    final String title =
        choice?.lesson.title ??
        (_isLoading
            ? 'Preparing your next lesson'
            : 'Recommendation unavailable');
    final String reason =
        choice?.reason ??
        (_isLoading
            ? 'Mia is checking your learning history.'
            : 'Refresh to try again.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const MiaPresence(
                size: 66,
                showLabel: false,
                state: MiaPresenceState.encouraging,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'MIA’S RECOMMENDATION',
                      style: TextStyle(
                        color: AppColors.primaryBright,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: _speakMiaGreeting,
                tooltip: 'Hear Mia',
                icon: const Icon(Icons.volume_up_rounded),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: choice == null
                    ? _loadHomeData
                    : _openRecommendedLesson,
                icon: Icon(
                  choice == null
                      ? Icons.refresh_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(choice == null ? 'Refresh' : 'Start lesson'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DAILY INTELLIGENCE
  // ===========================================================================

  Widget _buildDailyIntelligence() {
    final ProgressSnapshot progress = _currentProgress;

    final bool goalComplete = progress.isDailyGoalComplete;

    final int remaining = progress.remainingDailyGoal;

    final String goalDescription = goalComplete
        ? 'Your daily goal is complete. Keep the momentum going.'
        : remaining == 1
        ? 'Only 1 minute left to complete today’s goal.'
        : '$remaining minutes left to complete today’s goal.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.14),
                AppColors.secondary.withValues(alpha: 0.075),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
            border: Border.all(color: AppColors.glassBorderStrong),
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(alpha: 0.13),
                blurRadius: 48,
                spreadRadius: -7,
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIntelligenceIcon(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY INTELLIGENCE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Your plan for today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildAdaptiveBadge(),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Build your English confidence',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                goalDescription,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.76),
                  fontSize: 13,
                  height: 1.48,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _InfoPill(
                    icon: Icons.schedule_rounded,
                    label: '${progress.dailyGoal} min',
                  ),
                  const SizedBox(width: 8),
                  const _InfoPill(
                    icon: Icons.edit_note_rounded,
                    label: 'Practice',
                  ),
                  const SizedBox(width: 8),
                  const _InfoPill(
                    icon: Icons.auto_graph_rounded,
                    label: 'Smart',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSessionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -2,
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildAdaptiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.success.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'GUIDED',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.05,
        ),
      ),
    );
  }

  Widget _buildSessionButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _openRecommendedLesson,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Start recommended lesson',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 9),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STATS
  // ===========================================================================

  ProgressSnapshot get _currentProgress {
    return _progress ??
        const ProgressSnapshot(
          xp: 0,
          level: 1,
          currentStreak: 0,
          longestStreak: 0,
          lastActivityDate: null,
          skills: <String, double>{},
          dailyGoal: 20,
          dailyGoalProgress: 0,
          totalSessions: 0,
          learningMinutes: 0,
          completedLessons: 0,
        );
  }

  Widget _buildStats() {
    final ProgressSnapshot progress = _currentProgress;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            value: '${progress.currentStreak}',
            label: 'Streak',
            accent: AppColors.streak,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '⚡',
            value: '${progress.xp}',
            label: 'XP',
            accent: AppColors.xp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '◆',
            value: '${progress.level}',
            label: 'Level',
            accent: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.72),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.75,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.68),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // EVOLUTION
  // ===========================================================================

  Widget _buildEvolutionCard() {
    final ProgressSnapshot progress = _currentProgress;

    final double evolutionProgress = _calculateEvolutionProgress(
      progress.level,
      progress.averageSkill,
    );

    final String currentLevel = _levelLabel(progress.level);

    final String nextLevel = _nextLevelLabel(progress.level);

    final int percentage = (evolutionProgress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.065),
                Colors.white.withValues(alpha: 0.025),
              ],
            ),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildEvolutionIcon(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'English Evolution',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your journey from A1 to C2',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currentLevel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildEvolutionProgress(progress: evolutionProgress),
              const SizedBox(height: 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nextLevel.isEmpty
                        ? 'C2 mastered'
                        : 'Progress toward $nextLevel',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.68),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateEvolutionProgress(int level, double averageSkill) {
    final double levelProgress = (level.clamp(1, 6) - 1) / 5;

    final double skillProgress = averageSkill.clamp(0.0, 1.0);

    final double value = (levelProgress * 0.7) + (skillProgress * 0.3);

    return value.clamp(0.0, 1.0);
  }

  String _levelLabel(int level) {
    switch (level.clamp(1, 6)) {
      case 1:
        return 'A1';
      case 2:
        return 'A2';
      case 3:
        return 'B1';
      case 4:
        return 'B2';
      case 5:
        return 'C1';
      case 6:
        return 'C2';
    }

    return 'A1';
  }

  String _nextLevelLabel(int level) {
    switch (level.clamp(1, 6)) {
      case 1:
        return 'A2';
      case 2:
        return 'B1';
      case 3:
        return 'B2';
      case 4:
        return 'C1';
      case 5:
        return 'C2';
      case 6:
        return '';
    }

    return 'A2';
  }

  Widget _buildEvolutionIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.17)),
      ),
      child: const Icon(
        Icons.auto_graph_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  Widget _buildEvolutionProgress({required double progress}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            height: 8,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryBright],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 12,
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

// =============================================================================
// AMBIENT BACKGROUND
// =============================================================================

class _HomeAmbientBackground extends StatelessWidget {
  const _HomeAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -170,
          right: -120,
          child: _AmbientGlow(color: AppColors.primary, size: 380),
        ),
        Positioned(
          top: 300,
          left: -180,
          child: _AmbientGlow(color: AppColors.secondary, size: 390),
        ),
        Positioned(
          bottom: -180,
          right: -100,
          child: _AmbientGlow(color: AppColors.electricBlue, size: 330),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

// =============================================================================
// INFO PILL
// =============================================================================

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.045),
          border: Border.all(color: Colors.white.withValues(alpha: 0.065)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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

// =============================================================================
// STAT CARD
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.065),
                Colors.white.withValues(alpha: 0.025),
              ],
            ),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 21)),
              const SizedBox(height: 7),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.62),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
