import 'package:flutter/foundation.dart';
import 'package:eloqia_ai/core/storage/local_storage.dart';

/// Defines the lifecycle of Eloqia during application startup.
enum AppBootstrapStatus {
  idle,
  initializing,
  onboardingRequired,
  ready,
  failed,
}

/// Immutable application bootstrap state.
///
/// This object contains only application-level startup information.
/// Feature-specific data remains inside its dedicated storage services.
@immutable
class AppBootstrapState {
  const AppBootstrapState({
    required this.status,
    required this.schemaVersion,
    this.initializedAt,
    this.lastActiveAt,
    this.error,
  });

  final AppBootstrapStatus status;

  final int schemaVersion;

  final DateTime? initializedAt;

  final DateTime? lastActiveAt;

  final Object? error;

  bool get isIdle {
    return status == AppBootstrapStatus.idle;
  }

  bool get isInitializing {
    return status == AppBootstrapStatus.initializing;
  }

  bool get requiresOnboarding {
    return status == AppBootstrapStatus.onboardingRequired;
  }

  bool get isReady {
    return status == AppBootstrapStatus.ready;
  }

  bool get hasFailed {
    return status == AppBootstrapStatus.failed;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.name,
      'schemaVersion': schemaVersion,
      'initializedAt': initializedAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'error': error?.toString(),
    };
  }

  @override
  String toString() {
    return 'AppBootstrapState('
        'status: ${status.name}, '
        'schemaVersion: $schemaVersion, '
        'isReady: $isReady, '
        'requiresOnboarding: $requiresOnboarding'
        ')';
  }
}

/// Coordinates Eloqia's application startup lifecycle.
///
/// Responsibilities:
/// - initialize local persistence;
/// - restore application metadata;
/// - determine the initial application state;
/// - record application activity;
/// - expose a predictable state to the application.
///
/// This class intentionally does not manage:
/// - navigation;
/// - UI;
/// - learner profile business logic;
/// - progress;
/// - sessions;
/// - AI memory;
/// - courses.
class AppBootstrap extends ChangeNotifier {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  AppBootstrapState _state = const AppBootstrapState(
    status: AppBootstrapStatus.idle,
    schemaVersion: LocalStorage.currentSchemaVersion,
  );

  Future<AppBootstrapState>? _initializationFuture;

  bool _disposed = false;

  AppBootstrapState get state {
    return _state;
  }

  AppBootstrapStatus get status {
    return _state.status;
  }

  bool get isInitializing {
    return _state.isInitializing;
  }

  bool get requiresOnboarding {
    return _state.requiresOnboarding;
  }

  bool get isReady {
    return _state.isReady;
  }

  bool get hasFailed {
    return _state.hasFailed;
  }

  /// Initializes Eloqia's persistent application environment.
  ///
  /// If several parts of the application request initialization at the same
  /// time, they share the same operation instead of creating duplicate work.
  Future<AppBootstrapState> initialize() {
    final Future<AppBootstrapState>? runningInitialization =
        _initializationFuture;

    if (runningInitialization != null) {
      return runningInitialization;
    }

    final Future<AppBootstrapState> initialization =
        _initialize();

    _initializationFuture = initialization;

    initialization.whenComplete(() {
      if (identical(_initializationFuture, initialization)) {
        _initializationFuture = null;
      }
    });

    return initialization;
  }

  Future<AppBootstrapState> _initialize() async {
    _setState(
      const AppBootstrapState(
        status: AppBootstrapStatus.initializing,
        schemaVersion: LocalStorage.currentSchemaVersion,
      ),
    );

    try {
      await LocalStorage.initialize();

      final int schemaVersion =
          await LocalStorage.readSchemaVersion();

      final DateTime? initializedAt =
          await LocalStorage.readInitializedAt();

      final bool onboardingCompleted =
          await LocalStorage.isOnboardingCompleted();

      final DateTime now =
          DateTime.now().toUtc();

      await LocalStorage.saveLastActiveAt(now);

      final AppBootstrapStatus nextStatus =
          onboardingCompleted
              ? AppBootstrapStatus.ready
              : AppBootstrapStatus.onboardingRequired;

      final AppBootstrapState nextState =
          AppBootstrapState(
        status: nextStatus,
        schemaVersion: schemaVersion,
        initializedAt: initializedAt,
        lastActiveAt: now,
      );

      _setState(nextState);

      return nextState;
    } catch (error) {
      final AppBootstrapState failureState =
          AppBootstrapState(
        status: AppBootstrapStatus.failed,
        schemaVersion: LocalStorage.currentSchemaVersion,
        error: error,
      );

      _setState(failureState);

      return failureState;
    }
  }

  /// Marks onboarding as completed.
  Future<bool> completeOnboarding() async {
    final bool saved =
        await LocalStorage.saveOnboardingCompleted(true);

    if (!saved) {
      return false;
    }

    _setState(
      AppBootstrapState(
        status: AppBootstrapStatus.ready,
        schemaVersion: _state.schemaVersion,
        initializedAt: _state.initializedAt,
        lastActiveAt: _state.lastActiveAt,
      ),
    );

    return true;
  }

  /// Reopens onboarding.
  Future<bool> reopenOnboarding() async {
    final bool saved =
        await LocalStorage.saveOnboardingCompleted(false);

    if (!saved) {
      return false;
    }

    _setState(
      AppBootstrapState(
        status: AppBootstrapStatus.onboardingRequired,
        schemaVersion: _state.schemaVersion,
        initializedAt: _state.initializedAt,
        lastActiveAt: _state.lastActiveAt,
      ),
    );

    return true;
  }

  /// Records the latest application activity.
  Future<bool> recordActivity() async {
    final DateTime now =
        DateTime.now().toUtc();

    final bool saved =
        await LocalStorage.saveLastActiveAt(now);

    if (!saved) {
      return false;
    }

    _setState(
      AppBootstrapState(
        status: _state.status,
        schemaVersion: _state.schemaVersion,
        initializedAt: _state.initializedAt,
        lastActiveAt: now,
        error: _state.error,
      ),
    );

    return true;
  }

  /// Reloads application-level persistence state.
  Future<AppBootstrapState> refresh() async {
    await LocalStorage.initialize();

    final int schemaVersion =
        await LocalStorage.readSchemaVersion();

    final DateTime? initializedAt =
        await LocalStorage.readInitializedAt();

    final DateTime? lastActiveAt =
        await LocalStorage.readLastActiveAt();

    final bool onboardingCompleted =
        await LocalStorage.isOnboardingCompleted();

    final AppBootstrapState refreshedState =
        AppBootstrapState(
      status: onboardingCompleted
          ? AppBootstrapStatus.ready
          : AppBootstrapStatus.onboardingRequired,
      schemaVersion: schemaVersion,
      initializedAt: initializedAt,
      lastActiveAt: lastActiveAt,
    );

    _setState(refreshedState);

    return refreshedState;
  }

  /// Removes all locally persisted data owned by Eloqia.
  Future<bool> reset() async {
    final bool success =
        await LocalStorage.clearEloqiaData();

    if (!success) {
      return false;
    }

    _initializationFuture = null;

    _setState(
      const AppBootstrapState(
        status: AppBootstrapStatus.idle,
        schemaVersion: LocalStorage.currentSchemaVersion,
      ),
    );

    return true;
  }

  /// Returns diagnostic information useful during development.
  Map<String, dynamic> diagnostics() {
    return <String, dynamic>{
      'component': 'AppBootstrap',
      'state': _state.toJson(),
    };
  }

  void _setState(AppBootstrapState nextState) {
    if (_disposed) {
      return;
    }

    _state = nextState;

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}