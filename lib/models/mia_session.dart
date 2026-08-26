import 'package:flutter/foundation.dart';

/// Lifecycle of a Mia learning session.
enum MiaSessionStatus {
  notStarted,
  preparing,
  active,
  paused,
  completed,
  cancelled,
}

/// Type of content exchanged during a Mia session.
enum MiaMessageRole {
  learner,
  tutor,
  system,
}

/// A single message exchanged during a Mia session.
///
/// This model is intentionally provider-agnostic so the future AI layer
/// can be connected without changing the learning architecture.
@immutable
class MiaSessionMessage {
  const MiaSessionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isFinal = true,
    this.correction,
  });

  final String id;
  final MiaMessageRole role;
  final String content;
  final DateTime timestamp;

  /// False while speech recognition or streaming content is still arriving.
  final bool isFinal;

  /// Optional correction generated for the learner's message.
  final MiaCorrection? correction;

  MiaSessionMessage copyWith({
    String? id,
    MiaMessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isFinal,
    MiaCorrection? correction,
  }) {
    return MiaSessionMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFinal: isFinal ?? this.isFinal,
      correction: correction ?? this.correction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isFinal': isFinal,
      'correction': correction?.toJson(),
    };
  }

  factory MiaSessionMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return MiaSessionMessage(
      id: _readString(json['id']) ?? '',
      role: _readEnum(
        json['role'],
        MiaMessageRole.values,
        MiaMessageRole.system,
      ),
      content: _readString(json['content']) ?? '',
      timestamp: _readDateTime(
        json['timestamp'],
      ),
      isFinal: json['isFinal'] is bool
          ? json['isFinal'] as bool
          : true,
      correction: json['correction'] is Map
          ? MiaCorrection.fromJson(
              Map<String, dynamic>.from(
                json['correction'] as Map,
              ),
            )
          : null,
    );
  }
}

/// A correction attached to a learner message.
@immutable
class MiaCorrection {
  const MiaCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
    this.category = MiaCorrectionCategory.grammar,
  });

  final String original;
  final String corrected;
  final String explanation;
  final MiaCorrectionCategory category;

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'corrected': corrected,
      'explanation': explanation,
      'category': category.name,
    };
  }

  factory MiaCorrection.fromJson(
    Map<String, dynamic> json,
  ) {
    return MiaCorrection(
      original: _readString(json['original']) ?? '',
      corrected: _readString(json['corrected']) ?? '',
      explanation:
          _readString(json['explanation']) ?? '',
      category: _readEnum(
        json['category'],
        MiaCorrectionCategory.values,
        MiaCorrectionCategory.grammar,
      ),
    );
  }
}

/// Learning category targeted by a correction.
enum MiaCorrectionCategory {
  grammar,
  vocabulary,
  pronunciation,
  fluency,
  wordChoice,
  naturalness,
}

/// A skill measured during the session.
///
/// Values use a 0.0 → 100.0 scale.
@immutable
class MiaSkillSnapshot {
  const MiaSkillSnapshot({
    required this.skill,
    required this.score,
    this.delta = 0,
  });

  final String skill;
  final double score;

  /// Improvement detected during the session.
  final double delta;

  MiaSkillSnapshot copyWith({
    String? skill,
    double? score,
    double? delta,
  }) {
    return MiaSkillSnapshot(
      skill: skill ?? this.skill,
      score: _sanitizeScore(
        score ?? this.score,
      ),
      delta: delta ?? this.delta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'score': score,
      'delta': delta,
    };
  }

  factory MiaSkillSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return MiaSkillSnapshot(
      skill: _readString(json['skill']) ?? '',
      score: _sanitizeScore(
        _readDouble(json['score']),
      ),
      delta: _readDouble(json['delta']),
    );
  }
}

/// Final summary generated when a session is completed.
@immutable
class MiaSessionSummary {
  const MiaSessionSummary({
    required this.xpEarned,
    required this.durationMinutes,
    required this.messagesExchanged,
    required this.skills,
    this.strengths = const [],
    this.improvements = const [],
    this.nextRecommendation,
  });

  final int xpEarned;
  final int durationMinutes;
  final int messagesExchanged;
  final List<MiaSkillSnapshot> skills;
  final List<String> strengths;
  final List<String> improvements;
  final String? nextRecommendation;

  Map<String, dynamic> toJson() {
    return {
      'xpEarned': xpEarned,
      'durationMinutes': durationMinutes,
      'messagesExchanged': messagesExchanged,
      'skills': skills
          .map(
            (skill) => skill.toJson(),
          )
          .toList(),
      'strengths': List<String>.from(
        strengths,
      ),
      'improvements': List<String>.from(
        improvements,
      ),
      'nextRecommendation':
          nextRecommendation,
    };
  }

  factory MiaSessionSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawSkills = json['skills'];

    final List<MiaSkillSnapshot> skills = [];

    if (rawSkills is List) {
      for (final dynamic item in rawSkills) {
        if (item is Map) {
          skills.add(
            MiaSkillSnapshot.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return MiaSessionSummary(
      xpEarned: _readInt(
        json['xpEarned'],
      ),
      durationMinutes: _readInt(
        json['durationMinutes'],
      ),
      messagesExchanged: _readInt(
        json['messagesExchanged'],
      ),
      skills: List.unmodifiable(skills),
      strengths: _readStringList(
        json['strengths'],
      ),
      improvements: _readStringList(
        json['improvements'],
      ),
      nextRecommendation:
          _readString(
        json['nextRecommendation'],
      ),
    );
  }
}

/// Complete state of a Mia learning session.
///
/// This is the central model that the future:
///
/// microphone → speech recognition → AI → Mia voice
///
/// pipeline can operate on.
@immutable
class MiaSession {
  const MiaSession({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.targetLevel,
    required this.goal,
    required this.durationMinutes,
    this.startedAt,
    this.completedAt,
    this.messages = const [],
    this.skills = const [],
    this.summary,
    this.xpEarned = 0,
    this.elapsedSeconds = 0,
  });

  final String id;

  final DateTime createdAt;

  final MiaSessionStatus status;

  /// Learner level targeted by this session.
  final String targetLevel;

  /// Main objective of the session.
  final String goal;

  /// Planned duration.
  final int durationMinutes;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final List<MiaSessionMessage> messages;
  final List<MiaSkillSnapshot> skills;

  final MiaSessionSummary? summary;

  /// XP earned during this session.
  final int xpEarned;

  /// Current elapsed duration in seconds.
  final int elapsedSeconds;

  /// Whether the session is currently running.
  bool get isActive =>
      status == MiaSessionStatus.active;

  /// Whether the session has reached a terminal state.
  bool get isFinished =>
      status == MiaSessionStatus.completed ||
      status == MiaSessionStatus.cancelled;

  /// Planned duration converted to seconds.
  int get totalSeconds =>
      durationMinutes * 60;

  /// Remaining seconds in the planned session.
  int get remainingSeconds {
    final int remaining =
        totalSeconds - elapsedSeconds;

    return remaining < 0 ? 0 : remaining;
  }

  /// Completion ratio from 0.0 → 1.0.
  double get completionProgress {
    if (totalSeconds <= 0) {
      return 0.0;
    }

    return (
      elapsedSeconds / totalSeconds
    ).clamp(0.0, 1.0);
  }

  /// Number of learner messages.
  int get learnerMessageCount {
    return messages
        .where(
          (message) =>
              message.role ==
              MiaMessageRole.learner,
        )
        .length;
  }

  /// Number of tutor messages.
  int get tutorMessageCount {
    return messages
        .where(
          (message) =>
              message.role ==
              MiaMessageRole.tutor,
        )
        .length;
  }

  MiaSession copyWith({
    String? id,
    DateTime? createdAt,
    MiaSessionStatus? status,
    String? targetLevel,
    String? goal,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    List<MiaSessionMessage>? messages,
    List<MiaSkillSnapshot>? skills,
    MiaSessionSummary? summary,
    int? xpEarned,
    int? elapsedSeconds,
  }) {
    return MiaSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      targetLevel: targetLevel ?? this.targetLevel,
      goal: goal ?? this.goal,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt:
          completedAt ?? this.completedAt,
      messages: List.unmodifiable(
        messages ?? this.messages,
      ),
      skills: List.unmodifiable(
        skills ?? this.skills,
      ),
      summary: summary ?? this.summary,
      xpEarned: _sanitizeNonNegativeInt(
        xpEarned ?? this.xpEarned,
      ),
      elapsedSeconds:
          _sanitizeNonNegativeInt(
        elapsedSeconds ??
            this.elapsedSeconds,
      ),
    );
  }

  /// Creates a new session with safe defaults.
  factory MiaSession.create({
    required String id,
    required String targetLevel,
    required String goal,
    int durationMinutes = 15,
  }) {
    final int safeDuration =
        durationMinutes < 1
            ? 1
            : durationMinutes;

    return MiaSession(
      id: id,
      createdAt: DateTime.now().toUtc(),
      status: MiaSessionStatus.notStarted,
      targetLevel: targetLevel,
      goal: goal,
      durationMinutes: safeDuration,
    );
  }

  /// Adds a message without mutating the existing session.
  MiaSession addMessage(
    MiaSessionMessage message,
  ) {
    return copyWith(
      messages: [
        ...messages,
        message,
      ],
    );
  }

  /// Updates elapsed time safely.
  MiaSession updateElapsedSeconds(
    int seconds,
  ) {
    return copyWith(
      elapsedSeconds:
          _sanitizeNonNegativeInt(seconds),
    );
  }

  /// Starts the session.
  MiaSession start() {
    if (isFinished) {
      return this;
    }

    return copyWith(
      status: MiaSessionStatus.active,
      startedAt:
          startedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Pauses an active session.
  MiaSession pause() {
    if (status != MiaSessionStatus.active) {
      return this;
    }

    return copyWith(
      status: MiaSessionStatus.paused,
    );
  }

  /// Resumes a paused session.
  MiaSession resume() {
    if (status != MiaSessionStatus.paused) {
      return this;
    }

    return copyWith(
      status: MiaSessionStatus.active,
    );
  }

  /// Completes the session.
  MiaSession complete({
    MiaSessionSummary? sessionSummary,
  }) {
    return copyWith(
      status: MiaSessionStatus.completed,
      completedAt:
          DateTime.now().toUtc(),
      summary: sessionSummary ?? summary,
      xpEarned:
          sessionSummary?.xpEarned ??
          xpEarned,
    );
  }

  /// Cancels the session.
  MiaSession cancel() {
    if (isFinished) {
      return this;
    }

    return copyWith(
      status: MiaSessionStatus.cancelled,
      completedAt:
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt':
          createdAt.toIso8601String(),
      'status': status.name,
      'targetLevel': targetLevel,
      'goal': goal,
      'durationMinutes': durationMinutes,
      'startedAt':
          startedAt?.toIso8601String(),
      'completedAt':
          completedAt?.toIso8601String(),
      'messages': messages
          .map(
            (message) => message.toJson(),
          )
          .toList(),
      'skills': skills
          .map(
            (skill) => skill.toJson(),
          )
          .toList(),
      'summary': summary?.toJson(),
      'xpEarned': xpEarned,
      'elapsedSeconds': elapsedSeconds,
    };
  }

  factory MiaSession.fromJson(
    Map<String, dynamic> json,
  ) {
    final List<MiaSessionMessage> messages = [];
    final dynamic rawMessages =
        json['messages'];

    if (rawMessages is List) {
      for (final dynamic item in rawMessages) {
        if (item is Map) {
          messages.add(
            MiaSessionMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final List<MiaSkillSnapshot> skills = [];
    final dynamic rawSkills =
        json['skills'];

    if (rawSkills is List) {
      for (final dynamic item in rawSkills) {
        if (item is Map) {
          skills.add(
            MiaSkillSnapshot.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return MiaSession(
      id: _readString(json['id']) ?? '',
      createdAt: _readDateTime(
        json['createdAt'],
      ),
      status: _readEnum(
        json['status'],
        MiaSessionStatus.values,
        MiaSessionStatus.notStarted,
      ),
      targetLevel:
          _readString(
            json['targetLevel'],
          ) ??
          'A1',
      goal:
          _readString(json['goal']) ??
          'General English',
      durationMinutes:
          _sanitizeMinimumInt(
        _readInt(
          json['durationMinutes'],
          15,
        ),
        1,
      ),
      startedAt:
          _readNullableDateTime(
        json['startedAt'],
      ),
      completedAt:
          _readNullableDateTime(
        json['completedAt'],
      ),
      messages:
          List.unmodifiable(messages),
      skills:
          List.unmodifiable(skills),
      summary:
          json['summary'] is Map
              ? MiaSessionSummary.fromJson(
                  Map<String, dynamic>.from(
                    json['summary'] as Map,
                  ),
                )
              : null,
      xpEarned:
          _sanitizeNonNegativeInt(
        _readInt(
          json['xpEarned'],
        ),
      ),
      elapsedSeconds:
          _sanitizeNonNegativeInt(
        _readInt(
          json['elapsedSeconds'],
        ),
      ),
    );
  }
}

// =============================================================================
// SAFE HELPERS
// =============================================================================

String? _readString(
  dynamic value,
) {
  return value is String
      ? value
      : null;
}

int _readInt(
  dynamic value, [
  int fallback = 0,
]) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return fallback;
}

double _readDouble(
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

DateTime _readDateTime(
  dynamic value,
) {
  if (value is String) {
    final DateTime? parsed =
        DateTime.tryParse(value);

    if (parsed != null) {
      return parsed;
    }
  }

  return DateTime.now().toUtc();
}

DateTime? _readNullableDateTime(
  dynamic value,
) {
  if (value is! String) {
    return null;
  }

  return DateTime.tryParse(value);
}

List<String> _readStringList(
  dynamic value,
) {
  if (value is! List) {
    return const [];
  }

  return List.unmodifiable(
    value.whereType<String>(),
  );
}

T _readEnum<T extends Enum>(
  dynamic value,
  List<T> values,
  T fallback,
) {
  if (value is String) {
    for (final T item in values) {
      if (item.name == value) {
        return item;
      }
    }
  }

  return fallback;
}

int _sanitizeNonNegativeInt(
  int value,
) {
  return value < 0 ? 0 : value;
}

int _sanitizeMinimumInt(
  int value,
  int minimum,
) {
  return value < minimum ? minimum : value;
}

double _sanitizeScore(
  double value,
) {
  if (value.isNaN || value.isInfinite) {
    return 0.0;
  }

  return value.clamp(0.0, 100.0);
}