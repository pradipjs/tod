import 'dart:convert';
import 'dart:math';

import '../../core/constants/enums.dart';
import '../../core/utils/logger.dart';
import '../local_db/hive_boxes.dart';
import '../models/task.dart';
import '../remote_api/truth_or_dare_api.dart';

/// Repository for managing tasks.
/// 
/// Implements offline-first pattern with question rotation algorithm.
/// Supports multi-filter queries for age groups, languages, and categories.
class TaskRepository {
  static const _tag = 'TaskRepository';
  final TruthOrDareApi _api;
  final Random _random = Random();

  TaskRepository(this._api);

  /// Fetches tasks with filters.
  /// 
  /// Prefers local cache, syncs with server in background.
  /// 
  /// [categoryIds] - Filter by multiple categories
  /// [ageGroups] - Filter by age groups (kids, teen, adults)
  /// [languages] - Filter by languages that have content
  /// [type] - Filter by type (truth/dare)
  Future<List<Task>> getTasks({
    List<String>? categoryIds,
    List<String>? ageGroups,
    List<String>? languages,
    TaskType? type,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _getCachedTasks();
      if (cached.isNotEmpty) {
        _syncTasks(ageGroups: ageGroups, languages: languages);
        return _filterTasks(
          cached,
          categoryIds: categoryIds,
          ageGroups: ageGroups,
          languages: languages,
          type: type,
        );
      }
    }

    try {
      final tasks = await _api.getTasks(
        categoryIds: categoryIds,
        ageGroups: ageGroups,
        languages: languages,
        types: type != null ? [type.value] : null,
        limit: 500,
      );

      await _cacheTasks(tasks);
      return tasks;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch tasks from API', tag: _tag, error: e, stackTrace: stackTrace);
      final cached = _getCachedTasks();
      if (cached.isNotEmpty) {
        AppLogger.info('Using cached tasks as fallback', tag: _tag);
        return _filterTasks(
          cached,
          categoryIds: categoryIds,
          ageGroups: ageGroups,
          languages: languages,
          type: type,
        );
      }
      rethrow;
    }
  }

  /// Counts tasks in local cache matching the filters.
  /// Used to check task availability before starting a game.
  Future<int> countLocalTasks({
    List<String>? categoryIds,
    String? ageGroup,
    String? language,
    TaskType? type,
  }) async {
    final cached = _getCachedTasks();
    return _filterTasks(
      cached,
      categoryIds: categoryIds,
      ageGroups: ageGroup != null ? [ageGroup] : null,
      languages: language != null ? [language] : null,
      type: type,
    ).length;
  }

  /// Gets a random task using the rotation algorithm.
  /// 
  /// Ensures tasks don't repeat until all in the pool are exhausted.
  Future<Task?> getRandomTask({
    List<String>? categoryIds,
    String? ageGroup,
    String? language,
    TaskType? type,
    List<String> usedTaskIds = const [],
  }) async {
    // Get all eligible tasks
    final tasks = await getTasks(
      categoryIds: categoryIds,
      ageGroups: ageGroup != null ? [ageGroup] : null,
      languages: language != null ? [language] : null,
      type: type,
    );

    if (tasks.isEmpty) return null;

    // Filter out used tasks
    var availableTasks = tasks.where((t) => !usedTaskIds.contains(t.id)).toList();

    // If all tasks are used, reset (return from full pool)
    if (availableTasks.isEmpty) {
      availableTasks = tasks;
    }

    // Pick random task
    return availableTasks[_random.nextInt(availableTasks.length)];
  }

  /// Gets tasks for a specific type (truth or dare).
  Future<List<Task>> getTasksByType(
    TaskType type, {
    List<String>? categoryIds,
    String? ageGroup,
    String? language,
  }) async {
    return getTasks(
      type: type,
      categoryIds: categoryIds,
      ageGroups: ageGroup != null ? [ageGroup] : null,
      languages: language != null ? [language] : null,
    );
  }

  /// Preloads tasks for offline use.
  Future<void> preloadTasks({
    List<String>? ageGroups,
    List<String>? languages,
  }) async {
    try {
      final tasks = await _api.getTasks(
        ageGroups: ageGroups,
        languages: languages,
        limit: 1000,
      );
      await _cacheTasks(tasks);
      AppLogger.success('Preloaded ${tasks.length} tasks', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to preload tasks', tag: _tag, error: e, stackTrace: stackTrace);
    }
  }

  /// Saves tasks to local cache.
  Future<void> saveTasks(List<Task> tasks) async {
    final existing = _getCachedTasks();
    
    // Merge new tasks with existing (update existing, add new)
    final merged = <String, Task>{};
    for (final task in existing) {
      merged[task.id] = task;
    }
    for (final task in tasks) {
      merged[task.id] = task;
    }
    
    await _cacheTasks(merged.values.toList());
  }

  /// Clears all cached tasks.
  Future<void> clearCache() async {
    final box = HiveBoxes.tasks;
    await box.delete('all_tasks');
  }

  List<Task> _getCachedTasks() {
    try {
      final box = HiveBoxes.tasks;
      final data = box.get('all_tasks');
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data as String);
      return list
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse cached tasks', tag: _tag, error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> _cacheTasks(List<Task> tasks) async {
    final box = HiveBoxes.tasks;
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await box.put('all_tasks', json);
  }

  Future<void> _syncTasks({
    List<String>? ageGroups,
    List<String>? languages,
  }) async {
    try {
      final tasks = await _api.getTasks(
        ageGroups: ageGroups,
        languages: languages,
        limit: 1000,
      );
      await _cacheTasks(tasks);
      AppLogger.debug('Background sync completed: ${tasks.length} tasks', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.warning('Background sync failed', tag: _tag, error: e, stackTrace: stackTrace);
    }
  }

  List<Task> _filterTasks(
    List<Task> tasks, {
    List<String>? categoryIds,
    List<String>? ageGroups,
    List<String>? languages,
    TaskType? type,
  }) {
    return tasks.where((task) {
      // Filter by category IDs
      if (categoryIds != null &&
          categoryIds.isNotEmpty &&
          !categoryIds.contains(task.categoryId)) {
        return false;
      }
      
      // Filter by type
      if (type != null && task.type != type.value) return false;
      
      // Filter by age group
      if (ageGroups != null && ageGroups.isNotEmpty) {
        if (!ageGroups.contains(task.ageGroup)) {
          return false;
        }
      }
      
      // Filter by language (check if task has content in any of the requested languages)
      if (languages != null && languages.isNotEmpty) {
        final hasLanguage = languages.any((lang) => 
          task.content.containsKey(lang) && task.content[lang]!.isNotEmpty
        );
        if (!hasLanguage) return false;
      }
      
      return task.isActive;
    }).toList();
  }
}
