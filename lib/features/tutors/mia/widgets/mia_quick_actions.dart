import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// A premium collection of secondary learning actions for Mia.
///
/// This widget is intentionally navigation-agnostic.
/// The parent decides what each action actually opens.
///
/// The component provides:
/// - responsive horizontal layout
/// - Liquid Glass cards
/// - animated hover states
/// - press feedback
/// - ambient gradients
/// - icon depth
/// - contextual labels
/// - optional disabled states
/// - reusable action definitions
class MiaQuickActions extends StatelessWidget {
  const MiaQuickActions({
    super.key,
    this.onActionSelected,
    this.actions = defaultMiaQuickActions,
  });

  /// Called when the learner selects an action.
  final ValueChanged<MiaQuickAction>? onActionSelected;

  /// Actions displayed by the component.
  final List<MiaQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'LEARNING TOOLS',
                style: TextStyle(
                  color:
                      AppColors.primaryBright
                          .withValues(
                    alpha: 0.72,
                  ),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your focus',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
        ),
        _buildSparkleBadge(),
      ],
    );
  }

  Widget _buildSparkleBadge() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(
          alpha: 0.08,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: const Icon(
        Icons.tune_rounded,
        color: AppColors.primaryBright,
        size: 18,
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact =
            constraints.maxWidth < 430;

        if (compact) {
          return SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              itemCount: actions.length,
                separatorBuilder:
                  (_, _) =>
                      const SizedBox(width: 12),
              itemBuilder:
                  (context, index) {
                return SizedBox(
                  width: 156,
                  child: _MiaQuickActionCard(
                    action: actions[index],
                    onTap: onActionSelected,
                  ),
                );
              },
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            return _MiaQuickActionCard(
              action: actions[index],
              onTap: onActionSelected,
            );
          },
        );
      },
    );
  }
}

/// Immutable description of a Mia learning action.
class MiaQuickAction {
  const MiaQuickAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.eyebrow,
    required this.gradient,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final String eyebrow;
  final List<Color> gradient;
  final bool enabled;
}

/// Default Mia learning tools.
///
/// These are intentionally independent from navigation so future modules
/// can be connected without redesigning this widget.
const List<MiaQuickAction> defaultMiaQuickActions = [
  MiaQuickAction(
    icon: Icons.record_voice_over_rounded,
    title: 'Speaking',
    eyebrow: 'VOICE',
    description:
        'Build natural speaking confidence.',
    gradient: [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ],
  ),
  MiaQuickAction(
    icon: Icons.graphic_eq_rounded,
    title: 'Pronunciation',
    eyebrow: 'SOUND',
    description:
        'Sharpen your American English accent.',
    gradient: [
      Color(0xFF06B6D4),
      Color(0xFF2563EB),
    ],
  ),
  MiaQuickAction(
    icon: Icons.auto_stories_rounded,
    title: 'Vocabulary',
    eyebrow: 'WORDS',
    description:
        'Expand the words you can use naturally.',
    gradient: [
      Color(0xFF7C3AED),
      Color(0xFFEC4899),
    ],
  ),
  MiaQuickAction(
    icon: Icons.headphones_rounded,
    title: 'Listening',
    eyebrow: 'AUDIO',
    description:
        'Understand real English with confidence.',
    gradient: [
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
    ],
  ),
];

class _MiaQuickActionCard extends StatefulWidget {
  const _MiaQuickActionCard({
    required this.action,
    required this.onTap,
  });

  final MiaQuickAction action;
  final ValueChanged<MiaQuickAction>? onTap;

  @override
  State<_MiaQuickActionCard> createState() =>
      _MiaQuickActionCardState();
}

class _MiaQuickActionCardState
    extends State<_MiaQuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _animationController;

  bool _isHovered = false;
  bool _isPressed = false;

  bool get _interactive =>
      widget.action.enabled &&
      widget.onTap != null;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 1800,
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (!_interactive ||
        _isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (!_interactive ||
        _isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  void _handleTap() {
    if (!_interactive) {
      return;
    }

    widget.onTap?.call(widget.action);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque,
        onTapDown: (_) =>
            _setPressed(true),
        onTapUp: (_) =>
            _setPressed(false),
        onTapCancel: () =>
            _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.965
              : _isHovered
                  ? 1.018
                  : 1.0,
          duration:
              const Duration(
            milliseconds: 180,
          ),
          curve:
              Curves.easeOutCubic,
          child: AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 240,
            ),
            curve:
                Curves.easeOutCubic,
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final MiaQuickAction action =
        widget.action;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(24),
            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                action.gradient.first
                    .withValues(
                  alpha: _isHovered
                      ? 0.23
                      : 0.13,
                ),
                action.gradient.last
                    .withValues(
                  alpha: _isHovered
                      ? 0.14
                      : 0.065,
                ),
                Colors.white
                    .withValues(
                  alpha: 0.035,
                ),
              ],
            ),
            border: Border.all(
              color:
                  Colors.white.withValues(
                alpha: _isHovered
                    ? 0.20
                    : 0.095,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: action
                    .gradient
                    .first
                    .withValues(
                  alpha: _isHovered
                      ? 0.19
                      : 0.08,
                ),
                blurRadius:
                    _isHovered ? 30 : 20,
                spreadRadius: -5,
                offset:
                    const Offset(0, 10),
              ),
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 22,
                offset:
                    Offset(0, 11),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildIcon(action),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _buildText(action),
              ),
              _buildArrow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    MiaQuickAction action,
  ) {
    return AnimatedBuilder(
      animation:
          _animationController,
      builder: (context, child) {
        final double pulse =
            Curves.easeInOut.transform(
          _animationController.value,
        );

        return Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            gradient:
                LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                action.gradient.first
                    .withValues(
                  alpha: _isHovered
                      ? 0.34
                      : 0.22,
                ),
                action.gradient.last
                    .withValues(
                  alpha: _isHovered
                      ? 0.24
                      : 0.12,
                ),
              ],
            ),
            border: Border.all(
              color:
                  Colors.white.withValues(
                alpha:
                    _isHovered
                        ? 0.22
                        : 0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: action
                    .gradient
                    .first
                    .withValues(
                  alpha:
                      (_isHovered
                              ? 0.24
                              : 0.11) +
                          pulse * 0.05,
                ),
                blurRadius:
                    _isHovered
                        ? 24
                        : 16,
                spreadRadius: -3,
              ),
            ],
          ),
          child: Icon(
            action.icon,
            color:
                Colors.white.withValues(
              alpha:
                  action.enabled
                      ? 1.0
                      : 0.35,
            ),
            size: 22,
          ),
        );
      },
    );
  }

  Widget _buildText(
    MiaQuickAction action,
  ) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          action.eyebrow,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha: 0.45,
            ),
            fontSize: 7.5,
            fontWeight:
                FontWeight.w900,
            letterSpacing: 1.45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          action.title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha:
                  action.enabled
                      ? 1.0
                      : 0.38,
            ),
            fontSize: 14,
            fontWeight:
                FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          action.description,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha:
                  action.enabled
                      ? 0.58
                      : 0.28,
            ),
            fontSize: 9,
            height: 1.25,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return AnimatedSlide(
      offset: _isHovered
          ? const Offset(0.12, 0)
          : Offset.zero,
      duration:
          const Duration(
        milliseconds: 220,
      ),
      curve:
          Curves.easeOutCubic,
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color:
            Colors.white.withValues(
          alpha:
              _isHovered ? 0.72 : 0.34,
        ),
        size: 13,
      ),
    );
  }
}