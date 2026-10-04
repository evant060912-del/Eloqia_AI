import '../../models/learning_profile.dart';

/// =============================================================================
/// MIA PERSONALIZATION SERVICE
/// =============================================================================
///
/// Central personalization engine for Mia.
///
/// Responsibilities:
/// • Transform the learner profile into Mia's teaching context.
/// • Generate personalized introductions and coaching messages.
/// • Determine Mia's tone, correction intensity and teaching focus.
/// • Provide contextual recommendations for future sessions.
///
/// Architecture:
///
///     LearningProfile
///           ↓
///     MiaPersonalizationService
///           ↓
///     Mia teaching context
///           ↓
///     MiaScreen / MiaSession / AI backend
///
/// This service contains no Flutter UI code and remains independent from
/// widgets, screens and navigation.
///
/// Future evolution:
///
///     Local personalization
///           ↓
///     Session memory
///           ↓
///     AI-generated adaptation
///           ↓
///     FastAPI / LLM
/// =============================================================================

class MiaPersonalizationService {
  MiaPersonalizationService._();

  // ===========================================================================
  // CORE PROFILE ANALYSIS
  // ===========================================================================

  /// Builds the complete personalization context used by Mia.
  ///
  /// The returned map is intentionally serializable so it can later be sent
  /// directly to the backend / LLM layer.
  static Map<String, dynamic> buildContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'learner': _buildLearnerContext(profile),
      'goals': _buildGoalsContext(profile),
      'learning': _buildLearningContext(profile),
      'communication': _buildCommunicationContext(profile),
      'mia': _buildMiaContext(profile),
      'session': _buildSessionContext(profile),
    };
  }

  // ===========================================================================
  // LEARNER
  // ===========================================================================

  static Map<String, dynamic> _buildLearnerContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'name': _safe(profile.name),
      'currentLevel': _safe(profile.currentLevel),
      'confidenceLevel': _safe(profile.confidenceLevel),
      'strengths': List<String>.from(profile.strengths),
      'difficulties': List<String>.from(profile.difficulties),
      'interests': List<String>.from(profile.interests),
    };
  }

  // ===========================================================================
  // GOALS
  // ===========================================================================

  static Map<String, dynamic> _buildGoalsContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'primaryGoal': _safe(profile.primaryGoal),
      'secondaryGoals':
          List<String>.from(profile.secondaryGoals),
      'motivation': _safe(profile.motivation),
    };
  }

  // ===========================================================================
  // LEARNING STYLE
  // ===========================================================================

  static Map<String, dynamic> _buildLearningContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'preferences':
          List<String>.from(profile.learningPreferences),
      'pace': _safe(profile.learningPace),
      'speakingSituations':
          List<String>.from(profile.speakingSituations),
      'preferredTutorStyle':
          _safe(profile.preferredTutorStyle),
    };
  }

  // ===========================================================================
  // COMMUNICATION
  // ===========================================================================

  static Map<String, dynamic> _buildCommunicationContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'correctionStyle':
          _safe(profile.preferredCorrectionStyle),
      'confidence':
          _safe(profile.confidenceLevel),
    };
  }

  // ===========================================================================
  // MIA PERSONALITY
  // ===========================================================================

  static Map<String, dynamic> _buildMiaContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'name': 'Mia',
      'accent': 'American English; regional accent is not verified',
      'role': 'AI English Tutor',
      'personality': _miaPersonality(profile),
      'teachingStyle': _miaTeachingStyle(profile),
      'correctionIntensity':
          _correctionIntensity(profile),
    };
  }

  // ===========================================================================
  // SESSION
  // ===========================================================================

  static Map<String, dynamic> _buildSessionContext(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'recommendedFocus':
          getRecommendedFocus(profile),
      'recommendedActivity':
          getRecommendedActivity(profile),
      'difficulty':
          getRecommendedDifficulty(profile),
      'openingMessage':
          buildOpeningMessage(profile),
    };
  }

  // ===========================================================================
  // OPENING MESSAGE
  // ===========================================================================

  /// Generates Mia's personalized first message.
  static String buildOpeningMessage(
    LearningProfile profile,
  ) {
    final String name =
        _safe(profile.name);

    final String goal =
        _safe(profile.primaryGoal);

    if (name.isEmpty) {
      return goal.isEmpty
          ? 'Hey! I’m Mia. Ready to make some progress together?'
          : 'Hey! I’m Mia. Let’s work on your English and move toward your goal.';
    }

    if (goal.isEmpty) {
      return 'Hey $name! 👋 I’m Mia. Ready for some English practice?';
    }

    return 'Hey $name! 👋 I’m Mia. '
        'Let’s work on your English and get you closer to $goal.';
  }

  // ===========================================================================
  // PERSONALIZED GREETING
  // ===========================================================================

  static String buildGreeting(
    LearningProfile profile,
  ) {
    final String name =
        _safe(profile.name);

    if (name.isEmpty) {
      return 'Hey! 👋';
    }

    return 'Hey $name! 👋';
  }

  // ===========================================================================
  // RECOMMENDED FOCUS
  // ===========================================================================

  /// Determines the most useful learning focus for the learner.
  static String getRecommendedFocus(
    LearningProfile profile,
  ) {
    if (profile.difficulties.isNotEmpty) {
      return profile.difficulties.first;
    }

    if (profile.primaryGoal.trim().isNotEmpty) {
      return profile.primaryGoal.trim();
    }

    if (profile.strengths.isNotEmpty) {
      return profile.strengths.first;
    }

    return 'English communication';
  }

  // ===========================================================================
  // RECOMMENDED ACTIVITY
  // ===========================================================================

  static String getRecommendedActivity(
    LearningProfile profile,
  ) {
    final List<String> situations =
        profile.speakingSituations;

    if (situations.isNotEmpty) {
      final String situation =
          situations.first.toLowerCase();

      if (situation.contains('school') ||
          situation.contains('academic')) {
        return 'Academic conversation';
      }

      if (situation.contains('travel')) {
        return 'Travel conversation';
      }

      if (situation.contains('work')) {
        return 'Professional conversation';
      }

      if (situation.contains('social')) {
        return 'Natural conversation';
      }
    }

    if (profile.difficulties.isNotEmpty) {
      final String difficulty =
          profile.difficulties.first.toLowerCase();

      if (difficulty.contains('vocabulary')) {
        return 'Vocabulary practice';
      }

      if (difficulty.contains('grammar')) {
        return 'Grammar in context';
      }

      if (difficulty.contains('pronunciation')) {
        return 'Pronunciation practice';
      }

      if (difficulty.contains('listening')) {
        return 'Listening practice';
      }

      if (difficulty.contains('speaking')) {
        return 'Speaking practice';
      }
    }

    return 'Guided conversation';
  }

  // ===========================================================================
  // DIFFICULTY
  // ===========================================================================

  /// Determines how challenging Mia's next activity should feel.
  static String getRecommendedDifficulty(
    LearningProfile profile,
  ) {
    final String level =
        profile.currentLevel
            .trim()
            .toUpperCase();

    switch (level) {
      case 'A1':
        return 'gentle';

      case 'A2':
        return 'gentle_plus';

      case 'B1':
        return 'balanced';

      case 'B2':
        return 'challenging';

      case 'C1':
        return 'advanced';

      case 'C2':
        return 'mastery';

      default:
        return 'balanced';
    }
  }

  // ===========================================================================
  // MIA PERSONALITY
  // ===========================================================================

  static String _miaPersonality(
    LearningProfile profile,
  ) {
    final String style =
        profile.preferredTutorStyle
            .trim()
            .toLowerCase();

    if (style.contains('strict') ||
        style.contains('direct')) {
      return 'focused, direct, precise and motivating';
    }

    if (style.contains('friendly') ||
        style.contains('warm')) {
      return 'warm, encouraging, friendly and patient';
    }

    if (style.contains('energetic')) {
      return 'energetic, enthusiastic, motivating and playful';
    }

    if (style.contains('calm')) {
      return 'calm, patient, reassuring and supportive';
    }

    return 'warm, intelligent, patient, encouraging and adaptive';
  }

  // ===========================================================================
  // TEACHING STYLE
  // ===========================================================================

  static String _miaTeachingStyle(
    LearningProfile profile,
  ) {
    final String pace =
        profile.learningPace
            .trim()
            .toLowerCase();

    if (pace.contains('fast') ||
        pace.contains('intensive')) {
      return 'fast-paced, focused and challenge-oriented';
    }

    if (pace.contains('slow') ||
        pace.contains('relaxed')) {
      return 'calm, progressive and repetition-oriented';
    }

    return 'adaptive, conversational and progressively challenging';
  }

  // ===========================================================================
  // CORRECTION INTENSITY
  // ===========================================================================

  static String _correctionIntensity(
    LearningProfile profile,
  ) {
    final String correction =
        profile.preferredCorrectionStyle
            .trim()
            .toLowerCase();

    if (correction.contains('immediate') ||
        correction.contains('direct') ||
        correction.contains('strict')) {
      return 'high';
    }

    if (correction.contains('gentle') ||
        correction.contains('later') ||
        correction.contains('subtle')) {
      return 'low';
    }

    return 'adaptive';
  }

  // ===========================================================================
  // PERSONALIZED COACHING MESSAGE
  // ===========================================================================

  static String buildCoachingMessage(
    LearningProfile profile,
  ) {
    final String name =
        _safe(profile.name);

    final String focus =
        getRecommendedFocus(profile);

    if (name.isEmpty) {
      return 'Let’s focus on $focus and turn today’s practice into real progress.';
    }

    return '$name, today we’ll focus on $focus and turn your practice into real progress.';
  }

  // ===========================================================================
  // PERSONALIZED MOTIVATION
  // ===========================================================================

  static String buildMotivationMessage(
    LearningProfile profile,
  ) {
    final String motivation =
        _safe(profile.motivation);

    if (motivation.isEmpty) {
      return 'Small steps, consistent practice, real progress. ✨';
    }

    return 'Keep your goal in sight: $motivation. '
        'Every session gets you closer. ✨';
  }

  // ===========================================================================
  // PERSONALIZED SUMMARY
  // ===========================================================================

  static String buildLearnerSummary(
    LearningProfile profile,
  ) {
    final String name =
        _safe(profile.name);

    final String level =
        _safe(profile.currentLevel);

    final String goal =
        _safe(profile.primaryGoal);

    final String focus =
        getRecommendedFocus(profile);

    final String learnerName =
        name.isEmpty ? 'The learner' : name;

    final String levelText =
        level.isEmpty ? 'their current level' : level;

    final String goalText =
        goal.isEmpty ? 'their English goals' : goal;

    return '$learnerName is currently working around $levelText, '
        'with a primary focus on $goalText. '
        'Mia should prioritize $focus while adapting her teaching style '
        'to the learner’s preferences and confidence.';
  }

  // ===========================================================================
  // SAFE STRING
  // ===========================================================================

  static String _safe(
    String value,
  ) {
    return value.trim();
  }
}