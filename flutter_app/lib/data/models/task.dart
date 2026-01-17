import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';

/// Represents a Truth or Dare task/question.
/// 
/// Tasks are the core content of the game. Each task has multilingual
/// support and is categorized by type (truth/dare) and age group.
@HiveType(typeId: 2)
class Task extends Equatable {
  /// Unique identifier for the task.
  @HiveField(0)
  final String id;

  /// The task content in multiple languages (language code -> text).
  @HiveField(1)
  final Map<String, String> content;

  /// Type of task: truth or dare.
  @HiveField(2)
  final String type;

  /// Category ID this task belongs to.
  @HiveField(3)
  final String categoryId;

  /// Age group for this task (kids, teen, adults).
  @HiveField(4)
  final String ageGroup;

  /// Whether this task requires consent (for spicy content).
  @HiveField(5)
  final bool requiresConsent;

  /// Whether this task is active/available.
  @HiveField(6)
  final bool isActive;

  /// Optional hint for the task in multiple languages.
  @HiveField(7)
  final Map<String, String>? hint;

  /// Number of times this task has been used in the current session.
  /// This is frontend-only, not synced with backend.
  @HiveField(8)
  final int repeatCount;

  const Task({
    required this.id,
    required this.content,
    required this.type,
    required this.categoryId,
    this.ageGroup = 'adults',
    this.requiresConsent = false,
    this.isActive = true,
    this.hint,
    this.repeatCount = 0,
  });

  /// Creates a Task from JSON response.
  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle both 'content' and 'text' field names for compatibility
    final contentData = json['content'] ?? json['text'];
    return Task(
      id: json['id'] as String,
      content: Map<String, String>.from(contentData as Map),
      type: json['type'] as String,
      categoryId: json['category_id'] as String,
      ageGroup: json['age_group'] as String? ?? 'adults',
      requiresConsent: json['requires_consent'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      hint: json['hint'] != null 
          ? Map<String, String>.from(json['hint'] as Map) 
          : null,
      repeatCount: 0, // Always 0 from backend
    );
  }

  /// Converts to JSON (for local storage, includes repeatCount).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'category_id': categoryId,
      'age_group': ageGroup,
      'requires_consent': requiresConsent,
      'is_active': isActive,
      if (hint != null) 'hint': hint,
      'repeat_count': repeatCount,
    };
  }

  /// Gets the task type as enum.
  TaskType get taskType => TaskType.fromString(type);

  /// Gets the age group as enum.
  AgeGroup get ageGroupEnum => AgeGroup.fromString(ageGroup);

  /// Checks if task is a truth.
  bool get isTruth => type == TaskType.truth.apiValue;

  /// Checks if task is a dare.
  bool get isDare => type == TaskType.dare.apiValue;

  /// Gets localized task content with fallback to English.
  String getContent(String languageCode) {
    return content[languageCode] ?? content['en'] ?? content.values.first;
  }

  /// Alias for getContent for backward compatibility.
  String getText(String languageCode) => getContent(languageCode);

  /// Gets localized hint if available.
  String? getHint(String languageCode) {
    if (hint == null) return null;
    return hint![languageCode] ?? hint!['en'] ?? hint!.values.firstOrNull;
  }

  /// Checks if task content is available in the specified language.
  bool hasLanguage(String languageCode) {
    return content.containsKey(languageCode) && content[languageCode]!.isNotEmpty;
  }

  /// Checks if task is available for a specific age group.
  bool isAvailableForAgeGroup(AgeGroup group) {
    return ageGroup == group.value;
  }

  /// Returns true if this task hasn't been used yet (repeatCount == 0).
  bool get isUnused => repeatCount == 0;

  /// Returns a copy with incremented repeat count.
  Task markAsUsed() => copyWith(repeatCount: repeatCount + 1);

  /// Returns a copy with reset repeat count.
  Task resetUsage() => copyWith(repeatCount: 0);

  Task copyWith({
    String? id,
    Map<String, String>? content,
    String? type,
    String? categoryId,
    String? ageGroup,
    bool? requiresConsent,
    bool? isActive,
    Map<String, String>? hint,
    int? repeatCount,
  }) {
    return Task(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      ageGroup: ageGroup ?? this.ageGroup,
      requiresConsent: requiresConsent ?? this.requiresConsent,
      isActive: isActive ?? this.isActive,
      hint: hint ?? this.hint,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        type,
        categoryId,
        ageGroup,
        requiresConsent,
        isActive,
        hint,
        repeatCount,
      ];
}
