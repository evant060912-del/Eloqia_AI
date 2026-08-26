import '../../models/learning_profile.dart';
import 'local_storage.dart';

/// Persistent storage service dedicated to the Eloqia learning profile.
///
/// `LearningProfile` remains the single source of truth for learner
/// personalization. This service is responsible only for persistence,
/// restoration and integrity checks.
///
/// Storage flow:
///
///     LearningProfile
///           ↓
///     LearningProfileStorage
///           ↓
///       LocalStorage
///           ↓
///   SharedPreferences
///
/// The service is intentionally stateless and exposes a small,
/// predictable API suitable for the future cloud synchronization layer.
class LearningProfileStorage {
  LearningProfileStorage._();

  // ===========================================================================
  // STORAGE CONFIGURATION
  // ===========================================================================

  /// Current persistence format used for the learning profile.
  ///
  /// This version belongs to the storage envelope, not to the
  /// `LearningProfile` model itself.
  static const int storageVersion = 1;

  // ===========================================================================
  // SAVE
  // ===========================================================================

  /// Saves the complete learner profile.
  ///
  /// The profile itself remains untouched. A lightweight storage envelope
  /// is used so Eloqia can evolve its persistence format in future versions
  /// without changing the domain model.
  static Future<bool> save(
    LearningProfile profile,
  ) async {
    final Map<String, dynamic> payload =
        _createPayload(profile);

    return LocalStorage.saveJson(
      LocalStorage.learningProfileKey,
      payload,
    );
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  /// Restores the previously saved learner profile.
  ///
  /// Returns `null` when:
  ///
  /// - no profile has been saved;
  /// - the stored data is invalid;
  /// - the stored profile cannot be reconstructed safely.
  static Future<LearningProfile?> load() async {
    final Map<String, dynamic>? payload =
        await LocalStorage.readJsonMap(
      LocalStorage.learningProfileKey,
    );

    if (payload == null) {
      return null;
    }

    final Map<String, dynamic>? profileData =
        _extractProfileData(payload);

    if (profileData == null) {
      return null;
    }

    try {
      return LearningProfile.fromJson(
        profileData,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // EXISTENCE
  // ===========================================================================

  /// Returns `true` when a persisted learning profile exists.
  static Future<bool> exists() async {
    return LocalStorage.containsKey(
      LocalStorage.learningProfileKey,
    );
  }

  // ===========================================================================
  // COMPLETION
  // ===========================================================================

  /// Returns `true` when the persisted profile exists and
  /// satisfies the completion rules defined by `LearningProfile`.
  static Future<bool> isComplete() async {
    final LearningProfile? profile =
        await load();

    return profile?.isComplete() ?? false;
  }

  // ===========================================================================
  // SAVE + VERIFY
  // ===========================================================================

  /// Saves a profile and verifies that it can immediately be restored.
  ///
  /// This gives Eloqia an additional integrity check at the persistence
  /// boundary and prevents silently accepting corrupted profile data.
  static Future<bool> saveAndVerify(
    LearningProfile profile,
  ) async {
    final bool saved =
        await save(profile);

    if (!saved) {
      return false;
    }

    final LearningProfile? restored =
        await load();

    if (restored == null) {
      return false;
    }

    return _profilesAreEqual(
      profile,
      restored,
    );
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  /// Permanently removes the persisted learning profile.
  ///
  /// Other Eloqia data remains untouched.
  static Future<bool> clear() async {
    return LocalStorage.delete(
      LocalStorage.learningProfileKey,
    );
  }

  // ===========================================================================
  // STORAGE METADATA
  // ===========================================================================

  /// Returns the current local storage format version.
  static int get version => storageVersion;

  // ===========================================================================
  // PRIVATE PAYLOAD
  // ===========================================================================

  /// Creates the storage envelope.
  ///
  /// Keeping metadata outside the domain model allows the model to remain
  /// focused exclusively on learner data.
  static Map<String, dynamic> _createPayload(
    LearningProfile profile,
  ) {
    return <String, dynamic>{
      'version': storageVersion,
      'savedAt': DateTime.now()
          .toUtc()
          .toIso8601String(),
      'profile': profile.toJson(),
    };
  }

  /// Extracts the actual profile data from the storage envelope.
  ///
  /// The method also supports the direct profile format used by earlier
  /// persistence implementations. This makes the storage layer more
  /// tolerant of an existing local installation.
  static Map<String, dynamic>? _extractProfileData(
    Map<String, dynamic> payload,
  ) {
    final dynamic nestedProfile =
        payload['profile'];

    if (nestedProfile is Map) {
      return Map<String, dynamic>.from(
        nestedProfile,
      );
    }

    if (_looksLikeProfile(payload)) {
      return Map<String, dynamic>.from(
        payload,
      );
    }

    return null;
  }

  /// Determines whether a map looks like a serialized LearningProfile.
  static bool _looksLikeProfile(
    Map<String, dynamic> data,
  ) {
    const Set<String> profileFields = <String>{
      'name',
      'primaryGoal',
      'secondaryGoals',
      'difficulties',
      'strengths',
      'currentLevel',
      'confidenceLevel',
      'speakingSituations',
      'learningPreferences',
      'preferredCorrectionStyle',
      'motivation',
      'learningPace',
      'interests',
      'preferredTutorStyle',
    };

    return data.keys.any(
      profileFields.contains,
    );
  }

  // ===========================================================================
  // PROFILE INTEGRITY
  // ===========================================================================

  /// Performs a complete value comparison between two profiles.
  ///
  /// Lists are compared element by element instead of relying on
  /// object identity or string representations.
  static bool _profilesAreEqual(
    LearningProfile first,
    LearningProfile second,
  ) {
    return _mapsAreEqual(
      first.toJson(),
      second.toJson(),
    );
  }

  static bool _mapsAreEqual(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (final String key in first.keys) {
      if (!second.containsKey(key)) {
        return false;
      }

      if (!_valuesAreEqual(
        first[key],
        second[key],
      )) {
        return false;
      }
    }

    return true;
  }

  static bool _valuesAreEqual(
    dynamic first,
    dynamic second,
  ) {
    if (first is List && second is List) {
      if (first.length != second.length) {
        return false;
      }

      for (int index = 0;
          index < first.length;
          index++) {
        if (!_valuesAreEqual(
          first[index],
          second[index],
        )) {
          return false;
        }
      }

      return true;
    }

    if (first is Map && second is Map) {
      return _mapsAreEqual(
        Map<String, dynamic>.from(first),
        Map<String, dynamic>.from(second),
      );
    }

    return first == second;
  }
}