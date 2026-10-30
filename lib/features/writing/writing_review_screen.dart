import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/mia/mia_session_recorder.dart';
import '../../services/mia/writing_review.dart';
import '../../theme/app_colors.dart';
import '../lessons/engine/achievement_engine.dart';
import '../lessons/lesson_launcher.dart';
import '../lessons/models/lesson_models.dart';
import '../tutors/mia/widgets/mia_presence.dart';
import 'writing_checks.dart';
import 'writing_widgets.dart';

enum WritingReviewAction { revise, newTask, done }

/// Results of one text: Mia's review (when available), the automatic checks
/// and the learner's own text annotated with numbered references.
class WritingReviewScreen extends StatefulWidget {
  const WritingReviewScreen({
    super.key,
    required this.taskTitle,
    required this.genreLabel,
    required this.text,
    required this.review,
    required this.issues,
    required this.submittedAt,
    this.record,
    this.canRevise = true,
    this.offline = false,
  });

  final String taskTitle;
  final String genreLabel;
  final String text;

  /// Null when finished without the server (automatic checks only).
  final WritingReview? review;
  final List<MechanicalIssue> issues;
  final DateTime submittedAt;

  /// Null when reopened from the history (rewards already shown then).
  final MiaSessionRecord? record;
  final bool canRevise;

  /// True when the app had no server address at submission time.
  final bool offline;

  @override
  State<WritingReviewScreen> createState() => _WritingReviewScreenState();
}

class _WritingReviewScreenState extends State<WritingReviewScreen> {
  CorrectionPriority? _filter;
  bool _showRevised = false;

  WritingReview? get _review => widget.review;

  Future<void> _openNext(WritingNextActivity next) async {
    final LessonSkill? skill = switch (next.skill) {
      'grammar' => LessonSkill.grammar,
      'vocabulary' => LessonSkill.vocabulary,
      'reading' => LessonSkill.reading,
      _ => null,
    };
    if (skill == null) {
      Navigator.of(context).pop(WritingReviewAction.newTask);
      return;
    }
    await LessonLauncher.openSkill(context, skill);
  }

  @override
  Widget build(BuildContext context) {
    final WritingReview? review = _review;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          review == null ? 'Your text' : 'Mia’s review',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: <Widget>[
                _Header(
                  title: widget.taskTitle,
                  genre: widget.genreLabel,
                  review: review,
                  record: widget.record,
                  stats: WritingStats.of(widget.text),
                ),
                if (review != null && review.safetyRedirect) ...<Widget>[
                  const SizedBox(height: 18),
                  WritingPanel(
                    accent: AppColors.info,
                    child: Text(
                      review.overall,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ] else ...<Widget>[
                  if (review != null) ...<Widget>[
                    const SizedBox(height: 18),
                    WritingPanel(
                      accent: AppColors.mia,
                      child: Text(
                        review.overall,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ] else if (widget.offline) ...<Widget>[
                    const SizedBox(height: 18),
                    const WritingServerNotice(),
                  ],
                  ..._body(review),
                ],
                const SizedBox(height: 24),
                _Actions(
                  canRevise: widget.canRevise,
                  onAction: (WritingReviewAction a) =>
                      Navigator.of(context).pop(a),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(WritingReview? review) {
    final List<WritingCorrection> corrections =
        review?.corrections ?? const <WritingCorrection>[];
    final List<WritingCorrection> shown = _filter == null
        ? corrections
        : corrections
              .where((WritingCorrection c) => c.priority == _filter)
              .toList();

    return <Widget>[
      const WritingSectionTitle('Your text'),
      WritingPanel(
        child: _AnnotatedText(
          text: widget.text,
          corrections: corrections,
          issues: widget.issues,
        ),
      ),
      if (corrections.isNotEmpty || widget.issues.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Numbers match the corrections below. Lettered marks are '
            'automatic checks.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
      if (review != null && review.criteria.isNotEmpty) ...<Widget>[
        const WritingSectionTitle('Criteria for this genre'),
        WritingPanel(
          child: Column(
            children: <Widget>[
              for (final WritingCriterion c in review.criteria)
                _CriterionRow(criterion: c),
            ],
          ),
        ),
      ],
      if (review != null &&
          (review.strengths.isNotEmpty || review.weaknesses.isNotEmpty))
        _StrengthsAndFocus(review: review),
      if (corrections.isNotEmpty) ...<Widget>[
        WritingSectionTitle(
          'Corrections',
          trailing: Text(
            '${corrections.length}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final CorrectionPriority p in CorrectionPriority.values)
              if (corrections.any((WritingCorrection c) => c.priority == p))
                ChoiceChip(
                  label: Text(p.label),
                  selected: _filter == p,
                  onSelected: (_) => setState(() => _filter = p),
                ),
          ],
        ),
        const SizedBox(height: 12),
        for (final WritingCorrection c in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CorrectionCard(
              number: corrections.indexOf(c) + 1,
              correction: c,
            ),
          ),
      ],
      if (widget.issues.isNotEmpty) ...<Widget>[
        const WritingSectionTitle('Checked automatically'),
        for (int i = 0; i < widget.issues.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MechanicalIssueCard(
              issue: widget.issues[i],
              text: widget.text,
              mark: _letter(i),
            ),
          ),
      ],
      if (review != null && review.revisionPlan.isNotEmpty) ...<Widget>[
        const WritingSectionTitle('Revision plan'),
        WritingPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < review.revisionPlan.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          color: AppColors.primaryBright,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          review.revisionPlan[i],
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      if (review != null && review.revisedVersion.isNotEmpty) ...<Widget>[
        WritingSectionTitle(
          'Mia’s revised version',
          trailing: TextButton(
            onPressed: () => setState(() => _showRevised = !_showRevised),
            child: Text(_showRevised ? 'Hide' : 'Show'),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: !_showRevised
              ? const Text(
                  'Try your own revision first, then compare.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : WritingPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SelectableText(
                        review.revisedVersion,
                        style: writingTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: review.revisedVersion),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Revised version copied'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
      if (review?.nextActivity case final WritingNextActivity next) ...<Widget>[
        const WritingSectionTitle('Next step'),
        WritingPanel(
          accent: AppColors.primary,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  next.focus.isEmpty
                      ? 'Practise ${next.skill}'
                      : 'Practise ${next.skill}: ${next.focus}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => _openNext(next),
                child: Text(
                  next.skill == 'writing' ? 'New task' : 'Start lesson',
                ),
              ),
            ],
          ),
        ),
      ],
      if (review != null && review.estimateNote.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            review.estimateNote,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
    ];
  }
}

String _letter(int index) => String.fromCharCode(97 + index % 26);

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.genre,
    required this.review,
    required this.record,
    required this.stats,
  });

  final String title;
  final String genre;
  final WritingReview? review;
  final MiaSessionRecord? record;
  final WritingStats stats;

  @override
  Widget build(BuildContext context) {
    final int? score = review?.safetyRedirect == true
        ? null
        : review?.scorePercent;
    final MiaSessionRecord? rewards = record;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (score != null)
          _ScoreRing(score: score)
        else
          const MiaPresence(
            size: 68,
            showLabel: false,
            followVoice: false,
            state: MiaPresenceState.happy,
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$genre, ${stats.words} words, ${stats.sentences} sentences, '
                '${stats.paragraphs} paragraphs',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (rewards != null) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    if (rewards.xpAwarded > 0)
                      WritingTag(
                        '+${rewards.xpAwarded} XP',
                        color: AppColors.xp,
                      )
                    else
                      const WritingTag(
                        'No XP this time',
                        color: AppColors.textMuted,
                      ),
                    for (final Achievement a in rewards.newAchievements)
                      WritingTag(
                        'Unlocked: ${a.title}',
                        color: AppColors.reward,
                      ),
                  ],
                ),
                if (rewards.xpAwarded == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'A task earns XP once a day, when the text reaches its '
                      'minimum length.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Practice score $score percent',
      child: SizedBox(
        width: 78,
        height: 78,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: score / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? _) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                backgroundColor: AppColors.white08,
                color: AppColors.primary,
              ),
              Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The learner's text with numbered marks on corrected passages.
class _AnnotatedText extends StatelessWidget {
  const _AnnotatedText({
    required this.text,
    required this.corrections,
    required this.issues,
  });

  final String text;
  final List<WritingCorrection> corrections;
  final List<MechanicalIssue> issues;

  @override
  Widget build(BuildContext context) {
    final List<_Mark> marks = <_Mark>[];
    bool overlaps(int start, int end) =>
        marks.any((_Mark m) => start < m.end && end > m.start);

    final String lower = text.toLowerCase();
    for (int i = 0; i < corrections.length; i++) {
      final String quote = corrections[i].original;
      int at = text.indexOf(quote);
      if (at < 0) at = lower.indexOf(quote.toLowerCase());
      while (at >= 0 && overlaps(at, at + quote.length)) {
        at = lower.indexOf(quote.toLowerCase(), at + 1);
      }
      if (at < 0) continue;
      marks.add(
        _Mark(
          at,
          at + quote.length,
          '${i + 1}',
          corrections[i].certainty.isMistake
              ? AppColors.warning
              : AppColors.info,
        ),
      );
    }
    for (int i = 0; i < issues.length; i++) {
      final MechanicalIssue issue = issues[i];
      final int end = issue.offset + issue.length;
      if (end > text.length || overlaps(issue.offset, end)) continue;
      marks.add(_Mark(issue.offset, end, _letter(i), AppColors.grammar));
    }
    marks.sort((_Mark a, _Mark b) => a.start - b.start);

    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    for (final _Mark m in marks) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: TextStyle(
            backgroundColor: m.color.withValues(alpha: 0.16),
            decoration: TextDecoration.underline,
            decorationColor: m.color,
            decorationThickness: 2,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: ' ${m.label}',
          style: TextStyle(
            color: m.color,
            fontFamily: null,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));

    return SelectableText.rich(
      TextSpan(style: writingTextStyle, children: spans),
    );
  }
}

class _Mark {
  const _Mark(this.start, this.end, this.label, this.color);

  final int start;
  final int end;
  final String label;
  final Color color;
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion});

  final WritingCriterion criterion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${criterion.label}: ${criterion.score} out of 5. '
          '${criterion.comment}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      criterion.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (int i = 0; i < 5; i++)
                    Container(
                      width: 18,
                      height: 6,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: i < criterion.score
                            ? AppColors.primary
                            : AppColors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${criterion.score}/5',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (criterion.comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    criterion.comment,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthsAndFocus extends StatelessWidget {
  const _StrengthsAndFocus({required this.review});

  final WritingReview review;

  @override
  Widget build(BuildContext context) {
    Widget list(String title, List<String> items, IconData icon, Color color) =>
        WritingPanel(
          accent: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final String item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

    final List<Widget> panels = <Widget>[
      if (review.strengths.isNotEmpty)
        list(
          'What works',
          review.strengths,
          Icons.check_circle_outline,
          AppColors.success,
        ),
      if (review.weaknesses.isNotEmpty)
        list(
          'What to work on',
          review.weaknesses,
          Icons.flag_outlined,
          AppColors.warning,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 620 || panels.length < 2) {
            return Column(
              children: <Widget>[
                for (final Widget p in panels)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: p),
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: panels[0]),
                const SizedBox(width: 12),
                Expanded(child: panels[1]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.number, required this.correction});

  final int number;
  final WritingCorrection correction;

  @override
  Widget build(BuildContext context) {
    final WritingCorrection c = correction;
    final bool mistake = c.certainty.isMistake;
    final Color tone = mistake ? AppColors.warning : AppColors.info;
    return WritingPanel(
      accent: tone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                '$number',
                style: TextStyle(
                  color: tone,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              WritingTag(c.certainty.label, color: tone),
              WritingTag(c.category[0].toUpperCase() + c.category.substring(1)),
              WritingTag(
                c.priority.label,
                color: c.priority == CorrectionPriority.essential
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.original,
            style: writingTextStyle.copyWith(
              color: AppColors.textSecondary,
              decoration: mistake ? TextDecoration.lineThrough : null,
              decorationColor: tone,
            ),
          ),
          if (c.suggestion.isNotEmpty && c.suggestion != c.original)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.suggestion,
                      style: writingTextStyle.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (c.explanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              c.explanation,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          ],
          if (c.rule.isNotEmpty) _labelled('Rule', c.rule),
          if (c.example.isNotEmpty)
            _labelled('Example', c.example, italic: true),
          if (c.nextStep.isNotEmpty) _labelled('Practise', c.nextStep),
        ],
      ),
    );
  }

  Widget _labelled(String label, String value, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
        style: const TextStyle(height: 1.45),
      ),
    );
  }
}

/// One automatic check, with the surrounding words for context.
class MechanicalIssueCard extends StatelessWidget {
  const MechanicalIssueCard({
    super.key,
    required this.issue,
    required this.text,
    this.mark,
  });

  final MechanicalIssue issue;
  final String text;

  /// Letter shown in the annotated text, if any.
  final String? mark;

  @override
  Widget build(BuildContext context) {
    return WritingPanel(
      accent: AppColors.grammar,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (mark != null) ...<Widget>[
                Text(
                  mark!,
                  style: const TextStyle(
                    color: AppColors.grammar,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              WritingTag(issue.kind.label, color: AppColors.grammar),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contextAround(text, issue.offset, issue.length),
            style: writingTextStyle.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            issue.explanation,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.canRevise, required this.onAction});

  final bool canRevise;
  final ValueChanged<WritingReviewAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: <Widget>[
        TextButton(
          onPressed: () => onAction(WritingReviewAction.done),
          child: const Text('Done'),
        ),
        OutlinedButton(
          onPressed: () => onAction(WritingReviewAction.newTask),
          child: const Text('New task'),
        ),
        if (canRevise)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () => onAction(WritingReviewAction.revise),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Revise my text'),
          ),
      ],
    );
  }
}
