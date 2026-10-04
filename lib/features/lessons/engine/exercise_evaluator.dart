import '../models/lesson_models.dart';

class ExerciseEvaluation {
  const ExerciseEvaluation({
    required this.correct,
    required this.response,
    this.wrongPairs = const <String>[],
  });

  final bool correct;
  final String response;

  /// Left-hand items answered incorrectly in a matching exercise.
  final List<String> wrongPairs;
}

class ExerciseEvaluator {
  ExerciseEvaluator._();

  static String normalize(String value) {
    String text = value
        .replaceAll('\u2019', '\'')
        .replaceAll('\u2018', '\'')
        .toLowerCase()
        .trim();
    text = text.replaceAll(RegExp(r'[.!?]+$'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Map<String, String> parsePairs(String canonical) {
    final Map<String, String> pairs = <String, String>{};
    for (final String part in canonical.split(';')) {
      final int index = part.indexOf('=');
      if (index > 0) {
        pairs[part.substring(0, index)] = part.substring(index + 1);
      }
    }
    return pairs;
  }

  static ExerciseEvaluation evaluate(Exercise exercise, String response) {
    if (exercise.type == ExerciseType.matching) {
      final Map<String, String> given = parsePairs(response);
      final List<String> wrong = <String>[
        for (final MapEntry<String, String> entry in exercise.pairs.entries)
          if (given[entry.key] != entry.value) entry.key,
      ];
      return ExerciseEvaluation(
        correct: wrong.isEmpty && given.length == exercise.pairs.length,
        response: response,
        wrongPairs: wrong,
      );
    }

    final String normalized = normalize(response);
    final bool correct =
        normalized.isNotEmpty &&
        exercise.answers.any((String a) => normalize(a) == normalized);
    return ExerciseEvaluation(correct: correct, response: response);
  }
}
