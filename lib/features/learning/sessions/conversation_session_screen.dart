import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../models/learning_session.dart';
import '../../../services/learning/learning_engine.dart';
import '../../../services/learning/learning_progress_service.dart';
import '../../../services/learning/learning_session_service.dart';
import '../../../theme/app_colors.dart';
import '../../tutors/mia/mia_dialogue.dart';

class ConversationSessionScreen extends StatefulWidget {
  final LearningProfile profile;

  const ConversationSessionScreen({super.key, required this.profile});

  @override
  State<ConversationSessionScreen> createState() =>
      _ConversationSessionScreenState();
}

class _ConversationSessionScreenState extends State<ConversationSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  final TextEditingController _responseController = TextEditingController();

  final DateTime _sessionStartedAt = DateTime.now().toUtc();
  int _currentChallenge = 0;

  bool _showFeedback = false;
  bool _isCompleting = false;
  MiaPracticeFeedback? _feedback;

  final List<MiaPracticePrompt> _challenges = MiaDialogue.prompts;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    final name = profile.name.trim().isEmpty ? 'Learner' : profile.name.trim();

    final challenge = _challenges[_currentChallenge];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _SessionBackground(controller: _ambientController),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.025),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 22),
                          _buildProgress(),
                          const SizedBox(height: 26),
                          _buildWelcome(name),
                          const SizedBox(height: 20),
                          _buildChallenge(challenge),
                          const SizedBox(height: 18),
                          if (_showFeedback) _buildFeedback(),
                          const SizedBox(height: 18),
                          _buildResponseArea(),
                          const SizedBox(height: 18),
                          _buildActionButton(),
                        ]),
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

  Widget _buildHeader() {
    return Row(
      children: [
        _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONVERSATION',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Your learning session',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _SessionBadge(label: '${_currentChallenge + 1}/${_challenges.length}'),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = (_currentChallenge + 1) / _challenges.length;

    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SESSION PROGRESS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/tutors/mia/mia.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 42,
                  height: 42,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIA · WRITING PRACTICE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Local prompts · no live AI review',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Let’s make English feel natural, $name.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'There is no need to be perfect. Focus on expressing '
          'your ideas clearly and naturally.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChallenge(MiaPracticePrompt challenge) {
    return _GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR CHALLENGE',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.78),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _FocusBadge(label: challenge.focus),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            challenge.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.42,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white.withValues(alpha: 0.035),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.warmth,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    challenge.hint,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseArea() {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR RESPONSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                '${_responseController.text.length}/500',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _responseController,
            maxLength: 500,
            minLines: 5,
            maxLines: 8,
            onChanged: (_) {
              setState(() {});
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.5,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Write your answer here...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.27),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.035),
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final MiaPracticeFeedback feedback = _feedback!;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local practice check',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  feedback.observations.join(' · '),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Text(
                  feedback.nextStep,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Word and sentence counts only; no grammar score or AI review.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final hasResponse = _responseController.text.trim().isNotEmpty;

    final isLast = _currentChallenge == _challenges.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: FilledButton(
        onPressed: hasResponse ? _handleAction : null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: AppColors.background,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.28),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showFeedback
                  ? (isLast ? 'Complete session' : 'Continue')
                  : 'Submit response',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 9),
            Icon(
              _showFeedback && isLast
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction() {
    if (!_showFeedback) {
      setState(() {
        _feedback = MiaDialogue.review(
          _responseController.text,
          encourageQuestion: _challenges[_currentChallenge].encourageQuestion,
        );
        _showFeedback = true;
      });
      return;
    }

    if (_currentChallenge < _challenges.length - 1) {
      setState(() {
        _currentChallenge++;
        _showFeedback = false;
        _feedback = null;
        _responseController.clear();
      });
    } else {
      _finalizeAndShowCompletion();
    }
  }

  Future<void> _finalizeAndShowCompletion() async {
    if (_isCompleting) {
      return;
    }
    _isCompleting = true;

    final String id = 'writing-${_sessionStartedAt.microsecondsSinceEpoch}';
    final Duration duration = DateTime.now().toUtc().difference(
      _sessionStartedAt,
    );
    bool recorded = false;
    bool rewardGranted = false;

    try {
      final LearningSession? session =
          await LearningSessionService.createSession(
            id: id,
            activityType: LearningActivityType.writing,
            tutorId: 'mia',
            tutorName: 'Mia',
            targetLevel: widget.profile.currentLevel,
            startingLevel: widget.profile.currentLevel,
            skills: const <LearningSkill>[
              LearningSkill.writing,
              LearningSkill.vocabulary,
            ],
            adaptive: false,
          );

      if (session != null) {
        await LearningSessionService.startSession(
          id,
          startedAt: _sessionStartedAt,
        );
        await LearningSessionService.updateDuration(id, duration);
        await LearningSessionService.updateObjectives(
          id,
          completed: _challenges.length,
          total: _challenges.length,
        );
        final LearningSession? completed =
            await LearningSessionService.completeSession(
              id,
              xpEarned: LearningEngine.guidedWritingCompletionXp,
            );
        recorded = completed != null;
        if (recorded) {
          final progress =
              await LearningProgressService.registerCompletedSession(
                xpEarned: LearningEngine.guidedWritingCompletionXp,
                learningDuration: duration,
                updateStreak: true,
              );
          rewardGranted = progress != null;
          if (!rewardGranted) {
            await LearningSessionService.updateSession(
              completed.copyWith(xpEarned: 0),
            );
          }
        }
      }
    } on Object {
      recorded = false;
    }

    if (!mounted) {
      return;
    }
    _isCompleting = false;

    if (!recorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session history could not be saved.')),
      );
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: _CompletionCard(
            sessionRecorded: recorded,
            xpAwarded: rewardGranted
                ? LearningEngine.guidedWritingCompletionXp
                : 0,
            onClose: () {
              Navigator.of(context).pop();
              Navigator.of(this.context).pop();
            },
          ),
        );
      },
    );
  }
}

/* ================================================================
   COMPLETION
   ================================================================ */

class _CompletionCard extends StatelessWidget {
  final bool sessionRecorded;
  final int xpAwarded;
  final VoidCallback onClose;

  const _CompletionCard({
    required this.sessionRecorded,
    required this.xpAwarded,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: AppColors.backgroundElevated.withValues(alpha: 0.94),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 35,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Session complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sessionRecorded
                    ? 'The session was saved locally. Your written responses '
                          'were not saved or sent for AI review.'
                    : 'The session history could not be saved. Your written '
                          'responses were not saved, and no XP was awarded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              if (sessionRecorded && xpAwarded == 0) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'XP could not be saved, so none was awarded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.warning, fontSize: 11),
                ),
              ],
              const SizedBox(height: 20),
              if (xpAwarded > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color:
                        (sessionRecorded
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.07),
                    border: Border.all(
                      color:
                          (sessionRecorded
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.14),
                    ),
                  ),
                  child: TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: xpAwarded),
                    duration: const Duration(milliseconds: 650),
                    builder: (BuildContext context, int value, Widget? child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.xp,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '+$value XP earned for finishing all 3 prompts',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color:
                      (sessionRecorded ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.07),
                  border: Border.all(
                    color:
                        (sessionRecorded
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      sessionRecorded
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: sessionRecorded
                          ? AppColors.success
                          : AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      sessionRecorded ? 'Session recorded' : 'Not recorded',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Return to learning',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
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

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPanel({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            color: Colors.white.withValues(alpha: 0.047),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
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

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.055),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.78),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  final String label;

  const _SessionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: AppColors.primary.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FocusBadge extends StatelessWidget {
  final String label;

  const _FocusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.secondary.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.secondaryBright,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SessionBackground extends StatelessWidget {
  final Animation<double> controller;

  const _SessionBackground({required this.controller});

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
              top: -150 + shift * 30,
              right: -150,
              child: _GlowOrb(color: AppColors.primary, size: 380),
            ),
            Positioned(
              top: 360 - shift * 40,
              left: -190,
              child: _GlowOrb(color: AppColors.secondary, size: 410),
            ),
            Positioned(
              bottom: -220 + shift * 25,
              right: -30,
              child: _GlowOrb(color: AppColors.electricBlue, size: 340),
            ),
          ],
        );
      },
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
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
