import 'local_storage.dart';

/// Persistent memory layer for Eloqia's AI tutors.
///
/// This service stores meaningful learner information discovered
/// throughout the learning journey.
///
/// Memory is intentionally separated from `LearningProfile`:
///
/// - LearningProfile = stable learner configuration.
/// - MemoryStorage = evolving knowledge discovered through interactions.
///
/// This separation allows Mia to become progressively more personalized
/// without turning the learner profile into an unmaintainable data store.
///
/// Architecture:
///
///     AI Tutor
///         ↓
///     MemoryStorage
///         ↓
///     LocalStorage
///         ↓
///     SharedPreferences
///
/// The storage format is versioned so future migrations can be introduced
/// without forcing changes to the domain model.
class MemoryStorage {
  MemoryStorage._();

  // ===========================================================================
  // STORAGE CONFIGURATION
  // ===========================================================================

  /// Current version of the memory persistence format.
  static const int storageVersion = 1;

  /// Maximum number of memories retained locally.
  ///
  /// The limit keeps local persistence predictable while leaving enough
  /// capacity for a rich long-term learning history.
  static const int maxStoredMemories = 1000;

  // ===========================================================================
  // MEMORY CATEGORIES
  // ===========================================================================

  static const String preferenceCategory = 'preference';

  static const String learningCategory = 'learning';

  static const String interestCategory = 'interest';

  static const String contextCategory = 'context';

  static const String pronunciationCategory =
      'pronunciation';

  static const String grammarCategory = 'grammar';

  static const String vocabularyCategory = 'vocabulary';

  static const String achievementCategory =
      'achievement';

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Loads all persisted memories.
  ///
  /// Memories are returned from newest to oldest.
  static Future<List<Map<String, dynamic>>> load() async {
    final Map<String, dynamic>? data =
        await LocalStorage.readJsonMap(
      LocalStorage.memoryKey,
    );

    if (data == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic rawMemories =
        data['memories'];

    if (rawMemories is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> memories =
        <Map<String, dynamic>>[];

    for (final dynamic item in rawMemories) {
      if (item is Map) {
        memories.add(
          _normalizeMemory(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    _sortNewestFirst(memories);

    return memories;
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Saves the complete memory collection.
  static Future<bool> save(
    List<Map<String, dynamic>> memories,
  ) async {
    final List<Map<String, dynamic>> normalized =
        _normalizeMemories(memories);

    return LocalStorage.saveJson(
      LocalStorage.memoryKey,
      <String, dynamic>{
        'version': storageVersion,
        'memories': normalized,
      },
    );
  }

  // ===========================================================================
  // ADD
  // ===========================================================================

  /// Adds a new memory to Mia's persistent memory.
  ///
  /// A unique identifier and timestamps are generated automatically.
  ///
  /// Duplicate memories with the same category and normalized content
  /// are updated instead of being stored repeatedly.
  static Future<bool> add(
    Map<String, dynamic> memory,
  ) async {
    final Map<String, dynamic> normalized =
        _normalizeMemory(memory);

    final List<Map<String, dynamic>> memories =
        await load();

    final int existingIndex =
        _findEquivalentMemoryIndex(
      memories,
      normalized,
    );

    if (existingIndex >= 0) {
      final Map<String, dynamic> existing =
          memories[existingIndex];

      final int occurrences =
          _readNonNegativeInt(
            existing['occurrences'],
          );

      existing['occurrences'] =
          occurrences + 1;

      existing['lastUsedAt'] =
          DateTime.now()
              .toUtc()
              .toIso8601String();

      final int existingImportance =
          _readImportance(
            existing['importance'],
          );

      final int newImportance =
          _readImportance(
            normalized['importance'],
          );

      if (newImportance > existingImportance) {
        existing['importance'] =
            newImportance;
      }

      memories[existingIndex] = existing;

      return save(memories);
    }

    memories.insert(
      0,
      normalized,
    );

    return save(memories);
  }

  // ===========================================================================
  // FIND
  // ===========================================================================

  /// Finds a memory using its unique identifier.
  static Future<Map<String, dynamic>?> findById(
    String memoryId,
  ) async {
    final String id =
        memoryId.trim();

    if (id.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> memories =
        await load();

    for (final Map<String, dynamic> memory
        in memories) {
      if (memory['id'] == id) {
        return Map<String, dynamic>.from(
          memory,
        );
      }
    }

    return null;
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  /// Searches memories by content.
  ///
  /// The search is case-insensitive and accent-insensitive where possible
  /// through the normalized representation.
  static Future<List<Map<String, dynamic>>>
      search(
    String query,
  ) async {
    final String normalizedQuery =
        _normalizeText(query);

    if (normalizedQuery.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> memories =
        await load();

    return memories.where(
      (Map<String, dynamic> memory) {
        final String content =
            _normalizeText(
          _readString(memory['content']) ?? '',
        );

        final String category =
            _normalizeText(
          _readString(memory['category']) ?? '',
        );

        final String tags =
            _normalizeText(
          _readStringList(memory['tags'])
              .join(' '),
        );

        return content.contains(normalizedQuery) ||
            category.contains(normalizedQuery) ||
            tags.contains(normalizedQuery);
      },
    ).toList();
  }

  // ===========================================================================
  // CATEGORY
  // ===========================================================================

  /// Returns all memories belonging to a category.
  static Future<List<Map<String, dynamic>>>
      byCategory(
    String category,
  ) async {
    final String normalizedCategory =
        _normalizeText(category);

    if (normalizedCategory.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> memories =
        await load();

    return memories.where(
      (Map<String, dynamic> memory) =>
          _normalizeText(
            _readString(memory['category']) ?? '',
          ) ==
          normalizedCategory,
    ).toList();
  }

  // ===========================================================================
  // IMPORTANT MEMORIES
  // ===========================================================================

  /// Returns memories whose importance reaches the requested threshold.
  static Future<List<Map<String, dynamic>>>
      important({
    int minimumImportance = 4,
  }) async {
    final int threshold =
        minimumImportance.clamp(1, 5);

    final List<Map<String, dynamic>> memories =
        await load();

    return memories.where(
      (Map<String, dynamic> memory) =>
          _readImportance(
            memory['importance'],
          ) >=
          threshold,
    ).toList();
  }

  // ===========================================================================
  // RECENT MEMORIES
  // ===========================================================================

  /// Returns the most recently created memories.
  static Future<List<Map<String, dynamic>>>
      recent({
    int limit = 20,
  }) async {
    final int safeLimit =
        limit < 0 ? 0 : limit;

    final List<Map<String, dynamic>> memories =
        await load();

    if (safeLimit >= memories.length) {
      return memories;
    }

    return memories
        .take(safeLimit)
        .map(
          (Map<String, dynamic> memory) =>
              Map<String, dynamic>.from(memory),
        )
        .toList();
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Updates an existing memory.
  static Future<bool> update(
    String memoryId,
    Map<String, dynamic> updates,
  ) async {
    final String id =
        memoryId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> memories =
        await load();

    final int index = memories.indexWhere(
      (Map<String, dynamic> memory) =>
          memory['id'] == id,
    );

    if (index == -1) {
      return false;
    }

    final Map<String, dynamic> updated =
        Map<String, dynamic>.from(
      memories[index],
    );

    updated.addAll(updates);
    updated['id'] = id;

    memories[index] =
        _normalizeMemory(updated);

    return save(memories);
  }

  // ===========================================================================
  // MARK AS USED
  // ===========================================================================

  /// Marks a memory as recently used by the tutor.
  ///
  /// Usage count is incremented and the last-used timestamp is refreshed.
  static Future<bool> markAsUsed(
    String memoryId,
  ) async {
    final String id =
        memoryId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> memories =
        await load();

    final int index = memories.indexWhere(
      (Map<String, dynamic> memory) =>
          memory['id'] == id,
    );

    if (index == -1) {
      return false;
    }

    final Map<String, dynamic> memory =
        memories[index];

    memory['occurrences'] =
        _readNonNegativeInt(
          memory['occurrences'],
        ) +
        1;

    memory['lastUsedAt'] =
        DateTime.now()
            .toUtc()
            .toIso8601String();

    memories[index] = memory;

    return save(memories);
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Deletes one memory.
  static Future<bool> delete(
    String memoryId,
  ) async {
    final String id =
        memoryId.trim();

    if (id.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> memories =
        await load();

    final int initialLength =
        memories.length;

    memories.removeWhere(
      (Map<String, dynamic> memory) =>
          memory['id'] == id,
    );

    if (memories.length == initialLength) {
      return false;
    }

    return save(memories);
  }

  // ===========================================================================
  // STATISTICS
  // ===========================================================================

  /// Returns the total number of stored memories.
  static Future<int> count() async {
    final List<Map<String, dynamic>> memories =
        await load();

    return memories.length;
  }

  /// Returns the number of memories in a category.
  static Future<int> countByCategory(
    String category,
  ) async {
    final List<Map<String, dynamic>> memories =
        await byCategory(category);

    return memories.length;
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  /// Completely clears Mia's local memory.
  ///
  /// This does not affect the learner profile, progression or sessions.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.memoryKey,
    );
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  static List<Map<String, dynamic>> _normalizeMemories(
    List<Map<String, dynamic>> memories,
  ) {
    final List<Map<String, dynamic>> normalized =
        memories
            .map(_normalizeMemory)
            .toList();

    _sortNewestFirst(normalized);

    if (normalized.length <= maxStoredMemories) {
      return normalized;
    }

    return normalized
        .take(maxStoredMemories)
        .toList();
  }

  static Map<String, dynamic> _normalizeMemory(
    Map<String, dynamic> memory,
  ) {
    final Map<String, dynamic> normalized =
        Map<String, dynamic>.from(memory);

    normalized['id'] =
        _readString(normalized['id']) ??
            _createMemoryId();

    normalized['category'] =
        _readString(normalized['category']) ??
            contextCategory;

    normalized['content'] =
        _readString(normalized['content']) ??
            '';

    normalized['importance'] =
        _readImportance(
      normalized['importance'],
    );

    normalized['occurrences'] =
        _readNonNegativeInt(
      normalized['occurrences'],
    );

    normalized['createdAt'] =
        _readString(normalized['createdAt']) ??
            DateTime.now()
                .toUtc()
                .toIso8601String();

    normalized['lastUsedAt'] =
        _readString(normalized['lastUsedAt']) ??
            normalized['createdAt'];

    normalized['tags'] =
        _readStringList(
      normalized['tags'],
    );

    normalized['tutor'] =
        _readString(normalized['tutor']);

    normalized['source'] =
        _readString(normalized['source']);

    return normalized;
  }

  // ===========================================================================
  // DUPLICATE DETECTION
  // ===========================================================================

  static int _findEquivalentMemoryIndex(
    List<Map<String, dynamic>> memories,
    Map<String, dynamic> candidate,
  ) {
    final String candidateCategory =
        _normalizeText(
      candidate['category'] as String,
    );

    final String candidateContent =
        _normalizeText(
      candidate['content'] as String,
    );

    for (int index = 0;
        index < memories.length;
        index++) {
      final Map<String, dynamic> memory =
          memories[index];

      final String category =
          _normalizeText(
        _readString(memory['category']) ?? '',
      );

      final String content =
          _normalizeText(
        _readString(memory['content']) ?? '',
      );

      if (category == candidateCategory &&
          content == candidateContent) {
        return index;
      }
    }

    return -1;
  }

  // ===========================================================================
  // SORTING
  // ===========================================================================

  static void _sortNewestFirst(
    List<Map<String, dynamic>> memories,
  ) {
    memories.sort(
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

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .whereType<String>()
        .map(
          (String item) => item.trim(),
        )
        .where(
          (String item) => item.isNotEmpty,
        )
        .toList();
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

  static int _readImportance(
    dynamic value,
  ) {
    final int importance =
        _readNonNegativeInt(value);

    return importance.clamp(1, 5);
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
  // TEXT NORMALIZATION
  // ===========================================================================

  static String _normalizeText(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase();
  }

  // ===========================================================================
  // IDENTIFIER
  // ===========================================================================

  static String _createMemoryId() {
    final int timestamp =
        DateTime.now()
            .toUtc()
            .microsecondsSinceEpoch;

    return 'memory_$timestamp';
  }
}