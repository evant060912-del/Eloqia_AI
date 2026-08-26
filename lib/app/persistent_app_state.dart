import 'package:flutter/foundation.dart';

/// Represents the persistent lifecycle state of Eloqia.
enum PersistentAppStatus {
  /// The persistence state has not been restored yet.
  unknown,

  /// Eloqia is being opened for the first time on this device.
  firstLaunch,

  /// Eloqia has been initialized, but onboarding is not complete.
  onboardingRequired,

  /// Eloqia is fully initialized and ready for the main experience.
  ready,
}

/// Immutable snapshot of Eloqia's persistent application state.
///
/// This object contains state only.
///
/// It deliberately has no dependency on:
/// - SharedPreferences;
/// - LocalStorage;
/// - navigation;
/// - widgets;
/// - onboarding implementation;
/// - learner profile implementation;
/// - lessons;
/// - progress;
/// - tutor memory;
///
/// This separation keeps the application state predictable, testable,
/// maintainable, and ready for future synchronization with a backend.
@immutable
class PersistentAppState {
  const PersistentAppState({
    required this.status,
    required this.schemaVersion,
    this.initializedAt,
    this.lastActiveAt,
  });

  /// Creates the state used before persistence restoration.
  const PersistentAppState.initial()
      : status = PersistentAppStatus.unknown,
        schemaVersion = 1,
        initializedAt = null,
        lastActiveAt = null;

  /// Current persistent application status.
  final PersistentAppStatus status;

  /// Version of the local persistence schema.
  final int schemaVersion;

  /// Timestamp of Eloqia's first local persistence initialization.
  final DateTime? initializedAt;

  /// Timestamp of the latest recorded application activity.
  final DateTime? lastActiveAt;

  /// Whether the persistent state is still unknown.
  bool get isUnknown =>
      status == PersistentAppStatus.unknown;

  /// Whether Eloqia is being opened for the first time.
  bool get isFirstLaunch =>
      status == PersistentAppStatus.firstLaunch;

  /// Whether onboarding must be presented.
  bool get requiresOnboarding =>
      status == PersistentAppStatus.onboardingRequired;

  /// Whether Eloqia is ready for the main application experience.
  bool get isReady =>
      status == PersistentAppStatus.ready;

  /// Creates a new immutable state while preserving unchanged values.
  PersistentAppState copyWith({
    PersistentAppStatus? status,
    int? schemaVersion,
    DateTime? initializedAt,
    DateTime? lastActiveAt,
  }) {
    return PersistentAppState(
      status: status ?? this.status,
      schemaVersion:
          schemaVersion ?? this.schemaVersion,
      initializedAt:
          initializedAt ?? this.initializedAt,
      lastActiveAt:
          lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Serializes the state for diagnostics and observability.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'schemaVersion': schemaVersion,
      'initializedAt':
          initializedAt?.toUtc().toIso8601String(),
      'lastActiveAt':
          lastActiveAt?.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PersistentAppState('
        'status: ${status.name}, '
        'schemaVersion: $schemaVersion, '
        'initializedAt: $initializedAt, '
        'lastActiveAt: $lastActiveAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PersistentAppState &&
        other.status == status &&
        other.schemaVersion == schemaVersion &&
        other.initializedAt == initializedAt &&
        other.lastActiveAt == lastActiveAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      schemaVersion,
      initializedAt,
      lastActiveAt,
    );
  }
}
