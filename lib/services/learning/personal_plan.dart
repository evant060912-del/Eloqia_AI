/// A learning plan built from the onboarding answers: the areas to focus
/// on (with the learner's own reason), the daily minutes that match the pace
/// they chose, and the lesson tags that match their interests. Pure Dart, so
/// the Home screen, the lesson engine and the tests share the same rules.
library;

import '../../models/learning_profile.dart';

enum PlanArea {
  speaking('Speaking', 'Conversation'),
  grammar('Grammar', 'Grammar'),
  vocabulary('Vocabulary', 'Vocabulary'),
  reading('Reading', 'Reading'),
  listening('Listening', 'Listening'),
  writing('Writing', 'Writing');

  const PlanArea(this.label, this.activity);

  final String label;

  /// Title of the matching activity in Home and Learn.
  final String activity;
}

class PlanFocus {
  const PlanFocus(this.area, this.reason);

  final PlanArea area;

  /// Why, in the learner's terms ("you said grammar is hard").
  final String reason;
}

class PersonalPlan {
  const PersonalPlan({
    required this.focus,
    required this.dailyMinutes,
    required this.paceLabel,
    required this.lessonTags,
    required this.examPrep,
  });

  /// Up to three areas, most important first.
  final List<PlanFocus> focus;

  /// Daily goal that matches the chosen pace.
  final int dailyMinutes;
  final String paceLabel;

  /// Lesson tags matching goals and interests (see `Lesson.tags`).
  final Set<String> lessonTags;

  /// True when the goals point to school or university English: the TOEFL
  /// and IELTS practice in the Writing Studio is worth suggesting.
  final bool examPrep;

  bool get isEmpty => focus.isEmpty;

  static const Map<String, int> paceMinutes = <String, int>{
    'relaxed': 10,
    'regular': 20,
    'intensive': 30,
    'adaptive': 15,
  };

  static const Map<String, String> _areaWords = <String, String>{
    'speaking': 'speaking',
    'confidence': 'confidence when speaking',
    'speed': 'speaking without hesitating',
    'naturalness': 'sounding natural',
    'conversation': 'conversation',
    'pronunciation': 'pronunciation',
    'pronunciation_detail': 'pronunciation',
    'fluency': 'fluency',
    'grammar': 'grammar',
    'advanced_grammar': 'advanced grammar',
    'vocabulary': 'vocabulary',
    'listening': 'listening',
    'reading': 'reading',
    'writing': 'writing',
    'academic_writing': 'academic writing',
  };

  static PlanArea? _areaOf(String value) => switch (value) {
    'speaking' ||
    'confidence' ||
    'speed' ||
    'naturalness' ||
    'conversation' ||
    'pronunciation' ||
    'pronunciation_detail' ||
    'fluency' => PlanArea.speaking,
    'grammar' || 'advanced_grammar' => PlanArea.grammar,
    'vocabulary' => PlanArea.vocabulary,
    'listening' => PlanArea.listening,
    'reading' => PlanArea.reading,
    'writing' || 'academic_writing' => PlanArea.writing,
    _ => null,
  };

  /// Areas served by each main goal, with the words shown to the learner.
  static const Map<String, (List<PlanArea>, String)> _goalAreas =
      <String, (List<PlanArea>, String)>{
        'speaking': (<PlanArea>[PlanArea.speaking], 'speak with confidence'),
        'fluency': (
          <PlanArea>[PlanArea.speaking, PlanArea.vocabulary],
          'become fluent',
        ),
        'travel': (
          <PlanArea>[PlanArea.speaking, PlanArea.listening],
          'travel confidently',
        ),
        'school': (
          <PlanArea>[PlanArea.writing, PlanArea.grammar],
          'excel at school',
        ),
        'academic': (
          <PlanArea>[PlanArea.writing, PlanArea.reading],
          'master academic English',
        ),
        'career': (
          <PlanArea>[PlanArea.writing, PlanArea.speaking],
          'prepare for your career',
        ),
        'culture': (
          <PlanArea>[PlanArea.listening, PlanArea.reading],
          'understand English culture',
        ),
      };

  /// Interests and goals → lesson tags.
  static const Map<String, List<String>> _tagsOf = <String, List<String>>{
    'technology': <String>['technology'],
    'gaming': <String>['technology'],
    'science': <String>['academic', 'technology'],
    'space': <String>['academic'],
    'psychology': <String>['academic'],
    'history': <String>['academic', 'culture'],
    'music': <String>['culture'],
    'movies': <String>['culture'],
    'art': <String>['culture'],
    'travel': <String>['travel'],
    'sports': <String>['speaking'],
    'business': <String>['career'],
    'career': <String>['career'],
    'work': <String>['career'],
    'future': <String>['career'],
    'school': <String>['academic'],
    'academic': <String>['academic'],
    'culture': <String>['culture'],
    'speaking': <String>['speaking'],
    'fluency': <String>['fluency', 'speaking'],
  };

  static PersonalPlan from(LearningProfile profile) {
    final Map<PlanArea, int> score = <PlanArea, int>{};
    final Map<PlanArea, String> reason = <PlanArea, String>{};

    void add(String value, int points, String Function(String words) why) {
      final PlanArea? area = _areaOf(value);
      if (area == null) return;
      score[area] = (score[area] ?? 0) + points;
      if (points > 0) {
        reason.putIfAbsent(area, () => why(_areaWords[value] ?? value));
      }
    }

    for (final String d in profile.difficulties) {
      add(d, 3, (String w) => 'You said $w is hard for you.');
    }
    final String goal = profile.primaryGoal.trim();
    final (List<PlanArea>, String)? main = _goalAreas[goal];
    if (main != null) {
      for (final PlanArea area in main.$1) {
        score[area] = (score[area] ?? 0) + 2;
        reason.putIfAbsent(area, () => 'Your main goal: ${main.$2}.');
      }
    }
    for (final String g in profile.secondaryGoals) {
      add(g, 2, (String w) => 'You want to improve your $w.');
    }
    for (final String s in profile.strengths) {
      add(s, -2, (_) => '');
    }

    final List<PlanArea> ranked =
        PlanArea.values
            .where((PlanArea a) => (score[a] ?? 0) > 0 && reason[a] != null)
            .toList()
          ..sort((PlanArea a, PlanArea b) {
            final int byScore = score[b]!.compareTo(score[a]!);
            return byScore != 0 ? byScore : a.index.compareTo(b.index);
          });

    final String pace = profile.learningPace.trim();
    final Set<String> tags = <String>{
      for (final String value in <String>[
        goal,
        profile.motivation.trim(),
        ...profile.interests,
        ...profile.speakingSituations,
      ])
        ...?_tagsOf[value],
    };

    return PersonalPlan(
      focus: <PlanFocus>[
        for (final PlanArea area in ranked.take(3))
          PlanFocus(area, reason[area]!),
      ],
      dailyMinutes: paceMinutes[pace] ?? 15,
      paceLabel: pace.isEmpty ? 'not chosen yet' : pace,
      lessonTags: tags,
      examPrep:
          goal == 'school' ||
          goal == 'academic' ||
          profile.secondaryGoals.contains('academic_writing') ||
          profile.motivation.trim() == 'school',
    );
  }

  /// Bonus for lesson recommendations: 2 for the first focus, 1 for the
  /// next ones, 0 otherwise.
  int bonusFor(PlanArea area) {
    for (int i = 0; i < focus.length; i++) {
      if (focus[i].area == area) return i == 0 ? 2 : 1;
    }
    return 0;
  }
}
