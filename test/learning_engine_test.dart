import 'package:eloqia_ai/models/learning_profile.dart';
import 'package:eloqia_ai/models/learning_session.dart';
import 'package:eloqia_ai/services/learning/learning_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prioritizes a declared writing difficulty and preserves declared level',
    () {
      final LearningProfile profile = LearningProfile(
        currentLevel: 'B1',
        difficulties: <String>['Writing longer answers'],
      );

      final LearningRecommendation recommendation = LearningEngine.recommend(
        profile: profile,
        sessions: const <LearningSession>[],
      );

      expect(recommendation.activity, LearningActivityType.writing);
      expect(recommendation.targetLevel, 'B1');
      expect(recommendation.reason, contains('declared learning challenges'));
    },
  );

  test('uses the stated goal after a writing session is recorded', () {
    final LearningProfile profile = LearningProfile(
      primaryGoal: 'Speak confidently at work',
      currentLevel: 'A2',
    );
    final LearningSession completed = LearningSession(
      id: 'session-1',
      activityType: LearningActivityType.writing,
      status: LearningSessionStatus.completed,
      createdAt: DateTime.utc(2026),
      completedAt: DateTime.utc(2026),
      completed: true,
    );

    final LearningRecommendation recommendation = LearningEngine.recommend(
      profile: profile,
      sessions: <LearningSession>[completed],
    );

    expect(recommendation.reason, contains(profile.primaryGoal));
    expect(recommendation.minutes, 5);
  });
}
