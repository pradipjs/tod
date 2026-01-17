import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/background_sync_manager.dart';
import '../di/service_locator.dart';

/// Provider for the BackgroundSyncManager.
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((ref) {
  return ServiceLocator.instance.backgroundSyncManager;
});

/// Provider for tracking sync state.
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  final syncManager = ref.watch(backgroundSyncManagerProvider);
  return SyncStateNotifier(syncManager);
});

/// State for background sync.
class SyncState {
  final bool isSyncing;
  final bool hasCompletedInitialSync;
  final DateTime? lastSyncDate;
  final String? error;

  const SyncState({
    this.isSyncing = false,
    this.hasCompletedInitialSync = false,
    this.lastSyncDate,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? hasCompletedInitialSync,
    DateTime? lastSyncDate,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasCompletedInitialSync: hasCompletedInitialSync ?? this.hasCompletedInitialSync,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
      error: error,
    );
  }
}

/// Notifier for managing sync state.
class SyncStateNotifier extends StateNotifier<SyncState> {
  final BackgroundSyncManager _syncManager;

  SyncStateNotifier(this._syncManager) : super(const SyncState()) {
    _initializeState();
  }

  void _initializeState() {
    state = SyncState(
      hasCompletedInitialSync: !_syncManager.isFirstLaunch,
      lastSyncDate: _syncManager.lastSyncDate,
    );
  }

  /// Performs background sync if needed.
  /// 
  /// This should be called when the app starts.
  Future<void> performSyncIfNeeded() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final result = await _syncManager.performSyncIfNeeded();
      
      state = state.copyWith(
        isSyncing: false,
        hasCompletedInitialSync: true,
        lastSyncDate: result.wasNeeded && result.success 
            ? DateTime.now() 
            : state.lastSyncDate,
        error: result.success ? null : result.error,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// Forces a sync regardless of last sync time.
  Future<void> forceSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final result = await _syncManager.performSync();
      
      state = state.copyWith(
        isSyncing: false,
        hasCompletedInitialSync: true,
        lastSyncDate: result.success ? DateTime.now() : state.lastSyncDate,
        error: result.success ? null : result.error,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  /// Gets supported languages from sync manager.
  List<String> get supportedLanguages => _syncManager.getSupportedLanguages();
}
