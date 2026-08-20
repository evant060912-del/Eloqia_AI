import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class PreferencesPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const PreferencesPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<_PreferenceOption> _paces = const [
    _PreferenceOption(
      id: 'relaxed',
      title: 'Relaxed',
      description: 'A calm and flexible rhythm',
      icon: Icons.spa_rounded,
    ),
    _PreferenceOption(
      id: 'balanced',
      title: 'Balanced',
      description: 'Consistent progress without pressure',
      icon: Icons.balance_rounded,
    ),
    _PreferenceOption(
      id: 'intensive',
      title: 'Intensive',
      description: 'Fast progress and strong challenges',
      icon: Icons.bolt_rounded,
    ),
  ];

  final List<_PreferenceOption> _corrections = const [
    _PreferenceOption(
      id: 'gentle',
      title: 'Gentle',
      description: 'Correct me softly',
      icon: Icons.favorite_border_rounded,
    ),
    _PreferenceOption(
      id: 'balanced',
      title: 'Balanced',
      description: 'Correct me when it matters',
      icon: Icons.tune_rounded,
    ),
    _PreferenceOption(
      id: 'direct',
      title: 'Direct',
      description: 'Point out my mistakes clearly',
      icon: Icons.my_location_rounded,
    ),
  ];

  final List<_PreferenceOption> _tutors = const [
    _PreferenceOption(
      id: 'warm',
      title: 'Warm & patient',
      description: 'Supportive and encouraging',
      icon: Icons.favorite_rounded,
    ),
    _PreferenceOption(
      id: 'energetic',
      title: 'Energetic',
      description: 'Dynamic and motivating',
      icon: Icons.auto_awesome_rounded,
    ),
    _PreferenceOption(
      id: 'professional',
      title: 'Focused',
      description: 'Structured and precise',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.profile.learningPace.isNotEmpty &&
      widget.profile.preferredCorrectionStyle.isNotEmpty &&
      widget.profile.preferredTutorStyle.isNotEmpty;

  void _selectPace(String value) {
    setState(() {
      widget.profile.learningPace = value;
    });
  }

  void _selectCorrection(String value) {
    setState(() {
      widget.profile.preferredCorrectionStyle = value;
    });
  }

  void _selectTutor(String value) {
    setState(() {
      widget.profile.preferredTutorStyle = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildPreferencesCard(),
                  const SizedBox(height: 22),
                  OnboardingButton(
                    label: 'Create my profile',
                    icon: Icons.auto_awesome_rounded,
                    enabled: _canContinue,
                    onPressed: _canContinue
                        ? widget.onContinue
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.92),
                AppColors.secondary.withValues(alpha: 0.72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 34,
              ),
            ],
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 31,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'YOUR LEARNING STYLE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'How should Eloqia teach you?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Your preferences will shape the way Mia communicates, '
          'corrects and challenges you.',
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

  Widget _buildPreferencesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            title: 'Learning pace',
            subtitle: 'How intense should your journey feel?',
            options: _paces,
            selected: widget.profile.learningPace,
            onSelected: _selectPace,
          ),
          const SizedBox(height: 26),
          _buildDivider(),
          const SizedBox(height: 26),
          _buildSection(
            title: 'Correction style',
            subtitle: 'How should Mia correct your mistakes?',
            options: _corrections,
            selected: widget.profile.preferredCorrectionStyle,
            onSelected: _selectCorrection,
          ),
          const SizedBox(height: 26),
          _buildDivider(),
          const SizedBox(height: 26),
          _buildSection(
            title: 'Tutor personality',
            subtitle: 'What kind of tutor feels right for you?',
            options: _tutors,
            selected: widget.profile.preferredTutorStyle,
            onSelected: _selectTutor,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<_PreferenceOption> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return _PreferenceCard(
              option: option,
              selected: selected == option.id,
              onTap: () => onSelected(option.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.045),
    );
  }
}

class _PreferenceOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _PreferenceOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _PreferenceCard extends StatelessWidget {
  final _PreferenceOption option;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 245,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 20,
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.25,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ],
        ),
      ),
    );
  }
}