import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Premium learning hub for Eloqia AI.
///
/// This section provides direct access to the main learning experiences.
/// Each action is intentionally isolated so real learning modules can be
/// connected progressively without changing the visual architecture.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    this.onActionSelected,
  });

  /// Called when the learner selects a learning experience.
  ///
  /// The parent screen owns navigation so this widget remains reusable
  /// and independent from the application's routing architecture.
  final ValueChanged<QuickActionData>? onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEARNING HUB',
                style: TextStyle(
                  color: AppColors.primaryBright.withValues(
                    alpha: 0.78,
                  ),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Explore your learning',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Choose an experience and keep evolving.',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildHubIcon(),
      ],
    );
  }

  Widget _buildHubIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: 0.18,
                ),
                AppColors.secondary.withValues(
                  alpha: 0.08,
                ),
              ],
            ),
            border: Border.all(
              color: AppColors.glassBorderStrong,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.16,
                ),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBright,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final QuickActionData action = quickActions[index];

        return QuickActionCard(
          action: action,
          onTap: () => onActionSelected?.call(action),
        );
      },
    );
  }
}

/// Immutable definition of a learning experience.
class QuickActionData {
  const QuickActionData({
    required this.icon,
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String eyebrow;
  final String description;
  final List<Color> gradient;
}

/// V0.5.0 learning experiences.
///
/// These entries define the Learning Hub structure while keeping navigation
/// owned by the parent screen.
const List<QuickActionData> quickActions = [
  QuickActionData(
    icon: Icons.record_voice_over_rounded,
    title: 'Conversation',
    eyebrow: 'SPEAK',
    description: 'Speak naturally with your AI tutor.',
    gradient: [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ],
  ),
  QuickActionData(
    icon: Icons.auto_stories_rounded,
    title: 'Vocabulary',
    eyebrow: 'BUILD',
    description: 'Discover and master useful new words.',
    gradient: [
      Color(0xFF7C3AED),
      Color(0xFFEC4899),
    ],
  ),
  QuickActionData(
    icon: Icons.auto_fix_high_rounded,
    title: 'Grammar',
    eyebrow: 'REFINE',
    description: 'Improve accuracy and express yourself clearly.',
    gradient: [
      Color(0xFFEC4899),
      Color(0xFFF97316),
    ],
  ),
  QuickActionData(
    icon: Icons.headphones_rounded,
    title: 'Listening',
    eyebrow: 'UNDERSTAND',
    description: 'Train your ear with natural English.',
    gradient: [
      Color(0xFF06B6D4),
      Color(0xFF2563EB),
    ],
  ),
  QuickActionData(
    icon: Icons.edit_note_rounded,
    title: 'Writing',
    eyebrow: 'CREATE',
    description: 'Write with confidence and develop your style.',
    gradient: [
      Color(0xFF10B981),
      Color(0xFF14B8A6),
    ],
  ),
  QuickActionData(
    icon: Icons.school_rounded,
    title: 'Academic',
    eyebrow: 'MASTER',
    description: 'Develop advanced academic English skills.',
    gradient: [
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  ),
];

/// Interactive premium learning card.
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.action,
    this.onTap,
  });

  final QuickActionData action;
  final VoidCallback? onTap;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final QuickActionData action = widget.action;

    final double scale = _isPressed
        ? 0.965
        : _isHovered
            ? 1.018
            : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: _buildCard(action),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(QuickActionData action) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.gradient.first.withValues(
                  alpha: _isHovered ? 0.30 : 0.20,
                ),
                action.gradient.last.withValues(
                  alpha: _isHovered ? 0.17 : 0.09,
                ),
                Colors.white.withValues(
                  alpha: 0.035,
                ),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: _isHovered ? 0.22 : 0.11,
              ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: action.gradient.first.withValues(
                  alpha: _isHovered ? 0.22 : 0.11,
                ),
                blurRadius: _isHovered ? 36 : 26,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: 0.55,
                ),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(action),
              const Spacer(),
              Text(
                action.eyebrow,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.52,
                  ),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                action.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _buildExploreRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(QuickActionData action) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            action.gradient.first.withValues(
              alpha: _isHovered ? 0.40 : 0.27,
            ),
            action.gradient.last.withValues(
              alpha: _isHovered ? 0.27 : 0.15,
            ),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: _isHovered ? 0.25 : 0.14,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: action.gradient.first.withValues(
              alpha: _isHovered ? 0.32 : 0.16,
            ),
            blurRadius: _isHovered ? 28 : 18,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Icon(
        action.icon,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  Widget _buildExploreRow() {
    return Row(
      children: [
        Text(
          'Explore',
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: _isHovered ? 1.0 : 0.78,
            ),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        AnimatedSlide(
          offset: _isHovered
              ? const Offset(0.18, 0)
              : Offset.zero,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white.withValues(
              alpha: _isHovered ? 1.0 : 0.72,
            ),
            size: 15,
          ),
        ),
      ],
    );
  }
}