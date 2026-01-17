import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'multilingual_text.g.dart';

/// Represents text content in multiple languages.
/// 
/// Keys are ISO 639-1 language codes (e.g., 'en', 'hi', 'ar').
/// Values are the translated text in that language.
@HiveType(typeId: 0)
class MultilingualText extends Equatable {
  @HiveField(0)
  final Map<String, String> translations;

  const MultilingualText({
    required this.translations,
  });

  /// Creates a MultilingualText from JSON.
  factory MultilingualText.fromJson(Map<String, dynamic> json) {
    return MultilingualText(
      translations: Map<String, String>.from(json),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => translations;

  /// Gets text for a specific language, with fallback to English.
  String getText(String languageCode) {
    return translations[languageCode] ?? 
           translations['en'] ?? 
           translations.values.firstOrNull ?? 
           '';
  }

  /// Checks if translation exists for a language.
  bool hasLanguage(String languageCode) {
    return translations.containsKey(languageCode);
  }

  /// Gets all available language codes.
  List<String> get availableLanguages => translations.keys.toList();

  /// Creates a copy with updated translation.
  MultilingualText copyWith({
    String? languageCode,
    String? text,
  }) {
    if (languageCode == null || text == null) return this;
    
    return MultilingualText(
      translations: {...translations, languageCode: text},
    );
  }

  @override
  List<Object?> get props => [translations];
}
