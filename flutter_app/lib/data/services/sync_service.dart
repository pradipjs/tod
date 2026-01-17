import '../../core/utils/logger.dart';
import '../remote_api/truth_or_dare_api.dart';
import '../repositories/category_repository.dart';
import '../repositories/task_repository.dart';

/// Service for syncing data between the app and backend.
/// 
/// Handles:
/// - Checking task availability for game presets
/// - Fetching and caching categories and tasks
/// - Determining when to sync based on time thresholds
class SyncService {
  static const String _tag = 'SyncService';
  
  final TruthOrDareApi _api;
  final CategoryRepository _categoryRepository;
  final TaskRepository _taskRepository;
  
  /// Last sync time for categories
  DateTime? _lastCategorySyncTime;
  
  /// Last sync time for tasks
  DateTime? _lastTaskSyncTime;
  
  /// Sync threshold (24 hours)
  static const Duration syncThreshold = Duration(hours: 24);

  SyncService(
    this._api,
    this._categoryRepository,
    this._taskRepository,
  );

  /// Checks if categories should be synced based on time threshold.
  bool shouldSyncCategories() {
    if (_lastCategorySyncTime == null) return true;
    return DateTime.now().difference(_lastCategorySyncTime!) > syncThreshold;
  }

  /// Checks if tasks should be synced based on time threshold.
  bool shouldSyncTasks() {
    if (_lastTaskSyncTime == null) return true;
    return DateTime.now().difference(_lastTaskSyncTime!) > syncThreshold;
  }

  /// Syncs categories from the backend.
  /// 
  /// [ageGroups] - Optional filter for age groups
  /// [forceSync] - Force sync even if threshold not reached
  Future<bool> syncCategories({
    List<String>? ageGroups,
    bool forceSync = false,
  }) async {
    if (!forceSync && !shouldSyncCategories()) {
      return true; // Already synced recently
    }

    try {
      final categories = await _api.getCategories(
        ageGroups: ageGroups,
      );
      
      await _categoryRepository.saveCategories(categories);
      _lastCategorySyncTime = DateTime.now();
      
      AppLogger.success('Synced ${categories.length} categories', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync categories', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Syncs tasks from the backend.
  /// 
  /// [ageGroups] - Filter by age groups
  /// [languages] - Filter by languages
  /// [categoryIds] - Filter by categories
  /// [forceSync] - Force sync even if threshold not reached
  Future<bool> syncTasks({
    List<String>? ageGroups,
    List<String>? languages,
    List<String>? categoryIds,
    bool forceSync = false,
  }) async {
    if (!forceSync && !shouldSyncTasks()) {
      return true; // Already synced recently
    }

    try {
      final tasks = await _api.getTasks(
        ageGroups: ageGroups,
        languages: languages,
        categoryIds: categoryIds,
        limit: 500,
      );
      
      await _taskRepository.saveTasks(tasks);
      _lastTaskSyncTime = DateTime.now();
      
      AppLogger.success('Synced ${tasks.length} tasks', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync tasks', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Syncs data for game presets before starting a game.
  /// 
  /// This is called when the play button is pressed and local data
  /// is insufficient for the selected game configuration.
  /// 
  /// [ageGroups] - Age groups for the game
  /// [languages] - Languages needed for content
  /// [categoryIds] - Selected categories
  /// 
  /// Returns true if sync was successful or not needed.
  Future<bool> syncForGamePresets({
    required List<String> ageGroups,
    required List<String> languages,
    required List<String> categoryIds,
  }) async {
    try {
      // Sync categories if needed
      await syncCategories(
        ageGroups: ageGroups,
        forceSync: true,
      );

      // Sync tasks with specific filters
      final tasks = await _api.getTasks(
        ageGroups: ageGroups,
        languages: languages,
        categoryIds: categoryIds.isEmpty ? null : categoryIds,
        limit: 500,
      );

      await _taskRepository.saveTasks(tasks);
      _lastTaskSyncTime = DateTime.now();

      AppLogger.success('Synced ${tasks.length} tasks for game presets', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync for game presets', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks task availability on the backend.
  /// 
  /// Returns availability data including truth and dare counts.
  Future<Map<String, dynamic>> checkRemoteAvailability({
    List<String>? categoryIds,
    List<String>? ageGroups,
    List<String>? languages,
  }) async {
    try {
      return await _api.checkTaskAvailability(
        categoryIds: categoryIds,
        ageGroups: ageGroups,
        languages: languages,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check remote availability', tag: _tag, error: e, stackTrace: stackTrace);
      return {
        'truth_count': 0,
        'dare_count': 0,
        'total': 0,
        'has_enough': false,
        'error': e.toString(),
      };
    }
  }

  /// Performs a full sync of all data.
  /// 
  /// Use this for initial app load or manual refresh.
  Future<bool> fullSync() async {
    try {
      AppLogger.info('Starting full sync...', tag: _tag);
      final categoriesSuccess = await syncCategories(forceSync: true);
      final tasksSuccess = await syncTasks(forceSync: true);
      
      if (categoriesSuccess && tasksSuccess) {
        AppLogger.success('Full sync completed successfully', tag: _tag);
      } else {
        AppLogger.warning('Full sync partially failed: categories=$categoriesSuccess, tasks=$tasksSuccess', tag: _tag);
      }
      return categoriesSuccess && tasksSuccess;
    } catch (e, stackTrace) {
      AppLogger.error('Full sync failed', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clears all sync timestamps, forcing next sync.
  void resetSyncTimestamps() {
    _lastCategorySyncTime = null;
    _lastTaskSyncTime = null;
  }
}
