import 'dart:convert';

import '../local_db/hive_boxes.dart';
import '../models/language.dart';

/// Repository for managing language data.
/// 
/// Handles caching and retrieval of supported languages.
/// Follows the repository pattern for data access abstraction.
class LanguageRepository {
  static const String _cacheKey = 'cached_languages';
  static const String _supportedCodesKey = 'supported_languages';
  
  /// Default English language when no languages are available.
  static const Language defaultEnglish = Language(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    icon: '🇬🇧',
  );

  /// Retrieves cached languages from local storage.
  /// 
  /// Returns empty list if no cache exists or on error.
  List<Language> getCachedLanguages() {
    try {
      final box = HiveBoxes.settings;
      final cached = box.get(_cacheKey) as String?;
      
      if (cached == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(cached);
      return jsonList
          .map((json) => Language.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves languages to local cache.
  /// 
  /// Also stores language codes separately for quick access.
  Future<void> cacheLanguages(List<Language> languages) async {
    try {
      final box = HiveBoxes.settings;
      
      // Store full language data as JSON
      final jsonList = languages.map((l) => l.toJson()).toList();
      await box.put(_cacheKey, jsonEncode(jsonList));
      
      // Store codes for backward compatibility and quick access
      final codes = languages.map((l) => l.code).toList();
      await box.put(_supportedCodesKey, codes);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Clears the language cache.
  Future<void> clearCache() async {
    try {
      final box = HiveBoxes.settings;
      await box.delete(_cacheKey);
      await box.delete(_supportedCodesKey);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Gets supported language codes.
  List<String> getSupportedCodes() {
    try {
      final box = HiveBoxes.settings;
      final codes = box.get(_supportedCodesKey);
      if (codes is List) {
        return codes.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Checks if a language code is supported.
  bool isLanguageSupported(String code) {
    final codes = getSupportedCodes();
    return codes.isEmpty || codes.contains(code);
  }

  /// Finds a language by code from cached languages.
  Language? findByCode(String code) {
    final languages = getCachedLanguages();
    for (final lang in languages) {
      if (lang.code == code) return lang;
    }
    return null;
  }
}
