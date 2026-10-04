import '../models/lesson_models.dart';

LessonActivity introActivity(
  String title,
  List<String> text,
  List<String> examples,
) => LessonActivity(
  kind: ActivityKind.intro,
  title: title,
  explanation: text,
  examples: examples,
);

LessonActivity practiceActivity(List<Exercise> exercises) => LessonActivity(
  kind: ActivityKind.practice,
  title: 'Practice',
  exercises: exercises,
);

LessonActivity challengeActivity(List<Exercise> exercises) => LessonActivity(
  kind: ActivityKind.challenge,
  title: 'Challenge',
  exercises: exercises,
);
