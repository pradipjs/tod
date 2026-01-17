import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';

/// Represents a question/task category.
/// 
/// Categories are used to group questions by theme (e.g., "Funny", "Romantic").
/// Each category can have age restrictions and consent requirements.
@HiveType(typeId: 1)
class Category extends Equatable {
  /// Unique identifier for the category.
  @HiveField(0)
  final String id;

  /// Emoji/icon for the category.
  @HiveField(1)
  final String emoji;

  /// Age group this category belongs to (kids/teen/adults).
  @HiveField(2)
  final String ageGroup;

  /// Multilingual label for the category.
  /// Keys are language codes (en, es, hi, ur, etc.)
  @HiveField(3)
  final Map<String, String> label;

  /// Whether this category requires explicit consent.
  @HiveField(4)
  final bool requiresConsent;

  /// Whether this category is active/available.
  @HiveField(5)
  final bool isActive;

  /// Display order for sorting categories.
  @HiveField(6)
  final int sortOrder;

  const Category({
    required this.id,
    required this.emoji,
    required this.ageGroup,
    required this.label,
    this.requiresConsent = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Creates a Category from JSON response.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      emoji: json['emoji'] as String? ?? json['icon'] as String? ?? '📝',
      ageGroup: json['age_group'] as String? ?? 'adults',
      label: Map<String, String>.from(json['label'] as Map),
      requiresConsent: json['requires_consent'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'age_group': ageGroup,
      'label': label,
      'requires_consent': requiresConsent,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  /// Gets the age group as enum.
  AgeGroup get ageGroupEnum => AgeGroup.fromString(ageGroup);

  /// Icon alias for emoji (for compatibility).
  String get icon => emoji;

  /// Available game modes for this category.
  /// By default, categories are available for their age group and below.
  List<String> get availableModes {
    switch (ageGroupEnum) {
      case AgeGroup.kids:
        return ['kids'];
      case AgeGroup.teen:
        return ['kids', 'teen'];
      case AgeGroup.adults:
        return ['kids', 'teen', 'adults'];
    }
  }

  /// Checks if category is available for a specific game mode.
  bool isAvailableForMode(String mode) {
    return availableModes.contains(mode.toLowerCase());
  }

  /// Checks if category is available for a specific age group.
  bool isAvailableForAgeGroup(AgeGroup group) {
    return ageGroupEnum.minAge <= group.maxAge;
  }

  /// Gets localized name for the category with fallback to English.
  String getName(String languageCode) {
    return label[languageCode] ?? label['en'] ?? label.values.first;
  }

  Category copyWith({
    String? id,
    String? emoji,
    String? ageGroup,
    Map<String, String>? label,
    bool? requiresConsent,
    bool? isActive,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      ageGroup: ageGroup ?? this.ageGroup,
      label: label ?? this.label,
      requiresConsent: requiresConsent ?? this.requiresConsent,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        emoji,
        ageGroup,
        label,
        requiresConsent,
        isActive,
        sortOrder,
      ];
}
