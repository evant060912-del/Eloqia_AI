import '../../models/learning_session.dart';
import '../../core/storage/learning_session_storage.dart';

/// High-level orchestration service for Eloqia learning sessions.
///
/// [LearningSessionService] sits above persistence and below the future
/// adaptive-learning engine.
///
/// Architecture:
///
///     UI / AI / Learning Engine
///               ↓
///     LearningSessionService
///               ↓
///     LearningSessionStorage
///               ↓
///           LocalStorage
///
/// Responsibilities:
/// • Session creation.
/// • Session lifecycle orchestration.
/// • Session updates.
/// • Completion and abandonment.
/// • Safe session retrieval.
/// • Session history access.
/// • Session querying.
/// • Lightweight session-level analytics.
/// • Preparation for future synchronization.
///
/// Deliberately excluded:
/// • Flutter UI.
/// • Navigation.
/// • AI provider calls.
/// • XP calculation rules.
/// • Streak calculation rules.
/// • Memory intelligence.
/// • Lesson generation.
/// • Network communication.
///
/// Those responsibilities belong to specialized domain services.
class LearningSessionService {
  LearningSessionService._();

  // ===========================================================================
  // CREATION
  // ===========================================================================

  /// Creates and persists a new learning session.
  ///
  /// The session immediately enters the `inProgress` state.
  static Future<LearningSession?> createSession({
    required String id,
    LearningActivityType activityType = LearningActivityType.conversation,
    String? learnerId,
    String? tutorId,
    String? tutorName,
    String? targetLevel,
    String? startingLevel,
    String? primaryGoal,
    List<LearningSkill> skills = const <LearningSkill>[],
    List<String> topics = const <String>[],
    List<String> interests = const <String>[],
    bool adaptive = true,
    SessionDifficulty difficulty = SessionDifficulty.adaptive,
    LearningPace pace = LearningPace.adaptive,
  }) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final LearningSession session = LearningSession.create(
      id: normalizedId,
      activityType: activityType,
      learnerId: _normalizeNullable(learnerId),
      tutorId: _normalizeNullable(tutorId),
      tutorName: _normalizeNullable(tutorName),
      targetLevel: _normalizeLevel(targetLevel),
      startingLevel: _normalizeLevel(startingLevel),
      primaryGoal: _normalizeNullable(primaryGoal),
      skills: _normalizeEnumList(skills),
      topics: _normalizeStringList(topics),
      interests: _normalizeStringList(interests),
      adaptive: adaptive,
      difficulty: difficulty,
      pace: pace,
    );

    if (session.validate().isNotEmpty) {
      return null;
    }

    final bool saved = await LearningSessionStorage.saveSession(session);

    return saved ? session : null;
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Starts an existing session.
  static Future<LearningSession?> startSession(
    String id, {
    DateTime? startedAt,
  }) async {
    return LearningSessionStorage.startSession(id.trim(), startedAt: startedAt);
  }

  /// Completes an existing session.
  ///
  /// Completion itself does not calculate XP or progression.
  /// Those responsibilities remain in the progression layer.
  static Future<LearningSession?> completeSession(
    String id, {
    DateTime? completedAt,
    bool completed = true,
    int xpEarned = 0,
  }) async {
    if (xpEarned < 0) {
      return null;
    }

    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    final DateTime end = (completedAt ?? DateTime.now()).toUtc();

    final LearningSession updated = session.copyWith(
      status: completed
          ? LearningSessionStatus.completed
          : LearningSessionStatus.abandoned,
      completedAt: end,
      completed: completed,
      xpEarned: xpEarned,
    );

    final bool saved = await LearningSessionStorage.saveSession(updated);

    return saved ? updated : null;
  }

  /// Abandons an existing session.
  static Future<LearningSession?> abandonSession(
    String id, {
    DateTime? abandonedAt,
  }) async {
    return LearningSessionStorage.abandonSession(
      id.trim(),
      abandonedAt: abandonedAt,
    );
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Persists an updated session after validating it.
  ///
  /// This method is intentionally generic so future learning engines can
  /// progressively update a session without coupling themselves to storage.
  static Future<LearningSession?> updateSession(LearningSession session) async {
    if (session.validate().isNotEmpty) {
      return null;
    }

    final bool saved = await LearningSessionStorage.saveSession(session);

    return saved ? session : null;
  }

  /// Updates the active learning duration.
  static Future<LearningSession?> updateDuration(
    String id,
    Duration duration,
  ) async {
    if (duration.isNegative) {
      return null;
    }

    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    return updateSession(session.copyWith(activeDuration: duration));
  }

  /// Updates session objectives.
  static Future<LearningSession?> updateObjectives(
    String id, {
    required int completed,
    required int total,
  }) async {
    if (completed < 0 || total < 0) {
      return null;
    }

    if (total > 0 && completed > total) {
      return null;
    }

    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    return updateSession(
      session.copyWith(objectivesCompleted: completed, objectivesTotal: total),
    );
  }

  /// Updates the session performance data.
  static Future<LearningSession?> updatePerformance(
    String id, {
    double? score,
    double? confidenceScore,
    double? pronunciationScore,
    double? vocabularyScore,
    double? grammarScore,
    double? fluencyScore,
  }) async {
    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    final LearningSession updated = session.copyWith(
      score: _normalizePercentage(score),
      confidenceScore: _normalizePercentage(confidenceScore),
      pronunciationScore: _normalizePercentage(pronunciationScore),
      vocabularyScore: _normalizePercentage(vocabularyScore),
      grammarScore: _normalizePercentage(grammarScore),
      fluencyScore: _normalizePercentage(fluencyScore),
    );

    return updateSession(updated);
  }

  /// Updates AI-generated learning insights.
  static Future<LearningSession?> updateInsights(
    String id, {
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? vocabularyLearned,
    List<String>? grammarPoints,
    List<String>? recommendations,
    String? aiSummary,
  }) async {
    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    final LearningSession updated = session.copyWith(
      strengths: strengths == null ? null : _normalizeStringList(strengths),
      weaknesses: weaknesses == null ? null : _normalizeStringList(weaknesses),
      vocabularyLearned: vocabularyLearned == null
          ? null
          : _normalizeStringList(vocabularyLearned),
      grammarPoints: grammarPoints == null
          ? null
          : _normalizeStringList(grammarPoints),
      recommendations: recommendations == null
          ? null
          : _normalizeStringList(recommendations),
      aiSummary: _normalizeNullable(aiSummary),
    );

    return updateSession(updated);
  }

  /// Updates learner feedback for a finished session.
  static Future<LearningSession?> updateFeedback(
    String id, {
    int? rating,
    String? feedback,
  }) async {
    if (rating != null && (rating < 1 || rating > 5)) {
      return null;
    }

    final LearningSession? session = await getSession(id);

    if (session == null) {
      return null;
    }

    final LearningSession updated = session.copyWith(
      rating: rating,
      feedback: _normalizeNullable(feedback),
    );

    return updateSession(updated);
  }

  // ===========================================================================
  // READ
  // ===========================================================================

  /// Returns one session by ID.
  static Future<LearningSession?> getSession(String id) async {
    return LearningSessionStorage.getSession(id.trim());
  }

  /// Returns the complete local session history.
  static Future<List<LearningSession>> getHistory() async {
    return LearningSessionStorage.getAllSessions();
  }

  /// Returns a paginated session history.
  static Future<List<LearningSession>> getHistoryPage({
    int offset = 0,
    int limit = 20,
  }) async {
    return LearningSessionStorage.getSessionPage(offset: offset, limit: limit);
  }

  /// Returns the currently active session.
  static Future<LearningSession?> getActiveSession() async {
    return LearningSessionStorage.getActiveSession();
  }

  /// Returns the latest completed session.
  static Future<LearningSession?> getLatestCompletedSession() async {
    return LearningSessionStorage.getLatestCompletedSession();
  }

  /// Returns the latest session regardless of status.
  static Future<LearningSession?> getLatestSession() async {
    return LearningSessionStorage.getLatestSession();
  }

  // ===========================================================================
  // FILTERING
  // ===========================================================================

  /// Returns sessions for a specific activity.
  static Future<List<LearningSession>> getByActivity(
    LearningActivityType activityType,
  ) async {
    return LearningSessionStorage.getSessionsByActivity(activityType);
  }

  /// Returns sessions for a specific tutor.
  static Future<List<LearningSession>> getByTutor(String tutorId) async {
    return LearningSessionStorage.getSessionsByTutor(tutorId);
  }

  /// Returns sessions targeting a CEFR level.
  static Future<List<LearningSession>> getByTargetLevel(String level) async {
    return LearningSessionStorage.getSessionsByTargetLevel(level);
  }

  /// Returns sessions containing a specific skill.
  static Future<List<LearningSession>> getBySkill(LearningSkill skill) async {
    return LearningSessionStorage.getSessionsBySkill(skill);
  }

  /// Searches sessions using the storage search index.
  static Future<List<LearningSession>> search(String query) async {
    return LearningSessionStorage.search(query);
  }

  /// Returns the total number of locally stored sessions.
  static Future<int> count() async {
    return LearningSessionStorage.count();
  }

  /// Returns the number of completed sessions.
  static Future<int> completedCount() async {
    return LearningSessionStorage.completedCount();
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  static String? _normalizeNullable(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String? _normalizeLevel(String? value) {
    final String? normalized = _normalizeNullable(value);
    return normalized?.toUpperCase();
  }

  static List<String> _normalizeStringList(Iterable<String> values) {
    final Set<String> normalized = <String>{};

    for (final String value in values) {
      final String item = value.trim();
      if (item.isNotEmpty) {
        normalized.add(item);
      }
    }

    return List<String>.unmodifiable(normalized);
  }

  static List<LearningSkill> _normalizeEnumList(
    Iterable<LearningSkill> values,
  ) {
    return List<LearningSkill>.unmodifiable(values.toSet());
  }

  static double? _normalizePercentage(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }

    return value.clamp(0.0, 100.0).toDouble();
  }
}
