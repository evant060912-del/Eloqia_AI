import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'exam_clock.dart';
import 'exam_formats.dart';

/// Timer shown above the editor of an exam task.
class ExamTimerBar extends StatelessWidget {
  const ExamTimerBar({
    super.key,
    required this.clock,
    required this.onStart,
    required this.onReset,
  });

  final ExamClock clock;
  final VoidCallback onStart;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ExamClockPhase phase = clock.phase;
    final Color color = switch (phase) {
      ExamClockPhase.notStarted => AppColors.textSecondary,
      ExamClockPhase.running => AppColors.primaryBright,
      ExamClockPhase.lastMinutes => AppColors.warning,
      ExamClockPhase.over => AppColors.error,
    };
    final String caption = switch (phase) {
      ExamClockPhase.notStarted =>
        'Official time: ${formatClock(clock.limit, withUnits: true)}',
      ExamClockPhase.running => 'Time left',
      ExamClockPhase.lastMinutes => 'Last minutes: check your text',
      ExamClockPhase.over => 'Time is up: finish and submit',
    };
    return Semantics(
      liveRegion: phase == ExamClockPhase.over,
      label: phase == ExamClockPhase.notStarted
          ? caption
          : '$caption, ${clock.display}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.timer_outlined, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (clock.started) ...<Widget>[
              ExcludeSemantics(
                child: Text(
                  clock.display,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Stop the timer',
                onPressed: onReset,
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                color: AppColors.textMuted,
              ),
            ] else
              TextButton(onPressed: onStart, child: const Text('Start timer')),
          ],
        ),
      ),
    );
  }
}

/// The professor's question and the students' posts, like a class forum.
class DiscussionBoardView extends StatelessWidget {
  const DiscussionBoardView({super.key, required this.board});

  final DiscussionBoard board;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Post(
          author: 'Professor ${board.professor}',
          role: board.course,
          text: board.question,
          accent: AppColors.academic,
        ),
        for (final DiscussionPost post in board.posts) ...<Widget>[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: _Post(
              author: post.author,
              role: 'Student',
              text: post.text,
              accent: AppColors.listening,
            ),
          ),
        ],
      ],
    );
  }
}

class _Post extends StatelessWidget {
  const _Post({
    required this.author,
    required this.role,
    required this.text,
    required this.accent,
  });

  final String author;
  final String role;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 13,
                backgroundColor: accent.withValues(alpha: 0.18),
                child: Text(
                  author.characters.first,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  author,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                role,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// "Unofficial practice" notice, shown wherever exam scores appear.
class ExamDisclaimer extends StatelessWidget {
  const ExamDisclaimer({super.key, required this.exam});

  final ExamKind exam;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            exam.disclaimer,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small line of recent scores, oldest on the left.
class ScoreTrend extends StatelessWidget {
  const ScoreTrend({
    super.key,
    required this.values,
    required this.scaleMax,
    this.color = AppColors.primary,
  });

  final List<double> values;
  final int scaleMax;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: CustomPaint(
        painter: _TrendPainter(values, scaleMax, color),
        size: Size.infinite,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.scaleMax, this.color);

  final List<double> values;
  final int scaleMax;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || scaleMax <= 0) return;
    final Paint dot = Paint()..color = color;
    Offset at(int i) => Offset(
      values.length == 1
          ? size.width / 2
          : 4 + (size.width - 8) * i / (values.length - 1),
      size.height - 4 - (size.height - 8) * (values[i] / scaleMax).clamp(0, 1),
    );
    if (values.length > 1) {
      final Path path = Path()..moveTo(at(0).dx, at(0).dy);
      for (int i = 1; i < values.length; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (int i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), i == values.length - 1 ? 4 : 2.6, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
