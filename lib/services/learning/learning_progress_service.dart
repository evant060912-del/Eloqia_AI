import '../../core/storage/progress_storage.dart';
import '../../models/progress.dart';

typedef LearningProgress = Progress;

extension _ProgressCompatibility on Progress {
  int get totalXp => xp;
  int get longestStreak => currentStreak;
  int get totalLearningMinutes => statistics.learningMinutes;
  int get todayLearningMinutes => dailyGoal.completed;
  int get dailyGoalMinutes => dailyGoal.target;
  int get completedSessions => statistics.completedLessons;

  Progress addLearningTime(Duration duration) {
    return copyWith(
      statistics: statistics.copyWith(
        learningMinutes: statistics.learningMinutes + duration.inMinutes,
      ),
    );
  }

  Progress incrementCompletedSessions() {
    return copyWith(
      statistics: statistics.copyWith(
        completedLessons: statistics.completedLessons + 1,
      ),
    );
  }

  Progress registerLearningDay(DateTime date) {
    final DateTime normalizedDate = date.toUtc();
    final DateTime? previousDate = lastActivity?.toUtc();
    final bool sameDay =
        previousDate != null &&
        previousDate.year == normalizedDate.year &&
        previousDate.month == normalizedDate.month &&
        previousDate.day == normalizedDate.day;

    return copyWith(
      currentStreak: sameDay ? currentStreak : currentStreak + 1,
      longestStreak: sameDay
          ? longestStreak
          : (longestStreak > currentStreak ? longestStreak : currentStreak + 1),
      lastActivity: normalizedDate,
    );
  }
}

/// High-level domain service for Eloqia learning progression.
///
/// [LearningProgressService] orchestrates progression-related operations
/// between the application domain and the local persistence layer.
///
/// Architecture:
///
///     UI / Learning Engine / AI
///                 ↓
///     LearningProgressService
///                 ↓
///          ProgressStorage
///                 ↓
///            LocalStorage
///
/// Responsibilities:
/// • Progress retrieval.
/// • Progress initialization.
/// • XP management.
/// • Level progression.
/// • Streak management.
/// • Daily and global statistics.
/// • Learning-time tracking.
/// • Goal progression.
/// • Safe progression updates.
/// • Normalization and validation.
///
/// Deliberately excluded:
/// • Flutter UI.
/// • Navigation.
/// • AI provider calls.
/// • Lesson generation.
/// • Prompt generation.
/// • Memory intelligence.
/// • Network synchronization.
///
/// Business rules remain centralized here instead of being scattered
/// across screens and widgets.
class LearningProgressService {
  LearningProgressService._();

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Returns the learner's current progression.
  ///
  /// If no progression exists yet, a default progression is created and
  /// persisted automatically.
  static Future<Progress> getProgress() async {
    final Map<String, dynamic> stored = await ProgressStorage.load();

    final Progress initial = Progress.fromJson(stored);

    if (await ProgressStorage.exists()) {
      return initial;
    }

    await ProgressStorage.save(initial.toJson());

    return initial;
  }

  /// Initializes progression if it does not already exist.
  ///
  /// Returns the resulting progression regardless of whether it was newly
  /// created or already existed.
  static Future<LearningProgress> initialize() async {
    return getProgress();
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Persists a progression object after structural validation.
  static Future<Progress?> save(Progress progress) async {
    if (progress.xp < 0 ||
        progress.level < 1 ||
        progress.currentStreak < 0 ||
        progress.longestStreak < 0) {
      return null;
    }

    final bool saved = await ProgressStorage.save(progress.toJson());

    return saved ? progress : null;
  }

  // ===========================================================================
  // XP
  // ===========================================================================

  /// Awards XP to the learner.
  ///
  /// Negative XP is rejected.
  ///
  /// The underlying progression model remains responsible for calculating
  /// the resulting level when its XP state changes.
  static Future<LearningProgress?> addXp(int amount) async {
    if (amount <= 0) {
      return null;
    }

    final Progress progress = await getProgress();

    final Progress updated = progress.copyWith(xp: progress.xp + amount);

    return save(updated);
  }

  /// Removes XP from the learner.
  ///
  /// XP can never become negative.
  static Future<LearningProgress?> removeXp(int amount) async {
    if (amount <= 0) {
      return null;
    }

    final Progress progress = await getProgress();

    final Progress updated = progress.copyWith(
      xp: (progress.xp - amount).clamp(0, progress.xp),
    );

    return save(updated);
  }

  // ===========================================================================
  // SESSION COMPLETION
  // ===========================================================================

  /// Registers a successfully completed learning session.
  ///
  /// This method updates progression-related aggregates but does not attempt
  /// to modify the session itself.
  static Future<LearningProgress?> registerCompletedSession({
    int xpEarned = 0,
    Duration learningDuration = Duration.zero,
    bool updateStreak = true,
  }) async {
    if (xpEarned < 0 || learningDuration.isNegative) {
      return null;
    }

    LearningProgress progress = await getProgress();

    if (xpEarned > 0) {
      progress = progress.addXp(xpEarned);
    }

    progress = progress.incrementCompletedSessions();

    if (learningDuration > Duration.zero) {
      progress = progress.addLearningTime(learningDuration);
    }

    if (updateStreak) {
      progress = progress.registerLearningDay(DateTime.now().toUtc());
    }

    return save(progress);
  }

  // ===========================================================================
  // LEARNING TIME
  // ===========================================================================

  /// Adds active learning time to the learner's progression.
  static Future<LearningProgress?> addLearningTime(Duration duration) async {
    if (duration.isNegative || duration == Duration.zero) {
      return null;
    }

    final LearningProgress progress = await getProgress();

    final LearningProgress updated = progress.addLearningTime(duration);

    return save(updated);
  }

  // ===========================================================================
  // STREAK
  // ===========================================================================

  /// Registers a learning day and updates the learner's streak.
  static Future<LearningProgress?> registerLearningDay([DateTime? date]) async {
    final LearningProgress progress = await getProgress();

    final LearningProgress updated = progress.registerLearningDay(
      (date ?? DateTime.now()).toUtc(),
    );

    return save(updated);
  }

  /// Returns the current learning streak.
  static Future<int> getCurrentStreak() async {
    final LearningProgress progress = await getProgress();

    return progress.currentStreak;
  }

  /// Returns the longest streak ever achieved.
  static Future<int> getLongestStreak() async {
    final LearningProgress progress = await getProgress();

    return progress.longestStreak;
  }

  // ===========================================================================
  // LEVEL
  // ===========================================================================

  /// Returns the learner's current Eloqia progression level.
  static Future<int> getLevel() async {
    final LearningProgress progress = await getProgress();

    return progress.level;
  }

  /// Returns the total XP accumulated by the learner.
  static Future<int> getTotalXp() async {
    final LearningProgress progress = await getProgress();

    return progress.totalXp;
  }

  /// Returns XP progress toward the next level.
  static Future<double> getLevelProgress() async {
    final LearningProgress progress = await getProgress();

    return progress.levelProgress;
  }

  // ===========================================================================
  // GOALS
  // ===========================================================================

  /// Updates the learner's daily learning goal.
  static Future<LearningProgress?> setDailyGoal(int minutes) async {
    if (minutes < 0) {
      return null;
    }

    final LearningProgress progress = await getProgress();

    final LearningProgress updated = progress.copyWith(
      dailyGoal: progress.dailyGoal.copyWith(target: minutes),
    );

    return save(updated);
  }

  /// Updates today's completed learning time.
  static Future<LearningProgress?> setTodayLearningTime(int minutes) async {
    if (minutes < 0) {
      return null;
    }

    final LearningProgress progress = await getProgress();

    final LearningProgress updated = progress.copyWith(
      dailyGoal: progress.dailyGoal.copyWith(completed: minutes),
    );

    return save(updated);
  }

  /// Returns today's learning progress from 0 to 1.
  static Future<double> getDailyGoalProgress() async {
    final LearningProgress progress = await getProgress();

    return progress.dailyGoalProgress;
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Returns a compact progression snapshot for dashboard consumers.
  static Future<Map<String, dynamic>> getSnapshot() async {
    final LearningProgress progress = await getProgress();

    return <String, dynamic>{
      'level': progress.level,
      'totalXp': progress.totalXp,
      'levelProgress': progress.levelProgress,
      'currentStreak': progress.currentStreak,
      'longestStreak': progress.longestStreak,
      'completedSessions': progress.completedSessions,
      'totalLearningMinutes': progress.totalLearningMinutes,
      'todayLearningMinutes': progress.todayLearningMinutes,
      'dailyGoalMinutes': progress.dailyGoalMinutes,
      'dailyGoalProgress': progress.dailyGoalProgress,
    };
  }

  // ===========================================================================
  // COUNTERS
  // ===========================================================================

  /// Returns the number of completed learning sessions.
  static Future<int> getCompletedSessions() async {
    final LearningProgress progress = await getProgress();

    return progress.completedSessions;
  }

  /// Returns total accumulated learning time.
  static Future<Duration> getTotalLearningTime() async {
    final LearningProgress progress = await getProgress();

    return Duration(minutes: progress.totalLearningMinutes);
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  /// Resets progression to its initial state.
  ///
  /// This operation affects progression only.
  /// Profile, memory and session history remain untouched.
  static Future<bool> reset() async {
    final LearningProgress initial = Progress();

    return ProgressStorage.save(initial.toJson());
  }

  /// Deletes the persisted progression completely.
  ///
  /// The next call to [getProgress] will recreate it automatically.
  static Future<bool> clear() async {
    return ProgressStorage.clear();
  }
}
