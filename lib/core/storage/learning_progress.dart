/// Represents the complete learning progression of an Eloqia learner.
///
/// This model is intentionally independent from Flutter UI and AI logic.
/// It acts as the canonical representation of progression data that can
/// later be consumed by the Home screen, learning engine, analytics layer,
/// tutor system and future backend.
///
/// The model is designed to remain backward-compatible as Eloqia evolves.
class LearningProgress {
  // ===========================================================================
  // CORE PROGRESSION
  // ===========================================================================

  /// Total XP earned throughout the learner's journey.
  final int totalXp;

  /// Current Eloqia level.
  final int level;

  /// Current consecutive learning-day streak.
  final int currentStreak;

  /// Highest consecutive learning-day streak ever achieved.
  final int bestStreak;

  /// Total number of completed learning sessions.
  final int completedSessions;

  /// Total learning time in minutes.
  final int totalLearningMinutes;

  // ===========================================================================
  // ACTIVITY COUNTERS
  // ===========================================================================

  final int conversationSessions;
  final int writingSessions;
  final int readingSessions;
  final int listeningSessions;
  final int vocabularySessions;
  final int pronunciationSessions;
  final int grammarSessions;

  // ===========================================================================
  // XP BY EXPERIENCE
  // ===========================================================================

  final int conversationXp;
  final int writingXp;
  final int readingXp;
  final int listeningXp;
  final int vocabularyXp;
  final int pronunciationXp;
  final int grammarXp;

  // ===========================================================================
  // CEFR PROGRESSION
  // ===========================================================================

  /// Learner's current CEFR level.
  ///
  /// Examples:
  /// A1, A2, B1, B2, C1, C2
  final String cefrLevel;

  /// Progress toward the next CEFR milestone, from 0.0 to 1.0.
  final double cefrProgress;

  // ===========================================================================
  // ACTIVITY DATES
  // ===========================================================================

  /// Most recent learning activity.
  final DateTime? lastActivityAt;

  /// First recorded learning activity.
  final DateTime? firstActivityAt;

  // ===========================================================================
  // DAILY ACTIVITY
  // ===========================================================================

  /// Number of learning days recorded.
  final int activeDays;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const LearningProgress({
    this.totalXp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completedSessions = 0,
    this.totalLearningMinutes = 0,
    this.conversationSessions = 0,
    this.writingSessions = 0,
    this.readingSessions = 0,
    this.listeningSessions = 0,
    this.vocabularySessions = 0,
    this.pronunciationSessions = 0,
    this.grammarSessions = 0,
    this.conversationXp = 0,
    this.writingXp = 0,
    this.readingXp = 0,
    this.listeningXp = 0,
    this.vocabularyXp = 0,
    this.pronunciationXp = 0,
    this.grammarXp = 0,
    this.cefrLevel = 'A1',
    this.cefrProgress = 0.0,
    this.lastActivityAt,
    this.firstActivityAt,
    this.activeDays = 0,
  });

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'totalXp': totalXp,
      'level': level,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completedSessions': completedSessions,
      'totalLearningMinutes': totalLearningMinutes,

      'conversationSessions': conversationSessions,
      'writingSessions': writingSessions,
      'readingSessions': readingSessions,
      'listeningSessions': listeningSessions,
      'vocabularySessions': vocabularySessions,
      'pronunciationSessions': pronunciationSessions,
      'grammarSessions': grammarSessions,

      'conversationXp': conversationXp,
      'writingXp': writingXp,
      'readingXp': readingXp,
      'listeningXp': listeningXp,
      'vocabularyXp': vocabularyXp,
      'pronunciationXp': pronunciationXp,
      'grammarXp': grammarXp,

      'cefrLevel': cefrLevel,
      'cefrProgress': cefrProgress,

      'lastActivityAt': lastActivityAt?.toUtc().toIso8601String(),
      'firstActivityAt': firstActivityAt?.toUtc().toIso8601String(),

      'activeDays': activeDays,
    };
  }

  factory LearningProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return LearningProgress(
      totalXp: _readNonNegativeInt(json['totalXp']),
      level: _readPositiveInt(json['level'], fallback: 1),
      currentStreak:
          _readNonNegativeInt(json['currentStreak']),
      bestStreak:
          _readNonNegativeInt(json['bestStreak']),
      completedSessions:
          _readNonNegativeInt(json['completedSessions']),
      totalLearningMinutes:
          _readNonNegativeInt(json['totalLearningMinutes']),

      conversationSessions:
          _readNonNegativeInt(json['conversationSessions']),
      writingSessions:
          _readNonNegativeInt(json['writingSessions']),
      readingSessions:
          _readNonNegativeInt(json['readingSessions']),
      listeningSessions:
          _readNonNegativeInt(json['listeningSessions']),
      vocabularySessions:
          _readNonNegativeInt(json['vocabularySessions']),
      pronunciationSessions:
          _readNonNegativeInt(json['pronunciationSessions']),
      grammarSessions:
          _readNonNegativeInt(json['grammarSessions']),

      conversationXp:
          _readNonNegativeInt(json['conversationXp']),
      writingXp:
          _readNonNegativeInt(json['writingXp']),
      readingXp:
          _readNonNegativeInt(json['readingXp']),
      listeningXp:
          _readNonNegativeInt(json['listeningXp']),
      vocabularyXp:
          _readNonNegativeInt(json['vocabularyXp']),
      pronunciationXp:
          _readNonNegativeInt(json['pronunciationXp']),
      grammarXp:
          _readNonNegativeInt(json['grammarXp']),

      cefrLevel:
          _readCefrLevel(json['cefrLevel']),
      cefrProgress:
          _readProgress(json['cefrProgress']),

      lastActivityAt:
          _readDateTime(json['lastActivityAt']),
      firstActivityAt:
          _readDateTime(json['firstActivityAt']),

      activeDays:
          _readNonNegativeInt(json['activeDays']),
    );
  }

  // ===========================================================================
  // COPY
  // ===========================================================================

  LearningProgress copyWith({
    int? totalXp,
    int? level,
    int? currentStreak,
    int? bestStreak,
    int? completedSessions,
    int? totalLearningMinutes,

    int? conversationSessions,
    int? writingSessions,
    int? readingSessions,
    int? listeningSessions,
    int? vocabularySessions,
    int? pronunciationSessions,
    int? grammarSessions,

    int? conversationXp,
    int? writingXp,
    int? readingXp,
    int? listeningXp,
    int? vocabularyXp,
    int? pronunciationXp,
    int? grammarXp,

    String? cefrLevel,
    double? cefrProgress,

    DateTime? lastActivityAt,
    DateTime? firstActivityAt,

    int? activeDays,
  }) {
    return LearningProgress(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreak:
          currentStreak ?? this.currentStreak,
      bestStreak:
          bestStreak ?? this.bestStreak,
      completedSessions:
          completedSessions ?? this.completedSessions,
      totalLearningMinutes:
          totalLearningMinutes ?? this.totalLearningMinutes,

      conversationSessions:
          conversationSessions ?? this.conversationSessions,
      writingSessions:
          writingSessions ?? this.writingSessions,
      readingSessions:
          readingSessions ?? this.readingSessions,
      listeningSessions:
          listeningSessions ?? this.listeningSessions,
      vocabularySessions:
          vocabularySessions ?? this.vocabularySessions,
      pronunciationSessions:
          pronunciationSessions ?? this.pronunciationSessions,
      grammarSessions:
          grammarSessions ?? this.grammarSessions,

      conversationXp:
          conversationXp ?? this.conversationXp,
      writingXp:
          writingXp ?? this.writingXp,
      readingXp:
          readingXp ?? this.readingXp,
      listeningXp:
          listeningXp ?? this.listeningXp,
      vocabularyXp:
          vocabularyXp ?? this.vocabularyXp,
      pronunciationXp:
          pronunciationXp ?? this.pronunciationXp,
      grammarXp:
          grammarXp ?? this.grammarXp,

      cefrLevel:
          cefrLevel ?? this.cefrLevel,
      cefrProgress:
          cefrProgress ?? this.cefrProgress,

      lastActivityAt:
          lastActivityAt ?? this.lastActivityAt,
      firstActivityAt:
          firstActivityAt ?? this.firstActivityAt,

      activeDays:
          activeDays ?? this.activeDays,
    );
  }

  // ===========================================================================
  // SAFE READERS
  // ===========================================================================

  static int _readNonNegativeInt(dynamic value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final int result = value.toInt();
      return result < 0 ? 0 : result;
    }

    return 0;
  }

  static int _readPositiveInt(
    dynamic value, {
    required int fallback,
  }) {
    final int result = _readNonNegativeInt(value);
    return result > 0 ? result : fallback;
  }

  static double _readProgress(dynamic value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }

    return 0.0;
  }

  static String _readCefrLevel(dynamic value) {
    if (value is String) {
      final String normalized =
          value.trim().toUpperCase();

      const Set<String> validLevels = <String>{
        'A1',
        'A2',
        'B1',
        'B2',
        'C1',
        'C2',
      };

      if (validLevels.contains(normalized)) {
        return normalized;
      }
    }

    return 'A1';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }

    return null;
  }
}