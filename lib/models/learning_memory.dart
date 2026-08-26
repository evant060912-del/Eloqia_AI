/// Represents one persistent piece of learner memory in Eloqia.
///
/// A [LearningMemory] is a durable observation, preference, fact,
/// tendency or learning insight that can improve future personalization.
///
/// The model is intentionally independent from:
/// • Flutter
/// • persistence
/// • AI providers
/// • networking
/// • tutor implementations
///
/// Architecture:
///
///     LearningMemory
///          ↓
///     LearningMemoryStorage
///          ↓
///     LocalStorage
///          ↓
///     SharedPreferences
///
/// Future evolution:
///
///     Local memory
///          ↓
///     Memory engine
///          ↓
///     Mia
///          ↓
///     FastAPI
///          ↓
///     PostgreSQL
///
/// The model is designed to remain stable while Eloqia evolves
/// into a long-term adaptive learning platform.
class LearningMemory {
  // ===========================================================================
  // IDENTITY
  // ===========================================================================

  /// Unique identifier of this memory.
  final String id;

  /// Optional learner identifier for future authentication and synchronization.
  final String? learnerId;

  // ===========================================================================
  // MEMORY CONTENT
  // ===========================================================================

  /// Human-readable memory content.
  ///
  /// Example:
  /// "The learner prefers American English pronunciation."
  final String content;

  /// Structured category of this memory.
  final LearningMemoryType type;

  /// Origin of the memory.
  final LearningMemorySource source;

  // ===========================================================================
  // INTELLIGENCE
  // ===========================================================================

  /// Importance of this memory from 0 to 100.
  final double importance;

  /// Confidence that this memory is accurate from 0 to 100.
  final double confidence;

  /// Number of times this memory has been reinforced.
  final int reinforcementCount;

  /// Number of times this memory has been referenced.
  final int usageCount;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// When the memory was created.
  final DateTime createdAt;

  /// When the memory was last updated.
  final DateTime updatedAt;

  /// When the memory was last used by the learning system.
  final DateTime? lastUsedAt;

  /// Optional expiration date.
  ///
  /// Temporary memories can therefore naturally disappear
  /// without affecting permanent learner knowledge.
  final DateTime? expiresAt;

  /// Whether this memory is currently active.
  final bool active;

  // ===========================================================================
  // CONTEXT
  // ===========================================================================

  /// Optional session that generated or reinforced this memory.
  final String? sourceSessionId;

  /// Optional tutor associated with the memory.
  final String? tutorId;

  /// Tags used for fast semantic filtering.
  final List<String> tags;

  /// Additional structured metadata.
  final Map<String, dynamic> metadata;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const LearningMemory({
    required this.id,
    this.learnerId,
    required this.content,
    required this.type,
    required this.source,
    this.importance = 50.0,
    this.confidence = 50.0,
    this.reinforcementCount = 0,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.expiresAt,
    this.active = true,
    this.sourceSessionId,
    this.tutorId,
    this.tags = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  // ===========================================================================
  // FACTORY
  // ===========================================================================

  /// Creates a new active memory.
  factory LearningMemory.create({
    required String id,
    required String content,
    LearningMemoryType type =
        LearningMemoryType.observation,
    LearningMemorySource source =
        LearningMemorySource.ai,
    String? learnerId,
    double importance = 50.0,
    double confidence = 50.0,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? sourceSessionId,
    String? tutorId,
    List<String> tags = const <String>[],
    Map<String, dynamic> metadata =
        const <String, dynamic>{},
  }) {
    final DateTime now =
        (createdAt ?? DateTime.now()).toUtc();

    return LearningMemory(
      id: id.trim(),
      learnerId: learnerId,
      content: content.trim(),
      type: type,
      source: source,
      importance: _clampPercentage(importance),
      confidence: _clampPercentage(confidence),
      reinforcementCount: 0,
      usageCount: 0,
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt?.toUtc(),
      sourceSessionId: sourceSessionId,
      tutorId: tutorId,
      tags: _normalizeStringList(tags),
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(metadata),
      ),
    );
  }

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// Whether this memory has expired.
  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }

    return !DateTime.now()
        .toUtc()
        .isBefore(expiresAt!);
  }

  /// Whether this memory can currently be used.
  bool get isUsable =>
      active && !isExpired && content.trim().isNotEmpty;

  /// Returns the importance normalized between 0 and 1.
  double get normalizedImportance =>
      importance / 100.0;

  /// Returns the confidence normalized between 0 and 1.
  double get normalizedConfidence =>
      confidence / 100.0;

  /// Returns a combined relevance score.
  ///
  /// This is deliberately lightweight. A future memory engine can
  /// introduce more advanced semantic ranking without changing the model.
  double get relevanceScore {
    final double confidenceWeight =
        normalizedConfidence * 0.45;

    final double importanceWeight =
        normalizedImportance * 0.40;

    final double reinforcementWeight =
        _clamp01(reinforcementCount / 10.0) * 0.15;

    return _clamp01(
      confidenceWeight +
          importanceWeight +
          reinforcementWeight,
    );
  }

  // ===========================================================================
  // IMMUTABLE UPDATES
  // ===========================================================================

  /// Creates an immutable copy with selected values replaced.
  LearningMemory copyWith({
    String? learnerId,
    String? content,
    LearningMemoryType? type,
    LearningMemorySource? source,
    double? importance,
    double? confidence,
    int? reinforcementCount,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    DateTime? expiresAt,
    bool? active,
    String? sourceSessionId,
    String? tutorId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return LearningMemory(
      id: id,
      learnerId: learnerId ?? this.learnerId,
      content: content ?? this.content,
      type: type ?? this.type,
      source: source ?? this.source,
      importance: _clampPercentage(
        importance ?? this.importance,
      ),
      confidence: _clampPercentage(
        confidence ?? this.confidence,
      ),
      reinforcementCount:
          _sanitizeNonNegativeInt(
        reinforcementCount ??
            this.reinforcementCount,
      ),
      usageCount: _sanitizeNonNegativeInt(
        usageCount ?? this.usageCount,
      ),
      createdAt:
          (createdAt ?? this.createdAt).toUtc(),
      updatedAt:
          (updatedAt ?? this.updatedAt).toUtc(),
      lastUsedAt:
          lastUsedAt?.toUtc() ?? this.lastUsedAt,
      expiresAt:
          expiresAt?.toUtc() ?? this.expiresAt,
      active: active ?? this.active,
      sourceSessionId:
          sourceSessionId ?? this.sourceSessionId,
      tutorId: tutorId ?? this.tutorId,
      tags: _normalizeStringList(
        tags ?? this.tags,
      ),
      metadata: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(
          metadata ?? this.metadata,
        ),
      ),
    );
  }

  /// Reinforces the memory after a new confirmation.
  LearningMemory reinforce({
    double confidenceBoost = 5.0,
    double importanceBoost = 0.0,
    DateTime? at,
  }) {
    final DateTime timestamp =
        (at ?? DateTime.now()).toUtc();

    return copyWith(
      confidence: _clampPercentage(
        confidence + confidenceBoost,
      ),
      importance: _clampPercentage(
        importance + importanceBoost,
      ),
      reinforcementCount:
          reinforcementCount + 1,
      updatedAt: timestamp,
      lastUsedAt: timestamp,
    );
  }

  /// Marks the memory as used by the learning engine.
  LearningMemory markUsed({
    DateTime? at,
  }) {
    final DateTime timestamp =
        (at ?? DateTime.now()).toUtc();

    return copyWith(
      usageCount: usageCount + 1,
      lastUsedAt: timestamp,
      updatedAt: timestamp,
    );
  }

  /// Deactivates this memory without deleting it.
  LearningMemory deactivate({
    DateTime? at,
  }) {
    return copyWith(
      active: false,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    );
  }

  /// Reactivates this memory.
  LearningMemory activate({
    DateTime? at,
  }) {
    return copyWith(
      active: true,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    );
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  /// Converts this memory into a persistence-safe JSON structure.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'learnerId': learnerId,
      'content': content,
      'type': type.name,
      'source': source.name,
      'importance': importance,
      'confidence': confidence,
      'reinforcementCount': reinforcementCount,
      'usageCount': usageCount,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'lastUsedAt':
          lastUsedAt?.toUtc().toIso8601String(),
      'expiresAt':
          expiresAt?.toUtc().toIso8601String(),
      'active': active,
      'sourceSessionId': sourceSessionId,
      'tutorId': tutorId,
      'tags': List<String>.from(tags),
      'metadata': Map<String, dynamic>.from(metadata),
    };
  }

  /// Reconstructs a memory from persisted JSON.
  factory LearningMemory.fromJson(
    Map<String, dynamic> json,
  ) {
    final DateTime created =
        _readDateTime(json['createdAt']) ??
            DateTime.now().toUtc();

    return LearningMemory(
      id: _readRequiredString(
        json['id'],
        fallback: 'unknown_memory',
      ),
      learnerId:
          _readNullableString(json['learnerId']),
      content: _readRequiredString(
        json['content'],
        fallback: '',
      ),
      type: LearningMemoryTypeX.fromName(
        json['type'],
      ),
      source: LearningMemorySourceX.fromName(
        json['source'],
      ),
      importance: _readPercentage(
        json['importance'],
      ) ?? 50.0,
      confidence: _readPercentage(
        json['confidence'],
      ) ?? 50.0,
      reinforcementCount:
          _readNonNegativeInt(
        json['reinforcementCount'],
      ),
      usageCount:
          _readNonNegativeInt(
        json['usageCount'],
      ),
      createdAt: created,
      updatedAt:
          _readDateTime(json['updatedAt']) ??
              created,
      lastUsedAt:
          _readDateTime(json['lastUsedAt']),
      expiresAt:
          _readDateTime(json['expiresAt']),
      active: json['active'] != false,
      sourceSessionId:
          _readNullableString(
        json['sourceSessionId'],
      ),
      tutorId:
          _readNullableString(json['tutorId']),
      tags: _readStringList(json['tags']),
      metadata: _readMetadata(
        json['metadata'],
      ),
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Returns structural validation issues.
  ///
  /// An empty list means the memory is structurally valid.
  List<String> validate() {
    final List<String> issues = <String>[];

    if (id.trim().isEmpty) {
      issues.add(
        'Memory identifier cannot be empty.',
      );
    }

    if (content.trim().isEmpty) {
      issues.add(
        'Memory content cannot be empty.',
      );
    }

    if (reinforcementCount < 0) {
      issues.add(
        'Reinforcement count cannot be negative.',
      );
    }

    if (usageCount < 0) {
      issues.add(
        'Usage count cannot be negative.',
      );
    }

    if (expiresAt != null &&
        expiresAt!.isBefore(createdAt)) {
      issues.add(
        'Expiration date cannot precede creation date.',
      );
    }

    if (updatedAt.isBefore(createdAt)) {
      issues.add(
        'Updated date cannot precede creation date.',
      );
    }

    return issues;
  }

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  static double _clampPercentage(
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

  static double _clamp01(
    double value,
  ) {
    if (value < 0.0) {
      return 0.0;
    }

    if (value > 1.0) {
      return 1.0;
    }

    return value;
  }

  static int _sanitizeNonNegativeInt(
    int value,
  ) {
    return value < 0 ? 0 : value;
  }

  static String _readRequiredString(
    dynamic value, {
    required String fallback,
  }) {
    if (value is String) {
      final String result = value.trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return fallback;
  }

  static String? _readNullableString(
    dynamic value,
  ) {
    if (value is String) {
      final String result = value.trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return null;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }

  static int _readNonNegativeInt(
    dynamic value,
  ) {
    if (value is num) {
      final int result = value.toInt();

      return result < 0 ? 0 : result;
    }

    return 0;
  }

  static double? _readPercentage(
    dynamic value,
  ) {
    if (value is! num) {
      return null;
    }

    final double result = value.toDouble();

    if (result.isNaN || result.isInfinite) {
      return null;
    }

    return _clampPercentage(result);
  }

  static List<String> _normalizeStringList(
    Iterable<String> values,
  ) {
    final List<String> normalized = values
        .map((String value) => value.trim())
        .where(
          (String value) => value.isNotEmpty,
        )
        .toSet()
        .toList();

    return List<String>.unmodifiable(
      normalized,
    );
  }

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return const <String>[];
    }

    return _normalizeStringList(
      value.whereType<String>(),
    );
  }

  static Map<String, dynamic> _readMetadata(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(value),
      );
    }

    return const <String, dynamic>{};
  }
}

// =============================================================================
// MEMORY TYPE
// =============================================================================

/// Describes what kind of knowledge the memory represents.
enum LearningMemoryType {
  preference,
  goal,
  strength,
  weakness,
  vocabulary,
  grammar,
  pronunciation,
  behavior,
  motivation,
  interest,
  observation,
  achievement,
  correctionPattern,
  tutorPreference,
  learningHabit,
}

// =============================================================================
// MEMORY SOURCE
// =============================================================================

/// Describes where the memory originated.
enum LearningMemorySource {
  onboarding,
  session,
  user,
  ai,
  assessment,
  system,
}

// =============================================================================
// ENUM PARSERS
// =============================================================================

extension LearningMemoryTypeX on LearningMemoryType {
  static LearningMemoryType fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningMemoryType type
          in LearningMemoryType.values) {
        if (type.name == value) {
          return type;
        }
      }
    }

    return LearningMemoryType.observation;
  }
}

extension LearningMemorySourceX
    on LearningMemorySource {
  static LearningMemorySource fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningMemorySource source
          in LearningMemorySource.values) {
        if (source.name == value) {
          return source;
        }
      }
    }

    return LearningMemorySource.ai;
  }
}