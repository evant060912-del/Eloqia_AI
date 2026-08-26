import '../../../core/storage/progress_storage.dart';
import '../../../core/storage/session_storage.dart';

/// Immutable snapshot of the data displayed by the Home dashboard.
///
/// The Home UI should consume this object instead of reading persistence
/// services directly. This keeps storage concerns outside the presentation
/// layer and makes the dashboard easier to evolve.
class HomeDashboardData {
  const HomeDashboardData({
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.skills,
    required this.dailyGoal,
    required this.dailyGoalProgress,
    required this.totalSessions,
    required this.learningMinutes,
    required this.completedLessons,
    required this.recentSessions,
  });

  final int xp;

  final int level;

  final int currentStreak;

  final Map<String, double> skills;

  final int dailyGoal;

  final int dailyGoalProgress;

  final int totalSessions;

  final int learningMinutes;

  final int completedLessons;

  final List<Map<String, dynamic>> recentSessions;

  /// Creates a dashboard snapshot from persistent Eloqia data.
  static Future<HomeDashboardData> load() async {
    final Map<String, dynamic> progress =
        await ProgressStorage.load();

    final Map<String, double> skills =
        await ProgressStorage.getSkills();

    final int totalSessions =
        await ProgressStorage.getTotalSessions();

    final int learningMinutes =
        await ProgressStorage.getLearningMinutes();

    final int completedLessons =
        await ProgressStorage.getCompletedLessons();

    final List<Map<String, dynamic>> recentSessions =
        await SessionStorage.recent(
      limit: 5,
    );

    return HomeDashboardData(
      xp: _readInt(
        progress['xp'],
        0,
      ),
      level: _readInt(
        progress['level'],
        1,
      ),
      currentStreak:
          await ProgressStorage.getCurrentStreak(),
      skills: Map<String, double>.unmodifiable(
        skills,
      ),
      dailyGoal:
          await ProgressStorage.getDailyGoal(),
      dailyGoalProgress:
          await ProgressStorage.getDailyGoalProgress(),
      totalSessions: totalSessions,
      learningMinutes: learningMinutes,
      completedLessons: completedLessons,
      recentSessions: List<Map<String, dynamic>>.unmodifiable(
        recentSessions.map(
          (Map<String, dynamic> session) =>
              Map<String, dynamic>.unmodifiable(
            session,
          ),
        ),
      ),
    );
  }

  double get speaking {
    return skills['speaking'] ?? 0.0;
  }

  double get listening {
    return skills['listening'] ?? 0.0;
  }

  double get reading {
    return skills['reading'] ?? 0.0;
  }

  double get writing {
    return skills['writing'] ?? 0.0;
  }

  double get grammar {
    return skills['grammar'] ?? 0.0;
  }

  double get vocabulary {
    return skills['vocabulary'] ?? 0.0;
  }

  double get dailyGoalProgressRatio {
    if (dailyGoal <= 0) {
      return 0.0;
    }

    final double ratio =
        dailyGoalProgress / dailyGoal;

    if (ratio < 0.0) {
      return 0.0;
    }

    if (ratio > 1.0) {
      return 1.0;
    }

    return ratio;
  }

  bool get dailyGoalCompleted {
    return dailyGoalProgress >= dailyGoal;
  }

  static int _readInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }
}