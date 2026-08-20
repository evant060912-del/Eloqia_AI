import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class FinalProfilePage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onFinish;

  const FinalProfilePage({
    super.key,
    required this.profile,
    required this.onFinish,
  });

  @override
  State<FinalProfilePage> createState() => _FinalProfilePageState();
}

class _FinalProfilePageState extends State<FinalProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatValue(String value) {
    final cleanedValue = value.trim();

    if (cleanedValue.isEmpty) {
      return 'Not specified';
    }

    return cleanedValue
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return word;
            }

            return '${word[0].toUpperCase()}${word.substring(1)}';
          },
        )
        .join(' ');
  }

  String _formatList(List<String> values) {
    if (values.isEmpty) {
      return 'Not specified';
    }

    return values.map(_formatValue).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 720;
              final horizontalPadding =
                  constraints.maxWidth >= 850 ? 48.0 : 22.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isCompact ? 18 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 900,
                    ),
                    child: Column(
                      children: [
                        _buildHero(isCompact),
                        SizedBox(
                          height: isCompact ? 20 : 26,
                        ),
                        _buildProfileCard(isCompact),
                        SizedBox(
                          height: isCompact ? 18 : 22,
                        ),
                        _buildReadyCard(),
                        SizedBox(
                          height: isCompact ? 18 : 22,
                        ),
                        _buildButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isCompact) {
    final iconSize = isCompact ? 72.0 : 82.0;

    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
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
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.28,
                ),
                blurRadius: 42,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: isCompact ? 33 : 38,
          ),
        ),
        SizedBox(height: isCompact ? 18 : 22),
        Text(
          'YOUR ELOQIA PROFILE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We know how to help you learn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 27 : 30,
            height: 1.14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your answers have created a learning profile '
          'designed around you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.46),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isCompact) {
    return GlassCard(
      padding: EdgeInsets.all(
        isCompact ? 18 : 24,
      ),
      borderRadius: BorderRadius.circular(34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          SizedBox(height: isCompact ? 16 : 22),
          _buildProfileRow(
            icon: Icons.school_rounded,
            title: 'Current level',
            value: _formatValue(
              widget.profile.currentLevel,
            ),
          ),
          _buildProfileRow(
            icon: Icons.flag_rounded,
            title: 'Main goal',
            value: _formatValue(
              widget.profile.primaryGoal,
            ),
          ),
          _buildProfileRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Strengths',
            value: _formatList(
              widget.profile.strengths,
            ),
          ),
          _buildProfileRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Motivation',
            value: _formatValue(
              widget.profile.motivation,
            ),
          ),
          _buildProfileRow(
            icon: Icons.speed_rounded,
            title: 'Learning pace',
            value: _formatValue(
              widget.profile.learningPace,
            ),
          ),
          _buildProfileRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Correction style',
            value: _formatValue(
              widget.profile.preferredCorrectionStyle,
            ),
          ),
          _buildProfileRow(
            icon: Icons.person_rounded,
            title: 'Tutor style',
            value: _formatValue(
              widget.profile.preferredTutorStyle,
            ),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.person_search_rounded,
            color: AppColors.primary,
            size: 23,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized learning profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Built from your onboarding answers',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.verified_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.045,
                  ),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primary.withValues(
              alpha: 0.72,
            ),
          ),
          const SizedBox(width: 13),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(
                  alpha: 0.34,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'Mia can now adapt your lessons, corrections '
              'and challenges to your profile.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(
                  alpha: 0.58,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return OnboardingButton(
      label: 'Enter Eloqia',
      icon: Icons.arrow_forward_rounded,
      enabled: true,
      onPressed: widget.onFinish,
    );
  }
}