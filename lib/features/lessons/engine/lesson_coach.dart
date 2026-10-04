import '../../tutors/mia/mia_emotion_engine.dart';
import '../models/lesson_models.dart';
import 'lesson_result_service.dart';
import 'lesson_session.dart';

class CoachLine {
  const CoachLine(this.emotion, this.title, this.message);

  final MiaEmotion emotion;
  final String title;
  final String message;
}

/// Mia's lesson-level lines. Each claim is checked against measured results.
class LessonCoach {
  LessonCoach._();

  static CoachLine intro(Lesson lesson) {
    final String topic = lesson.topic;
    return switch (lesson.skill) {
      LessonSkill.grammar => CoachLine(
        MiaEmotion.curious,
        'Let\'s work on $topic.',
        'I\'ll explain it first, then we\'ll practise together.',
      ),
      LessonSkill.vocabulary => CoachLine(
        MiaEmotion.curious,
        'New words today.',
        'We\'ll see them in context first, then you\'ll use them.',
      ),
      LessonSkill.reading => lesson.difficulty >= 3
          ? const CoachLine(
              MiaEmotion.focused,
              'Okay, this one is a little more challenging.',
              'Read it twice if you need to. The answers are in the text.',
            )
          : const CoachLine(
              MiaEmotion.warm,
              'Take your time with this text.',
              'Every answer can be found in the passage.',
            ),
      LessonSkill.listening => const CoachLine(
        MiaEmotion.listening,
        'I\'ll play a short conversation.',
        'Listen first, then answer. You can replay it as often as you like.',
      ),
    };
  }

  static const CoachLine challenge = CoachLine(
    MiaEmotion.playfulFrustration,
    'Challenge time.',
    'Alright, let\'s see what you\'ve got. These are worth double XP.',
  );

  static CoachLine completion(LessonSummary summary, LessonRecord? record) {
    final List<String> parts = <String>[];
    MiaEmotion emotion;
    String title;

    if (summary.perfect) {
      emotion = MiaEmotion.celebrating;
      title = 'Okay, that was seriously good.';
      parts.add('Every answer was right the first time.');
    } else if (summary.finishedStronger) {
      emotion = MiaEmotion.proud;
      title = 'You finished strong.';
      parts.add('You started a little slowly, but your later answers were much stronger.');
    } else if (summary.accuracy >= 0.8) {
      emotion = MiaEmotion.proud;
      title = 'Solid work.';
      parts.add('You handled ${summary.lesson.topic} well.');
    } else if (summary.missedTopics.isNotEmpty) {
      emotion = MiaEmotion.empathetic;
      title = 'That one was a stretch.';
      parts.add('We\'ll come back to ${summary.missedTopics.keys.first} soon, and it will click.');
    } else {
      emotion = MiaEmotion.warm;
      title = 'Lesson complete.';
    }

    if (summary.maxCombo >= 5) {
      parts.add('A combo of ${summary.maxCombo}? I see you.');
    }
    if (record != null && record.leveledUp) {
      parts.add('New level: you just reached level ${record.newLevel}.');
    }
    return CoachLine(emotion, title, parts.join(' '));
  }
}
