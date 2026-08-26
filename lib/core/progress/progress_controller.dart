import 'package:flutter/foundation.dart';

import '../storage/progress_storage.dart';

/// Immutable view state exposed by [ProgressController].
///
/// The controller owns the runtime state while [ProgressStorage] remains
/// responsible for persistence.
///
/// This separation keeps the UI independent from the persistence layer
/// and gives Eloqia a clean path toward future cloud synchronization.
@immutable
class ProgressState {
  const ProgressState({
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.skills = const <String, double>{},
    this.dailyGoal = 20,
    this.dailyGoalProgress = 0,
    this.totalSessions = 0,
    this.learningMinutes = 0,
    this.completedLessons = 0,
    this.isLoading = false,
    this.hasError = false,
    this.error,
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

  final bool isLoading;

  final bool hasError;

  final Object? error;

  /// Returns the daily goal completion ratio.
  double get dailyGoalPercentage {
    if (dailyGoal <= 0) {
      return 0.0;
    }

    final double percentage =
        dailyGoalProgress / dailyGoal;

    if (percentage < 0.0) {
      return 0.0;
    }

    if (percentage > 1.0) {
      return 1.0;
    }

    return percentage;
  }

  /// Returns the progress of a specific skill as a value from 0.0 to 1.0.
  double skillPercentage(String skill) {
    final double value =
        skills[skill] ?? 0.0;

    return value.clamp(0.0, 100.0) / 100.0;
  }

  /// Returns a human-readable learning duration.
  String get formattedLearningTime {
    if (learningMinutes < 60) {
      return '${learningMinutes}m';
    }

    final int hours =
        learningMinutes ~/ 60;

    final int minutes =
        learningMinutes % 60;

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }

  /// Creates a modified copy of the current state.
  ProgressState copyWith({
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    Map<String, double>? skills,
    int? dailyGoal,
    int? dailyGoalProgress,
    int? totalSessions,
    int? learningMinutes,
    int? completedLessons,
    bool? isLoading,
    bool? hasError,
    Object? error,
    bool clearLastActivityDate = false,
    bool clearError = false,
  }) {
    return ProgressState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak:
          currentStreak ?? this.currentStreak,
      longestStreak:
          longestStreak ?? this.longestStreak,
      lastActivityDate:
          clearLastActivityDate
              ? null
              : lastActivityDate ??
                  this.lastActivityDate,
      skills:
          skills ?? this.skills,
      dailyGoal:
          dailyGoal ?? this.dailyGoal,
      dailyGoalProgress:
          dailyGoalProgress ??
              this.dailyGoalProgress,
      totalSessions:
          totalSessions ?? this.totalSessions,
      learningMinutes:
          learningMinutes ?? this.learningMinutes,
      completedLessons:
          completedLessons ?? this.completedLessons,
      isLoading:
          isLoading ?? this.isLoading,
      hasError:
          clearError
              ? false
              : hasError ?? this.hasError,
      error:
          clearError
              ? null
              : error ?? this.error,
    );
  }
}

/// Runtime progression controller for Eloqia.
///
/// Responsibilities:
///
/// - load persisted progression;
/// - expose progression to the UI;
/// - update progression through [ProgressStorage];
/// - keep UI state immutable;
/// - centralize progression mutations;
/// - provide a clean boundary for future business logic.
///
/// Architecture:
///
///     UI
///      ↓
///     ProgressController
///      ↓
///     ProgressStorage
///      ↓
///     LocalStorage
///      ↓
///     SharedPreferences
///
/// The controller deliberately does not contain widget code.
class ProgressController extends ChangeNotifier {
  ProgressController();

  ProgressState _state =
      const ProgressState();

  bool _disposed = false;

  Future<void>? _loadOperation;

  /// Current progression state.
  ProgressState get state => _state;

  /// Whether progression data is currently loading.
  bool get isLoading => _state.isLoading;

  /// Whether the latest operation failed.
  bool get hasError => _state.hasError;

  /// Current XP.
  int get xp => _state.xp;

  /// Current learner level.
  int get level => _state.level;

  /// Current learning streak.
  int get currentStreak =>
      _state.currentStreak;

  /// Longest recorded streak.
  int get longestStreak =>
      _state.longestStreak;

  /// Current skill values.
  Map<String, double> get skills =>
      _state.skills;

  /// Daily learning target.
  int get dailyGoal =>
      _state.dailyGoal;

  /// Today's completed daily goal.
  int get dailyGoalProgress =>
      _state.dailyGoalProgress;

  /// Number of completed sessions.
  int get totalSessions =>
      _state.totalSessions;

  /// Total learning time in minutes.
  int get learningMinutes =>
      _state.learningMinutes;

  /// Number of completed lessons.
  int get completedLessons =>
      _state.completedLessons;

  /// Loads progression from persistent storage.
  ///
  /// Concurrent calls share the same operation.
  Future<void> load() {
    final Future<void>? running =
        _loadOperation;

    if (running != null) {
      return running;
    }

    final Future<void> operation =
        _loadInternal();

    _loadOperation = operation;

    operation.whenComplete(() {
      if (identical(
        _loadOperation,
        operation,
      )) {
        _loadOperation = null;
      }
    });

    return operation;
  }

  Future<void> _loadInternal() async {
    _setState(
      _state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final Map<String, dynamic> progress =
          await ProgressStorage.load();

      final Map<String, dynamic> streak =
          _readMap(progress['streak']);

      final Map<String, dynamic> dailyGoal =
          _readMap(progress['dailyGoal']);

      final Map<String, dynamic> statistics =
          _readMap(progress['statistics']);

      final Map<String, dynamic> rawSkills =
          _readMap(progress['skills']);

      final Map<String, double> normalizedSkills =
          _normalizeSkills(rawSkills);

      final DateTime? lastActivity =
          _parseDateTime(
        streak['lastActivity'],
      );

      _setState(
        ProgressState(
          xp: _readNonNegativeInt(
            progress['xp'],
          ),
          level: _readMinimumInt(
            progress['level'],
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
          lastActivityDate:
              lastActivity,
          skills: normalizedSkills,
          dailyGoal:
              _readNonNegativeInt(
            dailyGoal['target'],
            fallback: ProgressStorage.defaultDailyGoal,
          ),
          dailyGoalProgress:
              _readNonNegativeInt(
            dailyGoal['completed'],
          ),
          totalSessions:
              _readNonNegativeInt(
            statistics['sessions'],
          ),
          learningMinutes:
              _readNonNegativeInt(
            statistics['learningMinutes'],
          ),
          completedLessons:
              _readNonNegativeInt(
            statistics['completedLessons'],
          ),
          isLoading: false,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          isLoading: false,
          hasError: true,
          error: error,
        ),
      );
    }
  }

  /// Refreshes progression from local persistence.
  Future<void> refresh() {
    return load();
  }

  /// Adds XP and immediately refreshes the runtime state.
  Future<bool> addXp(int amount) async {
    if (amount <= 0) {
      return true;
    }

    final bool success =
        await ProgressStorage.addXp(
      amount,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the XP update.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Sets the learner's total XP.
  Future<bool> setXp(int value) async {
    final bool success =
        await ProgressStorage.setXp(
      value,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the XP value.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Sets the learner's level.
  Future<bool> setLevel(int value) async {
    final bool success =
        await ProgressStorage.setLevel(
      value,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the learner level.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Updates the learner's streak.
  Future<bool> setStreak({
    required int current,
    required int longest,
    DateTime? lastActivity,
  }) async {
    final bool success =
        await ProgressStorage.setStreak(
      current: current,
      longest: longest,
      lastActivity: lastActivity,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the learning streak.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Updates a single skill.
  Future<bool> setSkill(
    String skill,
    double value,
  ) async {
    final String normalizedSkill =
        skill.trim().toLowerCase();

    if (normalizedSkill.isEmpty) {
      return false;
    }

    final bool success =
        await ProgressStorage.setSkill(
      normalizedSkill,
      value,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the skill value.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Updates several skills in one persistence operation.
  Future<bool> setSkills(
    Map<String, double> values,
  ) async {
    if (values.isEmpty) {
      return true;
    }

    final Map<String, double> normalized =
        <String, double>{
      for (final MapEntry<String, double> entry
          in values.entries)
        if (entry.key.trim().isNotEmpty)
          entry.key.trim().toLowerCase():
              entry.value,
    };

    if (normalized.isEmpty) {
      return true;
    }

    final bool success =
        await ProgressStorage.setSkills(
      normalized,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the skill values.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Sets the daily learning target.
  Future<bool> setDailyGoal(
    int target,
  ) async {
    final bool success =
        await ProgressStorage.setDailyGoal(
      target,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the daily goal.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Sets today's completed daily goal amount.
  Future<bool> setDailyGoalProgress(
    int completed,
  ) async {
    final bool success =
        await ProgressStorage.setDailyGoalProgress(
      completed,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the daily goal progress.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Updates the main learning statistics.
  Future<bool> setStatistics({
    required int sessions,
    required int learningMinutes,
    required int completedLessons,
  }) async {
    final bool success =
        await ProgressStorage.setStatistics(
      sessions: sessions,
      learningMinutes: learningMinutes,
      completedLessons: completedLessons,
    );

    if (!success) {
      _setError(
        StateError(
          'Eloqia could not save the learning statistics.',
        ),
      );

      return false;
    }

    await load();

    return true;
  }

  /// Records a completed learning session.
  ///
  /// This is intentionally lightweight. Advanced XP calculation,
  /// streak rules and adaptive progression can later move into a
  /// dedicated progression engine without changing the UI contract.
  Future<bool> recordLearningSession({
    int minutes = 0,
    int xp = 0,
    int completedLessons = 0,
  }) async {
    final ProgressState current =
        _state;

    final bool statisticsSaved =
        await ProgressStorage.setStatistics(
      sessions:
          current.totalSessions + 1,
      learningMinutes:
          current.learningMinutes +
              _nonNegative(minutes),
      completedLessons:
          current.completedLessons +
              _nonNegative(completedLessons),
    );

    if (!statisticsSaved) {
      _setError(
        StateError(
          'Eloqia could not save the learning session.',
        ),
      );

      return false;
    }

    if (xp > 0) {
      final bool xpSaved =
          await ProgressStorage.addXp(
        xp,
      );

      if (!xpSaved) {
        _setError(
          StateError(
            'Eloqia could not save the session XP.',
          ),
        );

        return false;
      }
    }

    await load();

    return true;
  }

  /// Clears the runtime error state.
  void clearError() {
    if (!_state.hasError &&
        _state.error == null) {
      return;
    }

    _setState(
      _state.copyWith(
        clearError: true,
      ),
    );
  }

  /// Returns a diagnostic representation useful during development.
  Map<String, dynamic> diagnostics() {
    return <String, dynamic>{
      'component': 'ProgressController',
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'dailyGoal': dailyGoal,
      'dailyGoalProgress':
          dailyGoalProgress,
      'totalSessions': totalSessions,
      'learningMinutes':
          learningMinutes,
      'completedLessons':
          completedLessons,
      'isLoading': isLoading,
      'hasError': hasError,
    };
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  static Map<String, dynamic> _readMap(
    dynamic value,
  ) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(
      value,
    );
  }

  static int _readNonNegativeInt(
    dynamic value, {
    int fallback = 0,
  }) {
    int result;

    if (value is int) {
      result = value;
    } else if (value is num) {
      result = value.toInt();
    } else {
      return fallback;
    }

    return result < 0 ? 0 : result;
  }

  static int _readMinimumInt(
    dynamic value,
    int minimum,
  ) {
    final int result =
        _readNonNegativeInt(
      value,
      fallback: minimum,
    );

    return result < minimum
        ? minimum
        : result;
  }

  static double _readSkill(
    dynamic value,
  ) {
    double result;

    if (value is double) {
      result = value;
    } else if (value is num) {
      result = value.toDouble();
    } else {
      return 0.0;
    }

    if (result.isNaN ||
        result.isInfinite) {
      return 0.0;
    }

    return result.clamp(
      0.0,
      100.0,
    );
  }

  static Map<String, double> _normalizeSkills(
    Map<String, dynamic> source,
  ) {
    const List<String> supportedSkills =
        <String>[
      'speaking',
      'listening',
      'reading',
      'writing',
      'grammar',
      'vocabulary',
    ];

    return <String, double>{
      for (final String skill in supportedSkills)
        skill: _readSkill(
          source[skill],
        ),
    };
  }

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value is! String ||
        value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value,
    )?.toUtc();
  }

  static int _nonNegative(int value) {
    return value < 0 ? 0 : value;
  }

  void _setError(Object error) {
    _setState(
      _state.copyWith(
        isLoading: false,
        hasError: true,
        error: error,
      ),
    );
  }

  void _setState(ProgressState nextState) {
    if (_disposed) {
      return;
    }

    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}