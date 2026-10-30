import 'package:flutter/foundation.dart';

/// Mia's review of one Writing Studio text (`POST /v1/writing/review`).
///
/// Parsing is tolerant on missing fields and strict on what matters: a review
/// without an overall assessment is rejected.
@immutable
class WritingReview {
  const WritingReview({
    required this.overall,
    this.scorePercent,
    this.criteria = const <WritingCriterion>[],
    this.strengths = const <String>[],
    this.weaknesses = const <String>[],
    this.corrections = const <WritingCorrection>[],
    this.revisionPlan = const <String>[],
    this.revisedVersion = '',
    this.nextActivity,
    this.wordCount = 0,
    this.estimateNote = '',
    this.examEstimate,
    this.safetyRedirect = false,
  });

  /// Returns null when the data is not a usable review.
  static WritingReview? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    final String overall = _string(json['overall']);
    if (overall.isEmpty) return null;
    final Object? score = json['score_percent'];
    final Object? next = json['next_activity'];
    return WritingReview(
      overall: overall,
      scorePercent: score is num ? score.toInt().clamp(0, 100) : null,
      criteria: _list(json['criteria'], WritingCriterion.fromJson),
      strengths: _strings(json['strengths']),
      weaknesses: _strings(json['weaknesses']),
      corrections: _list(json['corrections'], WritingCorrection.fromJson)
          .where((WritingCorrection c) => c.original.isNotEmpty)
          .toList(growable: false),
      revisionPlan: _strings(json['revision_plan']),
      revisedVersion: _string(json['revised_version']),
      nextActivity: next is Map
          ? WritingNextActivity.fromJson(Map<String, dynamic>.from(next))
          : null,
      wordCount: json['word_count'] is num
          ? (json['word_count'] as num).toInt()
          : 0,
      estimateNote: _string(json['estimate_note']),
      examEstimate: ExamEstimate.tryParse(json['exam_estimate']),
      safetyRedirect: json['safety_redirect'] == true,
    );
  }

  final String overall;

  /// Weighted practice score computed by the server (null when unreliable).
  final int? scorePercent;
  final List<WritingCriterion> criteria;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<WritingCorrection> corrections;
  final List<String> revisionPlan;
  final String revisedVersion;
  final WritingNextActivity? nextActivity;
  final int wordCount;
  final String estimateNote;

  /// IELTS band or TOEFL task score, for exam tasks only (unofficial).
  final ExamEstimate? examEstimate;
  final bool safetyRedirect;

  /// Same keys as the server, so a saved review can be parsed again.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'overall': overall,
    'score_percent': scorePercent,
    'criteria': criteria.map((WritingCriterion c) => c.toJson()).toList(),
    'strengths': strengths,
    'weaknesses': weaknesses,
    'corrections': corrections
        .map((WritingCorrection c) => c.toJson())
        .toList(),
    'revision_plan': revisionPlan,
    'revised_version': revisedVersion,
    'next_activity': nextActivity?.toJson(),
    'word_count': wordCount,
    'estimate_note': estimateNote,
    'exam_estimate': examEstimate?.toJson(),
    'safety_redirect': safetyRedirect,
  };
}

@immutable
class WritingCriterion {
  const WritingCriterion({
    required this.criterion,
    required this.label,
    required this.score,
    this.maxScore = 5,
    this.weight = 1,
    this.comment = '',
  });

  factory WritingCriterion.fromJson(Map<String, dynamic> json) {
    final String criterion = _string(json['criterion']);
    final int maxScore = json['max_score'] is num
        ? (json['max_score'] as num).toInt().clamp(1, 9)
        : 5;
    return WritingCriterion(
      criterion: criterion,
      label: _string(json['label'], fallback: criterion.replaceAll('_', ' ')),
      maxScore: maxScore,
      score: json['score'] is num
          ? (json['score'] as num).toInt().clamp(0, maxScore)
          : 0,
      weight: json['weight'] is num
          ? (json['weight'] as num).toInt().clamp(1, 3)
          : 1,
      comment: _string(json['comment']),
    );
  }

  final String criterion;
  final String label;

  /// 0 to [maxScore] (5 for Eloqia and TOEFL criteria, 9 for IELTS bands).
  final int score;
  final int maxScore;
  final int weight;
  final String comment;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'criterion': criterion,
    'label': label,
    'score': score,
    'max_score': maxScore,
    'weight': weight,
    'comment': comment,
  };
}

/// How sure Mia is that something is wrong.
enum CorrectionCertainty {
  definite('definite', 'Error'),
  likely('likely', 'Probable error'),
  awkward('awkward', 'Awkward'),
  optional('optional', 'Style option'),
  variation('variation', 'Also correct');

  const CorrectionCertainty(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Optional improvements and valid variants are not mistakes.
  bool get isMistake =>
      this == CorrectionCertainty.definite ||
      this == CorrectionCertainty.likely ||
      this == CorrectionCertainty.awkward;

  static CorrectionCertainty parse(Object? value) {
    for (final CorrectionCertainty c in CorrectionCertainty.values) {
      if (c.apiValue == value) return c;
    }
    return CorrectionCertainty.likely;
  }
}

enum CorrectionPriority {
  essential('essential', 'Essential'),
  important('important', 'Important'),
  optional('optional', 'Optional');

  const CorrectionPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CorrectionPriority parse(Object? value) {
    for (final CorrectionPriority p in CorrectionPriority.values) {
      if (p.apiValue == value) return p;
    }
    return CorrectionPriority.important;
  }
}

@immutable
class WritingCorrection {
  const WritingCorrection({
    required this.original,
    required this.suggestion,
    this.category = 'grammar',
    this.certainty = CorrectionCertainty.definite,
    this.priority = CorrectionPriority.important,
    this.explanation = '',
    this.rule = '',
    this.example = '',
    this.nextStep = '',
  });

  factory WritingCorrection.fromJson(Map<String, dynamic> json) =>
      WritingCorrection(
        original: _string(json['original']),
        suggestion: _string(json['suggestion']),
        category: _string(json['category'], fallback: 'grammar'),
        certainty: CorrectionCertainty.parse(json['certainty']),
        priority: CorrectionPriority.parse(json['priority']),
        explanation: _string(json['explanation']),
        rule: _string(json['rule']),
        example: _string(json['example']),
        nextStep: _string(json['next_step']),
      );

  /// Exact quote from the learner's text.
  final String original;
  final String suggestion;

  /// grammar, vocabulary, spelling, punctuation, register, organization,
  /// style.
  final String category;
  final CorrectionCertainty certainty;
  final CorrectionPriority priority;
  final String explanation;
  final String rule;
  final String example;
  final String nextStep;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'original': original,
    'suggestion': suggestion,
    'category': category,
    'certainty': certainty.apiValue,
    'priority': priority.apiValue,
    'explanation': explanation,
    'rule': rule,
    'example': example,
    'next_step': nextStep,
  };
}

/// What Mia suggests practising next; the app maps it to a real activity.
@immutable
class WritingNextActivity {
  const WritingNextActivity({required this.skill, this.focus = ''});

  factory WritingNextActivity.fromJson(Map<String, dynamic> json) =>
      WritingNextActivity(
        skill: _string(json['skill'], fallback: 'writing'),
        focus: _string(json['focus']),
      );

  /// grammar, vocabulary, writing or reading.
  final String skill;
  final String focus;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'skill': skill,
    'focus': focus,
  };
}

String _string(Object? value, {String fallback = ''}) {
  final String text = value is String ? value.trim() : '';
  return text.isEmpty ? fallback : text;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((Object? e) => e is String ? e.trim() : '')
      .where((String e) => e.isNotEmpty)
      .toList(growable: false);
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return List<T>.empty();
  return raw
      .whereType<Map>()
      .map((Map item) => parse(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

/// Unofficial estimate in an exam's own scale (IELTS band, TOEFL task score).
@immutable
class ExamEstimate {
  const ExamEstimate({
    required this.exam,
    required this.label,
    required this.value,
    required this.scaleMax,
    required this.note,
  });

  static ExamEstimate? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final Object? value = raw['value'];
    final Object? scale = raw['scale_max'];
    final String exam = _string(raw['exam']);
    if (value is! num || scale is! num || exam.isEmpty) return null;
    return ExamEstimate(
      exam: exam,
      label: _string(raw['label'], fallback: 'Estimated score'),
      value: value.toDouble().clamp(0, scale.toDouble()),
      scaleMax: scale.toInt(),
      note: _string(raw['note']),
    );
  }

  final String exam;
  final String label;
  final double value;
  final int scaleMax;
  final String note;

  /// "6.5" or "7".
  String get display => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'exam': exam,
    'label': label,
    'value': value,
    'scale_max': scaleMax,
    'note': note,
  };
}
