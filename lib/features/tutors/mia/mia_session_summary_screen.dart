import 'package:flutter/material.dart';

import '../../lessons/engine/achievement_engine.dart';
import '../../../services/mia/mia_chat_client.dart';
import '../../../services/mia/mia_session_recorder.dart';
import '../../../theme/app_colors.dart';
import 'widgets/mia_presence.dart';

/// End-of-session review. Pops `true` for "new session", `false` to leave.
class MiaSessionSummaryScreen extends StatelessWidget {
  const MiaSessionSummaryScreen({
    super.key,
    required this.summary,
    required this.record,
    required this.learnerTurns,
    this.errorMessage,
  });

  /// Null when the review could not be generated.
  final MiaSessionSummary? summary;
  final MiaSessionRecord record;
  final int learnerTurns;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final MiaSessionSummary? review = summary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Session review',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    MiaPresence(
                      size: 72,
                      showLabel: false,
                      followVoice: false,
                      state: record.newAchievements.isNotEmpty
                          ? MiaPresenceState.celebrating
                          : MiaPresenceState.happy,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Rewards(record: record, turns: learnerTurns),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (review == null)
                  _Section(
                    icon: Icons.info_outline_rounded,
                    title: 'Review unavailable',
                    child: Text(
                      errorMessage ??
                          'Le bilan n\'a pas pu être préparé. Ta séance est '
                              'tout de même enregistrée.',
                      style: _body,
                    ),
                  )
                else ...<Widget>[
                  _Section(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Summary',
                    child: Text(review.summary, style: _body),
                  ),
                  if (review.practiced.isNotEmpty)
                    _Section(
                      icon: Icons.fitness_center_rounded,
                      title: 'What you practised',
                      child: _Chips(items: review.practiced),
                    ),
                  if (review.strengths.isNotEmpty)
                    _Section(
                      icon: Icons.thumb_up_alt_rounded,
                      title: 'What went well',
                      child: _Bullets(items: review.strengths),
                    ),
                  if (review.improvements.isNotEmpty)
                    _Section(
                      icon: Icons.edit_rounded,
                      title: 'To improve (from your own words)',
                      child: Column(
                        children: review.improvements
                            .map(_Improvement.new)
                            .toList(),
                      ),
                    ),
                  if (review.usefulExpressions.isNotEmpty)
                    _Section(
                      icon: Icons.bookmark_rounded,
                      title: 'Expressions to reuse',
                      child: _Chips(items: review.usefulExpressions),
                    ),
                  if (review.nextStep.isNotEmpty)
                    _Section(
                      icon: Icons.arrow_forward_rounded,
                      title: 'Next step',
                      child: Text(review.nextStep, style: _body),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('mia-summary-new-session'),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('New session'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const TextStyle _body = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 14.5,
  height: 1.5,
);

class _Rewards extends StatelessWidget {
  const _Rewards({required this.record, required this.turns});

  final MiaSessionRecord record;
  final int turns;

  @override
  Widget build(BuildContext context) {
    final String xpLine = record.saved
        ? '+${record.xpAwarded} XP'
        : turns < MiaSessionRecorder.minLearnerTurns
        ? 'Send at least ${MiaSessionRecorder.minLearnerTurns} messages to earn XP'
        : 'No XP this time';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double scale, Widget? child) =>
              Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: child,
              ),
          child: Text(
            xpLine,
            style: TextStyle(
              color: record.saved
                  ? AppColors.primaryBright
                  : AppColors.textSecondary,
              fontSize: record.saved ? 26 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$turns ${turns == 1 ? 'message' : 'messages'} sent',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        for (final Achievement a in record.newAchievements)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.warmth,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Achievement unlocked: ${a.title}',
                    style: const TextStyle(
                      color: AppColors.warmth,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.primaryBright),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (String e) => Chip(
              label: Text(e, style: const TextStyle(fontSize: 12.5)),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (String e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.primaryBright,
                    ),
                  ),
                  Expanded(child: Text(e, style: _body)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Improvement extends StatelessWidget {
  const _Improvement(this.item);

  final MiaEvidenceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'You wrote: “${item.evidence}”',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (item.suggestion.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Better: ${item.suggestion}',
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (item.explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              item.explanation,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
