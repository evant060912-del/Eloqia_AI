class LearningProfile {
  LearningProfile({
    this.name = '',
    this.primaryGoal = '',
    List<String>? secondaryGoals,
    List<String>? difficulties,
    List<String>? strengths,
    this.currentLevel = '',
    this.confidenceLevel = '',
    List<String>? speakingSituations,
    List<String>? learningPreferences,
    this.preferredCorrectionStyle = '',
    this.motivation = '',
    this.learningPace = '',
    List<String>? interests,
    this.preferredTutorStyle = '',
  })  : secondaryGoals = List<String>.from(
          secondaryGoals ?? const <String>[],
        ),
        difficulties = List<String>.from(
          difficulties ?? const <String>[],
        ),
        strengths = List<String>.from(
          strengths ?? const <String>[],
        ),
        speakingSituations = List<String>.from(
          speakingSituations ?? const <String>[],
        ),
        learningPreferences = List<String>.from(
          learningPreferences ?? const <String>[],
        ),
        interests = List<String>.from(
          interests ?? const <String>[],
        );

  String name;

  String primaryGoal;

  final List<String> secondaryGoals;

  final List<String> difficulties;

  final List<String> strengths;

  String currentLevel;

  String confidenceLevel;

  final List<String> speakingSituations;

  final List<String> learningPreferences;

  String preferredCorrectionStyle;

  String motivation;

  String learningPace;

  final List<String> interests;

  String preferredTutorStyle;

  /// Indique si le profil contient les informations essentielles.
  bool isComplete() {
    return name.trim().isNotEmpty &&
        primaryGoal.trim().isNotEmpty &&
        difficulties.isNotEmpty &&
        currentLevel.trim().isNotEmpty &&
        motivation.trim().isNotEmpty;
  }

  /// Transforme le profil en données JSON sérialisables.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'primaryGoal': primaryGoal,
      'secondaryGoals': List<String>.from(secondaryGoals),
      'difficulties': List<String>.from(difficulties),
      'strengths': List<String>.from(strengths),
      'currentLevel': currentLevel,
      'confidenceLevel': confidenceLevel,
      'speakingSituations': List<String>.from(speakingSituations),
      'learningPreferences': List<String>.from(learningPreferences),
      'preferredCorrectionStyle': preferredCorrectionStyle,
      'motivation': motivation,
      'learningPace': learningPace,
      'interests': List<String>.from(interests),
      'preferredTutorStyle': preferredTutorStyle,
    };
  }

  /// Reconstruit un profil depuis des données JSON.
  ///
  /// Les données manquantes ou invalides sont ignorées proprement.
  factory LearningProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return LearningProfile(
      name: _readString(json, 'name'),
      primaryGoal: _readString(json, 'primaryGoal'),
      secondaryGoals: _readStringList(json, 'secondaryGoals'),
      difficulties: _readStringList(json, 'difficulties'),
      strengths: _readStringList(json, 'strengths'),
      currentLevel: _readString(json, 'currentLevel'),
      confidenceLevel: _readString(json, 'confidenceLevel'),
      speakingSituations: _readStringList(
        json,
        'speakingSituations',
      ),
      learningPreferences: _readStringList(
        json,
        'learningPreferences',
      ),
      preferredCorrectionStyle: _readString(
        json,
        'preferredCorrectionStyle',
      ),
      motivation: _readString(
        json,
        'motivation',
      ),
      learningPace: _readString(
        json,
        'learningPace',
      ),
      interests: _readStringList(
        json,
        'interests',
      ),
      preferredTutorStyle: _readString(
        json,
        'preferredTutorStyle',
      ),
    );
  }

  /// Crée une copie indépendante du profil.
  LearningProfile copyWith({
    String? name,
    String? primaryGoal,
    List<String>? secondaryGoals,
    List<String>? difficulties,
    List<String>? strengths,
    String? currentLevel,
    String? confidenceLevel,
    List<String>? speakingSituations,
    List<String>? learningPreferences,
    String? preferredCorrectionStyle,
    String? motivation,
    String? learningPace,
    List<String>? interests,
    String? preferredTutorStyle,
  }) {
    return LearningProfile(
      name: name ?? this.name,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      secondaryGoals:
          secondaryGoals ?? List<String>.from(this.secondaryGoals),
      difficulties:
          difficulties ?? List<String>.from(this.difficulties),
      strengths:
          strengths ?? List<String>.from(this.strengths),
      currentLevel:
          currentLevel ?? this.currentLevel,
      confidenceLevel:
          confidenceLevel ?? this.confidenceLevel,
      speakingSituations:
          speakingSituations ??
              List<String>.from(this.speakingSituations),
      learningPreferences:
          learningPreferences ??
              List<String>.from(this.learningPreferences),
      preferredCorrectionStyle:
          preferredCorrectionStyle ??
              this.preferredCorrectionStyle,
      motivation:
          motivation ?? this.motivation,
      learningPace:
          learningPace ?? this.learningPace,
      interests:
          interests ?? List<String>.from(this.interests),
      preferredTutorStyle:
          preferredTutorStyle ?? this.preferredTutorStyle,
    );
  }

  /// Réinitialise complètement le profil.
  void reset() {
    name = '';
    primaryGoal = '';

    secondaryGoals.clear();
    difficulties.clear();
    strengths.clear();

    currentLevel = '';
    confidenceLevel = '';

    speakingSituations.clear();
    learningPreferences.clear();

    preferredCorrectionStyle = '';
    motivation = '';
    learningPace = '';

    interests.clear();
    preferredTutorStyle = '';
  }

  /// Vérifie si une valeur texte peut être récupérée proprement.
  static String _readString(
    Map<String, dynamic> json,
    String key,
  ) {
    final dynamic value = json[key];

    if (value is String) {
      return value;
    }

    return '';
  }

  /// Récupère uniquement les valeurs texte d'une liste JSON.
  static List<String> _readStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final dynamic value = json[key];

    if (value is! List<dynamic>) {
      return <String>[];
    }

    return value
        .whereType<String>()
        .where((String item) => item.trim().isNotEmpty)
        .toList();
  }
}