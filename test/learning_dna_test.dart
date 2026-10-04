import 'package:eloqia_ai/features/onboarding/assessment/level_assessment_service.dart';
import 'package:eloqia_ai/services/learning/learning_dna_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Learning DNA keeps assessment separate from the declared profile',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LevelAssessmentService.saveSkipped(selfReportedLevel: 'C1');

      final LearningDNA dna = await LearningDNAService.load();

      expect(dna.profile.currentLevel, isEmpty);
      expect(dna.assessment?.selfReportedLevel, 'C1');
      expect(dna.assessment?.skipped, isTrue);
      expect(dna.completedSessions, 0);
      expect(dna.activeMemories, 0);
      expect(dna.skillSessionCounts, isEmpty);
    },
  );
}
