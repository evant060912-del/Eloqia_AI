/// Immutable domain model representing the learner's complete progression.
///
/// This model is intentionally independent from Flutter and persistence.
///
/// Architecture:
///
///     Progress
///        ↓
///     ProgressStorage
///        ↓
///     LocalStorage
///
/// The model represents the learner's progression state, while the storage
/// layer is responsible for persisting that state.
///
/// This separation keeps Eloqia ready for future evolution such as:
///
/// • adaptive progression
/// • cloud synchronization
/// • analytics
/// • achievements
/// • personalized learning paths
/// • FastAPI integration
/// • PostgreSQL persistence
class Progress {
  const Progress({
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivity,
    this.skills = const <String, double>{},
    this.dailyGoal = const DailyGoal(),
    this.statistics = const ProgressStatistics(),
  });

  // ===========================================================================
  // CORE PROGRESSION
  // ===========================================================================

  /// Total XP earned by the learner.
  final int xp;

  /// Current Eloqia progression level.
  final int level;

  /// Number of consecutive learning days.
  final int currentStreak;

  /// Longest consecutive learning streak ever achieved.
  final int longestStreak;

  /// Timestamp of the learner's latest learning activity.
  final DateTime? lastActivity;

  // ===========================================================================
  // SKILLS
  // ===========================================================================

  /// Skill mastery values expressed from 0.0 to 100.0.
  ///
  /// Supported default skills:
  ///
  /// • speaking
  /// • listening
  /// • reading
  /// • writing
  /// • grammar
  /// • vocabulary
  final Map<String, double> skills;

  // ===========================================================================
  // DAILY GOAL
  // ===========================================================================

  /// Current daily learning target and completion.
  final DailyGoal dailyGoal;

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Long-term learning statistics.
  final ProgressStatistics statistics;

  // ===========================================================================
  // DERIVED VALUES
  // ===========================================================================

  /// XP required for the next level.
  ///
  /// This formula deliberately lives in the domain model rather than the UI.
  int get xpForNextLevel {
    return level * 100;
  }

  /// XP accumulated toward the next level.
  int get xpIntoCurrentLevel {
    final int previousLevelXp = (level - 1) * 100;

    final int value = xp - previousLevelXp;

    return value < 0 ? 0 : value;
  }

  /// Progress toward the next level from 0.0 to 1.0.
  double get levelProgress {
    final int required = xpForNextLevel;

    if (required <= 0) {
      return 0.0;
    }

    final double progress =
        xpIntoCurrentLevel / required;

    return progress.clamp(0.0, 1.0);
  }

  /// Average mastery across all tracked skills.
  double get overallSkillMastery {
    if (skills.isEmpty) {
      return 0.0;
    }

    final double total = skills.values.fold(
      0.0,
      (double sum, double value) => sum + value,
    );

    return (total / skills.length).clamp(
      0.0,
      100.0,
    );
  }

  /// Whether today's learning goal has been completed.
  bool get dailyGoalCompleted {
    return dailyGoal.isCompleted;
  }

  /// Daily goal progress from 0.0 to 1.0.
  double get dailyGoalProgress {
    return dailyGoal.progress;
  }

  // ===========================================================================
  // SKILL ACCESS
  // ===========================================================================

  double skill(String name) {
    return skills[name] ?? 0.0;
  }

  double get speaking {
    return skill('speaking');
  }

  double get listening {
    return skill('listening');
  }

  double get reading {
    return skill('reading');
  }

  double get writing {
    return skill('writing');
  }

  double get grammar {
    return skill('grammar');
  }

  double get vocabulary {
    return skill('vocabulary');
  }

  // ===========================================================================
  // IMMUTABLE UPDATES
  // ===========================================================================

  /// Creates a new progression object with selected values replaced.
  Progress copyWith({
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivity,
    Map<String, double>? skills,
    DailyGoal? dailyGoal,
    ProgressStatistics? statistics,
  }) {
    return Progress(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak:
          currentStreak ?? this.currentStreak,
      longestStreak:
          longestStreak ?? this.longestStreak,
      lastActivity:
          lastActivity ?? this.lastActivity,
      skills: skills ?? this.skills,
      dailyGoal:
          dailyGoal ?? this.dailyGoal,
      statistics:
          statistics ?? this.statistics,
    );
  }

  /// Creates a new progression state with additional XP.
  Progress addXp(int amount) {
    if (amount <= 0) {
      return this;
    }

    return copyWith(
      xp: xp + amount,
    );
  }

  /// Creates a new progression state with an updated skill.
  Progress updateSkill(
    String name,
    double value,
  ) {
    final double safeValue =
        value.clamp(0.0, 100.0);

    final Map<String, double> updatedSkills =
        Map<String, double>.from(skills);

    updatedSkills[name] = safeValue;

    return copyWith(
      skills: updatedSkills,
    );
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  /// Converts this model into the structure expected by ProgressStorage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': 1,
      'xp': xp,
      'level': level,
      'streak': <String, dynamic>{
        'current': currentStreak,
        'longest': longestStreak,
        'lastActivity':
            lastActivity?.toUtc().toIso8601String(),
      },
      'skills': Map<String, dynamic>.from(skills),
      'dailyGoal': dailyGoal.toJson(),
      'statistics': statistics.toJson(),
    };
  }

  /// Reconstructs a Progress model from persisted data.
  factory Progress.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic> streak =
        _readMap(json['streak']);

    final Map<String, dynamic> skills =
        _readMap(json['skills']);

    final Map<String, dynamic> dailyGoal =
        _readMap(json['dailyGoal']);

    final Map<String, dynamic> statistics =
        _readMap(json['statistics']);

    return Progress(
      xp: _readNonNegativeInt(json['xp']),
      level: _readMinimumInt(
        json['level'],
        1,
      ),
      currentStreak:
          _readNonNegativeInt(
        streak['current'],
      ),
      longestStreak:
          _readNonNegativeInt(
        streak['longest'],
      ),
      lastActivity:
          _readDateTime(
        streak['lastActivity'],
      ),
      skills: _readSkills(skills),
      dailyGoal:
          DailyGoal.fromJson(dailyGoal),
      statistics:
          ProgressStatistics.fromJson(
        statistics,
      ),
    );
  }

  // ===========================================================================
  // OBJECT CONTRACT
  // ===========================================================================

  @override
  String toString() {
    return 'Progress('
        'xp: $xp, '
        'level: $level, '
        'currentStreak: $currentStreak, '
        'longestStreak: $longestStreak, '
        'overallSkillMastery: '
        '${overallSkillMastery.toStringAsFixed(1)}'
        ')';
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

  static int _readNonNegativeInt(
    dynamic value,
  ) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final int converted = value.toInt();

      return converted < 0 ? 0 : converted;
    }

    return 0;
  }

  static int _readMinimumInt(
    dynamic value,
    int minimum,
  ) {
    final int result =
        _readNonNegativeInt(value);

    return result < minimum
        ? minimum
        : result;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static Map<String, double> _readSkills(
    Map<String, dynamic> source,
  ) {
    final Map<String, double> result =
        <String, double>{};

    for (final MapEntry<String, dynamic> entry
        in source.entries) {
      final dynamic value = entry.value;

      if (value is num) {
        result[entry.key] =
            value.toDouble().clamp(
              0.0,
              100.0,
            );
      }
    }

    return result;
  }
}

// =============================================================================
// DAILY GOAL
// =============================================================================

/// Represents the learner's daily learning target.
///
/// The unit is intentionally abstract at this layer. The application can
/// interpret it as minutes, XP, exercises or another future metric.
class DailyGoal {
  const DailyGoal({
    this.target = 20,
    this.completed = 0,
  });

  final int target;

  final int completed;

  bool get isCompleted {
    return target > 0 &&
        completed >= target;
  }

  double get progress {
    if (target <= 0) {
      return 0.0;
    }

    return (completed / target).clamp(
      0.0,
      1.0,
    );
  }

  int get remaining {
    final int value =
        target - completed;

    return value < 0 ? 0 : value;
  }

  DailyGoal copyWith({
    int? target,
    int? completed,
  }) {
    return DailyGoal(
      target: target ?? this.target,
      completed:
          completed ?? this.completed,
    );
  }

  DailyGoal addCompleted(int amount) {
    if (amount <= 0) {
      return this;
    }

    return copyWith(
      completed: completed + amount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'target': target < 0 ? 0 : target,
      'completed':
          completed < 0 ? 0 : completed,
    };
  }

  factory DailyGoal.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyGoal(
      target: _readNonNegativeInt(
        json['target'],
        20,
      ),
      completed: _readNonNegativeInt(
        json['completed'],
        0,
      ),
    );
  }

  static int _readNonNegativeInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final int converted = value.toInt();

      return converted < 0 ? 0 : converted;
    }

    return fallback;
  }
}

// =============================================================================
// PROGRESS STATISTICS
// =============================================================================

/// Long-term statistics describing the learner's activity.
class ProgressStatistics {
  const ProgressStatistics({
    this.totalSessions = 0,
    this.learningMinutes = 0,
    this.completedLessons = 0,
  });

  final int totalSessions;

  final int learningMinutes;

  final int completedLessons;

  ProgressStatistics copyWith({
    int? totalSessions,
    int? learningMinutes,
    int? completedLessons,
  }) {
    return ProgressStatistics(
      totalSessions:
          totalSessions ?? this.totalSessions,
      learningMinutes:
          learningMinutes ?? this.learningMinutes,
      completedLessons:
          completedLessons ?? this.completedLessons,
    );
  }

  ProgressStatistics addSession({
    int minutes = 0,
    int lessons = 0,
  }) {
    return ProgressStatistics(
      totalSessions:
          totalSessions + 1,
      learningMinutes:
          learningMinutes +
              (minutes < 0 ? 0 : minutes),
      completedLessons:
          completedLessons +
              (lessons < 0 ? 0 : lessons),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessions':
          totalSessions < 0 ? 0 : totalSessions,
      'learningMinutes':
          learningMinutes < 0
              ? 0
              : learningMinutes,
      'completedLessons':
          completedLessons < 0
              ? 0
              : completedLessons,
    };
  }

  factory ProgressStatistics.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProgressStatistics(
      totalSessions:
          _readNonNegativeInt(
        json['sessions'],
      ),
      learningMinutes:
          _readNonNegativeInt(
        json['learningMinutes'],
      ),
      completedLessons:
          _readNonNegativeInt(
        json['completedLessons'],
      ),
    );
  }

  static int _readNonNegativeInt(
    dynamic value,
  ) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final int converted =
          value.toInt();

      return converted < 0
          ? 0
          : converted;
    }

    return 0;
  }
}