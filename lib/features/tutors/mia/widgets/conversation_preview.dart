import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Premium conversational preview for Mia.
///
/// This component introduces the learner to the current conversational
/// experience before entering the real-time session.
///
/// It is intentionally presentation-focused:
/// • no navigation
/// • no AI calls
/// • no audio engine
/// • no persistence
///
/// The parent screen owns the actual session logic.
class ConversationPreview extends StatefulWidget {
  const ConversationPreview({
    super.key,
    required this.name,
    this.level = 'B2',
    this.goal = 'Build your English confidence',
    this.message =
        'I’m ready when you are. Let’s make today’s English feel natural.',
    this.isReady = true,
    this.onTap,
  });

  /// Learner's display name.
  final String name;

  /// Current CEFR level displayed by the preview.
  final String level;

  /// Main learning objective.
  final String goal;

  /// Mia's introductory message.
  final String message;

  /// Controls the availability state.
  final bool isReady;

  /// Optional callback for opening the conversation.
  final VoidCallback? onTap;

  @override
  State<ConversationPreview> createState() =>
      _ConversationPreviewState();
}

class _ConversationPreviewState
    extends State<ConversationPreview>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _entryController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3200,
      ),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() {
      _isHovered = value;
    });
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  void _handleTap() {
    if (!widget.isReady) {
      return;
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ambientController,
        _entryController,
      ]),
      builder: (context, child) {
        final double entry =
            Curves.easeOutCubic.transform(
          _entryController.value,
        );

        final double breathing =
            Curves.easeInOut.transform(
          _ambientController.value,
        );

        return Opacity(
          opacity: entry,
          child: Transform.translate(
            offset: Offset(
              0,
              16 * (1 - entry),
            ),
            child: Transform.scale(
              scale: 0.985 + (entry * 0.015),
              child: _buildCard(
                breathing: breathing,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required double breathing,
  }) {
    final bool interactive =
        widget.isReady && widget.onTap != null;

    return MouseRegion(
      cursor: interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onTapDown:
            interactive ? (_) => _setPressed(true) : null,
        onTapUp:
            interactive ? (_) => _setPressed(false) : null,
        onTapCancel:
            interactive ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.985
              : _isHovered && interactive
                  ? 1.008
                  : 1.0,
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 25,
                sigmaY: 25,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(
                        alpha: _isHovered
                            ? 0.15
                            : 0.105,
                      ),
                      AppColors.secondary.withValues(
                        alpha: 0.055,
                      ),
                      Colors.white.withValues(
                        alpha: 0.035,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: _isHovered
                          ? 0.17
                          : 0.095,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(
                        alpha:
                            0.08 + (breathing * 0.045),
                      ),
                      blurRadius:
                          38 + (breathing * 12),
                      spreadRadius: -8,
                      offset: const Offset(0, 15),
                    ),
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 30,
                      offset: Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    _buildAmbientOrb(
                      breathing: breathing,
                    ),
                    _buildContent(
                      interactive: interactive,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientOrb({
    required double breathing,
  }) {
    return Positioned(
      top: -45,
      right: -45,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 35,
            sigmaY: 35,
          ),
          child: Container(
            width: 130 + (breathing * 15),
            height: 130 + (breathing * 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: 0.07,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool interactive,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildTopRow(),
        const SizedBox(height: 19),
        _buildMessage(),
        const SizedBox(height: 19),
        _buildSessionMetadata(),
        if (interactive) ...[
          const SizedBox(height: 18),
          _buildActionHint(),
        ],
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        _buildMiniAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'MIA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'English Tutor',
                style: TextStyle(
                  color:
                      AppColors.textSecondary.withValues(
                    alpha: 0.66,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _buildReadyIndicator(),
      ],
    );
  }

  Widget _buildMiniAvatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBright,
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
            color: AppColors.primary.withValues(
              alpha: 0.28,
            ),
            blurRadius: 22,
            spreadRadius: -3,
          ),
        ],
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildReadyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: widget.isReady
            ? AppColors.success.withValues(
                alpha: 0.08,
              )
            : Colors.white.withValues(
                alpha: 0.045,
              ),
        border: Border.all(
          color: widget.isReady
              ? AppColors.success.withValues(
                  alpha: 0.18,
                )
              : Colors.white.withValues(
                  alpha: 0.08,
                ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isReady
                  ? AppColors.success
                  : AppColors.textSecondary,
              boxShadow: widget.isReady
                  ? [
                      BoxShadow(
                        color: AppColors.success
                            .withValues(
                          alpha: 0.45,
                        ),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isReady ? 'READY' : 'OFFLINE',
            style: TextStyle(
              color: widget.isReady
                  ? AppColors.success
                  : AppColors.textSecondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    final String greeting = widget.name.trim().isEmpty
        ? 'Let’s learn something great today.'
        : 'Hey ${widget.name.trim()},';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.56,
            ),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          widget.message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionMetadata() {
    return Row(
      children: [
        Expanded(
          child: _MetadataItem(
            icon: Icons.flag_rounded,
            label: widget.level,
            caption: 'Level',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          flex: 2,
          child: _MetadataItem(
            icon: Icons.auto_awesome_rounded,
            label: widget.goal,
            caption: 'Focus',
          ),
        ),
      ],
    );
  }

  Widget _buildActionHint() {
    return Row(
      children: [
        Icon(
          Icons.graphic_eq_rounded,
          color: AppColors.primaryBright.withValues(
            alpha: 0.8,
          ),
          size: 17,
        ),
        const SizedBox(width: 8),
        Text(
          'Voice conversation • Personalized for you',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(
              alpha: 0.62,
            ),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Small metadata surface used by [ConversationPreview].
class _MetadataItem extends StatelessWidget {
  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 55,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(
                alpha: 0.09,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBright,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        AppColors.textSecondary.withValues(
                      alpha: 0.48,
                    ),
                    fontSize: 6.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
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