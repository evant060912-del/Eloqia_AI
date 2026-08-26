import '../../models/learning_session.dart';
import 'local_storage.dart';

/// Premium persistence infrastructure for Eloqia learning sessions.
///
/// [LearningSessionStorage] is the persistence boundary between the
/// learning-session domain and the local storage engine.
///
/// Architecture:
///
///     LearningSession
///           ↓
///     LearningSessionStorage
///           ↓
///     LocalStorage
///           ↓
///     SharedPreferences
///
/// Design principles:
/// • Domain-independent persistence.
/// • Defensive deserialization.
/// • Immutable collections at the public boundary.
/// • Deterministic ordering.
/// • Versioned storage format.
/// • Safe recovery from malformed records.
/// • Efficient batch operations.
/// • Active-session lifecycle support.
/// • Advanced local analytics.
/// • Future synchronization readiness.
///
/// This class intentionally contains NO:
/// • Flutter UI logic.
/// • navigation.
/// • AI provider logic.
/// • XP calculation.
/// • streak calculation.
/// • business-level lesson generation.
///
/// Those responsibilities belong to higher-level domain services.
class LearningSessionStorage {
  LearningSessionStorage._();

  // ===========================================================================
  // STORAGE CONTRACT
  // ===========================================================================

  /// Current persistence schema version.
  ///
  /// This version describes the structure stored locally.
  /// It is independent from Eloqia application versions.
  static const int storageVersion = 1;

  /// Maximum number of sessions retained locally.
  ///
  /// The local history remains bounded while the architecture stays ready
  /// for an unlimited cloud-backed history in the future.
  static const int maxStoredSessions = 250;

  /// Maximum number of sessions returned by a single history query.
  static const int maxQueryLimit = 100;

  static const String _versionKey = 'version';
  static const String _sessionsKey = 'sessions';

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Persists a session.
  ///
  /// If the session already exists, the existing record is atomically
  /// replaced by its newest representation.
  ///
  /// Returns `false` when the session fails structural validation or when
  /// persistence fails.
  static Future<bool> saveSession(
    LearningSession session,
  ) async {
    if (session.validate().isNotEmpty) {
      return false;
    }

    final List<LearningSession> sessions =
        await _loadSessions();

    final int existingIndex = sessions.indexWhere(
      (LearningSession item) => item.id == session.id,
    );

    if (existingIndex >= 0) {
      sessions[existingIndex] = session;
    } else {
      sessions.add(session);
    }

    _sortNewestFirst(sessions);

    return _persistSessions(
      _trimHistory(sessions),
    );
  }

  /// Persists multiple sessions using a single storage write.
  ///
  /// Invalid sessions are ignored.
  /// Existing sessions with identical IDs are replaced.
  static Future<bool> saveSessions(
    Iterable<LearningSession> sessionsToSave,
  ) async {
    final List<LearningSession> existing =
        await _loadSessions();

    final Map<String, LearningSession> indexed =
        <String, LearningSession>{
      for (final LearningSession session in existing)
        session.id: session,
    };

    for (final LearningSession session
        in sessionsToSave) {
      if (session.validate().isEmpty) {
        indexed[session.id] = session;
      }
    }

    final List<LearningSession> merged =
        indexed.values.toList();

    _sortNewestFirst(merged);

    return _persistSessions(
      _trimHistory(merged),
    );
  }

  /// Marks a session as started.
  ///
  /// The session remains otherwise immutable.
  static Future<LearningSession?> startSession(
    String id, {
    DateTime? startedAt,
  }) async {
    final LearningSession? session =
        await getSession(id);

    if (session == null) {
      return null;
    }

    final LearningSession updated =
        session.copyWith(
      status: LearningSessionStatus.inProgress,
      startedAt:
          (startedAt ?? DateTime.now()).toUtc(),
      completedAt: null,
    );

    final bool saved =
        await saveSession(updated);

    return saved ? updated : null;
  }

  /// Marks a session as completed.
  ///
  /// [completedAt] defaults to the current UTC timestamp.
  static Future<LearningSession?> completeSession(
    String id, {
    DateTime? completedAt,
  }) async {
    final LearningSession? session =
        await getSession(id);

    if (session == null) {
      return null;
    }

    final DateTime end =
        (completedAt ?? DateTime.now()).toUtc();

    final LearningSession updated =
        session.copyWith(
      status: LearningSessionStatus.completed,
      completedAt: end,
      completed: true,
    );

    final bool saved =
        await saveSession(updated);

    return saved ? updated : null;
  }

  /// Marks a session as abandoned.
  static Future<LearningSession?> abandonSession(
    String id, {
    DateTime? abandonedAt,
  }) async {
    final LearningSession? session =
        await getSession(id);

    if (session == null) {
      return null;
    }

    final LearningSession updated =
        session.copyWith(
      status: LearningSessionStatus.abandoned,
      completedAt:
          (abandonedAt ?? DateTime.now()).toUtc(),
      completed: false,
    );

    final bool saved =
        await saveSession(updated);

    return saved ? updated : null;
  }

  // ===========================================================================
  // READ
  // ===========================================================================

  /// Retrieves one session by its unique identifier.
  static Future<LearningSession?> getSession(
    String id,
  ) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final List<LearningSession> sessions =
        await _loadSessions();

    for (final LearningSession session in sessions) {
      if (session.id == normalizedId) {
        return session;
      }
    }

    return null;
  }

  /// Returns the complete local session history.
  ///
  /// Results are ordered newest first.
  static Future<List<LearningSession>>
      getAllSessions() async {
    final List<LearningSession> sessions =
        await _loadSessions();

    _sortNewestFirst(sessions);

    return List<LearningSession>.unmodifiable(
      sessions,
    );
  }

  /// Returns a bounded page of session history.
  ///
  /// [offset] starts at zero.
  /// [limit] is automatically clamped to [maxQueryLimit].
  static Future<List<LearningSession>>
      getSessionPage({
    int offset = 0,
    int limit = 20,
  }) async {
    final int safeOffset =
        offset < 0 ? 0 : offset;

    final int safeLimit =
        limit.clamp(1, maxQueryLimit);

    final List<LearningSession> sessions =
        await _loadSessions();

    _sortNewestFirst(sessions);

    if (safeOffset >= sessions.length) {
      return const <LearningSession>[];
    }

    final int end =
        (safeOffset + safeLimit)
            .clamp(0, sessions.length);

    return List<LearningSession>.unmodifiable(
      sessions.sublist(
        safeOffset,
        end,
      ),
    );
  }

  /// Returns the currently active session.
  ///
  /// If multiple active records somehow exist, the newest one wins.
  static Future<LearningSession?>
      getActiveSession() async {
    final List<LearningSession> sessions =
        await _loadSessions();

    _sortNewestFirst(sessions);

    for (final LearningSession session
        in sessions) {
      if (session.isActive) {
        return session;
      }
    }

    return null;
  }

  /// Returns all successfully completed sessions.
  static Future<List<LearningSession>>
      getCompletedSessions() async {
    return _filter(
      (LearningSession session) =>
          session.status ==
          LearningSessionStatus.completed,
    );
  }

  /// Returns all abandoned sessions.
  static Future<List<LearningSession>>
      getAbandonedSessions() async {
    return _filter(
      (LearningSession session) =>
          session.status ==
          LearningSessionStatus.abandoned,
    );
  }

  /// Returns all sessions currently in progress.
  static Future<List<LearningSession>>
      getInProgressSessions() async {
    return _filter(
      (LearningSession session) =>
          session.status ==
          LearningSessionStatus.inProgress,
    );
  }

  // ===========================================================================
  // FILTERING
  // ===========================================================================

  /// Returns sessions matching an activity.
  static Future<List<LearningSession>>
      getSessionsByActivity(
    LearningActivityType activityType,
  ) async {
    return _filter(
      (LearningSession session) =>
          session.activityType == activityType,
    );
  }

  /// Returns sessions matching a tutor.
  static Future<List<LearningSession>>
      getSessionsByTutor(
    String tutorId,
  ) async {
    final String normalized =
        tutorId.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const <LearningSession>[];
    }

    return _filter(
      (LearningSession session) =>
          session.tutorId?.trim().toLowerCase() ==
          normalized,
    );
  }

  /// Returns sessions targeting a specific CEFR level.
  static Future<List<LearningSession>>
      getSessionsByTargetLevel(
    String level,
  ) async {
    final String normalized =
        level.trim().toUpperCase();

    if (normalized.isEmpty) {
      return const <LearningSession>[];
    }

    return _filter(
      (LearningSession session) =>
          session.targetLevel?.trim().toUpperCase() ==
          normalized,
    );
  }

  /// Returns sessions containing a specific skill.
  static Future<List<LearningSession>>
      getSessionsBySkill(
    LearningSkill skill,
  ) async {
    return _filter(
      (LearningSession session) =>
          session.skills.contains(skill),
    );
  }

  /// Returns sessions created after [from].
  static Future<List<LearningSession>>
      getSessionsSince(
    DateTime from,
  ) async {
    final DateTime boundary = from.toUtc();

    return _filter(
      (LearningSession session) =>
          !session.createdAt.isBefore(boundary),
    );
  }

  /// Returns sessions created within a date range.
  static Future<List<LearningSession>>
      getSessionsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime start = from.toUtc();
    final DateTime end = to.toUtc();

    if (end.isBefore(start)) {
      return const <LearningSession>[];
    }

    return _filter(
      (LearningSession session) =>
          !session.createdAt.isBefore(start) &&
          !session.createdAt.isAfter(end),
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  /// Searches the local session history.
  ///
  /// The query is matched against:
  /// • session ID
  /// • tutor name
  /// • tutor ID
  /// • primary goal
  /// • target level
  /// • topics
  /// • interests
  /// • AI summary
  /// • recommendations
  static Future<List<LearningSession>>
      search(
    String query,
  ) async {
    final String normalized =
        query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return getAllSessions();
    }

    final List<LearningSession> sessions =
        await _loadSessions();

    final List<LearningSession> matches =
        sessions.where(
      (LearningSession session) {
        final Iterable<String> searchableValues =
            <String>[
          session.id,
          session.tutorId ?? '',
          session.tutorName ?? '',
          session.primaryGoal ?? '',
          session.targetLevel ?? '',
          session.startingLevel ?? '',
          session.aiSummary ?? '',
          ...session.topics,
          ...session.interests,
          ...session.strengths,
          ...session.weaknesses,
          ...session.recommendations,
          ...session.vocabularyLearned,
          ...session.grammarPoints,
        ];

        return searchableValues.any(
          (String value) =>
              value.toLowerCase().contains(normalized),
        );
      },
    ).toList();

    _sortNewestFirst(matches);

    return List<LearningSession>.unmodifiable(
      matches,
    );
  }

  // ===========================================================================
  // COUNTS
  // ===========================================================================

  /// Returns the number of locally persisted sessions.
  static Future<int> count() async {
    final List<LearningSession> sessions =
        await _loadSessions();

    return sessions.length;
  }

  /// Returns the number of completed sessions.
  static Future<int> completedCount() async {
    final List<LearningSession> sessions =
        await _loadSessions();

    return sessions
        .where(
          (LearningSession session) =>
              session.status ==
              LearningSessionStatus.completed,
        )
        .length;
  }

  // ===========================================================================
  // EXISTENCE
  // ===========================================================================

  /// Returns whether at least one valid session exists.
  static Future<bool> exists() async {
    return await count() > 0;
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one session by ID.
  ///
  /// Returns `false` when no matching session exists.
  static Future<bool> deleteSession(
    String id,
  ) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final List<LearningSession> sessions =
        await _loadSessions();

    final int originalLength =
        sessions.length;

    sessions.removeWhere(
      (LearningSession session) =>
          session.id == normalizedId,
    );

    if (sessions.length == originalLength) {
      return false;
    }

    return _persistSessions(sessions);
  }

  /// Deletes all sessions matching [activityType].
  static Future<bool> deleteByActivity(
    LearningActivityType activityType,
  ) async {
    final List<LearningSession> sessions =
        await _loadSessions();

    sessions.removeWhere(
      (LearningSession session) =>
          session.activityType == activityType,
    );

    return _persistSessions(sessions);
  }

  /// Deletes sessions older than [before].
  ///
  /// This is useful for controlled local-history maintenance.
  static Future<bool> purgeOlderThan(
    DateTime before,
  ) async {
    final DateTime boundary = before.toUtc();

    final List<LearningSession> sessions =
        await _loadSessions();

    sessions.removeWhere(
      (LearningSession session) =>
          session.createdAt.isBefore(boundary),
    );

    return _persistSessions(sessions);
  }

  /// Completely clears the local session history.
  ///
  /// Other Eloqia persistence domains remain untouched.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.sessionsKey,
    );
  }

  // ===========================================================================
  // ANALYTICS
  // ===========================================================================

  /// Returns an advanced local analytics snapshot.
  ///
  /// This method intentionally exposes aggregate information instead of
  /// returning raw session records to dashboard consumers.
  static Future<Map<String, dynamic>>
      getAnalyticsSnapshot() async {
    final List<LearningSession> sessions =
        await _loadSessions();

    int completed = 0;
    int abandoned = 0;
    int active = 0;
    int totalXp = 0;
    int totalMinutes = 0;
    int totalObjectives = 0;
    int completedObjectives = 0;

    double scoreSum = 0;
    int scoredSessions = 0;

    final Map<String, int> activityCounts =
        <String, int>{};

    final Map<String, int> tutorCounts =
        <String, int>{};

    final Map<String, int> skillCounts =
        <String, int>{};

    for (final LearningSession session
        in sessions) {
      switch (session.status) {
        case LearningSessionStatus.completed:
          completed++;
          break;

        case LearningSessionStatus.abandoned:
          abandoned++;
          break;

        case LearningSessionStatus.inProgress:
          active++;
          break;
      }

      totalXp += session.xpEarned;
      totalMinutes +=
          session.activeDuration.inMinutes;

      totalObjectives +=
          session.objectivesTotal;

      completedObjectives +=
          session.objectivesCompleted;

      if (session.score != null) {
        scoreSum += session.score!;
        scoredSessions++;
      }

      final String activity =
          session.activityType.name;

      activityCounts[activity] =
          (activityCounts[activity] ?? 0) + 1;

      final String tutor =
          session.tutorId ?? 'unknown';

      tutorCounts[tutor] =
          (tutorCounts[tutor] ?? 0) + 1;

      for (final LearningSkill skill
          in session.skills) {
        final String skillName = skill.name;

        skillCounts[skillName] =
            (skillCounts[skillName] ?? 0) + 1;
      }
    }

    final double completionRate =
        sessions.isEmpty
            ? 0.0
            : completed / sessions.length;

    final double averageScore =
        scoredSessions == 0
            ? 0.0
            : scoreSum / scoredSessions;

    final double objectiveCompletionRate =
        totalObjectives == 0
            ? 0.0
            : completedObjectives /
                totalObjectives;

    return <String, dynamic>{
      'version': storageVersion,
      'totalSessions': sessions.length,
      'completedSessions': completed,
      'abandonedSessions': abandoned,
      'activeSessions': active,
      'completionRate': completionRate,
      'totalXp': totalXp,
      'totalLearningMinutes': totalMinutes,
      'totalObjectives': totalObjectives,
      'completedObjectives':
          completedObjectives,
      'objectiveCompletionRate':
          objectiveCompletionRate,
      'averageScore': averageScore,
      'activityCounts': activityCounts,
      'tutorCounts': tutorCounts,
      'skillCounts': skillCounts,
    };
  }

  // ===========================================================================
  // RECENT ACTIVITY
  // ===========================================================================

  /// Returns the latest successful learning activity.
  static Future<LearningSession?> getLatestCompletedSession()
      async {
    final List<LearningSession> sessions =
        await getCompletedSessions();

    return sessions.isEmpty
        ? null
        : sessions.first;
  }

  /// Returns the latest session regardless of status.
  static Future<LearningSession?> getLatestSession()
      async {
    final List<LearningSession> sessions =
        await getAllSessions();

    return sessions.isEmpty
        ? null
        : sessions.first;
  }

  // ===========================================================================
  // INTERNAL FILTER ENGINE
  // ===========================================================================

  static Future<List<LearningSession>> _filter(
    bool Function(LearningSession session) predicate,
  ) async {
    final List<LearningSession> sessions =
        await _loadSessions();

    final List<LearningSession> result =
        sessions.where(predicate).toList();

    _sortNewestFirst(result);

    return List<LearningSession>.unmodifiable(
      result,
    );
  }

  // ===========================================================================
  // INTERNAL LOAD
  // ===========================================================================

  static Future<List<LearningSession>>
      _loadSessions() async {
    final Map<String, dynamic>? raw =
        await LocalStorage.readJsonMap(
      LocalStorage.sessionsKey,
    );

    return _decodeAndNormalize(raw);
  }

  // ===========================================================================
  // INTERNAL PERSISTENCE
  // ===========================================================================

  static Future<bool> _persistSessions(
    List<LearningSession> sessions,
  ) async {
    _sortNewestFirst(sessions);

    final List<LearningSession> trimmed =
        _trimHistory(sessions);

    final Map<String, dynamic> payload =
        <String, dynamic>{
      _versionKey: storageVersion,
      _sessionsKey: trimmed
          .map(
            (LearningSession session) =>
                session.toJson(),
          )
          .toList(),
    };

    return LocalStorage.saveJson(
      LocalStorage.sessionsKey,
      payload,
    );
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  /// Converts arbitrary persisted data into the canonical storage format.
  ///
  /// Malformed records are isolated and ignored instead of preventing the
  /// remaining history from loading.
  static List<LearningSession> _decodeAndNormalize(
    Map<String, dynamic>? source,
  ) {
    if (source == null) {
      return <LearningSession>[];
    }

    final dynamic rawSessions =
        source[_sessionsKey];

    if (rawSessions is! List) {
      return <LearningSession>[];
    }

    final Map<String, LearningSession> unique =
        <String, LearningSession>{};

    for (final dynamic rawSession
        in rawSessions) {
      if (rawSession is! Map) {
        continue;
      }

      try {
        final LearningSession session =
            LearningSession.fromJson(
          Map<String, dynamic>.from(rawSession),
        );

        if (session.validate().isEmpty) {
          unique[session.id] = session;
        }
      } catch (_) {
        // One malformed record must never invalidate the complete history.
      }
    }

    final List<LearningSession> sessions =
        unique.values.toList();

    _sortNewestFirst(sessions);

    return _trimHistory(sessions);
  }

  // ===========================================================================
  // HISTORY MANAGEMENT
  // ===========================================================================

  static List<LearningSession> _trimHistory(
    List<LearningSession> sessions,
  ) {
    if (sessions.length <= maxStoredSessions) {
      return sessions;
    }

    return sessions
        .take(maxStoredSessions)
        .toList();
  }

  static void _sortNewestFirst(
    List<LearningSession> sessions,
  ) {
    sessions.sort(
      (
        LearningSession first,
        LearningSession second,
      ) {
        final int createdComparison =
            second.createdAt.compareTo(
          first.createdAt,
        );

        if (createdComparison != 0) {
          return createdComparison;
        }

        return second.id.compareTo(first.id);
      },
    );
  }
}