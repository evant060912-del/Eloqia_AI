import 'package:flutter/material.dart';

import '../../models/learning_memory.dart';
import '../../models/learning_profile.dart';
import '../../models/learning_session.dart';
import '../../models/progress.dart';
import '../../services/learning/learning_memory_service.dart';
import '../../services/learning/learning_profile_service.dart';
import '../../services/learning/learning_progress_service.dart';
import '../../services/learning/learning_session_service.dart';
import '../onboarding/assessment/level_assessment_result.dart';
import '../onboarding/assessment/level_assessment_service.dart';
import 'engine/lesson_engine.dart';
import 'models/lesson_models.dart';
import 'ui/lesson_runner_screen.dart';

/// Everything the lesson engine needs, loaded from the existing services.
class LessonContext {
  const LessonContext({
    required this.profile,
    required this.assessment,
    required this.sessions,
    required this.memories,
    required this.progress,
  });

  final LearningProfile profile;
  final LevelAssessmentResult? assessment;
  final List<LearningSession> sessions;
  final List<LearningMemory> memories;
  final Progress progress;

  static Future<LessonContext> load() async {
    final List<Object?> loaded = await Future.wait<Object?>(<Future<Object?>>[
      LearningProfileService.getProfile(),
      LevelAssessmentService.load(),
      LearningSessionService.getHistory(),
      MemoryService.getActiveMemories(),
      LearningProgressService.getProgress(),
    ]);
    return LessonContext(
      profile: loaded[0]! as LearningProfile,
      assessment: loaded[1] as LevelAssessmentResult?,
      sessions: loaded[2]! as List<LearningSession>,
      memories: loaded[3]! as List<LearningMemory>,
      progress: loaded[4]! as Progress,
    );
  }

  LessonChoice select(LessonSkill skill) => LessonEngine.select(
    skill: skill,
    profile: profile,
    assessment: assessment,
    sessions: sessions,
    memories: memories,
  );

  LessonChoice recommend() => LessonEngine.recommend(
    profile: profile,
    assessment: assessment,
    sessions: sessions,
    memories: memories,
    progress: progress,
  );
}

class LessonLauncher {
  LessonLauncher._();

  static Future<void> openSkill(BuildContext context, LessonSkill skill) async {
    final NavigatorState navigator = Navigator.of(context);
    final LessonContext data = await LessonContext.load();
    await navigator.push<void>(_route(data.select(skill), data));
  }

  static Future<void> openRecommended(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LessonContext data = await LessonContext.load();
    await navigator.push<void>(_route(data.recommend(), data));
  }

  static Future<void> openLesson(
    BuildContext context,
    LessonChoice choice,
    LessonContext data,
  ) => Navigator.of(context).push<void>(_route(choice, data));

  static MaterialPageRoute<void> _route(LessonChoice choice, LessonContext data) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => _screen(choice, data),
    );
  }

  static Widget _screen(LessonChoice choice, LessonContext data) {
    return LessonRunnerScreen(
      lesson: choice.lesson,
      profile: data.profile,
      reason: choice.reason,
      buildNext: _nextScreen,
    );
  }

  static Future<Widget> _nextScreen() async {
    final LessonContext fresh = await LessonContext.load();
    return _screen(fresh.recommend(), fresh);
  }
}
