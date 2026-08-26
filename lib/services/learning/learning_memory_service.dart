import '../../models/learning_memory_storage.dart';
import '../../models/learning_memory.dart';

/// High-level domain service for Eloqia learner memory.
///
/// [MemoryService] is the business-facing gateway for learner memory.
///
/// Architecture:
///
///     UI / AI / Learning Engine
///                 ↓
///           MemoryService
///                 ↓
///      LearningMemoryStorage
///                 ↓
///           LocalStorage
///
/// The service deliberately separates memory intelligence from persistence.
///
/// Responsibilities:
/// • Memory creation and persistence.
/// • Safe memory retrieval.
/// • Relevant-memory retrieval.
/// • Memory reinforcement.
/// • Memory usage tracking.
/// • Memory activation lifecycle.
/// • Memory expiration management.
/// • Memory search and filtering.
/// • Memory statistics.
/// • Input normalization.
/// • Structural validation.
///
/// Deliberately excluded:
/// • Flutter UI.
/// • Navigation.
/// • AI provider calls.
/// • Prompt generation.
/// • LLM inference.
/// • Embedding generation.
/// • Network synchronization.
/// • Lesson generation.
/// • XP calculation.
///
/// Future AI intelligence can consume this service without coupling itself
/// directly to the persistence layer.
class MemoryService {
  MemoryService._();

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  /// Maximum number of memories returned by a relevance query.
  static const int maxRetrievalLimit = 50;

  /// Maximum number of memories returned by a search.
  static const int maxSearchLimit = 100;

  // ===========================================================================
  // CREATION
  // ===========================================================================

  /// Creates and persists a new learner memory.
  ///
  /// The [id] must be unique.
  ///
  /// Empty textual values are normalized before persistence.
  ///
  /// Returns the persisted memory when successful.
  static Future<LearningMemory?> createMemory({
    required String id,
    required LearningMemoryType type,
    required LearningMemorySource source,
    required String content,
    String? tutorId,
    String? sourceSessionId,
    List<String> tags = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
    double confidence = 50.0,
    double importance = 50.0,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) async {
    final String normalizedId = id.trim();
    final String normalizedContent = content.trim();

    if (normalizedId.isEmpty || normalizedContent.isEmpty) {
      return null;
    }

    final LearningMemory memory = LearningMemory.create(
      id: normalizedId,
      type: type,
      source: source,
      content: normalizedContent,
      tutorId: _normalizeNullable(tutorId),
      sourceSessionId: _normalizeNullable(sourceSessionId),
      tags: _normalizeStringList(tags),
      metadata: _normalizeMetadata(metadata),
      confidence: _normalizeScore(confidence),
      importance: _normalizeScore(importance),
      createdAt: createdAt?.toUtc(),
      expiresAt: expiresAt?.toUtc(),
    );

    if (memory.validate().isNotEmpty) {
      return null;
    }

    final bool saved = await LearningMemoryStorage.saveMemory(memory);

    return saved ? memory : null;
  }

  /// Saves an already-created memory after validation.
  ///
  /// This is useful when the learning engine has already constructed
  /// a complete [LearningMemory] instance.
  static Future<LearningMemory?> saveMemory(LearningMemory memory) async {
    if (memory.validate().isNotEmpty) {
      return null;
    }

    final bool saved = await LearningMemoryStorage.saveMemory(memory);

    return saved ? memory : null;
  }

  /// Saves multiple memories in one persistence operation.
  ///
  /// Invalid memories are ignored by the persistence layer.
  static Future<bool> saveMemories(Iterable<LearningMemory> memories) async {
    final List<LearningMemory> validMemories = <LearningMemory>[];

    for (final LearningMemory memory in memories) {
      if (memory.validate().isEmpty) {
        validMemories.add(memory);
      }
    }

    if (validMemories.isEmpty) {
      return false;
    }

    return LearningMemoryStorage.saveMemories(validMemories);
  }

  // ===========================================================================
  // RETRIEVAL
  // ===========================================================================

  /// Retrieves one memory by its unique identifier.
  static Future<LearningMemory?> getMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return LearningMemoryStorage.getMemory(normalizedId);
  }

  /// Returns all currently usable memories.
  static Future<List<LearningMemory>> getActiveMemories() async {
    return LearningMemoryStorage.getActiveMemories();
  }

  /// Returns the complete local memory collection.
  ///
  /// Inactive and expired records are included.
  static Future<List<LearningMemory>> getAllMemories() async {
    return LearningMemoryStorage.getAllMemories();
  }

  /// Retrieves the most relevant memories for AI personalization.
  ///
  /// This is the primary retrieval entry point for future tutor intelligence.
  static Future<List<LearningMemory>> getRelevantMemories({
    int limit = 20,
  }) async {
    final int safeLimit = limit.clamp(1, maxRetrievalLimit);

    return LearningMemoryStorage.getRelevantMemories(limit: safeLimit);
  }

  /// Retrieves relevant memories associated with a specific tutor.
  static Future<List<LearningMemory>> getRelevantMemoriesForTutor(
    String tutorId, {
    int limit = 20,
  }) async {
    final String normalizedTutorId = tutorId.trim().toLowerCase();

    if (normalizedTutorId.isEmpty) {
      return const <LearningMemory>[];
    }

    final int safeLimit = limit.clamp(1, maxRetrievalLimit);

    final List<LearningMemory> memories =
        await LearningMemoryStorage.getByTutor(normalizedTutorId);

    if (memories.length <= safeLimit) {
      return memories;
    }

    return List<LearningMemory>.unmodifiable(memories.take(safeLimit));
  }

  // ===========================================================================
  // FILTERING
  // ===========================================================================

  /// Returns memories belonging to [type].
  static Future<List<LearningMemory>> getByType(LearningMemoryType type) async {
    return LearningMemoryStorage.getByType(type);
  }

  /// Returns memories belonging to any of [types].
  static Future<List<LearningMemory>> getByTypes(
    Iterable<LearningMemoryType> types,
  ) async {
    return LearningMemoryStorage.getByTypes(types);
  }

  /// Returns memories generated by [source].
  static Future<List<LearningMemory>> getBySource(
    LearningMemorySource source,
  ) async {
    return LearningMemoryStorage.getBySource(source);
  }

  /// Returns memories associated with [tutorId].
  static Future<List<LearningMemory>> getByTutor(String tutorId) async {
    return LearningMemoryStorage.getByTutor(tutorId);
  }

  /// Returns memories generated during [sessionId].
  static Future<List<LearningMemory>> getBySession(String sessionId) async {
    return LearningMemoryStorage.getBySession(sessionId);
  }

  /// Returns memories containing [tag].
  static Future<List<LearningMemory>> getByTag(String tag) async {
    return LearningMemoryStorage.getByTag(tag);
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  /// Searches active learner memories.
  ///
  /// The search is intentionally delegated to the storage layer so that
  /// retrieval behavior remains centralized and consistent.
  static Future<List<LearningMemory>> search(
    String query, {
    int limit = maxSearchLimit,
  }) async {
    final int safeLimit = limit.clamp(1, maxSearchLimit);

    return LearningMemoryStorage.search(query, limit: safeLimit);
  }

  // ===========================================================================
  // MEMORY REINFORCEMENT
  // ===========================================================================

  /// Reinforces an existing memory.
  ///
  /// Reinforcement indicates that a new observation supports the memory.
  ///
  /// Confidence and importance adjustments remain controlled by the
  /// [LearningMemory] domain model.
  static Future<LearningMemory?> reinforceMemory(
    String id, {
    double confidenceBoost = 5.0,
    double importanceBoost = 0.0,
    DateTime? at,
  }) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    if (!confidenceBoost.isFinite || !importanceBoost.isFinite) {
      return null;
    }

    return LearningMemoryStorage.reinforceMemory(
      normalizedId,
      confidenceBoost: confidenceBoost,
      importanceBoost: importanceBoost,
      at: at,
    );
  }

  /// Marks a memory as used by the learning engine.
  ///
  /// Usage tracking allows future retrieval systems to understand which
  /// memories are actually useful during learning.
  static Future<LearningMemory?> markMemoryUsed(
    String id, {
    DateTime? at,
  }) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return LearningMemoryStorage.markMemoryUsed(normalizedId, at: at);
  }

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Deactivates a memory without permanently deleting it.
  static Future<LearningMemory?> deactivateMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return LearningMemoryStorage.deactivateMemory(normalizedId);
  }

  /// Reactivates an existing memory.
  static Future<LearningMemory?> activateMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return LearningMemoryStorage.activateMemory(normalizedId);
  }

  /// Removes all naturally expired memories.
  ///
  /// Returns the number of successfully removed records.
  static Future<int> purgeExpired() async {
    return LearningMemoryStorage.purgeExpired();
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one memory permanently.
  static Future<bool> deleteMemory(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    return LearningMemoryStorage.deleteMemory(normalizedId);
  }

  /// Deletes every memory belonging to [type].
  static Future<bool> deleteByType(LearningMemoryType type) async {
    return LearningMemoryStorage.deleteByType(type);
  }

  /// Permanently clears the learner memory store.
  ///
  /// Other Eloqia persistence domains remain untouched.
  static Future<bool> clear() async {
    return LearningMemoryStorage.clear();
  }

  // ===========================================================================
  // COUNTS
  // ===========================================================================

  /// Returns the total number of stored memories.
  static Future<int> count() async {
    return LearningMemoryStorage.count();
  }

  /// Returns the number of currently usable memories.
  static Future<int> activeCount() async {
    return LearningMemoryStorage.activeCount();
  }

  /// Returns the number of expired memories.
  static Future<int> expiredCount() async {
    return LearningMemoryStorage.expiredCount();
  }

  /// Returns whether at least one usable learner memory exists.
  static Future<bool> exists() async {
    return LearningMemoryStorage.exists();
  }

  // ===========================================================================
  // ANALYTICS
  // ===========================================================================

  /// Returns a compact analytics snapshot of learner memory.
  ///
  /// This method intentionally exposes aggregate information rather than raw
  /// memory records.
  static Future<Map<String, dynamic>> getAnalyticsSnapshot() async {
    final Map<String, dynamic> snapshot =
        await LearningMemoryStorage.getAnalyticsSnapshot();

    return Map<String, dynamic>.unmodifiable(snapshot);
  }

  // ===========================================================================
  // MAINTENANCE
  // ===========================================================================

  /// Performs lightweight local memory maintenance.
  ///
  /// Currently this removes naturally expired records.
  ///
  /// The method is intentionally centralized so future maintenance tasks
  /// can be added without changing consumers.
  static Future<int> maintain() async {
    return purgeExpired();
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  /// Normalizes nullable textual values.
  static String? _normalizeNullable(String? value) {
    final String normalized = value?.trim() ?? '';

    return normalized.isEmpty ? null : normalized;
  }

  /// Normalizes a score to the canonical 0–100 range.
  static double _normalizeScore(double value) {
    if (!value.isFinite) {
      return 0.0;
    }

    return value.clamp(0.0, 100.0).toDouble();
  }

  /// Normalizes string collections.
  ///
  /// Empty values are discarded and duplicates are removed while preserving
  /// the first occurrence.
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

  /// Normalizes metadata while preserving its dynamic values.
  ///
  /// Keys are trimmed and empty keys are ignored.
  /// Nested values are deliberately preserved because metadata belongs to
  /// the memory domain rather than the service layer.
  static Map<String, dynamic> _normalizeMetadata(
    Map<String, dynamic> metadata,
  ) {
    final Map<String, dynamic> normalized = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in metadata.entries) {
      final String key = entry.key.trim();

      if (key.isEmpty) {
        continue;
      }

      normalized[key] = entry.value;
    }

    return Map<String, dynamic>.unmodifiable(normalized);
  }
}
