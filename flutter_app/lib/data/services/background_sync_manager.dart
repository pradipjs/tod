import 'dart:async';

import '../../core/utils/logger.dart';
import '../local_db/hive_boxes.dart';
import '../remote_api/truth_or_dare_api.dart';
import '../repositories/category_repository.dart';
import '../repositories/language_repository.dart';
import '../repositories/task_repository.dart';

/// Background sync manager for fetching and caching data from backend.
/// 
/// Features:
/// - First launch sync: Fetches all categories and languages
/// - Daily refresh: Syncs once per day on app open
/// - Retry logic: Max 3 retries with exponential backoff
/// - Non-blocking: Runs in background without affecting UI
class BackgroundSyncManager {
  static const String _tag = 'BackgroundSyncManager';
  
  // Sync metadata keys
  static const String _lastSyncDateKey = 'last_sync_date';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _syncVersionKey = 'sync_version';
  
  // Current sync version - increment to force refresh
  static const int _currentSyncVersion = 1;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  
  final TruthOrDareApi _api;
  final CategoryRepository _categoryRepository;
  final TaskRepository _taskRepository;
  final LanguageRepository _languageRepository;
  
  bool _isSyncing = false;
  final _syncCompleter = Completer<SyncResult>();
  
  BackgroundSyncManager({
    required TruthOrDareApi api,
    required CategoryRepository categoryRepository,
    required TaskRepository taskRepository,
    required LanguageRepository languageRepository,
  })  : _api = api,
        _categoryRepository = categoryRepository,
        _taskRepository = taskRepository,
        _languageRepository = languageRepository;

  /// Checks if this is the first launch of the app.
  bool get isFirstLaunch {
    final box = HiveBoxes.settings;
    return box.get(_isFirstLaunchKey, defaultValue: true) as bool;
  }

  /// Gets the last sync date.
  DateTime? get lastSyncDate {
    final box = HiveBoxes.settings;
    final timestamp = box.get(_lastSyncDateKey) as int?;
    return timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp) 
        : null;
  }

  /// Checks if sync is needed (first launch or 24+ hours since last sync).
  bool get needsSync {
    // Check if sync version changed (force refresh on version bump)
    final savedVersion = HiveBoxes.settings.get(_syncVersionKey, defaultValue: 0) as int;
    if (savedVersion < _currentSyncVersion) {
      AppLogger.info('Sync version changed, forcing refresh', tag: _tag);
      return true;
    }
    
    // First launch always needs sync
    if (isFirstLaunch) {
      AppLogger.info('First launch detected, sync needed', tag: _tag);
      return true;
    }
    
    // Check if 24 hours have passed since last sync
    final last = lastSyncDate;
    if (last == null) {
      AppLogger.info('No previous sync found, sync needed', tag: _tag);
      return true;
    }
    
    final hoursSinceLastSync = DateTime.now().difference(last).inHours;
    final needsRefresh = hoursSinceLastSync >= 24;
    
    if (needsRefresh) {
      AppLogger.info('$hoursSinceLastSync hours since last sync, refresh needed', tag: _tag);
    } else {
      AppLogger.debug('Last sync was $hoursSinceLastSync hours ago, no refresh needed', tag: _tag);
    }
    
    return needsRefresh;
  }

  /// Performs background sync if needed.
  /// 
  /// This should be called when the app starts or resumes.
  /// It runs in the background and doesn't block the UI.
  /// 
  /// Returns a [Future] that completes with the sync result.
  Future<SyncResult> performSyncIfNeeded() async {
    if (!needsSync) {
      return SyncResult.notNeeded();
    }
    
    return performSync();
  }

  /// Forces a sync regardless of the last sync time.
  /// 
  /// Useful for manual refresh or after network recovery.
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      AppLogger.warning('Sync already in progress, waiting...', tag: _tag);
      return _syncCompleter.future;
    }
    
    _isSyncing = true;
    AppLogger.info('Starting background sync...', tag: _tag);
    
    try {
      final result = await _executeWithRetry();
      
      if (result.success) {
        await _markSyncComplete();
        AppLogger.success('Background sync completed successfully', tag: _tag);
      } else {
        AppLogger.warning('Background sync completed with failures: ${result.error}', tag: _tag);
      }
      
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Executes sync with retry logic.
  Future<SyncResult> _executeWithRetry() async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;
    String? lastError;
    
    while (attempt < _maxRetries) {
      attempt++;
      AppLogger.debug('Sync attempt $attempt of $_maxRetries', tag: _tag);
      
      try {
        // Sync categories
        final categoriesSuccess = await _syncCategories();
        if (!categoriesSuccess) {
          throw Exception('Failed to sync categories');
        }
        
        // Sync supported languages (from categories metadata or dedicated endpoint)
        final languagesSuccess = await _syncLanguages();
        if (!languagesSuccess) {
          throw Exception('Failed to sync languages');
        }
        
        // Optionally sync initial tasks for common presets
        await _syncInitialTasks();
        
        return SyncResult.success(
          categoriesSynced: true,
          languagesSynced: true,
        );
      } catch (e, stackTrace) {
        lastError = e.toString();
        AppLogger.error(
          'Sync attempt $attempt failed: $e',
          tag: _tag,
          error: e,
          stackTrace: stackTrace,
        );
        
        if (attempt < _maxRetries) {
          AppLogger.info('Retrying in ${delay.inSeconds} seconds...', tag: _tag);
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        }
      }
    }
    
    return SyncResult.failed(
      error: 'Sync failed after $_maxRetries attempts: $lastError',
    );
  }

  /// Syncs categories from backend.
  Future<bool> _syncCategories() async {
    try {
      AppLogger.debug('Fetching categories...', tag: _tag);
      
      final categories = await _api.getCategories();
      
      if (categories.isEmpty) {
        AppLogger.warning('No categories returned from API', tag: _tag);
        return true; // Empty is valid, not an error
      }
      
      await _categoryRepository.saveCategories(categories);
      AppLogger.success('Synced ${categories.length} categories', tag: _tag);
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync categories', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Syncs supported languages from the backend.
  Future<bool> _syncLanguages() async {
    try {
      AppLogger.debug('Fetching languages from API...', tag: _tag);
      
      final languages = await _api.getLanguages();
      
      if (languages.isEmpty) {
        AppLogger.warning('No languages returned from API', tag: _tag);
        return true; // Empty is valid, not an error
      }
      
      // Use repository to cache languages
      await _languageRepository.cacheLanguages(languages);
      
      AppLogger.success('Synced ${languages.length} languages', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync languages', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Syncs initial tasks for common game presets.
  /// 
  /// This pre-fetches tasks for the most common configurations
  /// to improve game start time.
  Future<void> _syncInitialTasks() async {
    try {
      AppLogger.debug('Pre-fetching initial tasks...', tag: _tag);
      
      // Fetch tasks for common age groups
      final tasks = await _api.getTasks(
        limit: 200,
        random: true,
      );
      
      if (tasks.isNotEmpty) {
        await _taskRepository.saveTasks(tasks);
        AppLogger.success('Pre-fetched ${tasks.length} tasks', tag: _tag);
      }
    } catch (e) {
      // Non-critical, log but don't fail sync
      AppLogger.warning('Failed to pre-fetch tasks: $e', tag: _tag);
    }
  }

  /// Marks sync as complete and updates metadata.
  Future<void> _markSyncComplete() async {
    final box = HiveBoxes.settings;
    
    await box.put(_lastSyncDateKey, DateTime.now().millisecondsSinceEpoch);
    await box.put(_isFirstLaunchKey, false);
    await box.put(_syncVersionKey, _currentSyncVersion);
    
    AppLogger.debug('Sync metadata updated', tag: _tag);
  }

  /// Gets the list of supported languages.
  List<String> getSupportedLanguages() {
    final box = HiveBoxes.settings;
    final languages = box.get('supported_languages') as List<dynamic>?;
    return languages?.cast<String>() ?? ['en'];
  }

  /// Resets sync state (useful for testing or forced refresh).
  Future<void> resetSyncState() async {
    final box = HiveBoxes.settings;
    await box.delete(_lastSyncDateKey);
    await box.delete(_isFirstLaunchKey);
    await box.delete(_syncVersionKey);
    AppLogger.info('Sync state reset', tag: _tag);
  }
}

/// Result of a background sync operation.
class SyncResult {
  final bool success;
  final bool categoriesSynced;
  final bool languagesSynced;
  final bool wasNeeded;
  final String? error;

  const SyncResult._({
    required this.success,
    required this.categoriesSynced,
    required this.languagesSynced,
    required this.wasNeeded,
    this.error,
  });

  /// Sync was successful.
  factory SyncResult.success({
    bool categoriesSynced = false,
    bool languagesSynced = false,
  }) {
    return SyncResult._(
      success: true,
      categoriesSynced: categoriesSynced,
      languagesSynced: languagesSynced,
      wasNeeded: true,
    );
  }

  /// Sync was not needed (already synced recently).
  factory SyncResult.notNeeded() {
    return const SyncResult._(
      success: true,
      categoriesSynced: false,
      languagesSynced: false,
      wasNeeded: false,
    );
  }

  /// Sync failed after all retries.
  factory SyncResult.failed({required String error}) {
    return SyncResult._(
      success: false,
      categoriesSynced: false,
      languagesSynced: false,
      wasNeeded: true,
      error: error,
    );
  }

  @override
  String toString() {
    if (!wasNeeded) return 'SyncResult: Not needed';
    if (success) return 'SyncResult: Success (categories: $categoriesSynced, languages: $languagesSynced)';
    return 'SyncResult: Failed - $error';
  }
}
