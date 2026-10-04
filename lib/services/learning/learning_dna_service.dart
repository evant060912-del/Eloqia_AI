import '../../features/onboarding/assessment/level_assessment_result.dart';
import '../../features/onboarding/assessment/level_assessment_service.dart';
import '../../models/learning_memory.dart';
import '../../models/learning_profile.dart';
import '../../models/learning_session.dart';
import '../../models/progress.dart';
import 'learning_memory_service.dart';
import 'learning_progress_service.dart';
import 'learning_profile_service.dart';
import 'learning_session_service.dart';

class LearningDNA {
  const LearningDNA({
    required this.profile,
    required this.assessment,
    required this.completedSessions,
    required this.activeMemories,
    required this.minutesLearned,
    required this.skillSessionCounts,
    required this.latestSessionAt,
  });

  final LearningProfile profile;
  final LevelAssessmentResult? assessment;
  final int completedSessions;
  final int activeMemories;
  final int minutesLearned;
  final Map<LearningSkill, int> skillSessionCounts;
  final DateTime? latestSessionAt;

  String? get strongestPracticeSkill {
    if (skillSessionCounts.isEmpty) {
      return null;
    }
    final List<MapEntry<LearningSkill, int>> entries =
        skillSessionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key.name;
  }
}

/// Builds a local learner snapshot from declared profile and recorded data.
/// It does not infer language ability or send data to a provider.
class LearningDNAService {
  LearningDNAService._();

  static Future<LearningDNA> load() async {
    final List<Object?> loaded = await Future.wait<Object?>(<Future<Object?>>[
      LearningProfileService.getProfile(),
      LevelAssessmentService.load(),
      LearningSessionService.getHistory(),
      MemoryService.getActiveMemories(),
      LearningProgressService.getProgress(),
    ]);
    final LearningProfile profile = loaded[0]! as LearningProfile;
    final LevelAssessmentResult? assessment =
        loaded[1] as LevelAssessmentResult?;
    final List<LearningSession> sessions = loaded[2]! as List<LearningSession>;
    final List<LearningMemory> memories = loaded[3]! as List<LearningMemory>;
    final Progress progress = loaded[4]! as Progress;
    final List<LearningSession> completed = sessions
        .where((LearningSession session) => session.completed)
        .toList();
    final Map<LearningSkill, int> skillCounts = <LearningSkill, int>{};

    for (final LearningSession session in completed) {
      for (final LearningSkill skill in session.skills) {
        skillCounts.update(skill, (int count) => count + 1, ifAbsent: () => 1);
      }
    }

    DateTime? latest;
    for (final LearningSession session in completed) {
      final DateTime? at = session.completedAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
      }
    }

    return LearningDNA(
      profile: profile,
      assessment: assessment,
      completedSessions: completed.length,
      activeMemories: memories.length,
      minutesLearned: progress.statistics.learningMinutes,
      skillSessionCounts: Map<LearningSkill, int>.unmodifiable(skillCounts),
      latestSessionAt: latest,
    );
  }
}
