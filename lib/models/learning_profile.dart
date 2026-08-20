class LearningProfile {
  String name = '';

  String primaryGoal = '';

  final List<String> secondaryGoals = [];

  final List<String> difficulties = [];

  final List<String> strengths = [];

  String currentLevel = '';

  String confidenceLevel = '';

  final List<String> speakingSituations = [];

  final List<String> learningPreferences = [];

  String preferredCorrectionStyle = '';

  String motivation = '';

  String learningPace = '';

  final List<String> interests = [];

  String preferredTutorStyle = '';

  bool isComplete() {
    return name.trim().isNotEmpty &&
        primaryGoal.isNotEmpty &&
        difficulties.isNotEmpty &&
        currentLevel.isNotEmpty &&
        motivation.isNotEmpty;
  }

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
}