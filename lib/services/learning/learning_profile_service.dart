import '../../models/learning_profile.dart';
import '../../core/storage/learning_profile_storage.dart';
import '../../core/storage/local_storage.dart';

/// High-level domain service for Eloqia learner profiles.
///
/// [LearningProfileService] is the business-facing gateway for learner
/// profile operations.
///
/// Architecture:
///
///     UI / Onboarding / AI / Learning Engine
///                    ↓
///          LearningProfileService
///                    ↓
///          LearningProfileStorage
///                    ↓
///               LocalStorage
///
/// Responsibilities:
/// • Profile initialization.
/// • Profile retrieval.
/// • Profile persistence.
/// • Profile updates.
/// • Onboarding completion state.
/// • Safe profile replacement.
/// • Profile validation.
/// • Input normalization.
/// • Lightweight profile snapshots.
///
/// Deliberately excluded:
/// • Flutter UI.
/// • Navigation.
/// • AI provider calls.
/// • Prompt generation.
/// • Lesson generation.
/// • Progress calculation.
/// • Memory intelligence.
/// • Network synchronization.
///
/// LearningProfile remains the single source of truth for learner
/// personalization.
class LearningProfileService {
  LearningProfileService._();

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Returns the current learner profile.
  ///
  /// If no valid profile exists, a default profile is created and persisted.
  static Future<LearningProfile> getProfile() async {
    final LearningProfile? stored = await LearningProfileStorage.load();

    if (stored != null && stored.isComplete()) {
      return stored;
    }

    final LearningProfile initial = LearningProfile();

    await LearningProfileStorage.save(initial);

    return initial;
  }

  /// Initializes the learner profile if necessary.
  ///
  /// Returns the resulting profile regardless of whether it already existed.
  static Future<LearningProfile> initialize() async {
    return getProfile();
  }

  // ===========================================================================
  // PERSISTENCE
  // ===========================================================================

  /// Saves a complete learner profile after validation.
  static Future<LearningProfile?> saveProfile(LearningProfile profile) async {
    if (!profile.isComplete()) {
      return null;
    }

    final bool saved = await LearningProfileStorage.save(profile);

    return saved ? profile : null;
  }

  /// Replaces the current learner profile.
  ///
  /// This is intentionally explicit because the profile is the single source
  /// of truth for personalization.
  static Future<LearningProfile?> replaceProfile(
    LearningProfile profile,
  ) async {
    return saveProfile(profile);
  }

  // ===========================================================================
  // ONBOARDING
  // ===========================================================================

  /// Marks the learner onboarding as completed.
  ///
  /// The actual onboarding answers remain inside [LearningProfile].
  /// This method only updates the onboarding lifecycle state when supported
  /// by the current profile model.
  static Future<LearningProfile?> completeOnboarding() async {
    final LearningProfile profile = await getProfile();

    final bool markedCompleted = await LocalStorage.saveOnboardingCompleted(
      true,
    );

    return markedCompleted ? saveProfile(profile) : null;
  }

  /// Returns whether onboarding has been completed.
  static Future<bool> isOnboardingCompleted() async {
    return LocalStorage.isOnboardingCompleted();
  }

  // ===========================================================================
  // PROFILE UPDATES
  // ===========================================================================

  /// Updates the learner's name.
  static Future<LearningProfile?> updateName(String name) async {
    final String? normalized = _normalizeNullable(name);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(name: normalized));
  }

  /// Updates the learner's primary learning goal.
  static Future<LearningProfile?> updatePrimaryGoal(String goal) async {
    final String? normalized = _normalizeNullable(goal);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(primaryGoal: normalized));
  }

  /// Updates the learner's current CEFR level.
  static Future<LearningProfile?> updateCurrentLevel(String level) async {
    final String? normalized = _normalizeLevel(level);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(currentLevel: normalized));
  }

  /// Updates the learner's confidence level.
  static Future<LearningProfile?> updateConfidenceLevel(
    String confidence,
  ) async {
    final String? normalized = _normalizeNullable(confidence);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(confidenceLevel: normalized));
  }

  /// Updates the learner's motivation.
  static Future<LearningProfile?> updateMotivation(String motivation) async {
    final String? normalized = _normalizeNullable(motivation);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(motivation: normalized));
  }

  /// Updates the learner's preferred learning pace.
  static Future<LearningProfile?> updateLearningPace(String pace) async {
    final String? normalized = _normalizeNullable(pace);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(learningPace: normalized));
  }

  /// Updates the learner's preferred tutor style.
  static Future<LearningProfile?> updateTutorStyle(String style) async {
    final String? normalized = _normalizeNullable(style);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(preferredTutorStyle: normalized));
  }

  // ===========================================================================
  // PERSONALIZATION COLLECTIONS
  // ===========================================================================

  /// Replaces the learner's secondary goals.
  static Future<LearningProfile?> updateSecondaryGoals(
    Iterable<String> goals,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(secondaryGoals: _normalizeStringList(goals)),
    );
  }

  /// Replaces the learner's difficulties.
  static Future<LearningProfile?> updateDifficulties(
    Iterable<String> difficulties,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(difficulties: _normalizeStringList(difficulties)),
    );
  }

  /// Replaces the learner's strengths.
  static Future<LearningProfile?> updateStrengths(
    Iterable<String> strengths,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(strengths: _normalizeStringList(strengths)),
    );
  }

  /// Replaces preferred speaking situations.
  static Future<LearningProfile?> updateSpeakingSituations(
    Iterable<String> situations,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(speakingSituations: _normalizeStringList(situations)),
    );
  }

  /// Replaces learning preferences.
  static Future<LearningProfile?> updateLearningPreferences(
    Iterable<String> preferences,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(learningPreferences: _normalizeStringList(preferences)),
    );
  }

  /// Replaces learner interests.
  static Future<LearningProfile?> updateInterests(
    Iterable<String> interests,
  ) async {
    final LearningProfile profile = await getProfile();

    return saveProfile(
      profile.copyWith(interests: _normalizeStringList(interests)),
    );
  }

  // ===========================================================================
  // CORRECTION STYLE
  // ===========================================================================

  /// Updates the learner's preferred correction style.
  static Future<LearningProfile?> updateCorrectionStyle(String style) async {
    final String? normalized = _normalizeNullable(style);

    if (normalized == null) {
      return null;
    }

    final LearningProfile profile = await getProfile();

    return saveProfile(profile.copyWith(preferredCorrectionStyle: normalized));
  }

  // ===========================================================================
  // SNAPSHOT
  // ===========================================================================

  /// Returns a compact profile snapshot for application consumers.
  ///
  /// The snapshot contains personalization data without exposing persistence
  /// implementation details.
  static Future<Map<String, dynamic>> getSnapshot() async {
    final LearningProfile profile = await getProfile();

    return <String, dynamic>{
      'name': profile.name,
      'primaryGoal': profile.primaryGoal,
      'secondaryGoals': List<String>.from(profile.secondaryGoals),
      'difficulties': List<String>.from(profile.difficulties),
      'strengths': List<String>.from(profile.strengths),
      'confidenceLevel': profile.confidenceLevel,
      'speakingSituations': List<String>.from(profile.speakingSituations),
      'learningPreferences': List<String>.from(profile.learningPreferences),
      'preferredCorrectionStyle': profile.preferredCorrectionStyle,
      'motivation': profile.motivation,
      'learningPace': profile.learningPace,
      'interests': List<String>.from(profile.interests),
      'preferredTutorStyle': profile.preferredTutorStyle,
      'currentLevel': profile.currentLevel,
      'onboardingCompleted': await LocalStorage.isOnboardingCompleted(),
    };
  }

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// Returns whether a usable learner profile currently exists.
  static Future<bool> exists() async {
    final LearningProfile? profile = await LearningProfileStorage.load();

    return profile != null && profile.isComplete();
  }

  /// Clears the learner profile.
  ///
  /// This does not affect progression, sessions or learner memory.
  static Future<bool> clear() async {
    return LearningProfileStorage.clear();
  }

  /// Resets the profile to a clean initial state.
  static Future<bool> reset() async {
    return clear();
  }

  // ===========================================================================
  // NORMALIZATION
  // ===========================================================================

  static String? _normalizeNullable(String? value) {
    final String normalized = value?.trim() ?? '';

    return normalized.isEmpty ? null : normalized;
  }

  static String? _normalizeLevel(String? value) {
    final String? normalized = _normalizeNullable(value);

    return normalized?.toUpperCase();
  }

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
}
