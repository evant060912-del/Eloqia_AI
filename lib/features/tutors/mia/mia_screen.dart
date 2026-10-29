import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../services/learning/learning_profile_service.dart';
import '../../../services/voice/voice_output_provider.dart';
import '../../../services/voice/voice_session_client.dart';
import '../../../theme/app_colors.dart';
import '../../learning/sessions/conversation_session_screen.dart';
import 'widgets/mia_presence.dart';
import 'mia_chat_screen.dart';
import 'mia_live_session_screen.dart';

class MiaScreen extends StatefulWidget {
  const MiaScreen({
    super.key,
    this.accessTokenProvider,
    this.showBackButton = true,
  });

  final OidcAccessTokenProvider? accessTokenProvider;
  final bool showBackButton;

  @override
  State<MiaScreen> createState() => _MiaScreenState();
}

class _MiaScreenState extends State<MiaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  LearningProfile? _profile;
  bool _isLoading = true;
  bool _isStartingConversation = false;
  late final VoiceSessionClient _voiceClient;

  @override
  void initState() {
    super.initState();

    _voiceClient = VoiceSessionClient.fromEnvironment(
      accessTokenProvider: widget.accessTokenProvider,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final LearningProfile profile = await LearningProfileService.getProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
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

  @override
  void dispose() {
    _animationController.dispose();
    _voiceClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _MiaAmbientBackground(),

          SafeArea(child: _isLoading ? _buildLoading() : _buildContent()),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.primaryBright,
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  Widget _buildContent() {
    final LearningProfile? profile = _profile;

    final String name = profile?.name.trim().isNotEmpty == true
        ? profile!.name.trim()
        : 'there';

    final String level = _formatLevel(profile?.currentLevel);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 34),
          _buildMiaHero(),
          const SizedBox(height: 32),
          _buildGreeting(name: name, level: level),
          const SizedBox(height: 24),
          _buildPersonalizationCard(),
          const SizedBox(height: 20),
          _buildConversationCard(),
          const SizedBox(height: 20),
          _buildSessionPreview(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        if (widget.showBackButton) ...[
          _buildBackButton(),
          const SizedBox(width: 14),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MIA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'YOUR AI ENGLISH TUTOR',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        _buildOnlineBadge(),
      ],
    );
  }

  Widget _buildBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.055),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineBadge() {
    final bool profileLoaded = !_isLoading && _profile != null;
    final Color statusColor = profileLoaded
        ? AppColors.primaryBright
        : AppColors.warmth;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.55),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            profileLoaded ? 'PROFILE LOADED' : 'PROFILE UNAVAILABLE',
            style: TextStyle(
              color: statusColor,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MIA HERO
  // ===========================================================================

  Widget _buildMiaHero() {
    return const Center(
      child: MiaPresence(
        size: 150,
        state: MiaPresenceState.happy,
        showLabel: true,
      ),
    );
  }

  // ===========================================================================
  // GREETING
  // ===========================================================================

  Widget _buildGreeting({required String name, required String level}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PERSONAL TUTOR',
          style: TextStyle(
            color: AppColors.primaryBright.withValues(alpha: 0.82),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.1,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Hey $name',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'I’m Mia. Let’s make your English stronger, '
          'one conversation at a time.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 15),
        _buildLevelBadge(level),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => MiaVoice.provider.speak(
            'Hey $name. I am Mia. Let us make your English stronger, one step at a time.',
            style: MiaSpeechStyle.warm,
          ),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('Hear Mia'),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up_rounded,
            color: AppColors.primaryBright,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            'Current level • $level',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PERSONALIZATION
  // ===========================================================================

  Widget _buildPersonalizationCard() {
    final LearningProfile? profile = _profile;

    final String goal = profile?.primaryGoal.trim().isNotEmpty == true
        ? profile!.primaryGoal
        : 'Improve your English';

    final String pace = profile?.learningPace.trim().isNotEmpty == true
        ? profile!.learningPace
        : 'Adaptive';

    final String tutorStyle =
        profile?.preferredTutorStyle.trim().isNotEmpty == true
        ? profile!.preferredTutorStyle
        : 'Personalized';

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSmallIcon(Icons.psychology_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERSONALIZED FOR YOU',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mia knows your learning profile',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PersonalizationRow(
            icon: Icons.flag_rounded,
            label: 'Main goal',
            value: goal,
          ),
          const SizedBox(height: 10),
          _PersonalizationRow(
            icon: Icons.speed_rounded,
            label: 'Learning pace',
            value: pace,
          ),
          const SizedBox(height: 10),
          _PersonalizationRow(
            icon: Icons.favorite_rounded,
            label: 'Tutor style',
            value: tutorStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary.withValues(alpha: 0.09),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: AppColors.primaryBright, size: 20),
    );
  }

  // ===========================================================================
  // CONVERSATION
  // ===========================================================================

  Widget _buildConversationCard() {
    final bool configured = _voiceClient.isConfigured;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(23),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 38,
                spreadRadius: -5,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'REAL-TIME VOICE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              const Text(
                'Ready to speak?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _voiceClient.configurationStatus,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 21),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                    onPressed: _isStartingConversation || !configured
                      ? null
                      : _startConversation,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isStartingConversation
                          ? 'Connecting to Mia…'
                          : configured
                          ? 'Start conversation'
                            : 'Unavailable',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(
                        _isStartingConversation
                          ? Icons.hourglass_top_rounded
                          : configured
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_outline_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  key: const Key('mia-open-chat'),
                  onPressed: _openChat,
                  icon: const Icon(Icons.forum_rounded, size: 19),
                  label: const Text('Chat with Mia'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _startWritingPractice,
                  icon: const Icon(Icons.edit_note_rounded, size: 19),
                  label: const Text('Practice by writing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Offline prompts with local writing checks',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SESSION PREVIEW
  // ===========================================================================

  Widget _buildSessionPreview() {
    final LearningProfile? profile = _profile;

    final String correctionStyle =
        profile?.preferredCorrectionStyle.trim().isNotEmpty == true
        ? profile!.preferredCorrectionStyle
        : 'Personalized';

    return _GlassCard(
      child: Row(
        children: [
          _buildSmallIcon(Icons.tune_rounded),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SESSION STYLE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  correctionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBright,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // START CONVERSATION
  // ===========================================================================

  Future<void> _openChat() async {
    try {
      final LearningProfile profile =
          _profile ?? await LearningProfileService.getProfile();
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MiaChatScreen(
            profile: profile,
            accessTokenProvider: widget.accessTokenProvider,
          ),
        ),
      );
    } on Object {
      _showConversationError('La discussion avec Mia ne peut pas démarrer.');
    }
  }

  Future<void> _startWritingPractice() async {
    try {
      final LearningProfile profile =
          _profile ?? await LearningProfileService.getProfile();
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationSessionScreen(profile: profile),
        ),
      );
    } on Object {
      _showConversationError('La pratique écrite ne peut pas démarrer.');
    }
  }

  Future<void> _startConversation() async {
    final bool? consent = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const _VoiceConsentDialog(),
    );

    if (consent != true || !mounted || _isStartingConversation) {
      return;
    }

    setState(() {
      _isStartingConversation = true;
    });

    try {
      final LearningProfile profile =
          _profile ?? await LearningProfileService.getProfile();
      final VoiceSessionResponse session = await _voiceClient.startSession(
        profile: profile,
        voiceConsent: true,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MiaLiveSessionScreen(session: session),
        ),
      );
    } on VoiceSessionException catch (error) {
      _showConversationError(error.message);
    } on Object {
      _showConversationError(
        'Mia ne peut pas démarrer cette session pour le moment.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingConversation = false;
        });
      }
    }
  }

  void _showConversationError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          backgroundColor: AppColors.surface,
          content: Text(message),
        ),
      );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _formatLevel(String? level) {
    if (level == null || level.trim().isEmpty) {
      return 'Adaptive';
    }

    return level.trim().toUpperCase();
  }
}

// =============================================================================
// GLASS CARD
// =============================================================================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(21),
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
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// PERSONALIZATION ROW
// =============================================================================

class _PersonalizationRow extends StatelessWidget {
  const _PersonalizationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBright, size: 17),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
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

class _MiaAmbientBackground extends StatelessWidget {
  const _MiaAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          right: -130,
          child: _Glow(color: AppColors.primary, size: 380),
        ),
        Positioned(
          top: 360,
          left: -190,
          child: _Glow(color: AppColors.secondary, size: 400),
        ),
        Positioned(
          bottom: -170,
          right: -120,
          child: _Glow(color: AppColors.electricBlue, size: 340),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

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

class _VoiceConsentDialog extends StatefulWidget {
  const _VoiceConsentDialog();

  @override
  State<_VoiceConsentDialog> createState() => _VoiceConsentDialogState();
}

class _VoiceConsentDialogState extends State<_VoiceConsentDialog> {
  bool _consentGiven = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            border: Border.all(color: AppColors.glassBorderStrong),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Voice session consent',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mia will receive microphone audio through the configured '
                'voice providers. Eloqia does not currently save transcripts. '
                'Provider retention follows their published policies.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.82),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consentGiven,
                  onChanged: (bool? value) {
                    setState(() {
                      _consentGiven = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'I agree to use my microphone for this session.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _consentGiven
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: const Text('Continue'),
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
}
