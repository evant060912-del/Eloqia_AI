import 'local_storage.dart';

/// Persistent storage for Eloqia learning sessions.
///
/// A session represents one completed or ongoing learning experience.
/// The storage layer intentionally remains independent from the UI,
/// tutor implementation and future AI backend.
///
/// Each session can contain:
///
/// • a unique identifier
/// • tutor information
/// • activity type
/// • start and end timestamps
/// • duration
/// • XP earned
/// • completion state
/// • learner feedback
/// • optional metadata
///
/// This structure is intentionally flexible so future Eloqia experiences
/// such as conversation, pronunciation, writing, listening and lessons
/// can share the same persistence foundation.
class SessionStorage {
  SessionStorage._();

  // ===========================================================================
  // STORAGE
  // ===========================================================================

  /// Current persistence format for session history.
  static const int storageVersion = 1;

  /// Maximum number of sessions retained locally.
  ///
  /// This prevents the local database from growing indefinitely while
  /// preserving a substantial learning history.
  static const int maxStoredSessions = 500;

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Loads the complete local session history.
  ///
  /// The returned list is always safe to consume.
  /// Newest sessions are kept first.
  static Future<List<Map<String, dynamic>>> load() async {
    final Map<String, dynamic>? data =
        await LocalStorage.readJsonMap(
      LocalStorage.sessionsKey,
    );

    if (data == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic rawSessions =
        data['sessions'];

    if (rawSessions is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> sessions =
        <Map<String, dynamic>>[];

    for (final dynamic item in rawSessions) {
      if (item is Map) {
        sessions.add(
          Map<String, dynamic>.from(item),
        );
      }
    }

    _sortNewestFirst(sessions);

    return sessions;
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Persists the complete session history.
  static Future<bool> save(
    List<Map<String, dynamic>> sessions,
  ) async {
    final List<Map<String, dynamic>> normalized =
        _normalizeSessions(sessions);

    return LocalStorage.saveJson(
      LocalStorage.sessionsKey,
      <String, dynamic>{
        'version': storageVersion,
        'sessions': normalized,
      },
    );
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Adds a new learning session to the local history.
  ///
  /// A session identifier and creation timestamp are generated automatically
  /// when they are not already provided.
  static Future<bool> add(
    Map<String, dynamic> session,
  ) async {
    final List<Map<String, dynamic>> sessions =
        await load();

    final Map<String, dynamic> normalized =
        _normalizeSession(session);

    sessions.insert(
      0,
      normalized,
    );

    if (sessions.length > maxStoredSessions) {
      sessions.removeRange(
        maxStoredSessions,
        sessions.length,
      );
    }

    return save(sessions);
  }

  // ===========================================================================
  // FIND
  // ===========================================================================

  /// Finds a session by its unique identifier.
  static Future<Map<String, dynamic>?> findById(
    String sessionId,
  ) async {
    final String normalizedId =
        sessionId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> sessions =
        await load();

    for (final Map<String, dynamic> session
        in sessions) {
      if (session['id'] == normalizedId) {
        return Map<String, dynamic>.from(
          session,
        );
      }
    }

    return null;
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Updates an existing session.
  ///
  /// Returns `false` when no session with the specified identifier exists.
  static Future<bool> update(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    final String normalizedId =
        sessionId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> sessions =
        await load();

    final int index = sessions.indexWhere(
      (Map<String, dynamic> session) =>
          session['id'] == normalizedId,
    );

    if (index == -1) {
      return false;
    }

    final Map<String, dynamic> updated =
        Map<String, dynamic>.from(
      sessions[index],
    );

    updated.addAll(updates);

    updated['id'] = normalizedId;

    sessions[index] =
        _normalizeSession(updated);

    return save(sessions);
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one session by identifier.
  static Future<bool> delete(
    String sessionId,
  ) async {
    final String normalizedId =
        sessionId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> sessions =
        await load();

    final int initialLength =
        sessions.length;

    sessions.removeWhere(
      (Map<String, dynamic> session) =>
          session['id'] == normalizedId,
    );

    if (sessions.length == initialLength) {
      return false;
    }

    return save(sessions);
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Returns the total number of stored sessions.
  static Future<int> count() async {
    final List<Map<String, dynamic>> sessions =
        await load();

    return sessions.length;
  }

  /// Returns the total duration of all stored sessions in minutes.
  static Future<int> totalLearningMinutes() async {
    final List<Map<String, dynamic>> sessions =
        await load();

    int total = 0;

    for (final Map<String, dynamic> session
        in sessions) {
      final dynamic duration =
          session['durationMinutes'];

      if (duration is num) {
        total += duration.toInt();
      }
    }

    return total;
  }

  /// Returns the total XP earned across stored sessions.
  static Future<int> totalXpEarned() async {
    final List<Map<String, dynamic>> sessions =
        await load();

    int total = 0;

    for (final Map<String, dynamic> session
        in sessions) {
      final dynamic xp =
          session['xpEarned'];

      if (xp is num) {
        total += xp.toInt();
      }
    }

    return total;
  }

  // ===========================================================================
  // RECENT
  // ===========================================================================

  /// Returns the most recent sessions.
  static Future<List<Map<String, dynamic>>>
      recent({
    int limit = 10,
  }) async {
    final int safeLimit =
        limit < 0 ? 0 : limit;

    final List<Map<String, dynamic>> sessions =
        await load();

    if (safeLimit >= sessions.length) {
      return sessions;
    }

    return sessions
        .take(safeLimit)
        .map(
          (Map<String, dynamic> session) =>
              Map<String, dynamic>.from(session),
        )
        .toList();
  }

  // ===========================================================================
  // EXISTENCE
  // ===========================================================================

  /// Returns whether at least one session is stored.
  static Future<bool> exists() async {
    return LocalStorage.containsKey(
      LocalStorage.sessionsKey,
    );
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  /// Deletes the complete local session history.
  ///
  /// This affects sessions only. Profile and progression data remain intact.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.sessionsKey,
    );
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  static List<Map<String, dynamic>> _normalizeSessions(
    List<Map<String, dynamic>> sessions,
  ) {
    final List<Map<String, dynamic>> normalized =
        sessions
            .map(_normalizeSession)
            .toList();

    _sortNewestFirst(normalized);

    if (normalized.length <= maxStoredSessions) {
      return normalized;
    }

    return normalized
        .take(maxStoredSessions)
        .toList();
  }

  static Map<String, dynamic> _normalizeSession(
    Map<String, dynamic> session,
  ) {
    final Map<String, dynamic> normalized =
        Map<String, dynamic>.from(session);

    final String id =
        _readString(normalized['id']) ??
            _createSessionId();

    final String createdAt =
        _readString(normalized['createdAt']) ??
            DateTime.now()
                .toUtc()
                .toIso8601String();

    normalized['id'] = id;
    normalized['createdAt'] = createdAt;

    normalized['durationMinutes'] =
        _readNonNegativeInt(
      normalized['durationMinutes'],
    );

    normalized['xpEarned'] =
        _readNonNegativeInt(
      normalized['xpEarned'],
    );

    normalized['completed'] =
        normalized['completed'] == true;

    normalized['tutor'] =
        _readString(normalized['tutor']);

    normalized['activity'] =
        _readString(normalized['activity']);

    return normalized;
  }

  // ===========================================================================
  // SORTING
  // ===========================================================================

  static void _sortNewestFirst(
    List<Map<String, dynamic>> sessions,
  ) {
    sessions.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final DateTime firstDate =
            _parseDate(first['createdAt']);

        final DateTime secondDate =
            _parseDate(second['createdAt']);

        return secondDate.compareTo(
          firstDate,
        );
      },
    );
  }

  // ===========================================================================
  // SAFE READERS
  // ===========================================================================

  static String? _readString(
    dynamic value,
  ) {
    if (value is String) {
      final String result =
          value.trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return null;
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

      return converted < 0 ? 0 : converted;
    }

    return 0;
  }

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value is String) {
      final DateTime? parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
      isUtc: true,
    );
  }

  // ===========================================================================
  // IDENTIFIER
  // ===========================================================================

  static String _createSessionId() {
    final int timestamp =
        DateTime.now()
            .toUtc()
            .microsecondsSinceEpoch;

    return 'session_$timestamp';
  }
}