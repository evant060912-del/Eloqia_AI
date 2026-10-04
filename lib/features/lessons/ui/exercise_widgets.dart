import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../models/lesson_models.dart';

/// Soft, non-punishing colour for corrections.
const Color kCorrectionColor = Color(0xFFFFB86B);

enum AnswerResult { none, correct, incorrect }

/// Renders the input for one exercise type and reports the response, or null
/// while the answer is incomplete.
class ExerciseInput extends StatelessWidget {
  const ExerciseInput({
    super.key,
    required this.exercise,
    required this.result,
    required this.locked,
    required this.onChanged,
    this.eliminated = const <String>{},
    this.wrongPairs = const <String>[],
    this.revealAnswer = false,
    this.onSubmit,
  });

  final Exercise exercise;
  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;

  /// Options already tried and wrong, muted on a retry.
  final Set<String> eliminated;
  final List<String> wrongPairs;
  final bool revealAnswer;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return switch (exercise.type) {
      ExerciseType.multipleChoice => _ChoiceInput(
        exercise: exercise,
        result: result,
        locked: locked,
        onChanged: onChanged,
        eliminated: eliminated,
        revealAnswer: revealAnswer,
      ),
      ExerciseType.trueFalse => _TrueFalseInput(
        exercise: exercise,
        result: result,
        locked: locked,
        onChanged: onChanged,
        eliminated: eliminated,
        revealAnswer: revealAnswer,
      ),
      ExerciseType.fillBlank => _FillInput(
        result: result,
        locked: locked,
        onChanged: onChanged,
        onSubmit: onSubmit,
      ),
      ExerciseType.ordering => _OrderingInput(
        exercise: exercise,
        result: result,
        locked: locked,
        onChanged: onChanged,
      ),
      ExerciseType.matching => _MatchingInput(
        exercise: exercise,
        result: result,
        locked: locked,
        onChanged: onChanged,
        wrongPairs: wrongPairs,
      ),
    };
  }
}

Color _resultColor(AnswerResult r) => switch (r) {
  AnswerResult.correct => AppColors.success,
  AnswerResult.incorrect => kCorrectionColor,
  AnswerResult.none => AppColors.primary,
};

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child, this.label});

  final VoidCallback? onTap;
  final Widget child;
  final String? label;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.state,
    required this.onTap,
    this.leading,
    this.muted = false,
    this.minHeight = 56,
    this.center = false,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool muted;
  final double minHeight;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (state) {
      _OptionState.selected => AppColors.primary,
      _OptionState.correct => AppColors.success,
      _OptionState.incorrect => kCorrectionColor,
      _OptionState.idle => AppColors.glassBorder,
    };
    final bool active = state != _OptionState.idle;

    return _Pressable(
      label: label,
      onTap: muted ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.12)
              : AppColors.glass.withValues(alpha: muted ? 0.05 : 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: active ? 1.6 : 1),
          boxShadow: state == _OptionState.correct
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.28),
                    blurRadius: 22,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            ?leading,
            if (leading != null) const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: muted ? AppColors.textDisabled : AppColors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  decoration: muted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (state == _OptionState.correct) ...<Widget>[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ] else if (state == _OptionState.incorrect) ...<Widget>[
              const SizedBox(width: 8),
              const Icon(Icons.info_outline_rounded, color: kCorrectionColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, selected, correct, incorrect }

class _ChoiceInput extends StatefulWidget {
  const _ChoiceInput({
    required this.exercise,
    required this.result,
    required this.locked,
    required this.onChanged,
    required this.eliminated,
    required this.revealAnswer,
  });

  final Exercise exercise;
  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;
  final Set<String> eliminated;
  final bool revealAnswer;

  @override
  State<_ChoiceInput> createState() => _ChoiceInputState();
}

class _ChoiceInputState extends State<_ChoiceInput> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final List<String> letters = <String>['A', 'B', 'C', 'D', 'E'];
    return Column(
      children: <Widget>[
        for (int i = 0; i < widget.exercise.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildOption(widget.exercise.options[i], letters[i]),
          ),
      ],
    );
  }

  Widget _buildOption(String option, String letter) {
    final bool isCorrectAnswer = widget.exercise.answers.contains(option);
    _OptionState state = _OptionState.idle;
    if (_selected == option) {
      state = switch (widget.result) {
        AnswerResult.none => _OptionState.selected,
        AnswerResult.correct => _OptionState.correct,
        AnswerResult.incorrect => _OptionState.incorrect,
      };
    } else if (widget.revealAnswer && isCorrectAnswer) {
      state = _OptionState.correct;
    }

    return _OptionCard(
      label: option,
      state: state,
      muted: widget.eliminated.contains(option),
      onTap: widget.locked
          ? null
          : () {
              setState(() => _selected = option);
              HapticFeedback.selectionClick();
              widget.onChanged(option);
            },
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Text(
          letter,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrueFalseInput extends StatefulWidget {
  const _TrueFalseInput({
    required this.exercise,
    required this.result,
    required this.locked,
    required this.onChanged,
    required this.eliminated,
    required this.revealAnswer,
  });

  final Exercise exercise;
  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;
  final Set<String> eliminated;
  final bool revealAnswer;

  @override
  State<_TrueFalseInput> createState() => _TrueFalseInputState();
}

class _TrueFalseInputState extends State<_TrueFalseInput> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _tile('True', Icons.check_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _tile('False', Icons.close_rounded)),
      ],
    );
  }

  Widget _tile(String value, IconData icon) {
    _OptionState state = _OptionState.idle;
    if (_selected == value) {
      state = switch (widget.result) {
        AnswerResult.none => _OptionState.selected,
        AnswerResult.correct => _OptionState.correct,
        AnswerResult.incorrect => _OptionState.incorrect,
      };
    } else if (widget.revealAnswer && widget.exercise.answers.contains(value)) {
      state = _OptionState.correct;
    }
    return _OptionCard(
      label: value,
      state: state,
      center: true,
      minHeight: 84,
      muted: widget.eliminated.contains(value),
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      onTap: widget.locked
          ? null
          : () {
              setState(() => _selected = value);
              HapticFeedback.selectionClick();
              widget.onChanged(value);
            },
    );
  }
}

class _FillInput extends StatefulWidget {
  const _FillInput({
    required this.result,
    required this.locked,
    required this.onChanged,
    this.onSubmit,
  });

  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onSubmit;

  @override
  State<_FillInput> createState() => _FillInputState();
}

class _FillInputState extends State<_FillInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _resultColor(widget.result);
    return TextField(
      controller: _controller,
      enabled: !widget.locked,
      autofocus: true,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: AppColors.primary,
      onChanged: (String v) =>
          widget.onChanged(v.trim().isEmpty ? null : v.trim()),
      onSubmitted: (_) => widget.onSubmit?.call(),
      decoration: InputDecoration(
        hintText: 'Type your answer',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: color.withValues(alpha: widget.result == AnswerResult.none ? 0.05 : 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.result == AnswerResult.none
                ? AppColors.glassBorder
                : color,
            width: widget.result == AnswerResult.none ? 1 : 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.8),
        ),
      ),
    );
  }
}

List<int> _shuffledOrder(String seed, int length) {
  final List<int> order = List<int>.generate(length, (int i) => i);
  order.shuffle(math.Random(seed.hashCode));
  final bool identity = <int>[
    for (int i = 0; i < length; i++) i,
  ].every((int i) => order[i] == i);
  return identity ? order.reversed.toList() : order;
}

class _OrderingInput extends StatefulWidget {
  const _OrderingInput({
    required this.exercise,
    required this.result,
    required this.locked,
    required this.onChanged,
  });

  final Exercise exercise;
  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;

  @override
  State<_OrderingInput> createState() => _OrderingInputState();
}

class _OrderingInputState extends State<_OrderingInput> {
  late final List<int> _bank = _shuffledOrder(
    widget.exercise.id,
    widget.exercise.options.length,
  );
  final List<int> _chosen = <int>[];

  void _emit() {
    widget.onChanged(
      _chosen.length == widget.exercise.options.length
          ? _chosen.map((int i) => widget.exercise.options[i]).join(' ')
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _resultColor(widget.result);
    final List<int> remaining = _bank
        .where((int i) => !_chosen.contains(i))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: widget.result == AnswerResult.none ? 0.05 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.result == AnswerResult.none ? AppColors.glassBorder : color,
              width: widget.result == AnswerResult.none ? 1 : 1.6,
            ),
          ),
          child: _chosen.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Tap the words below to build the sentence',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final int i in _chosen)
                      _chip(widget.exercise.options[i], selected: true, onTap: widget.locked
                          ? null
                          : () {
                              setState(() => _chosen.remove(i));
                              _emit();
                            }),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final int i in remaining)
              _chip(widget.exercise.options[i], selected: false, onTap: widget.locked
                  ? null
                  : () {
                      setState(() => _chosen.add(i));
                      HapticFeedback.selectionClick();
                      _emit();
                    }),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, {required bool selected, VoidCallback? onTap}) {
    return _Pressable(
      label: text,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MatchingInput extends StatefulWidget {
  const _MatchingInput({
    required this.exercise,
    required this.result,
    required this.locked,
    required this.onChanged,
    required this.wrongPairs,
  });

  final Exercise exercise;
  final AnswerResult result;
  final bool locked;
  final ValueChanged<String?> onChanged;
  final List<String> wrongPairs;

  @override
  State<_MatchingInput> createState() => _MatchingInputState();
}

class _MatchingInputState extends State<_MatchingInput> {
  static const List<Color> _palette = <Color>[
    AppColors.primary,
    AppColors.secondary,
    AppColors.warmth,
    AppColors.success,
    AppColors.electricBlue,
  ];

  late final List<String> _left = widget.exercise.pairs.keys.toList()..sort();
  late final List<String> _right = () {
    final List<String> values = widget.exercise.pairs.values.toList();
    final List<int> order = _shuffledOrder(widget.exercise.id, values.length);
    return <String>[for (final int i in order) values[i]];
  }();
  final Map<String, String> _pairs = <String, String>{};
  String? _selectedLeft;

  Color _colorFor(String left) =>
      _palette[_left.indexOf(left) % _palette.length];

  void _emit() {
    widget.onChanged(
      _pairs.length == _left.length ? Exercise.canonicalPairs(_pairs) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[for (final String l in _left) _leftTile(l)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: <Widget>[for (final String r in _right) _rightTile(r)],
          ),
        ),
      ],
    );
  }

  Widget _leftTile(String left) {
    final bool paired = _pairs.containsKey(left);
    final bool selected = _selectedLeft == left;
    final bool wrong = widget.wrongPairs.contains(left);
    final bool graded = widget.result != AnswerResult.none;
    final Color accent = graded
        ? (wrong ? kCorrectionColor : AppColors.success)
        : (paired || selected ? _colorFor(left) : AppColors.glassBorder);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Pressable(
        label: left,
        onTap: widget.locked
            ? null
            : () => setState(() {
                if (paired) {
                  _pairs.remove(left);
                  _emit();
                }
                _selectedLeft = selected ? null : left;
              }),
        child: _matchBox(left, accent, active: paired || selected || graded),
      ),
    );
  }

  Widget _rightTile(String right) {
    final String? owner = _pairs.entries
        .where((MapEntry<String, String> e) => e.value == right)
        .map((MapEntry<String, String> e) => e.key)
        .firstOrNull;
    final bool graded = widget.result != AnswerResult.none;
    final Color accent = owner == null
        ? AppColors.glassBorder
        : (graded
              ? (widget.wrongPairs.contains(owner)
                    ? kCorrectionColor
                    : AppColors.success)
              : _colorFor(owner));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Pressable(
        label: right,
        onTap: widget.locked || _selectedLeft == null
            ? null
            : () => setState(() {
                _pairs.removeWhere(
                  (String _, String value) => value == right,
                );
                _pairs[_selectedLeft!] = right;
                _selectedLeft = null;
                HapticFeedback.selectionClick();
                _emit();
              }),
        child: _matchBox(right, accent, active: owner != null),
      ),
    );
  }

  Widget _matchBox(String text, Color accent, {required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.14) : AppColors.glass.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: active ? 1.6 : 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
    );
  }
}
