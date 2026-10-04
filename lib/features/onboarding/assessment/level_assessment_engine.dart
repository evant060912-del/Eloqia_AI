import 'dart:math' as math;

import 'level_assessment_data.dart';
import 'level_assessment_result.dart';

class AssessmentAnswer {
  const AssessmentAnswer({required this.question, required this.correct});

  final AssessmentQuestion question;
  final bool correct;
}

/// Adaptive staircase over the CEFR bank. Pure Dart: no I/O, no randomness.
class LevelAssessmentEngine {
  LevelAssessmentEngine({
    required this.selfReportedLevel,
    this.bank = assessmentQuestionBank,
    this.maxQuestions = 8,
  }) : _startLevelIndex = _indexOfLevel(selfReportedLevel);

  static const int minAnswersForResult = 4;
  static const double _pCorrectWithinAbility = 0.85;
  static const double _pCorrectAboveAbility = 0.2;

  final String selfReportedLevel;
  final int maxQuestions;
  final List<AssessmentQuestion> bank;
  final int _startLevelIndex;
  final List<AssessmentAnswer> _answers = <AssessmentAnswer>[];

  List<AssessmentAnswer> get answers =>
      List<AssessmentAnswer>.unmodifiable(_answers);
  int get answeredCount => _answers.length;
  bool get isFinished =>
      _answers.length >= maxQuestions || nextQuestion() == null;

  static int _indexOfLevel(String level) {
    final int index = assessmentLevels.indexOf(level.trim().toUpperCase());

    // Unknown or undeclared level: start in the middle of the scale.
    return index < 0 ? 2 : index;
  }

  int get _targetLevelIndex {
    if (_answers.isEmpty) {
      return _startLevelIndex;
    }

    final AssessmentAnswer last = _answers.last;
    final int step = last.correct ? 1 : -1;

    return (last.question.levelIndex + step).clamp(
      0,
      assessmentLevels.length - 1,
    );
  }

  /// Next question, or null when the bank or question budget is exhausted.
  AssessmentQuestion? nextQuestion() {
    if (_answers.length >= maxQuestions) {
      return null;
    }

    final Set<String> asked = <String>{
      for (final AssessmentAnswer a in _answers) a.question.id,
    };
    final List<AssessmentQuestion> remaining = bank
        .where((AssessmentQuestion q) => !asked.contains(q.id))
        .toList();

    if (remaining.isEmpty) {
      return null;
    }

    final int target = _targetLevelIndex;
    final Map<AssessmentSkill, int> skillCounts = <AssessmentSkill, int>{
      for (final AssessmentSkill s in AssessmentSkill.values) s: 0,
    };
    for (final AssessmentAnswer a in _answers) {
      skillCounts[a.question.skill] = skillCounts[a.question.skill]! + 1;
    }

    remaining.sort((AssessmentQuestion a, AssessmentQuestion b) {
      final int byLevel = (a.levelIndex - target).abs().compareTo(
        (b.levelIndex - target).abs(),
      );
      if (byLevel != 0) {
        return byLevel;
      }

      // Same distance: favour the least-tested skill, then bank order.
      return skillCounts[a.skill]!.compareTo(skillCounts[b.skill]!);
    });

    return remaining.first;
  }

  void submit(AssessmentQuestion question, int selectedIndex) {
    _answers.add(
      AssessmentAnswer(
        question: question,
        correct: selectedIndex == question.correctIndex,
      ),
    );
  }

  /// Maximum-likelihood CEFR estimate with a posterior-based confidence.
  LevelAssessmentResult buildResult({DateTime? at}) {
    final DateTime now = (at ?? DateTime.now()).toUtc();

    if (_answers.length < minAnswersForResult) {
      return LevelAssessmentResult(
        status: LevelAssessmentStatus.incomplete,
        selfReportedLevel: selfReportedLevel,
        recordedAt: now,
        answeredCount: _answers.length,
      );
    }

    final List<double> logLikelihood = List<double>.generate(
      assessmentLevels.length,
      (int ability) {
        double total = 0;
        for (final AssessmentAnswer a in _answers) {
          final double p = a.question.levelIndex <= ability
              ? _pCorrectWithinAbility
              : _pCorrectAboveAbility;
          total += math.log(a.correct ? p : 1 - p);
        }

        return total;
      },
    );

    int best = 0;
    for (int i = 1; i < logLikelihood.length; i++) {
      if (logLikelihood[i] > logLikelihood[best]) {
        best = i;
      }
    }

    final double maxLog = logLikelihood[best];
    final double normaliser = logLikelihood.fold<double>(
      0,
      (double sum, double value) => sum + math.exp(value - maxLog),
    );

    double weightedCorrect = 0;
    double weightedTotal = 0;
    final Map<AssessmentSkill, List<bool>> bySkill =
        <AssessmentSkill, List<bool>>{};
    for (final AssessmentAnswer a in _answers) {
      final double weight = a.question.levelIndex + 1.0;
      weightedTotal += weight;
      if (a.correct) {
        weightedCorrect += weight;
      }
      bySkill.putIfAbsent(a.question.skill, () => <bool>[]).add(a.correct);
    }

    return LevelAssessmentResult(
      status: LevelAssessmentStatus.completed,
      selfReportedLevel: selfReportedLevel,
      assessedLevel: assessmentLevels[best],
      score: weightedCorrect / weightedTotal * 100,
      confidence: 1 / normaliser,
      answeredCount: _answers.length,
      skillScores: <String, double>{
        for (final MapEntry<AssessmentSkill, List<bool>> e in bySkill.entries)
          e.key.name:
              e.value.where((bool c) => c).length / e.value.length * 100,
      },
      recordedAt: now,
    );
  }
}
