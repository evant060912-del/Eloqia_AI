import 'package:flutter/material.dart';

import '../../../models/learning_profile.dart';
import '../../../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/onboarding_button.dart';

class IdentityPage extends StatefulWidget {
  final LearningProfile profile;
  final VoidCallback onContinue;

  const IdentityPage({
    super.key,
    required this.profile,
    required this.onContinue,
  });

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile.name,
    );

    _nameFocusNode = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _updateName(String value) {
    widget.profile.name = value;

    if (mounted) {
      setState(() {});
    }
  }

  void _continue() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _nameFocusNode.requestFocus();
      return;
    }

    widget.profile.name = name;
    FocusScope.of(context).unfocus();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 800;
        final bool isCompact = constraints.maxHeight < 700;

        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 24,
                vertical: isCompact ? 18 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 760 : 620,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildTopBadge(),
                        SizedBox(
                          height: isCompact ? 20 : 28,
                        ),
                        _buildMainCard(
                          isWide: isWide,
                          isCompact: isCompact,
                        ),
                        SizedBox(
                          height: isCompact ? 18 : 24,
                        ),
                        _buildReassurance(),
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

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
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
                  color: AppColors.primary.withValues(
                    alpha: 0.5,
                  ),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'PERSONALIZATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.1,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard({
    required bool isWide,
    required bool isCompact,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(
        isWide ? 42 : isCompact ? 24 : 30,
      ),
      borderRadius: BorderRadius.circular(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIcon(),
          const SizedBox(height: 24),
          Text(
            'LET’S GET TO KNOW YOU',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'What should we call you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWide ? 34 : 29,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your name helps Eloqia make every interaction feel more personal, natural, and truly yours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 30),
          _buildNameField(),
          const SizedBox(height: 22),
          _buildPersonalizationPreview(),
          const SizedBox(height: 26),
          OnboardingButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            enabled: _nameController.text.trim().isNotEmpty,
            onPressed: _nameController.text.trim().isNotEmpty
                ? _continue
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.9),
              AppColors.secondary.withValues(alpha: 0.72),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 31,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: _nameFocusNode.hasFocus ? 0.08 : 0,
            ),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        onChanged: _updateName,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _continue(),
        cursorColor: AppColors.primary,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Your first name',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              left: 18,
              right: 12,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 52,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.045),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 21,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationPreview() {
    final bool hasName = _nameController.text.trim().isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(hasName),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.025),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.055),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                hasName
                    ? Icons.check_rounded
                    : Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.primary.withValues(
                  alpha: 0.85,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasName
                    ? 'Perfect. We’ll use this to personalize your journey.'
                    : 'This is the first step toward a learning experience built around you.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReassurance() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.23),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your information stays under your control.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
              color: Colors.white.withValues(alpha: 0.27),
            ),
          ),
        ),
      ],
    );
  }
}