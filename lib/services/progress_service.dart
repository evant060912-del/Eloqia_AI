import '../core/storage/progress_storage.dart';

/// Immutable snapshot of Eloqia's complete learning progression.
///
/// This object provides the application with one consistent representation
/// of the learner's progression without exposing storage implementation
/// details to the UI.
class ProgressSnapshot {
  const ProgressSnapshot({
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.skills,
    required this.dailyGoal,
    required this.dailyGoalProgress,
    required this.totalSessions,
    required this.learningMinutes,
    required this.completedLessons,
  });

  final int xp;
  final int level;

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  final Map<String, double> skills;

  final int dailyGoal;
  final int dailyGoalProgress;

  final int totalSessions;
  final int learningMinutes;
  final int completedLessons;

  /// Returns the daily goal completion ratio.
  double get dailyGoalRatio {
    if (dailyGoal <= 0) {
      return 0.0;
    }

    final double ratio =
        dailyGoalProgress / dailyGoal;

    return ratio.clamp(0.0, 1.0);
  }

  /// Returns whether today's goal has been completed.
  bool get isDailyGoalComplete =>
      dailyGoalProgress >= dailyGoal;

  /// Returns the remaining amount required to complete today's goal.
  int get remainingDailyGoal {
    final int remaining =
        dailyGoal - dailyGoalProgress;

    return remaining < 0 ? 0 : remaining;
  }

  /// Returns the learner's average skill level.
  double get averageSkill {
    if (skills.isEmpty) {
      return 0.0;
    }

    final double total =
        skills.values.fold(
      0.0,
      (double sum, double value) => sum + value,
    );

    return total / skills.length;
  }

  /// Returns a compact immutable map representation.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate':
          lastActivityDate?.toUtc().toIso8601String(),
      'skills': Map<String, double>.from(skills),
      'dailyGoal': dailyGoal,
      'dailyGoalProgress': dailyGoalProgress,
      'totalSessions': totalSessions,
      'learningMinutes': learningMinutes,
      'completedLessons': completedLessons,
    };
  }
}

/// High-level progression service.
///
/// This is the application-facing gateway for learner progression.
///
/// Architecture:
///
///     UI / Home / Learning Engine
///                 ↓
///         ProgressService
///                 ↓
///         ProgressStorage
///                 ↓
///          LocalStorage
///
/// The service intentionally keeps progression business access separate
/// from persistence implementation details.
class ProgressService {
  ProgressService._();

  // ===========================================================================
  // SNAPSHOT
  // ===========================================================================

  /// Loads the complete progression in one operation.
  ///
  /// The returned snapshot is the preferred way for screens and application
  /// services to consume progression data.
  static Future<ProgressSnapshot> getSnapshot() async {
    final Map<String, dynamic> snapshot =
        await ProgressStorage.getSnapshot();

    final Map<String, dynamic> streak =
        _readMap(snapshot['streak']);

    final Map<String, dynamic> skills =
        _readMap(snapshot['skills']);

    final Map<String, dynamic> dailyGoal =
        _readMap(snapshot['dailyGoal']);

    final Map<String, dynamic> statistics =
        _readMap(snapshot['statistics']);

    return ProgressSnapshot(
      xp: _readInt(snapshot['xp']),
      level: _readInt(snapshot['level'], 1),
      currentStreak:
          _readInt(streak['current']),
      longestStreak:
          _readInt(streak['longest']),
      lastActivityDate:
          _readDateTime(streak['lastActivity']),
      skills: _readSkills(skills),
      dailyGoal:
          _readInt(dailyGoal['target'], 20),
      dailyGoalProgress:
          _readInt(dailyGoal['completed']),
      totalSessions:
          _readInt(statistics['sessions']),
      learningMinutes:
          _readInt(statistics['learningMinutes']),
      completedLessons:
          _readInt(statistics['completedLessons']),
    );
  }

  // ===========================================================================
  // XP
  // ===========================================================================

  static Future<bool> setXp(int xp) {
    return ProgressStorage.setXp(xp);
  }

  static Future<bool> addXp(int amount) {
    return ProgressStorage.addXp(amount);
  }

  // ===========================================================================
  // LEVEL
  // ===========================================================================

  static Future<bool> setLevel(int level) {
    return ProgressStorage.setLevel(level);
  }

  // ===========================================================================
  // STREAK
  // ===========================================================================

  static Future<bool> setStreak({
    required int current,
    required int longest,
    DateTime? lastActivity,
  }) {
    return ProgressStorage.setStreak(
      current: current,
      longest: longest,
      lastActivity: lastActivity,
    );
  }

  // ===========================================================================
  // SKILLS
  // ===========================================================================

  static Future<bool> setSkill(
    String skill,
    double value,
  ) {
    return ProgressStorage.setSkill(
      skill,
      value,
    );
  }

  static Future<bool> setSkills(
    Map<String, double> values,
  ) {
    return ProgressStorage.setSkills(values);
  }

  // ===========================================================================
  // DAILY GOAL
  // ===========================================================================

  static Future<bool> setDailyGoal(
    int target,
  ) {
    return ProgressStorage.setDailyGoal(target);
  }

  static Future<bool> setDailyGoalProgress(
    int completed,
  ) {
    return ProgressStorage.setDailyGoalProgress(
      completed,
    );
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  static Future<bool> setStatistics({
    required int sessions,
    required int learningMinutes,
    required int completedLessons,
  }) {
    return ProgressStorage.setStatistics(
      sessions: sessions,
      learningMinutes: learningMinutes,
      completedLessons: completedLessons,
    );
  }

  // ===========================================================================
  // STATE
  // ===========================================================================

  static Future<bool> exists() {
    return ProgressStorage.exists();
  }

  static Future<bool> clear() {
    return ProgressStorage.clear();
  }

  // ===========================================================================
  // SAFE READERS
  // ===========================================================================

  static Map<String, dynamic> _readMap(
    dynamic value,
  ) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(value);
  }

  static int _readInt(
    dynamic value, [
    int fallback = 0,
  ]) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static Map<String, double> _readSkills(
    Map<String, dynamic> source,
  ) {
    return <String, double>{
      'speaking': _readDouble(
        source['speaking'],
      ),
      'listening': _readDouble(
        source['listening'],
      ),
      'reading': _readDouble(
        source['reading'],
      ),
      'writing': _readDouble(
        source['writing'],
      ),
      'grammar': _readDouble(
        source['grammar'],
      ),
      'vocabulary': _readDouble(
        source['vocabulary'],
      ),
    };
  }

  static double _readDouble(
    dynamic value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return 0.0;
  }
}