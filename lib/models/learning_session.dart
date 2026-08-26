/// Represents one complete Eloqia learning session.
///
/// This model is the domain representation of a learning experience.
/// It intentionally remains independent from:
///
/// • Flutter UI
/// • persistence
/// • AI providers
/// • tutor implementations
/// • networking
///
/// A session can represent:
///
/// • an AI conversation
/// • speaking practice
/// • pronunciation training
/// • writing practice
/// • listening practice
/// • reading practice
/// • vocabulary training
/// • grammar practice
/// • a complete adaptive lesson
///
/// The model is designed to remain stable while Eloqia evolves from
/// a local application into a complete intelligent learning platform.
class LearningSession {
  // ===========================================================================
  // CORE IDENTITY
  // ===========================================================================

  /// Unique identifier of this session.
  final String id;

  /// Identifier of the learner who owns this session.
  ///
  /// This is optional for the current local-first architecture but prepares
  /// the model for future authentication and cloud synchronization.
  final String? learnerId;

  /// Identifier of the tutor used during the session.
  ///
  /// Example:
  /// `mia`
  final String? tutorId;

  /// Human-readable tutor name.
  ///
  /// Example:
  /// `Mia`
  final String? tutorName;

  // ===========================================================================
  // SESSION TYPE
  // ===========================================================================

  /// Main learning activity performed during the session.
  final LearningActivityType activityType;

  /// Current lifecycle state of the session.
  final LearningSessionStatus status;

  // ===========================================================================
  // TIMING
  // ===========================================================================

  /// When the session was created.
  final DateTime createdAt;

  /// When the learner actually started the experience.
  final DateTime? startedAt;

  /// When the session ended.
  final DateTime? completedAt;

  /// Total active learning time.
  final Duration activeDuration;

  // ===========================================================================
  // LEARNING CONTEXT
  // ===========================================================================

  /// CEFR level targeted during the session.
  ///
  /// Example:
  /// `A2`, `B1`, `C1`
  final String? targetLevel;

  /// CEFR level detected at the beginning of the session.
  final String? startingLevel;

  /// Main objective being trained.
  final String? primaryGoal;

  /// Specific skills targeted during the experience.
  final List<LearningSkill> skills;

  /// Topics discussed or practiced.
  final List<String> topics;

  /// User interests involved in the session.
  final List<String> interests;

  // ===========================================================================
  // PERSONALIZATION
  // ===========================================================================

  /// Whether the session was dynamically adapted to the learner.
  final bool adaptive;

  /// Difficulty selected by the learning engine.
  final SessionDifficulty difficulty;

  /// Learning pace used by the session.
  final LearningPace pace;

  /// Whether AI personalization was active.
  final bool personalized;

  // ===========================================================================
  // PERFORMANCE
  // ===========================================================================

  /// Overall performance score from 0 to 100.
  final double? score;

  /// Confidence score from 0 to 100.
  final double? confidenceScore;

  /// Pronunciation score from 0 to 100, when applicable.
  final double? pronunciationScore;

  /// Vocabulary score from 0 to 100, when applicable.
  final double? vocabularyScore;

  /// Grammar score from 0 to 100, when applicable.
  final double? grammarScore;

  /// Fluency score from 0 to 100, when applicable.
  final double? fluencyScore;

  // ===========================================================================
  // PROGRESSION
  // ===========================================================================

  /// XP awarded after the session.
  final int xpEarned;

  /// Whether the session contributed to the learner's streak.
  final bool contributedToStreak;

  /// Whether the learner completed the planned experience.
  final bool completed;

  /// Number of objectives completed during the session.
  final int objectivesCompleted;

  /// Total number of objectives planned.
  final int objectivesTotal;

  // ===========================================================================
  // AI INSIGHTS
  // ===========================================================================

  /// Strengths detected during the session.
  final List<String> strengths;

  /// Areas that need improvement.
  final List<String> weaknesses;

  /// New vocabulary discovered.
  final List<String> vocabularyLearned;

  /// Grammar concepts practiced.
  final List<String> grammarPoints;

  /// AI-generated recommendations for future sessions.
  final List<String> recommendations;

  /// Short AI-generated summary of the experience.
  final String? aiSummary;

  // ===========================================================================
  // USER FEEDBACK
  // ===========================================================================

  /// Learner's satisfaction rating from 1 to 5.
  final int? rating;

  /// Optional learner feedback.
  final String? feedback;

  // ===========================================================================
  // EXTENSIBILITY
  // ===========================================================================

  /// Additional structured information.
  ///
  /// This allows future Eloqia features to introduce new metadata without
  /// constantly changing the core persistence architecture.
  final Map<String, dynamic> metadata;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const LearningSession({
    required this.id,
    this.learnerId,
    this.tutorId,
    this.tutorName,
    required this.activityType,
    this.status = LearningSessionStatus.inProgress,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.activeDuration = Duration.zero,
    this.targetLevel,
    this.startingLevel,
    this.primaryGoal,
    this.skills = const <LearningSkill>[],
    this.topics = const <String>[],
    this.interests = const <String>[],
    this.adaptive = true,
    this.difficulty = SessionDifficulty.adaptive,
    this.pace = LearningPace.adaptive,
    this.personalized = true,
    this.score,
    this.confidenceScore,
    this.pronunciationScore,
    this.vocabularyScore,
    this.grammarScore,
    this.fluencyScore,
    this.xpEarned = 0,
    this.contributedToStreak = false,
    this.completed = false,
    this.objectivesCompleted = 0,
    this.objectivesTotal = 0,
    this.strengths = const <String>[],
    this.weaknesses = const <String>[],
    this.vocabularyLearned = const <String>[],
    this.grammarPoints = const <String>[],
    this.recommendations = const <String>[],
    this.aiSummary,
    this.rating,
    this.feedback,
    this.metadata = const <String, dynamic>{},
  });

  // ===========================================================================
  // FACTORIES
  // ===========================================================================

  /// Creates a fresh learning session.
  factory LearningSession.create({
    required String id,
    LearningActivityType activityType =
        LearningActivityType.conversation,
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
    SessionDifficulty difficulty =
        SessionDifficulty.adaptive,
    LearningPace pace = LearningPace.adaptive,
  }) {
    final DateTime now = DateTime.now().toUtc();

    return LearningSession(
      id: id,
      learnerId: learnerId,
      tutorId: tutorId,
      tutorName: tutorName,
      activityType: activityType,
      status: LearningSessionStatus.inProgress,
      createdAt: now,
      startedAt: now,
      targetLevel: targetLevel,
      startingLevel: startingLevel,
      primaryGoal: primaryGoal,
      skills: List<LearningSkill>.unmodifiable(skills),
      topics: List<String>.unmodifiable(topics),
      interests: List<String>.unmodifiable(interests),
      adaptive: adaptive,
      difficulty: difficulty,
      pace: pace,
    );
  }

  // ===========================================================================
  // STATE HELPERS
  // ===========================================================================

  /// Whether the session is currently active.
  bool get isActive =>
      status == LearningSessionStatus.inProgress;

  /// Whether the session has finished.
  bool get isFinished =>
      status == LearningSessionStatus.completed ||
      status == LearningSessionStatus.abandoned;

  /// Whether the learner successfully completed the session.
  bool get isSuccessful =>
      status == LearningSessionStatus.completed &&
      completed;

  /// Progress through planned objectives from 0 to 1.
  double get objectiveProgress {
    if (objectivesTotal <= 0) {
      return 0;
    }

    return _clamp01(
      objectivesCompleted / objectivesTotal,
    );
  }

  /// Returns the performance score normalized between 0 and 1.
  double get normalizedScore {
    return _clamp01(
      (score ?? 0) / 100,
    );
  }

  /// Whether the session contains meaningful performance data.
  bool get hasPerformanceData =>
      score != null ||
      confidenceScore != null ||
      pronunciationScore != null ||
      vocabularyScore != null ||
      grammarScore != null ||
      fluencyScore != null;

  // ===========================================================================
  // IMMUTABLE UPDATES
  // ===========================================================================

  /// Creates a new session with selected values replaced.
  LearningSession copyWith({
    String? learnerId,
    String? tutorId,
    String? tutorName,
    LearningActivityType? activityType,
    LearningSessionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? activeDuration,
    String? targetLevel,
    String? startingLevel,
    String? primaryGoal,
    List<LearningSkill>? skills,
    List<String>? topics,
    List<String>? interests,
    bool? adaptive,
    SessionDifficulty? difficulty,
    LearningPace? pace,
    bool? personalized,
    double? score,
    double? confidenceScore,
    double? pronunciationScore,
    double? vocabularyScore,
    double? grammarScore,
    double? fluencyScore,
    int? xpEarned,
    bool? contributedToStreak,
    bool? completed,
    int? objectivesCompleted,
    int? objectivesTotal,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? vocabularyLearned,
    List<String>? grammarPoints,
    List<String>? recommendations,
    String? aiSummary,
    int? rating,
    String? feedback,
    Map<String, dynamic>? metadata,
  }) {
    return LearningSession(
      id: id,
      learnerId: learnerId ?? this.learnerId,
      tutorId: tutorId ?? this.tutorId,
      tutorName: tutorName ?? this.tutorName,
      activityType: activityType ?? this.activityType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      activeDuration:
          activeDuration ?? this.activeDuration,
      targetLevel: targetLevel ?? this.targetLevel,
      startingLevel:
          startingLevel ?? this.startingLevel,
      primaryGoal:
          primaryGoal ?? this.primaryGoal,
      skills: List<LearningSkill>.unmodifiable(
        skills ?? this.skills,
      ),
      topics: List<String>.unmodifiable(
        topics ?? this.topics,
      ),
      interests: List<String>.unmodifiable(
        interests ?? this.interests,
      ),
      adaptive: adaptive ?? this.adaptive,
      difficulty:
          difficulty ?? this.difficulty,
      pace: pace ?? this.pace,
      personalized:
          personalized ?? this.personalized,
      score: score ?? this.score,
      confidenceScore:
          confidenceScore ?? this.confidenceScore,
      pronunciationScore:
          pronunciationScore ?? this.pronunciationScore,
      vocabularyScore:
          vocabularyScore ?? this.vocabularyScore,
      grammarScore:
          grammarScore ?? this.grammarScore,
      fluencyScore:
          fluencyScore ?? this.fluencyScore,
      xpEarned: xpEarned ?? this.xpEarned,
      contributedToStreak:
          contributedToStreak ??
          this.contributedToStreak,
      completed:
          completed ?? this.completed,
      objectivesCompleted:
          objectivesCompleted ??
          this.objectivesCompleted,
      objectivesTotal:
          objectivesTotal ??
          this.objectivesTotal,
      strengths: List<String>.unmodifiable(
        strengths ?? this.strengths,
      ),
      weaknesses: List<String>.unmodifiable(
        weaknesses ?? this.weaknesses,
      ),
      vocabularyLearned:
          List<String>.unmodifiable(
        vocabularyLearned ??
            this.vocabularyLearned,
      ),
      grammarPoints:
          List<String>.unmodifiable(
        grammarPoints ??
            this.grammarPoints,
      ),
      recommendations:
          List<String>.unmodifiable(
        recommendations ??
            this.recommendations,
      ),
      aiSummary: aiSummary ?? this.aiSummary,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      metadata: Map<String, dynamic>.unmodifiable(
        metadata ?? this.metadata,
      ),
    );
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  /// Converts the session into a persistence-safe JSON structure.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'learnerId': learnerId,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'activityType': activityType.name,
      'status': status.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'startedAt':
          startedAt?.toUtc().toIso8601String(),
      'completedAt':
          completedAt?.toUtc().toIso8601String(),
      'activeDurationSeconds':
          activeDuration.inSeconds,
      'targetLevel': targetLevel,
      'startingLevel': startingLevel,
      'primaryGoal': primaryGoal,
      'skills': skills
          .map((LearningSkill item) => item.name)
          .toList(),
      'topics': List<String>.from(topics),
      'interests': List<String>.from(interests),
      'adaptive': adaptive,
      'difficulty': difficulty.name,
      'pace': pace.name,
      'personalized': personalized,
      'score': score,
      'confidenceScore': confidenceScore,
      'pronunciationScore':
          pronunciationScore,
      'vocabularyScore': vocabularyScore,
      'grammarScore': grammarScore,
      'fluencyScore': fluencyScore,
      'xpEarned': xpEarned,
      'contributedToStreak':
          contributedToStreak,
      'completed': completed,
      'objectivesCompleted':
          objectivesCompleted,
      'objectivesTotal': objectivesTotal,
      'strengths': List<String>.from(strengths),
      'weaknesses': List<String>.from(weaknesses),
      'vocabularyLearned':
          List<String>.from(vocabularyLearned),
      'grammarPoints':
          List<String>.from(grammarPoints),
      'recommendations':
          List<String>.from(recommendations),
      'aiSummary': aiSummary,
      'rating': rating,
      'feedback': feedback,
      'metadata':
          Map<String, dynamic>.from(metadata),
    };
  }

  /// Reconstructs a session from persisted JSON.
  factory LearningSession.fromJson(
    Map<String, dynamic> json,
  ) {
    return LearningSession(
      id: _readRequiredString(
        json['id'],
        fallback: 'unknown_session',
      ),
      learnerId:
          _readNullableString(json['learnerId']),
      tutorId:
          _readNullableString(json['tutorId']),
      tutorName:
          _readNullableString(json['tutorName']),
      activityType:
          LearningActivityTypeX.fromName(
        json['activityType'],
      ),
      status:
          LearningSessionStatusX.fromName(
        json['status'],
      ),
      createdAt:
          _readDateTime(
        json['createdAt'],
      ) ??
              DateTime.now().toUtc(),
      startedAt:
          _readDateTime(json['startedAt']),
      completedAt:
          _readDateTime(json['completedAt']),
      activeDuration:
          Duration(
        seconds: _readNonNegativeInt(
          json['activeDurationSeconds'],
        ),
      ),
      targetLevel:
          _readNullableString(json['targetLevel']),
      startingLevel:
          _readNullableString(
            json['startingLevel'],
          ),
      primaryGoal:
          _readNullableString(json['primaryGoal']),
      skills:
          _readEnumList<LearningSkill>(
        json['skills'],
        LearningSkillX.fromName,
      ),
      topics:
          _readStringList(json['topics']),
      interests:
          _readStringList(json['interests']),
      adaptive:
          json['adaptive'] == true,
      difficulty:
          SessionDifficultyX.fromName(
        json['difficulty'],
      ),
      pace:
          LearningPaceX.fromName(json['pace']),
      personalized:
          json['personalized'] != false,
      score:
          _readPercentage(json['score']),
      confidenceScore:
          _readPercentage(
            json['confidenceScore'],
          ),
      pronunciationScore:
          _readPercentage(
            json['pronunciationScore'],
          ),
      vocabularyScore:
          _readPercentage(
            json['vocabularyScore'],
          ),
      grammarScore:
          _readPercentage(
            json['grammarScore'],
          ),
      fluencyScore:
          _readPercentage(
            json['fluencyScore'],
          ),
      xpEarned:
          _readNonNegativeInt(json['xpEarned']),
      contributedToStreak:
          json['contributedToStreak'] == true,
      completed:
          json['completed'] == true,
      objectivesCompleted:
          _readNonNegativeInt(
            json['objectivesCompleted'],
          ),
      objectivesTotal:
          _readNonNegativeInt(
            json['objectivesTotal'],
          ),
      strengths:
          _readStringList(json['strengths']),
      weaknesses:
          _readStringList(json['weaknesses']),
      vocabularyLearned:
          _readStringList(
            json['vocabularyLearned'],
          ),
      grammarPoints:
          _readStringList(
            json['grammarPoints'],
          ),
      recommendations:
          _readStringList(
            json['recommendations'],
          ),
      aiSummary:
          _readNullableString(json['aiSummary']),
      rating:
          _readRating(json['rating']),
      feedback:
          _readNullableString(json['feedback']),
      metadata:
          _readMetadata(json['metadata']),
    );
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Returns validation issues detected in the session.
  ///
  /// An empty list means the session is structurally valid.
  List<String> validate() {
    final List<String> issues = <String>[];

    if (id.trim().isEmpty) {
      issues.add('Session identifier cannot be empty.');
    }

    if (activeDuration.isNegative) {
      issues.add('Active duration cannot be negative.');
    }

    if (xpEarned < 0) {
      issues.add('XP cannot be negative.');
    }

    if (objectivesCompleted > objectivesTotal &&
        objectivesTotal > 0) {
      issues.add(
        'Completed objectives cannot exceed total objectives.',
      );
    }

    if (rating != null &&
        (rating! < 1 || rating! > 5)) {
      issues.add(
        'Rating must be between 1 and 5.',
      );
    }

    return issues;
  }

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  static double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }

    if (value > 1) {
      return 1;
    }

    return value;
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

    return result.clamp(0, 100).toDouble();
  }

  static int? _readRating(dynamic value) {
    if (value is! num) {
      return null;
    }

    final int result = value.toInt();

    if (result < 1 || result > 5) {
      return null;
    }

    return result;
  }

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return List<String>.unmodifiable(
      value
          .whereType<String>()
          .map((String item) => item.trim())
          .where(
            (String item) => item.isNotEmpty,
          ),
    );
  }

  static List<T> _readEnumList<T>(
    dynamic value,
    T Function(dynamic value) parser,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return List<T>.unmodifiable(
      value.map(parser),
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
// LEARNING ACTIVITY
// =============================================================================

enum LearningActivityType {
  conversation,
  speaking,
  pronunciation,
  writing,
  reading,
  listening,
  vocabulary,
  grammar,
  lesson,
  assessment,
}

extension LearningActivityTypeX
    on LearningActivityType {
  static LearningActivityType fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningActivityType type
          in LearningActivityType.values) {
        if (type.name == value) {
          return type;
        }
      }
    }

    return LearningActivityType.lesson;
  }
}

// =============================================================================
// SESSION STATUS
// =============================================================================

enum LearningSessionStatus {
  inProgress,
  completed,
  abandoned,
}

extension LearningSessionStatusX
    on LearningSessionStatus {
  static LearningSessionStatus fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningSessionStatus status
          in LearningSessionStatus.values) {
        if (status.name == value) {
          return status;
        }
      }
    }

    return LearningSessionStatus.inProgress;
  }
}

// =============================================================================
// LEARNING SKILLS
// =============================================================================

enum LearningSkill {
  speaking,
  listening,
  reading,
  writing,
  pronunciation,
  vocabulary,
  grammar,
  fluency,
  confidence,
}

extension LearningSkillX on LearningSkill {
  static LearningSkill fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningSkill skill
          in LearningSkill.values) {
        if (skill.name == value) {
          return skill;
        }
      }
    }

    return LearningSkill.speaking;
  }
}

// =============================================================================
// DIFFICULTY
// =============================================================================

enum SessionDifficulty {
  adaptive,
  beginner,
  intermediate,
  advanced,
  expert,
}

// =============================================================================
// LEARNING PACE
// =============================================================================

enum LearningPace {
  adaptive,
  relaxed,
  balanced,
  intensive,
}

// =============================================================================
// ENUM PARSERS
// =============================================================================

extension SessionDifficultyX
    on SessionDifficulty {
  static SessionDifficulty fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final SessionDifficulty difficulty
          in SessionDifficulty.values) {
        if (difficulty.name == value) {
          return difficulty;
        }
      }
    }

    return SessionDifficulty.adaptive;
  }
}

extension LearningPaceX on LearningPace {
  static LearningPace fromName(
    dynamic value,
  ) {
    if (value is String) {
      for (final LearningPace pace
          in LearningPace.values) {
        if (pace.name == value) {
          return pace;
        }
      }
    }

    return LearningPace.adaptive;
  }
}