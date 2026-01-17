import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/language.dart';
import '../../data/repositories/language_repository.dart';
import '../di/service_locator.dart';

/// Provider for the language repository.
final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return ServiceLocator.instance.languageRepository;
});

/// Provider for supported languages state.
final languagesProvider = StateNotifierProvider<LanguagesNotifier, LanguagesState>((ref) {
  final repository = ref.watch(languageRepositoryProvider);
  return LanguagesNotifier(repository: repository);
});

/// Immutable state for languages.
class LanguagesState {
  final List<Language> languages;
  final bool isLoading;
  final String? error;

  const LanguagesState({
    this.languages = const [],
    this.isLoading = false,
    this.error,
  });

  /// Whether the language selector should be shown.
  /// Only show if there are multiple languages available.
  bool get showSelector => languages.length > 1;

  /// Gets the effective language for a code.
  /// Falls back to English or first available language.
  Language getLanguageForCode(String code) {
    // Try to find exact match
    for (final lang in languages) {
      if (lang.code == code) return lang;
    }
    
    // Fallback to English if available
    for (final lang in languages) {
      if (lang.code == 'en') return lang;
    }
    
    // Fallback to first language or default English
    return languages.isNotEmpty 
        ? languages.first 
        : LanguageRepository.defaultEnglish;
  }

  LanguagesState copyWith({
    List<Language>? languages,
    bool? isLoading,
    String? error,
  }) {
    return LanguagesState(
      languages: languages ?? this.languages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing languages state.
/// 
/// Loads languages from repository and handles state updates.
class LanguagesNotifier extends StateNotifier<LanguagesState> {
  final LanguageRepository _repository;

  LanguagesNotifier({required LanguageRepository repository}) 
      : _repository = repository,
        super(const LanguagesState()) {
    _loadFromCache();
  }

  /// Reloads languages from cache.
  /// Call this after background sync completes.
  void reloadFromCache() {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _repository.getCachedLanguages();
    
    if (cached.isNotEmpty) {
      state = state.copyWith(languages: cached);
    } else {
      // No languages available - use empty list
      // The app will default to English via settings
      state = state.copyWith(languages: []);
    }
  }

  /// Updates languages and persists to cache.
  Future<void> updateLanguages(List<Language> languages) async {
    await _repository.cacheLanguages(languages);
    state = state.copyWith(languages: languages);
  }

  /// Gets a language by code.
  Language? getLanguageByCode(String code) {
    return _repository.findByCode(code);
  }
}
