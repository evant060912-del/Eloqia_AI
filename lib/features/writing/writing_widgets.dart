import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'writing_checks.dart';

/// The learner's own words use a book face, everything else the app face:
/// it keeps "what I wrote" visually distinct from Mia's comments.
const TextStyle writingTextStyle = TextStyle(
  fontFamily: 'Georgia',
  fontFamilyFallback: <String>['Times New Roman', 'serif'],
  color: AppColors.textPrimary,
  fontSize: 17,
  height: 1.6,
);

/// Elevated surface used across the studio.
class WritingPanel extends StatelessWidget {
  const WritingPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Optional colour for the left edge (status, genre).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color? edge = accent;
    // A positioned edge (not IntrinsicHeight) keeps layout cheap and safe
    // around selectable or wrapping text.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: edge == null
                ? padding
                : padding.add(const EdgeInsets.only(left: 4)),
            child: child,
          ),
          if (edge != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: edge),
            ),
        ],
      ),
    );
  }
}

class WritingSectionTitle extends StatelessWidget {
  const WritingSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small label with text (never colour alone).
class WritingTag extends StatelessWidget {
  const WritingTag(
    this.label, {
    super.key,
    this.color = AppColors.textSecondary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Word count against the task's target range.
class WritingLengthMeter extends StatelessWidget {
  const WritingLengthMeter({
    super.key,
    required this.words,
    required this.minWords,
    required this.maxWords,
  });

  final int words;
  final int minWords;
  final int maxWords;

  @override
  Widget build(BuildContext context) {
    final LengthStatus status = lengthStatus(words, minWords, maxWords);
    final (Color color, String note) = switch (status) {
      LengthStatus.empty => (AppColors.textMuted, 'Start writing'),
      LengthStatus.tooShort => (
        AppColors.warning,
        '${minWords - words} more to reach the target',
      ),
      LengthStatus.inRange => (AppColors.success, 'In the target range'),
      LengthStatus.tooLong => (
        AppColors.warning,
        '${words - maxWords} over the limit',
      ),
    };
    final int scale = maxWords > 0 ? maxWords : (minWords > 0 ? minWords : 100);
    final double value = (words / scale).clamp(0, 1).toDouble();
    final String target = maxWords > 0
        ? '$minWords–$maxWords'
        : (minWords > 0 ? '$minWords+' : 'free');

    return Semantics(
      label: '$words words, target $target. $note',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '$words words',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '  /  $target',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    note,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: value),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (BuildContext context, double v, Widget? _) =>
                    LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: AppColors.white08,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the app was started without the server address.
class WritingServerNotice extends StatelessWidget {
  const WritingServerNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return WritingPanel(
      accent: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Mia’s review is offline',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can still write, keep drafts and run the automatic checks. '
            'To get Mia’s detailed review, start the Eloqia server and launch '
            'the app with its address:',
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SelectableText(
              'flutter run -d chrome --web-port 5000 '
              '--dart-define=ELOQIA_API_URL=http://localhost:8000',
              style: TextStyle(
                color: AppColors.primaryBright,
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String describeWhen(DateTime when) {
  final DateTime local = when.toLocal();
  final Duration age = DateTime.now().difference(local);
  if (age.inMinutes < 1) return 'just now';
  if (age.inHours < 1) return '${age.inMinutes} min ago';
  if (age.inDays < 1) return '${age.inHours} h ago';
  if (age.inDays == 1) return 'yesterday';
  if (age.inDays < 7) return '${age.inDays} days ago';
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
