import '../models/category.dart';
import '../models/language.dart';
import '../models/task.dart';
import 'api_client.dart';

/// API service for Truth or Dare backend.
/// 
/// Provides methods to interact with categories, tasks, and languages endpoints.
/// Supports multiple filters for categories, age groups, and languages.
class TruthOrDareApi {
  final ApiClient _client;

  TruthOrDareApi(this._client);

  // ============ Languages ============

  /// Fetches all supported languages.
  Future<List<Language>> getLanguages() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/languages',
    );

    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Language.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============ Categories ============

  /// Fetches all categories with optional filters.
  /// 
  /// [ageGroups] - Filter by multiple age groups (kids, teen, adults)
  /// [requiresConsent] - Filter by consent requirement
  Future<List<Category>> getCategories({
    List<String>? ageGroups,
    bool? requiresConsent,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (ageGroups != null && ageGroups.isNotEmpty) {
      queryParams['age_groups'] = ageGroups.join(',');
    }
    if (requiresConsent != null) queryParams['requires_consent'] = requiresConsent;

    final response = await _client.get<Map<String, dynamic>>(
      '/categories',
      queryParameters: queryParams,
    );

    // Handle paginated response
    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single category by ID.
  Future<Category> getCategoryById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/categories/$id',
    );

    return Category.fromJson(response.data!);
  }

  // ============ Tasks ============

  /// Fetches tasks with optional filters.
  /// Supports multiple categories, age groups, types, and languages.
  /// 
  /// [categoryIds] - Filter by multiple categories
  /// [ageGroups] - Filter by multiple age groups (kids, teen, adults)
  /// [types] - Filter by multiple types (truth, dare)
  /// [languages] - Filter by languages that have content
  /// [excludeIds] - Task IDs to exclude (for rotation)
  /// [limit] - Limit results
  /// [offset] - Pagination offset
  /// [random] - Randomize results
  Future<List<Task>> getTasks({
    List<String>? categoryIds,
    List<String>? ageGroups,
    List<String>? types,
    List<String>? languages,
    List<String>? excludeIds,
    int? limit,
    int? offset,
    bool? random,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_ids'] = categoryIds.join(',');
    }
    if (ageGroups != null && ageGroups.isNotEmpty) {
      queryParams['age_groups'] = ageGroups.join(',');
    }
    if (types != null && types.isNotEmpty) {
      queryParams['types'] = types.join(',');
    }
    if (languages != null && languages.isNotEmpty) {
      queryParams['languages'] = languages.join(',');
    }
    if (excludeIds != null && excludeIds.isNotEmpty) {
      queryParams['exclude'] = excludeIds.join(',');
    }
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (random != null) queryParams['random'] = random;

    final response = await _client.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: queryParams,
    );

    final data = response.data?['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Checks task availability for the given presets.
  /// Returns counts of available truths and dares.
  Future<Map<String, dynamic>> checkTaskAvailability({
    List<String>? categoryIds,
    List<String>? ageGroups,
    List<String>? languages,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_ids'] = categoryIds.join(',');
    }
    if (ageGroups != null && ageGroups.isNotEmpty) {
      queryParams['age_groups'] = ageGroups.join(',');
    }
    if (languages != null && languages.isNotEmpty) {
      queryParams['languages'] = languages.join(',');
    }

    final response = await _client.get<Map<String, dynamic>>(
      '/tasks/availability',
      queryParameters: queryParams,
    );

    return response.data ?? {};
  }

  /// Fetches a random task matching the filters.
  Future<Task> getRandomTask({
    List<String>? categoryIds,
    List<String>? ageGroups,
    String? type,
    List<String>? languages,
    List<String>? excludeIds,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_ids'] = categoryIds.join(',');
    }
    if (ageGroups != null && ageGroups.isNotEmpty) {
      queryParams['age_groups'] = ageGroups.join(',');
    }
    if (type != null) queryParams['type'] = type;
    if (languages != null && languages.isNotEmpty) {
      queryParams['languages'] = languages.join(',');
    }
    if (excludeIds != null && excludeIds.isNotEmpty) {
      queryParams['exclude'] = excludeIds.join(',');
    }

    final response = await _client.get<Map<String, dynamic>>(
      '/tasks/random',
      queryParameters: queryParams,
    );

    return Task.fromJson(response.data!);
  }

  /// Fetches a single task by ID.
  Future<Task> getTaskById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/tasks/$id',
    );

    return Task.fromJson(response.data!);
  }

  /// Fetches task statistics.
  Future<TaskStats> getTaskStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/tasks/stats',
    );

    return TaskStats.fromJson(response.data!);
  }
}

/// Response wrapper for paginated task list.
class TaskListResponse {
  final List<Task> data;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  TaskListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      data: (json['data'] as List?)
              ?.map((item) => Task.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}

/// Task statistics response.
class TaskStats {
  final int total;
  final Map<String, int> byCategory;
  final Map<String, int> byType;

  TaskStats({
    required this.total,
    required this.byCategory,
    required this.byType,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) {
    return TaskStats(
      total: json['total'] as int? ?? 0,
      byCategory: Map<String, int>.from(json['by_category'] ?? {}),
      byType: Map<String, int>.from(json['by_type'] ?? {}),
    );
  }
}
