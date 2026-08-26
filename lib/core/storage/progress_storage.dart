import 'local_storage.dart';

/// Persistent progression storage for Eloqia.
///
/// This service manages the learner's progression data independently
/// from the learner profile.
///
/// The progression layer is designed around six complementary domains:
///
/// • XP
/// • Level
/// • Streak
/// • Skills
/// • Daily goal
/// • Statistics
///
/// The service deliberately keeps persistence separate from business logic.
/// This allows the progression engine to evolve without coupling it to
/// Flutter widgets, screens or the LearningProfile model.
///
/// Storage flow:
///
///     Progress data
///          ↓
///     ProgressStorage
///          ↓
///     LocalStorage
///          ↓
///     SharedPreferences
///
/// Future evolution:
///
///     Local storage
///          ↓
///     Cloud synchronization
///          ↓
///     FastAPI
///          ↓
///     PostgreSQL
class ProgressStorage {
  ProgressStorage._();

  // ===========================================================================
  // STORAGE FORMAT
  // ===========================================================================

  /// Current version of the progression persistence format.
  ///
  /// This value belongs to the storage layer and does not represent
  /// the learner's Eloqia level.
  static const int storageVersion = 1;

  // ===========================================================================
  // DEFAULT VALUES
  // ===========================================================================

  static const int defaultXp = 0;

  static const int defaultLevel = 1;

  static const int defaultCurrentStreak = 0;

  static const int defaultLongestStreak = 0;

  static const int defaultDailyGoal = 20;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Loads the complete persisted progression.
  ///
  /// Returns a normalized map so callers always receive predictable
  /// top-level domains, even when no previous progression exists.
  static Future<Map<String, dynamic>> load() async {
    final Map<String, dynamic>? storedData =
        await LocalStorage.readJsonMap(
      LocalStorage.progressKey,
    );

    return _normalize(storedData);
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Saves a complete progression object.
  ///
  /// The supplied data is normalized before being persisted so malformed
  /// or incomplete external maps cannot accidentally become the canonical
  /// local representation.
  static Future<bool> save(
    Map<String, dynamic> progress,
  ) async {
    final Map<String, dynamic> normalized =
        _normalize(progress);

    return LocalStorage.saveJson(
      LocalStorage.progressKey,
      normalized,
    );
  }

  // ===========================================================================
  // EXISTENCE
  // ===========================================================================

  /// Returns whether progression data has already been persisted.
  static Future<bool> exists() async {
    return LocalStorage.containsKey(
      LocalStorage.progressKey,
    );
  }

  // ===========================================================================
  // XP
  // ===========================================================================

  /// Returns the learner's total XP.
  static Future<int> getXp() async {
    final Map<String, dynamic> progress =
        await load();

    return _readInt(
      progress['xp'],
      defaultXp,
    );
  }

  /// Saves the learner's total XP.
  static Future<bool> setXp(
    int xp,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    progress['xp'] = _sanitizeNonNegativeInt(
      xp,
    );

    return save(progress);
  }

  /// Adds XP to the learner's total.
  ///
  /// Negative values are ignored.
  static Future<bool> addXp(
    int amount,
  ) async {
    if (amount <= 0) {
      return true;
    }

    final int currentXp =
        await getXp();

    return setXp(
      currentXp + amount,
    );
  }

  // ===========================================================================
  // LEVEL
  // ===========================================================================

  /// Returns the learner's current level.
  static Future<int> getLevel() async {
    final Map<String, dynamic> progress =
        await load();

    return _readInt(
      progress['level'],
      defaultLevel,
    );
  }

  /// Saves the learner's current level.
  static Future<bool> setLevel(
    int level,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    progress['level'] = _sanitizeMinimumInt(
      level,
      defaultLevel,
    );

    return save(progress);
  }

  // ===========================================================================
  // STREAK
  // ===========================================================================

  /// Returns the current learning streak.
  static Future<int> getCurrentStreak() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> streak =
        _readMap(progress['streak']);

    return _readInt(
      streak['current'],
      defaultCurrentStreak,
    );
  }

  /// Returns the longest learning streak.
  static Future<int> getLongestStreak() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> streak =
        _readMap(progress['streak']);

    return _readInt(
      streak['longest'],
      defaultLongestStreak,
    );
  }

  /// Returns the UTC date of the learner's latest activity.
  static Future<DateTime?> getLastActivityDate() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> streak =
        _readMap(progress['streak']);

    final String? value =
        _readString(streak['lastActivity']);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  /// Saves the complete streak state.
  static Future<bool> setStreak({
    required int current,
    required int longest,
    DateTime? lastActivity,
  }) async {
    final Map<String, dynamic> progress =
        await load();

    final int safeCurrent =
        _sanitizeNonNegativeInt(current);

    final int safeLongest =
        _sanitizeNonNegativeInt(longest);

    progress['streak'] = <String, dynamic>{
      'current': safeCurrent,
      'longest': safeLongest < safeCurrent
          ? safeCurrent
          : safeLongest,
      'lastActivity':
          lastActivity?.toUtc().toIso8601String(),
    };

    return save(progress);
  }

  // ===========================================================================
  // SKILLS
  // ===========================================================================

  /// Returns all persisted skill values.
  static Future<Map<String, double>> getSkills() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> skills =
        _readMap(progress['skills']);

    return <String, double>{
      'speaking': _readDouble(
        skills['speaking'],
      ),
      'listening': _readDouble(
        skills['listening'],
      ),
      'reading': _readDouble(
        skills['reading'],
      ),
      'writing': _readDouble(
        skills['writing'],
      ),
      'grammar': _readDouble(
        skills['grammar'],
      ),
      'vocabulary': _readDouble(
        skills['vocabulary'],
      ),
    };
  }

  /// Returns a single skill value.
  static Future<double> getSkill(
    String skill,
  ) async {
    final Map<String, double> skills =
        await getSkills();

    return skills[skill] ?? 0.0;
  }

  /// Saves a single skill value.
  ///
  /// Skill values are normalized to the range 0.0 → 100.0.
  static Future<bool> setSkill(
    String skill,
    double value,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> skills =
        _readMap(progress['skills']);

    skills[skill] =
        _sanitizeSkillValue(value);

    progress['skills'] = skills;

    return save(progress);
  }

  /// Saves multiple skills at once.
  static Future<bool> setSkills(
    Map<String, double> values,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> skills =
        _readMap(progress['skills']);

    for (final MapEntry<String, double> entry
        in values.entries) {
      skills[entry.key] =
          _sanitizeSkillValue(entry.value);
    }

    progress['skills'] = skills;

    return save(progress);
  }

  // ===========================================================================
  // DAILY GOAL
  // ===========================================================================

  /// Returns the daily learning goal.
  static Future<int> getDailyGoal() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> goal =
        _readMap(progress['dailyGoal']);

    return _readInt(
      goal['target'],
      defaultDailyGoal,
    );
  }

  /// Returns today's completed amount.
  static Future<int> getDailyGoalProgress() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> goal =
        _readMap(progress['dailyGoal']);

    return _readInt(
      goal['completed'],
      0,
    );
  }

  /// Saves the daily goal target.
  static Future<bool> setDailyGoal(
    int target,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> goal =
        _readMap(progress['dailyGoal']);

    goal['target'] =
        _sanitizeNonNegativeInt(target);

    progress['dailyGoal'] = goal;

    return save(progress);
  }

  /// Saves today's completed daily goal amount.
  static Future<bool> setDailyGoalProgress(
    int completed,
  ) async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> goal =
        _readMap(progress['dailyGoal']);

    goal['completed'] =
        _sanitizeNonNegativeInt(completed);

    progress['dailyGoal'] = goal;

    return save(progress);
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Returns the total number of learning sessions.
  static Future<int> getTotalSessions() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> statistics =
        _readMap(progress['statistics']);

    return _readInt(
      statistics['sessions'],
      0,
    );
  }

  /// Returns the total learning time in minutes.
  static Future<int> getLearningMinutes() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> statistics =
        _readMap(progress['statistics']);

    return _readInt(
      statistics['learningMinutes'],
      0,
    );
  }

  /// Returns the total number of completed lessons.
  static Future<int> getCompletedLessons() async {
    final Map<String, dynamic> progress =
        await load();

    final Map<String, dynamic> statistics =
        _readMap(progress['statistics']);

    return _readInt(
      statistics['completedLessons'],
      0,
    );
  }

  /// Saves the main learning statistics.
  static Future<bool> setStatistics({
    required int sessions,
    required int learningMinutes,
    required int completedLessons,
  }) async {
    final Map<String, dynamic> progress =
        await load();

    progress['statistics'] = <String, dynamic>{
      'sessions':
          _sanitizeNonNegativeInt(sessions),
      'learningMinutes':
          _sanitizeNonNegativeInt(learningMinutes),
      'completedLessons':
          _sanitizeNonNegativeInt(completedLessons),
    };

    return save(progress);
  }

  // ===========================================================================
  // SNAPSHOT
  // ===========================================================================

  /// Returns a compact progression snapshot suitable for dashboards,
  /// widgets and future analytics.
  static Future<Map<String, dynamic>>
      getSnapshot() async {
    final Map<String, dynamic> progress =
        await load();

    return <String, dynamic>{
      'xp': progress['xp'],
      'level': progress['level'],
      'streak': progress['streak'],
      'skills': progress['skills'],
      'dailyGoal': progress['dailyGoal'],
      'statistics': progress['statistics'],
    };
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  /// Completely removes persisted progression data.
  ///
  /// The learner profile and other Eloqia storage domains remain untouched.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.progressKey,
    );
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  /// Creates a stable progression structure.
  ///
  /// This method is the defensive boundary of the service:
  /// callers can provide incomplete data without breaking the storage layer.
  static Map<String, dynamic> _normalize(
    Map<String, dynamic>? source,
  ) {
    final Map<String, dynamic> data =
        source == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(source);

    final Map<String, dynamic> streak =
        _readMap(data['streak']);

    final Map<String, dynamic> skills =
        _readMap(data['skills']);

    final Map<String, dynamic> dailyGoal =
        _readMap(data['dailyGoal']);

    final Map<String, dynamic> statistics =
        _readMap(data['statistics']);

    return <String, dynamic>{
      'version': storageVersion,
      'xp': _readInt(
        data['xp'],
        defaultXp,
      ),
      'level': _readInt(
        data['level'],
        defaultLevel,
      ),
      'streak': <String, dynamic>{
        'current': _readInt(
          streak['current'],
          defaultCurrentStreak,
        ),
        'longest': _readInt(
          streak['longest'],
          defaultLongestStreak,
        ),
        'lastActivity':
            _readString(streak['lastActivity']),
      },
      'skills': <String, dynamic>{
        'speaking': _readDouble(
          skills['speaking'],
        ),
        'listening': _readDouble(
          skills['listening'],
        ),
        'reading': _readDouble(
          skills['reading'],
        ),
        'writing': _readDouble(
          skills['writing'],
        ),
        'grammar': _readDouble(
          skills['grammar'],
        ),
        'vocabulary': _readDouble(
          skills['vocabulary'],
        ),
      },
      'dailyGoal': <String, dynamic>{
        'target': _readInt(
          dailyGoal['target'],
          defaultDailyGoal,
        ),
        'completed': _readInt(
          dailyGoal['completed'],
          0,
        ),
      },
      'statistics': <String, dynamic>{
        'sessions': _readInt(
          statistics['sessions'],
          0,
        ),
        'learningMinutes': _readInt(
          statistics['learningMinutes'],
          0,
        ),
        'completedLessons': _readInt(
          statistics['completedLessons'],
          0,
        ),
      },
    };
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

  static double _readDouble(
    dynamic value, [
    double fallback = 0.0,
  ]) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return fallback;
  }

  static String? _readString(
    dynamic value,
  ) {
    if (value is String) {
      return value;
    }

    return null;
  }

  // ===========================================================================
  // SANITIZATION
  // ===========================================================================

  static int _sanitizeNonNegativeInt(
    int value,
  ) {
    return value < 0 ? 0 : value;
  }

  static int _sanitizeMinimumInt(
    int value,
    int minimum,
  ) {
    return value < minimum ? minimum : value;
  }

  static double _sanitizeSkillValue(
    double value,
  ) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }

    if (value < 0.0) {
      return 0.0;
    }

    if (value > 100.0) {
      return 100.0;
    }

    return value;
  }
}