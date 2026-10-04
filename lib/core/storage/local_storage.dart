import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Low-level local persistence engine for Eloqia.
///
/// [LocalStorage] is the technical foundation of the application's
/// on-device persistence layer.
///
/// Responsibilities:
/// - initialize local persistence safely;
/// - persist primitive values;
/// - persist JSON payloads;
/// - expose Eloqia-owned persistence keys;
/// - maintain application persistence metadata;
/// - provide safe Eloqia-only data removal.
///
/// Business logic does not belong in this class.
///
/// Feature-specific persistence must be implemented by dedicated services,
/// such as [LearningProfileStorage], [ProgressStorage], [SessionStorage],
/// or [MemoryStorage].
class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _preferences;

  static Future<bool>? _initialization;

  /// Private namespace used by every Eloqia-owned persistence key.
  static const String namespace = 'eloqia';

  // ---------------------------------------------------------------------------
  // APPLICATION METADATA
  // ---------------------------------------------------------------------------

  static const String schemaVersionKey = '$namespace.system.schema_version';

  static const String initializedAtKey = '$namespace.system.initialized_at';

  static const String lastActiveAtKey = '$namespace.system.last_active_at';

  // ---------------------------------------------------------------------------
  // LEARNER PROFILE
  // ---------------------------------------------------------------------------

  static const String learningProfileKey = '$namespace.profile.learning';

  static const String onboardingCompletedKey =
      '$namespace.profile.onboarding_completed';

  // ---------------------------------------------------------------------------
  // LEARNING DATA
  // ---------------------------------------------------------------------------

  static const String progressKey = '$namespace.learning.progress';

  static const String sessionsKey = '$namespace.learning.sessions';

  static const String memoryKey = '$namespace.learning.memory';

  static const String coursesKey = '$namespace.learning.courses';

  static const String assessmentKey = '$namespace.learning.assessment';

  /// Current version of Eloqia's local persistence schema.
  ///
  /// This version must be incremented whenever the persisted data format
  /// changes in a way that requires a migration.
  static const int currentSchemaVersion = 1;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  /// Initializes Eloqia's local persistence.
  ///
  /// Returns `true` when no previous Eloqia initialization marker existed.
  ///
  /// Multiple simultaneous calls share the same initialization operation.
  /// This guarantees that application startup cannot accidentally initialize
  /// the persistence layer multiple times.
  static Future<bool> initialize() {
    final Future<bool>? activeInitialization = _initialization;

    if (activeInitialization != null) {
      return activeInitialization;
    }

    final Future<bool> initialization = _initializeInternal();

    _initialization = initialization;

    initialization.whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });

    return initialization;
  }

  static Future<bool> _initializeInternal() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final bool isFirstLaunch = !preferences.containsKey(initializedAtKey);

    if (!preferences.containsKey(initializedAtKey)) {
      final bool initialized = await preferences.setString(
        initializedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      if (!initialized) {
        throw StateError(
          'Eloqia could not persist its initialization timestamp.',
        );
      }
    }

    if (!preferences.containsKey(schemaVersionKey)) {
      final bool schemaCreated = await preferences.setInt(
        schemaVersionKey,
        currentSchemaVersion,
      );

      if (!schemaCreated) {
        throw StateError('Eloqia could not persist its local schema version.');
      }
    }

    _preferences = preferences;

    return isFirstLaunch;
  }

  /// Returns the initialized [SharedPreferences] instance.
  static Future<SharedPreferences> get instance async {
    if (_preferences == null) {
      await initialize();
    }

    return _preferences!;
  }

  // ---------------------------------------------------------------------------
  // STRING
  // ---------------------------------------------------------------------------

  static Future<bool> saveString(String key, String value) async {
    final SharedPreferences preferences = await instance;

    return preferences.setString(key, value);
  }

  static Future<String?> readString(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.getString(key);
  }

  // ---------------------------------------------------------------------------
  // INTEGER
  // ---------------------------------------------------------------------------

  static Future<bool> saveInt(String key, int value) async {
    final SharedPreferences preferences = await instance;

    return preferences.setInt(key, value);
  }

  static Future<int?> readInt(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.getInt(key);
  }

  // ---------------------------------------------------------------------------
  // DOUBLE
  // ---------------------------------------------------------------------------

  static Future<bool> saveDouble(String key, double value) async {
    final SharedPreferences preferences = await instance;

    return preferences.setDouble(key, value);
  }

  static Future<double?> readDouble(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.getDouble(key);
  }

  // ---------------------------------------------------------------------------
  // BOOLEAN
  // ---------------------------------------------------------------------------

  static Future<bool> saveBool(String key, bool value) async {
    final SharedPreferences preferences = await instance;

    return preferences.setBool(key, value);
  }

  static Future<bool?> readBool(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.getBool(key);
  }

  // ---------------------------------------------------------------------------
  // STRING LIST
  // ---------------------------------------------------------------------------

  static Future<bool> saveStringList(String key, List<String> values) async {
    final SharedPreferences preferences = await instance;

    return preferences.setStringList(key, List<String>.from(values));
  }

  static Future<List<String>?> readStringList(String key) async {
    final SharedPreferences preferences = await instance;

    final List<String>? values = preferences.getStringList(key);

    if (values == null) {
      return null;
    }

    return List<String>.from(values);
  }

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  /// Persists an object as a JSON string.
  ///
  /// Returns `false` when the value cannot be serialized or persisted.
  static Future<bool> saveJson(String key, Object value) async {
    try {
      final String encoded = jsonEncode(value);

      return await saveString(key, encoded);
    } on Object {
      return false;
    }
  }

  /// Reads and decodes a JSON value.
  ///
  /// Returns `null` when the key is missing, empty, or contains invalid JSON.
  static Future<dynamic> readJson(String key) async {
    final String? encoded = await readString(key);

    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(encoded);
    } on FormatException {
      return null;
    }
  }

  /// Reads a JSON object as a strongly typed map.
  static Future<Map<String, dynamic>?> readJsonMap(String key) async {
    final dynamic value = await readJson(key);

    if (value is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(value);
  }

  // ---------------------------------------------------------------------------
  // KEY MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Returns whether a key currently exists.
  static Future<bool> containsKey(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.containsKey(key);
  }

  /// Removes one persisted value.
  static Future<bool> delete(String key) async {
    final SharedPreferences preferences = await instance;

    return preferences.remove(key);
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING
  // ---------------------------------------------------------------------------

  /// Persists the onboarding completion state.
  static Future<bool> saveOnboardingCompleted(bool completed) {
    return saveBool(onboardingCompletedKey, completed);
  }

  /// Returns whether the onboarding has been completed.
  ///
  /// Missing data safely defaults to `false`.
  static Future<bool> isOnboardingCompleted() async {
    final bool? completed = await readBool(onboardingCompletedKey);

    return completed ?? false;
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY
  // ---------------------------------------------------------------------------

  /// Persists the latest application activity timestamp in UTC.
  static Future<bool> saveLastActiveAt(DateTime value) {
    return saveString(lastActiveAtKey, value.toUtc().toIso8601String());
  }

  /// Reads the latest application activity timestamp.
  static Future<DateTime?> readLastActiveAt() async {
    final String? value = await readString(lastActiveAtKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }

  // ---------------------------------------------------------------------------
  // METADATA
  // ---------------------------------------------------------------------------

  /// Returns the locally stored persistence schema version.
  static Future<int> readSchemaVersion() async {
    final int? version = await readInt(schemaVersionKey);

    return version ?? currentSchemaVersion;
  }

  /// Returns the timestamp at which local persistence was initialized.
  static Future<DateTime?> readInitializedAt() async {
    final String? value = await readString(initializedAtKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toUtc();
  }

  // ---------------------------------------------------------------------------
  // ELOQIA RESET
  // ---------------------------------------------------------------------------

  /// Removes every persisted key owned by Eloqia.
  ///
  /// Data belonging to other applications or unrelated namespaces remains
  /// untouched.
  static Future<bool> clearEloqiaData() async {
    final SharedPreferences preferences = await instance;

    final List<String> eloqiaKeys = preferences
        .getKeys()
        .where((String key) => key.startsWith('$namespace.'))
        .toList();

    bool success = true;

    for (final String key in eloqiaKeys) {
      final bool removed = await preferences.remove(key);

      if (!removed && preferences.containsKey(key)) {
        success = false;
      }
    }

    return success;
  }
}
