import 'package:flutter/foundation.dart';

import '../core/storage/local_storage.dart';
import 'persistent_app_state.dart';

/// Coordinates Eloqia's persistent application lifecycle.
///
/// [PersistentAppController] is the orchestration layer between the
/// application's persistent state and the low-level local storage engine.
///
/// Responsibilities:
/// - restore persistent application state;
/// - expose the current immutable state;
/// - coordinate onboarding lifecycle;
/// - record application activity;
/// - reset Eloqia-owned local data;
/// - prevent duplicate restoration operations.
///
/// This controller does not own:
/// - navigation;
/// - UI;
/// - learner profile business logic;
/// - lesson logic;
/// - progress calculations;
/// - tutor memory;
/// - network synchronization.
///
/// Those responsibilities belong to their respective application layers.
class PersistentAppController extends ChangeNotifier {
  PersistentAppController._();

  /// Global application-level persistence controller.
  ///
  /// Eloqia has one global persistent application lifecycle, so a singleton
  /// controller is appropriate at this architectural level.
  static final PersistentAppController instance =
      PersistentAppController._();

  PersistentAppState _state =
      const PersistentAppState.initial();

  Future<void>? _activeRestore;

  bool _isDisposed = false;

  /// Current immutable application state.
  PersistentAppState get state => _state;

  /// Whether persistence restoration is currently running.
  bool get isRestoring =>
      _activeRestore != null;

  /// Whether onboarding must be presented.
  bool get requiresOnboarding =>
      _state.requiresOnboarding;

  /// Whether Eloqia is ready for its main experience.
  bool get isReady =>
      _state.isReady;

  /// Restores Eloqia's persistent application state.
  ///
  /// Multiple simultaneous calls share the same restoration operation.
  /// This prevents duplicate work during application startup.
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
    _updateState(
      _state.copyWith(
        status: PersistentAppStatus.unknown,
      ),
    );

    try {
      final bool isFirstLaunch =
          await LocalStorage.initialize();

      final int schemaVersion =
          await LocalStorage.readSchemaVersion();

      final DateTime? initializedAt =
          await LocalStorage.readInitializedAt();

      final DateTime? lastActiveAt =
          await LocalStorage.readLastActiveAt();

      final bool onboardingCompleted =
          await LocalStorage.isOnboardingCompleted();

      final PersistentAppStatus status;

      if (isFirstLaunch) {
        status = PersistentAppStatus.firstLaunch;
      } else if (onboardingCompleted) {
        status = PersistentAppStatus.ready;
      } else {
        status =
            PersistentAppStatus.onboardingRequired;
      }

      _updateState(
        PersistentAppState(
          status: status,
          schemaVersion: schemaVersion,
          initializedAt: initializedAt,
          lastActiveAt: lastActiveAt,
        ),
      );
    } catch (_) {
      _updateState(
        _state.copyWith(
          status: PersistentAppStatus.unknown,
        ),
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING
  // ---------------------------------------------------------------------------

  /// Marks onboarding as completed and makes Eloqia ready.
  Future<bool> completeOnboarding() async {
    final bool saved =
        await LocalStorage.saveOnboardingCompleted(
      true,
    );

    if (!saved) {
      return false;
    }

    _updateState(
      _state.copyWith(
        status: PersistentAppStatus.ready,
      ),
    );

    return true;
  }

  /// Reopens onboarding without deleting the learner's other data.
  Future<bool> reopenOnboarding() async {
    final bool saved =
        await LocalStorage.saveOnboardingCompleted(
      false,
    );

    if (!saved) {
      return false;
    }

    _updateState(
      _state.copyWith(
        status:
            PersistentAppStatus.onboardingRequired,
      ),
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY
  // ---------------------------------------------------------------------------

  /// Records the latest application activity timestamp in UTC.
  Future<bool> recordActivity() async {
    final DateTime now =
        DateTime.now().toUtc();

    final bool saved =
        await LocalStorage.saveLastActiveAt(now);

    if (!saved) {
      return false;
    }

    _updateState(
      _state.copyWith(
        lastActiveAt: now,
      ),
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  /// Refreshes the persistent application state.
  Future<void> refresh() {
    return restore();
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  /// Removes every piece of data owned by Eloqia from local persistence.
  ///
  /// This does not affect data outside Eloqia's namespace.
  ///
  /// After a successful reset, the controller returns to its initial state.
  /// The next [restore] operation will correctly identify the application
  /// as a first launch again.
  Future<bool> reset() async {
    final bool cleared =
        await LocalStorage.clearEloqiaData();

    if (!cleared) {
      return false;
    }

    _updateState(
      const PersistentAppState.initial(),
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // DIAGNOSTICS
  // ---------------------------------------------------------------------------

  /// Returns a compact diagnostic snapshot useful during development.
  Map<String, dynamic> diagnostics() {
    return <String, dynamic>{
      'controller':
          'PersistentAppController',
      'state': _state.toJson(),
      'isRestoring': isRestoring,
    };
  }

  // ---------------------------------------------------------------------------
  // INTERNAL STATE MANAGEMENT
  // ---------------------------------------------------------------------------

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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}