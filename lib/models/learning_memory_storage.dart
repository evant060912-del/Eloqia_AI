import '../core/storage/local_storage.dart';
import 'learning_memory.dart';

/// Premium persistence infrastructure for Eloqia learner memory.
///
/// [LearningMemoryStorage] is the persistence boundary between the
/// learner-memory domain and the local storage engine.
///
/// Architecture:
///
///     LearningMemory
///           ↓
///     LearningMemoryStorage
///           ↓
///     LocalStorage
///           ↓
///     SharedPreferences
///
/// Responsibilities:
/// • Persistent memory lifecycle.
/// • Defensive deserialization.
/// • Memory deduplication.
/// • Memory reinforcement.
/// • Relevance-aware retrieval.
/// • Filtering and search.
/// • Expiration management.
/// • Local analytics.
/// • Bounded local history.
/// • Future synchronization readiness.
///
/// Deliberately excluded:
/// • Flutter UI.
/// • AI provider calls.
/// • Prompt generation.
/// • Navigation.
/// • XP calculation.
/// • Business-level learning decisions.
///
/// Higher-level memory intelligence belongs in a future memory engine.
class LearningMemoryStorage {
  LearningMemoryStorage._();

  // ===========================================================================
  // STORAGE CONTRACT
  // ===========================================================================

  /// Current local memory persistence schema.
  static const int storageVersion = 1;

  /// Maximum number of memories retained locally.
  ///
  /// This keeps local storage bounded while allowing future cloud storage
  /// to maintain a substantially larger long-term memory.
  static const int maxStoredMemories = 500;

  /// Maximum number of results returned by a single query.
  static const int maxQueryLimit = 100;

  static const String _versionKey = 'version';
  static const String _memoriesKey = 'memories';

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Loads the complete normalized local memory collection.
  static Future<List<LearningMemory>> load() async {
    final Map<String, dynamic>? raw = await LocalStorage.readJsonMap(
      LocalStorage.memoryKey,
    );

    return _decodeAndNormalize(raw);
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Creates or replaces one memory.
  ///
  /// Memories are uniquely identified by their [LearningMemory.id].
  static Future<bool> saveMemory(LearningMemory memory) async {
    if (memory.validate().isNotEmpty) {
      return false;
    }

    final List<LearningMemory> memories = await load();

    final int index = memories.indexWhere(
      (LearningMemory item) => item.id == memory.id,
    );

    if (index >= 0) {
      memories[index] = memory;
    } else {
      memories.add(memory);
    }

    _sortByRelevance(memories);

    return _persistMemories(_trimHistory(memories));
  }

  /// Creates or replaces multiple memories in one persistence operation.
  static Future<bool> saveMemories(
    Iterable<LearningMemory> memoriesToSave,
  ) async {
    final List<LearningMemory> existing = await load();

    final Map<String, LearningMemory> indexed = <String, LearningMemory>{
      for (final LearningMemory memory in existing) memory.id: memory,
    };

    for (final LearningMemory memory in memoriesToSave) {
      if (memory.validate().isEmpty) {
        indexed[memory.id] = memory;
      }
    }

    final List<LearningMemory> merged = indexed.values.toList();

    _sortByRelevance(merged);

    return _persistMemories(_trimHistory(merged));
  }

  // ===========================================================================
  // READ
  // ===========================================================================

  /// Retrieves a memory by its unique identifier.
  static Future<LearningMemory?> getMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final List<LearningMemory> memories = await load();

    for (final LearningMemory memory in memories) {
      if (memory.id == normalizedId) {
        return memory;
      }
    }

    return null;
  }

  /// Returns all active, usable memories.
  static Future<List<LearningMemory>> getActiveMemories() async {
    final List<LearningMemory> memories = await load();

    final List<LearningMemory> active = memories
        .where((LearningMemory memory) => memory.isUsable)
        .toList();

    _sortByRelevance(active);

    return List<LearningMemory>.unmodifiable(active);
  }

  /// Returns all memories, including inactive and expired records.
  ///
  /// Useful for diagnostics, analytics and future memory management screens.
  static Future<List<LearningMemory>> getAllMemories() async {
    final List<LearningMemory> memories = await load();

    _sortByUpdatedAt(memories);

    return List<LearningMemory>.unmodifiable(memories);
  }

  /// Returns the most relevant active memories.
  ///
  /// This is intended to become the primary retrieval primitive for
  /// future AI personalization.
  static Future<List<LearningMemory>> getRelevantMemories({
    int limit = 20,
  }) async {
    final int safeLimit = limit.clamp(1, maxQueryLimit);

    final List<LearningMemory> memories = await getActiveMemories();

    if (memories.length <= safeLimit) {
      return memories;
    }

    return List<LearningMemory>.unmodifiable(memories.take(safeLimit));
  }

  // ===========================================================================
  // FILTERING — TYPE
  // ===========================================================================

  /// Returns memories belonging to a specific type.
  static Future<List<LearningMemory>> getByType(LearningMemoryType type) async {
    return _filter((LearningMemory memory) => memory.type == type);
  }

  /// Returns all memories matching one of several types.
  static Future<List<LearningMemory>> getByTypes(
    Iterable<LearningMemoryType> types,
  ) async {
    final Set<LearningMemoryType> allowed = types.toSet();

    if (allowed.isEmpty) {
      return const <LearningMemory>[];
    }

    return _filter((LearningMemory memory) => allowed.contains(memory.type));
  }

  // ===========================================================================
  // FILTERING — SOURCE
  // ===========================================================================

  /// Returns memories created by a specific source.
  static Future<List<LearningMemory>> getBySource(
    LearningMemorySource source,
  ) async {
    return _filter((LearningMemory memory) => memory.source == source);
  }

  // ===========================================================================
  // FILTERING — TUTOR
  // ===========================================================================

  /// Returns memories associated with a tutor.
  static Future<List<LearningMemory>> getByTutor(String tutorId) async {
    final String normalized = tutorId.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const <LearningMemory>[];
    }

    return _filter(
      (LearningMemory memory) =>
          memory.tutorId?.trim().toLowerCase() == normalized,
    );
  }

  // ===========================================================================
  // FILTERING — SESSION
  // ===========================================================================

  /// Returns memories generated by a specific learning session.
  static Future<List<LearningMemory>> getBySession(String sessionId) async {
    final String normalized = sessionId.trim();

    if (normalized.isEmpty) {
      return const <LearningMemory>[];
    }

    return _filter(
      (LearningMemory memory) => memory.sourceSessionId == normalized,
    );
  }

  // ===========================================================================
  // TAGS
  // ===========================================================================

  /// Returns memories containing a specific tag.
  static Future<List<LearningMemory>> getByTag(String tag) async {
    final String normalized = tag.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const <LearningMemory>[];
    }

    return _filter(
      (LearningMemory memory) =>
          memory.tags.any((String item) => item.toLowerCase() == normalized),
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  /// Searches active memory content and contextual metadata.
  ///
  /// Search fields:
  /// • memory content
  /// • tags
  /// • tutor
  /// • source session
  /// • metadata string values
  static Future<List<LearningMemory>> search(
    String query, {
    int limit = maxQueryLimit,
  }) async {
    final String normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return getRelevantMemories(limit: limit);
    }

    final int safeLimit = limit.clamp(1, maxQueryLimit);

    final List<LearningMemory> memories = await getActiveMemories();

    final List<LearningMemory> matches = memories.where((
      LearningMemory memory,
    ) {
      final List<String> values = <String>[
        memory.id,
        memory.content,
        memory.type.name,
        memory.source.name,
        memory.tutorId ?? '',
        memory.sourceSessionId ?? '',
        ...memory.tags,
        ..._metadataSearchValues(memory.metadata),
      ];

      return values.any(
        (String value) => value.toLowerCase().contains(normalized),
      );
    }).toList();

    if (matches.length <= safeLimit) {
      return List<LearningMemory>.unmodifiable(matches);
    }

    return List<LearningMemory>.unmodifiable(matches.take(safeLimit));
  }

  // ===========================================================================
  // REINFORCEMENT
  // ===========================================================================

  /// Reinforces an existing memory.
  ///
  /// Reinforcement increases confidence and records another observation
  /// supporting the memory.
  static Future<LearningMemory?> reinforceMemory(
    String id, {
    double confidenceBoost = 5.0,
    double importanceBoost = 0.0,
    DateTime? at,
  }) async {
    final LearningMemory? memory = await getMemory(id);

    if (memory == null) {
      return null;
    }

    final LearningMemory updated = memory.reinforce(
      confidenceBoost: confidenceBoost,
      importanceBoost: importanceBoost,
      at: at,
    );

    final bool saved = await saveMemory(updated);

    return saved ? updated : null;
  }

  /// Marks a memory as used by the learning engine.
  static Future<LearningMemory?> markMemoryUsed(
    String id, {
    DateTime? at,
  }) async {
    final LearningMemory? memory = await getMemory(id);

    if (memory == null) {
      return null;
    }

    final LearningMemory updated = memory.markUsed(at: at);

    final bool saved = await saveMemory(updated);

    return saved ? updated : null;
  }

  // ===========================================================================
  // ACTIVATION
  // ===========================================================================

  /// Deactivates a memory without deleting it.
  static Future<LearningMemory?> deactivateMemory(String id) async {
    final LearningMemory? memory = await getMemory(id);

    if (memory == null) {
      return null;
    }

    final LearningMemory updated = memory.deactivate();

    final bool saved = await saveMemory(updated);

    return saved ? updated : null;
  }

  /// Reactivates an existing memory.
  static Future<LearningMemory?> activateMemory(String id) async {
    final LearningMemory? memory = await getMemory(id);

    if (memory == null) {
      return null;
    }

    final LearningMemory updated = memory.activate();

    final bool saved = await saveMemory(updated);

    return saved ? updated : null;
  }

  // ===========================================================================
  // EXPIRATION
  // ===========================================================================

  /// Removes memories that have naturally expired.
  ///
  /// Returns the number of removed memories.
  static Future<int> purgeExpired() async {
    final List<LearningMemory> memories = await load();

    final int originalLength = memories.length;

    memories.removeWhere((LearningMemory memory) => memory.isExpired);

    if (memories.length == originalLength) {
      return 0;
    }

    final bool saved = await _persistMemories(memories);

    return saved ? originalLength - memories.length : 0;
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one memory by ID.
  static Future<bool> deleteMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final List<LearningMemory> memories = await load();

    final int originalLength = memories.length;

    memories.removeWhere((LearningMemory memory) => memory.id == normalizedId);

    if (memories.length == originalLength) {
      return false;
    }

    return _persistMemories(memories);
  }

  /// Deletes all memories of a specific type.
  static Future<bool> deleteByType(LearningMemoryType type) async {
    final List<LearningMemory> memories = await load();

    memories.removeWhere((LearningMemory memory) => memory.type == type);

    return _persistMemories(memories);
  }

  /// Completely clears learner memory.
  ///
  /// Other Eloqia storage domains remain untouched.
  static Future<bool> clear() async {
    return LocalStorage.delete(LocalStorage.memoryKey);
  }

  // ===========================================================================
  // COUNTS
  // ===========================================================================

  /// Returns the total number of stored memories.
  static Future<int> count() async {
    final List<LearningMemory> memories = await load();

    return memories.length;
  }

  /// Returns the number of currently usable memories.
  static Future<int> activeCount() async {
    final List<LearningMemory> memories = await getActiveMemories();

    return memories.length;
  }

  /// Returns the number of expired memories.
  static Future<int> expiredCount() async {
    final List<LearningMemory> memories = await load();

    return memories.where((LearningMemory memory) => memory.isExpired).length;
  }

  /// Returns whether at least one usable memory exists.
  static Future<bool> exists() async {
    return await activeCount() > 0;
  }

  // ===========================================================================
  // ANALYTICS
  // ===========================================================================

  /// Returns an aggregate snapshot of learner memory.
  ///
  /// This deliberately returns analytics rather than raw memory records,
  /// allowing dashboards and future AI services to consume compact data.
  static Future<Map<String, dynamic>> getAnalyticsSnapshot() async {
    final List<LearningMemory> memories = await load();

    int active = 0;
    int expired = 0;
    int totalReinforcements = 0;
    int totalUsage = 0;

    double confidenceSum = 0.0;
    double importanceSum = 0.0;

    final Map<String, int> typeCounts = <String, int>{};

    final Map<String, int> sourceCounts = <String, int>{};

    for (final LearningMemory memory in memories) {
      if (memory.isUsable) {
        active++;
      }

      if (memory.isExpired) {
        expired++;
      }

      totalReinforcements += memory.reinforcementCount;

      totalUsage += memory.usageCount;

      confidenceSum += memory.confidence;
      importanceSum += memory.importance;

      final String type = memory.type.name;

      typeCounts[type] = (typeCounts[type] ?? 0) + 1;

      final String source = memory.source.name;

      sourceCounts[source] = (sourceCounts[source] ?? 0) + 1;
    }

    final int total = memories.length;

    return <String, dynamic>{
      'version': storageVersion,
      'totalMemories': total,
      'activeMemories': active,
      'expiredMemories': expired,
      'inactiveMemories': total - active - expired,
      'totalReinforcements': totalReinforcements,
      'totalUsage': totalUsage,
      'averageConfidence': total == 0 ? 0.0 : confidenceSum / total,
      'averageImportance': total == 0 ? 0.0 : importanceSum / total,
      'typeCounts': typeCounts,
      'sourceCounts': sourceCounts,
    };
  }

  // ===========================================================================
  // INTERNAL FILTER ENGINE
  // ===========================================================================

  static Future<List<LearningMemory>> _filter(
    bool Function(LearningMemory memory) predicate,
  ) async {
    final List<LearningMemory> memories = await load();

    final List<LearningMemory> result = memories
        .where(predicate)
        .where((LearningMemory memory) => memory.isUsable)
        .toList();

    _sortByRelevance(result);

    return List<LearningMemory>.unmodifiable(result);
  }

  // ===========================================================================
  // INTERNAL PERSISTENCE
  // ===========================================================================

  static Future<bool> _persistMemories(List<LearningMemory> memories) async {
    _sortByRelevance(memories);

    final List<LearningMemory> trimmed = _trimHistory(memories);

    final Map<String, dynamic> payload = <String, dynamic>{
      _versionKey: storageVersion,
      _memoriesKey: trimmed
          .map((LearningMemory memory) => memory.toJson())
          .toList(),
    };

    return LocalStorage.saveJson(LocalStorage.memoryKey, payload);
  }

  // ===========================================================================
  // INTERNAL DECODING
  // ===========================================================================

  /// Decodes persisted memory records defensively.
  ///
  /// One corrupted record never invalidates the complete memory store.
  static List<LearningMemory> _decodeAndNormalize(
    Map<String, dynamic>? source,
  ) {
    if (source == null) {
      return <LearningMemory>[];
    }

    final dynamic rawMemories = source[_memoriesKey];

    if (rawMemories is! List) {
      return <LearningMemory>[];
    }

    final Map<String, LearningMemory> unique = <String, LearningMemory>{};

    for (final dynamic rawMemory in rawMemories) {
      if (rawMemory is! Map) {
        continue;
      }

      try {
        final LearningMemory memory = LearningMemory.fromJson(
          Map<String, dynamic>.from(rawMemory),
        );

        if (memory.validate().isEmpty) {
          unique[memory.id] = memory;
        }
      } catch (_) {
        // Corrupted memory records are intentionally isolated.
      }
    }

    final List<LearningMemory> memories = unique.values.toList();

    _sortByRelevance(memories);

    return _trimHistory(memories);
  }

  // ===========================================================================
  // HISTORY MANAGEMENT
  // ===========================================================================

  static List<LearningMemory> _trimHistory(List<LearningMemory> memories) {
    if (memories.length <= maxStoredMemories) {
      return memories;
    }

    return memories.take(maxStoredMemories).toList();
  }

  // ===========================================================================
  // SORTING
  // ===========================================================================

  /// Sorts memories by calculated relevance.
  ///
  /// Ties are resolved using confidence, importance and recency.
  static void _sortByRelevance(List<LearningMemory> memories) {
    memories.sort((LearningMemory first, LearningMemory second) {
      final int relevanceComparison = second.relevanceScore.compareTo(
        first.relevanceScore,
      );

      if (relevanceComparison != 0) {
        return relevanceComparison;
      }

      final int confidenceComparison = second.confidence.compareTo(
        first.confidence,
      );

      if (confidenceComparison != 0) {
        return confidenceComparison;
      }

      final int importanceComparison = second.importance.compareTo(
        first.importance,
      );

      if (importanceComparison != 0) {
        return importanceComparison;
      }

      return second.updatedAt.compareTo(first.updatedAt);
    });
  }

  /// Sorts memories from most recently updated to oldest.
  static void _sortByUpdatedAt(List<LearningMemory> memories) {
    memories.sort(
      (LearningMemory first, LearningMemory second) =>
          second.updatedAt.compareTo(first.updatedAt),
    );
  }

  // ===========================================================================
  // METADATA SEARCH
  // ===========================================================================

  static List<String> _metadataSearchValues(Map<String, dynamic> metadata) {
    final List<String> values = <String>[];

    for (final dynamic value in metadata.values) {
      if (value is String) {
        values.add(value);
      }
    }

    return values;
  }
}
