import 'dart:convert';

import '../../core/utils/logger.dart';
import '../local_db/hive_boxes.dart';
import '../models/category.dart';
import '../remote_api/truth_or_dare_api.dart';

/// Repository for managing categories.
/// 
/// Implements offline-first pattern with local caching and remote sync.
class CategoryRepository {
  static const _tag = 'CategoryRepository';
  final TruthOrDareApi _api;
  
  CategoryRepository(this._api);

  /// Fetches categories, preferring local cache.
  /// 
  /// Returns cached data immediately if available, then syncs with server.
  /// 
  /// [ageGroups] - Filter by age groups (kids, teen, adults)
  Future<List<Category>> getCategories({
    List<String>? ageGroups,
    bool? requiresConsent,
    bool forceRefresh = false,
  }) async {
    // Try to get from cache first
    if (!forceRefresh) {
      final cached = _getCachedCategories();
      if (cached.isNotEmpty) {
        // Return cached, sync in background
        _syncCategories(ageGroups: ageGroups, requiresConsent: requiresConsent);
        return _filterCategories(cached, ageGroups: ageGroups, requiresConsent: requiresConsent);
      }
    }

    // Fetch from API
    try {
      final categories = await _api.getCategories(
        ageGroups: ageGroups,
        requiresConsent: requiresConsent,
      );
      
      // Cache the results
      await _cacheCategories(categories);
      
      return categories;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch categories from API', tag: _tag, error: e, stackTrace: stackTrace);
      // Fallback to cache on error
      final cached = _getCachedCategories();
      if (cached.isNotEmpty) {
        AppLogger.info('Using cached categories as fallback', tag: _tag);
        return _filterCategories(cached, ageGroups: ageGroups, requiresConsent: requiresConsent);
      }
      rethrow;
    }
  }

  /// Gets a single category by ID.
  Future<Category?> getCategoryById(String id) async {
    // Try cache first
    final cached = _getCachedCategories();
    final category = cached.where((c) => c.id == id).firstOrNull;
    if (category != null) return category;

    // Fetch from API
    try {
      return await _api.getCategoryById(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch category by ID: $id', tag: _tag, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Saves categories to local cache.
  Future<void> saveCategories(List<Category> categories) async {
    final existing = _getCachedCategories();
    
    // Merge new categories with existing (update existing, add new)
    final merged = <String, Category>{};
    for (final cat in existing) {
      merged[cat.id] = cat;
    }
    for (final cat in categories) {
      merged[cat.id] = cat;
    }
    
    await _cacheCategories(merged.values.toList());
  }

  /// Clears all cached categories.
  Future<void> clearCache() async {
    final box = HiveBoxes.categories;
    await box.delete('all_categories');
  }

  List<Category> _getCachedCategories() {
    try {
      final box = HiveBoxes.categories;
      final data = box.get('all_categories');
      if (data == null) return [];
      
      final List<dynamic> list = jsonDecode(data as String);
      return list
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse cached categories', tag: _tag, error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> _cacheCategories(List<Category> categories) async {
    final box = HiveBoxes.categories;
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    await box.put('all_categories', json);
  }

  Future<void> _syncCategories({
    List<String>? ageGroups,
    bool? requiresConsent,
  }) async {
    try {
      final categories = await _api.getCategories(
        ageGroups: ageGroups,
        requiresConsent: requiresConsent,
      );
      await _cacheCategories(categories);
      AppLogger.debug('Background sync completed: ${categories.length} categories', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.warning('Background sync failed', tag: _tag, error: e, stackTrace: stackTrace);
    }
  }

  List<Category> _filterCategories(
    List<Category> categories, {
    List<String>? ageGroups,
    bool? requiresConsent,
  }) {
    return categories.where((cat) {
      if (ageGroups != null && ageGroups.isNotEmpty) {
        final hasAgeGroup = ageGroups.any((ag) => cat.ageGroup == ag);
        if (!hasAgeGroup) return false;
      }
      if (requiresConsent != null && cat.requiresConsent != requiresConsent) return false;
      return true;
    }).toList();
  }
}
