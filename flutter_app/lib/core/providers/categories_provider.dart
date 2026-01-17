import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../di/service_locator.dart';
import '../utils/logger.dart';

/// Provider for category repository.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return ServiceLocator.instance.categoryRepository;
});

/// State for categories loading.
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing categories state.
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  static const _tag = 'CategoriesNotifier';
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(const CategoriesState());

  /// Loads categories with optional filters.
  Future<void> loadCategories({
    List<String>? ageGroups,
    bool? requiresConsent,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.getCategories(
        ageGroups: ageGroups,
        requiresConsent: requiresConsent,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
      AppLogger.success('Loaded ${categories.length} categories', tag: _tag);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load categories', tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refreshes categories from API.
  Future<void> refresh() async {
    await loadCategories(forceRefresh: true);
  }

  /// Gets categories filtered by game mode.
  List<Category> getCategoriesForMode(String mode) {
    return state.categories
        .where((c) => c.availableModes.contains(mode))
        .toList();
  }

  /// Gets category by ID.
  Category? getCategoryById(String id) {
    return state.categories.where((c) => c.id == id).firstOrNull;
  }
}

/// Provider for categories.
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});

/// Provider for categories filtered by mode.
final categoriesByModeProvider = Provider.family<List<Category>, String>((ref, mode) {
  final state = ref.watch(categoriesProvider);
  return state.categories
      .where((c) => c.availableModes.contains(mode))
      .toList();
});
