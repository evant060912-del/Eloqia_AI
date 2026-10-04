import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/storage/local_storage.dart';
import 'persistent_app_state.dart';

/// Coordinates Eloqia's persistent application lifecycle.
///
/// This controller is the single orchestration point for application-level
/// persistence.
///
/// Responsibilities:
/// - initialize local persistence;
/// - restore the persisted application state;
/// - expose an immutable application state;
/// - coordinate onboarding completion/reopening;
/// - record application activity;
/// - reset Eloqia-owned local data;
/// - prevent duplicated restore operations;
/// - provide lightweight diagnostics.
///
/// This controller deliberately does NOT own:
/// - navigation;
/// - UI;
/// - learner profile business logic;
/// - learning activities;
/// - progress calculations;
/// - tutor memory;
/// - network synchronization.
///
/// Those responsibilities belong to their dedicated layers.
class PersistentAppController extends ChangeNotifier {
  PersistentAppController._();

  /// Global application persistence controller.
  ///
  /// Eloqia has a single application lifecycle, therefore one controller
  /// instance is intentionally shared across the application.
  static final PersistentAppController instance =
      PersistentAppController._();

  // ---------------------------------------------------------------------------
  // INTERNAL STATE
  // ---------------------------------------------------------------------------

  PersistentAppState _state =
      const PersistentAppState.initial();

  Future<void>? _activeRestore;

  bool _isDisposed = false;

  bool _isCompletingOnboarding = false;

  bool _isReopeningOnboarding = false;

  bool _isRecordingActivity = false;

  bool _isResetting = false;

  // ---------------------------------------------------------------------------
  // PUBLIC STATE
  // ---------------------------------------------------------------------------

  /// Current immutable persistent application state.
  PersistentAppState get state => _state;

  /// Whether the controller is currently restoring persistent data.
  bool get isRestoring => _activeRestore != null;

  /// Whether Eloqia currently requires onboarding.
  bool get requiresOnboarding => _state.requiresOnboarding;

  /// Whether Eloqia is ready to display its main experience.
  bool get isReady => _state.isReady;

  /// Whether an onboarding completion operation is currently running.
  bool get isCompletingOnboarding =>
      _isCompletingOnboarding;

  /// Whether an onboarding reopening operation is currently running.
  bool get isReopeningOnboarding =>
      _isReopeningOnboarding;

  /// Whether an activity timestamp is currently being persisted.
  bool get isRecordingActivity =>
      _isRecordingActivity;

  /// Whether a complete Eloqia reset is currently running.
  bool get isResetting => _isResetting;

  // ---------------------------------------------------------------------------
  // RESTORE
  // ---------------------------------------------------------------------------

  /// Restores Eloqia's persistent application state.
  ///
  /// If several parts of the application request restoration simultaneously,
  /// every caller receives the same Future instead of starting duplicate
  /// initialization work.
  Future<void> restore() {
    final Future<void>? activeRestore =
        _activeRestore;

    if (activeRestore != null) {
      return activeRestore;
    }

    final Future<void> restoration =
        _restoreInternal();

    _activeRestore = restoration;

    restoration.whenComplete(() {
      if (identical(
        _activeRestore,
        restoration,
      )) {
        _activeRestore = null;
      }
    });

    return restoration;
  }

  Future<void> _restoreInternal() async {
    _setStatus(
      PersistentAppStatus.unknown,
    );

    try {
      // Initialize the local persistence layer first.
      final bool isFirstLaunch =
          await LocalStorage.initialize();

      // Read all application-level metadata together.
      final int schemaVersion =
          await LocalStorage.readSchemaVersion();

      final DateTime? initializedAt =
          await LocalStorage.readInitializedAt();

      final DateTime? lastActiveAt =
          await LocalStorage.readLastActiveAt();

      final bool onboardingCompleted =
          await LocalStorage.isOnboardingCompleted();

      final PersistentAppStatus status =
          _resolveStatus(
        isFirstLaunch: isFirstLaunch,
        onboardingCompleted: onboardingCompleted,
      );

      _updateState(
        PersistentAppState(
          status: status,
          schemaVersion: schemaVersion,
          initializedAt: initializedAt,
          lastActiveAt: lastActiveAt,
        ),
      );
    } catch (_) {
      // Keep the application in a known non-ready state if restoration fails.
      _setStatus(
        PersistentAppStatus.unknown,
      );

      rethrow;
    }
  }

  PersistentAppStatus _resolveStatus({
    required bool isFirstLaunch,
    required bool onboardingCompleted,
  }) {
    if (isFirstLaunch) {
      return PersistentAppStatus.firstLaunch;
    }

    if (onboardingCompleted) {
      return PersistentAppStatus.ready;
    }

    return PersistentAppStatus.onboardingRequired;
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING
  // ---------------------------------------------------------------------------

  /// Marks onboarding as completed.
  ///
  /// The learner profile itself is intentionally saved by the dedicated
  /// LearningProfileService. This controller only records the application-
  /// level fact that onboarding has been completed.
  ///
  /// The method is idempotent: calling it again when Eloqia is already ready
  /// simply preserves the ready state.
  Future<bool> completeOnboarding() async {
    if (_isDisposed) {
      return false;
    }

    if (_isCompletingOnboarding) {
      return false;
    }

    if (_isResetting) {
      return false;
    }

    _isCompletingOnboarding = true;

    try {
      final bool saved =
          await LocalStorage.saveOnboardingCompleted(
        true,
      );

      if (!saved || _isDisposed) {
        return false;
      }

      _updateState(
        _state.copyWith(
          status: PersistentAppStatus.ready,
        ),
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isCompletingOnboarding = false;
    }
  }

  /// Reopens onboarding without deleting learner data.
  ///
  /// Existing profile, progress and memory remain untouched.
  Future<bool> reopenOnboarding() async {
    if (_isDisposed) {
      return false;
    }

    if (_isReopeningOnboarding) {
      return false;
    }

    if (_isResetting) {
      return false;
    }

    _isReopeningOnboarding = true;

    try {
      final bool saved =
          await LocalStorage.saveOnboardingCompleted(
        false,
      );

      if (!saved || _isDisposed) {
        return false;
      }

      _updateState(
        _state.copyWith(
          status:
              PersistentAppStatus.onboardingRequired,
        ),
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isReopeningOnboarding = false;
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY
  // ---------------------------------------------------------------------------

  /// Persists the latest application activity timestamp in UTC.
  ///
  /// Repeated calls are protected against accidental concurrent writes.
  Future<bool> recordActivity() async {
    if (_isDisposed) {
      return false;
    }

    if (_isRecordingActivity) {
      return false;
    }

    if (_isResetting) {
      return false;
    }

    _isRecordingActivity = true;

    try {
      final DateTime now =
          DateTime.now().toUtc();

      final bool saved =
          await LocalStorage.saveLastActiveAt(
        now,
      );

      if (!saved || _isDisposed) {
        return false;
      }

      _updateState(
        _state.copyWith(
          lastActiveAt: now,
        ),
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isRecordingActivity = false;
    }
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  /// Re-reads the persistent application state.
  ///
  /// This intentionally delegates to [restore] so refreshes benefit from
  /// the same duplicate-operation protection.
  Future<void> refresh() {
    return restore();
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  /// Removes all local data owned by Eloqia.
  ///
  /// This includes application-level persistence managed by Eloqia's storage
  /// layer. Data outside Eloqia's namespace is not touched.
  ///
  /// After a successful reset, the controller returns to its initial state.
  Future<bool> reset() async {
    if (_isDisposed) {
      return false;
    }

    if (_isResetting) {
      return false;
    }

    if (_activeRestore != null) {
      await _activeRestore;
    }

    _isResetting = true;

    try {
      final bool cleared =
          await LocalStorage.clearEloqiaData();

      if (!cleared || _isDisposed) {
        return false;
      }

      _updateState(
        const PersistentAppState.initial(),
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isResetting = false;
    }
  }

  // ---------------------------------------------------------------------------
  // DIAGNOSTICS
  // ---------------------------------------------------------------------------

  /// Returns a compact diagnostic snapshot.
  ///
  /// This is intentionally framework-independent so it can later be exposed
  /// to development tooling, debug panels or automated diagnostics.
  Map<String, dynamic> diagnostics() {
    return <String, dynamic>{
      'controller':
          'PersistentAppController',
      'status':
          _state.status.name,
      'schemaVersion':
          _state.schemaVersion,
      'initializedAt':
          _state.initializedAt?.toIso8601String(),
      'lastActiveAt':
          _state.lastActiveAt?.toIso8601String(),
      'requiresOnboarding':
          requiresOnboarding,
      'isReady':
          isReady,
      'isRestoring':
          isRestoring,
      'isCompletingOnboarding':
          isCompletingOnboarding,
      'isReopeningOnboarding':
          isReopeningOnboarding,
      'isRecordingActivity':
          isRecordingActivity,
      'isResetting':
          isResetting,
    };
  }

  // ---------------------------------------------------------------------------
  // INTERNAL STATE MANAGEMENT
  // ---------------------------------------------------------------------------

  void _setStatus(
    PersistentAppStatus status,
  ) {
    _updateState(
      _state.copyWith(
        status: status,
      ),
    );
  }

  void _updateState(
    PersistentAppState nextState,
  ) {
    if (_isDisposed) {
      return;
    }

    if (_state == nextState) {
      return;
    }

    _state = nextState;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _isDisposed = true;

    _activeRestore = null;

    super.dispose();
  }
}