import '../models/lesson_models.dart';
import 'exercise_evaluator.dart';
import 'lesson_feedback.dart';

class ExerciseOutcome {
  const ExerciseOutcome({
    required this.exercise,
    required this.evaluation,
    required this.feedback,
    required this.attempt,
    required this.xp,
    required this.comboBonus,
    required this.combo,
    required this.isChallenge,
  });

  final Exercise exercise;
  final ExerciseEvaluation evaluation;
  final LessonFeedback feedback;
  final int attempt;
  final int xp;
  final int comboBonus;
  final int combo;
  final bool isChallenge;

  int get totalXp => xp + comboBonus;
}

class LessonSummary {
  const LessonSummary({
    required this.lesson,
    required this.firstTryCorrect,
    required this.totalExercises,
    required this.answerXp,
    required this.completionXp,
    required this.maxCombo,
    required this.missedTopics,
    required this.firstHalfAccuracy,
    required this.secondHalfAccuracy,
    required this.duration,
  });

  final Lesson lesson;
  final int firstTryCorrect;
  final int totalExercises;
  final int answerXp;
  final int completionXp;
  final int maxCombo;
  final Map<String, int> missedTopics;

  /// Null when the session is too short to compare halves.
  final double? firstHalfAccuracy;
  final double? secondHalfAccuracy;
  final Duration duration;

  int get totalXp => answerXp + completionXp;
  double get accuracy =>
      totalExercises == 0 ? 0 : firstTryCorrect / totalExercises;
  bool get perfect => totalExercises >= 4 && firstTryCorrect == totalExercises;

  /// True only when later answers were measurably better than earlier ones.
  bool get finishedStronger =>
      firstHalfAccuracy != null &&
      secondHalfAccuracy != null &&
      secondHalfAccuracy! - firstHalfAccuracy! >= 0.3;
}

/// Pure lesson state machine: queueing, retries, adaptive extension and XP.
class LessonSession {
  LessonSession({
    required this.lesson,
    this.correctionStyle = '',
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now(),
       _queue = <Exercise>[...lesson.exercisesOf(ActivityKind.practice)];

  static const double challengeAccuracy = 0.75;

  final Lesson lesson;
  final String correctionStyle;
  final DateTime startedAt;

  final List<Exercise> _queue;
  final Set<String> _challengeIds = <String>{};
  final Map<String, bool> _firstTry = <String, bool>{};
  final List<bool> _firstTryLog = <bool>[];
  final Map<String, int> _mistakesByTopic = <String, int>{};
  final List<Exercise> _missed = <Exercise>[];

  int _index = 0;
  int _attempts = 0;
  bool _challengeAdded = false;
  bool _reviewAdded = false;
  bool _answeredCurrent = false;
  int combo = 0;
  int maxCombo = 0;
  int answerXp = 0;

  Exercise? get current => _index < _queue.length ? _queue[_index] : null;
  int get position => _index;
  int get queueLength => _queue.length;
  bool get isComplete => current == null;
  bool get isChallenge =>
      current != null && !isReview && _challengeIds.contains(current!.id);
  bool get isReview => _reviewAdded && _index >= _reviewStart;
  int _reviewStart = 1 << 30;
  bool get answeredCurrent => _answeredCurrent;

  /// First-try result of every exercise answered so far (spaced review).
  Map<String, bool> get firstTryResults =>
      Map<String, bool>.unmodifiable(_firstTry);

  double get practiceAccuracy {
    final Iterable<MapEntry<String, bool>> practice = _firstTry.entries.where(
      (MapEntry<String, bool> e) => !_challengeIds.contains(e.key),
    );
    if (practice.isEmpty) {
      return 0;
    }
    return practice.where((MapEntry<String, bool> e) => e.value).length /
        practice.length;
  }

  int mistakesOn(String topic) => _mistakesByTopic[topic] ?? 0;

  static int baseXp(Exercise exercise) => switch (exercise.difficulty) {
    >= 3 => 5,
    2 => 3,
    _ => 2,
  };

  static int comboBonusFor(int combo) => switch (combo) {
    3 => 2,
    5 => 3,
    7 => 5,
    _ => 0,
  };

  ExerciseOutcome submit(String response) {
    final Exercise exercise = current!;
    final ExerciseEvaluation evaluation = ExerciseEvaluator.evaluate(
      exercise,
      response,
    );
    _attempts++;
    _answeredCurrent = true;
    final bool first = _attempts == 1;
    final bool review = isReview;
    final bool challenge = isChallenge;
    final int mistakesBefore = mistakesOn(exercise.topic);

    int xp = 0;
    int bonus = 0;

    if (evaluation.correct) {
      xp = first && !review ? baseXp(exercise) : 1;
      if (challenge) {
        xp *= 2;
      }
      if (first && !review) {
        combo++;
        maxCombo = combo > maxCombo ? combo : maxCombo;
        bonus = comboBonusFor(combo);
      }
    } else if (first && !review) {
      combo = 0;
    }

    if (first && !review && !_firstTry.containsKey(exercise.id)) {
      _firstTry[exercise.id] = evaluation.correct;
      _firstTryLog.add(evaluation.correct);
      if (!evaluation.correct) {
        _mistakesByTopic[exercise.topic] = mistakesBefore + 1;
        _missed.add(exercise);
      }
    }

    answerXp += xp + bonus;

    final LessonFeedback feedback = FeedbackBuilder.build(
      exercise: exercise,
      evaluation: evaluation,
      context: FeedbackContext(
        attempt: _attempts,
        previousMistakesOnTopic: first ? mistakesBefore : mistakesBefore - 1,
        comboAfter: combo,
        isChallenge: challenge,
        correctionStyle: correctionStyle,
        skill: lesson.skill,
      ),
    );

    return ExerciseOutcome(
      exercise: exercise,
      evaluation: evaluation,
      feedback: feedback,
      attempt: _attempts,
      xp: xp,
      comboBonus: bonus,
      combo: combo,
      isChallenge: challenge,
    );
  }

  /// Lets the learner retry the current exercise after a wrong first answer.
  void retry() {
    _answeredCurrent = false;
  }

  bool get retryAvailable => _attempts < 2;

  /// Moves on and adaptively extends the queue; returns false when finished.
  bool advance() {
    _index++;
    _attempts = 0;
    _answeredCurrent = false;
    if (_index >= _queue.length) {
      _extend();
    }
    return !isComplete;
  }

  void _extend() {
    if (!_challengeAdded) {
      _challengeAdded = true;
      final List<Exercise> challenge = lesson.exercisesOf(
        ActivityKind.challenge,
      );
      if (challenge.isNotEmpty && practiceAccuracy >= challengeAccuracy) {
        _challengeIds.addAll(challenge.map((Exercise e) => e.id));
        _queue.addAll(challenge);
        return;
      }
    }
    if (!_reviewAdded) {
      _reviewAdded = true;
      final List<Exercise> review = <Exercise>[
        for (final Exercise e in _missed)
          if (_firstTry[e.id] == false) e,
      ];
      if (review.isNotEmpty) {
        _reviewStart = _queue.length;
        _queue.addAll(review);
      }
    }
  }

  LessonSummary summarize({DateTime? now}) {
    final int total = _firstTry.length;
    final int correct = _firstTry.values.where((bool v) => v).length;
    final double accuracy = total == 0 ? 0 : correct / total;
    final double factor = accuracy >= 0.8 ? 1 : (accuracy >= 0.5 ? 0.6 : 0.3);

    double? firstHalf;
    double? secondHalf;
    if (_firstTryLog.length >= 6) {
      final int mid = _firstTryLog.length ~/ 2;
      double rate(Iterable<bool> items) =>
          items.where((bool v) => v).length / items.length;
      firstHalf = rate(_firstTryLog.take(mid));
      secondHalf = rate(_firstTryLog.skip(mid));
    }

    return LessonSummary(
      lesson: lesson,
      firstTryCorrect: correct,
      totalExercises: total,
      answerXp: answerXp,
      completionXp: (lesson.xpReward * factor).round(),
      maxCombo: maxCombo,
      missedTopics: Map<String, int>.unmodifiable(_mistakesByTopic),
      firstHalfAccuracy: firstHalf,
      secondHalfAccuracy: secondHalf,
      duration: (now ?? DateTime.now()).difference(startedAt),
    );
  }
}
