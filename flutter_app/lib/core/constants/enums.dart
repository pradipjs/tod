/// Application enums.
/// 
/// Centralized enum definitions for type-safe constants.

/// Age groups for content filtering.
enum AgeGroup {
  kids,
  teen,
  adults;

  /// Returns the minimum age for this group.
  int get minAge => switch (this) {
    AgeGroup.kids => 0,
    AgeGroup.teen => 13,
    AgeGroup.adults => 18,
  };

  /// Returns the maximum age for this group.
  int get maxAge => switch (this) {
    AgeGroup.kids => 12,
    AgeGroup.teen => 17,
    AgeGroup.adults => 99,
  };

  /// Returns display label.
  String get label => switch (this) {
    AgeGroup.kids => 'Kids',
    AgeGroup.teen => 'Teen',
    AgeGroup.adults => 'Adults',
  };

  /// Returns the API value (alias for apiValue).
  String get value => name;

  /// Returns the API value.
  String get apiValue => name;

  /// Parse from string.
  static AgeGroup fromString(String value) {
    return AgeGroup.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AgeGroup.adults,
    );
  }
}

/// Task types.
enum TaskType {
  truth,
  dare;

  /// Returns display label.
  String get label => switch (this) {
    TaskType.truth => 'Truth',
    TaskType.dare => 'Dare',
  };

  /// Returns the API value (alias for apiValue).
  String get value => name;

  /// Returns the API value.
  String get apiValue => name;

  /// Parse from string.
  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => TaskType.truth,
    );
  }
}

/// Turn modes for player selection.
enum TurnMode {
  sequential,
  random,
  spinBottle;

  /// Returns display label.
  String get label => switch (this) {
    TurnMode.sequential => 'Sequential',
    TurnMode.random => 'Random',
    TurnMode.spinBottle => 'Spin Bottle',
  };

  /// Returns the string value.
  String get value => name;

  /// Parse from string.
  static TurnMode fromString(String value) {
    return TurnMode.values.firstWhere(
      (e) => e.name == value.toLowerCase() || e.name == value,
      orElse: () => TurnMode.sequential,
    );
  }
}

/// Timer states.
enum TimerState {
  idle,
  running,
  paused,
  finished,
  completed, // Alias for finished
  forfeited; // Task was forfeited
}

// Note: SoundEffect and HapticType are defined in their respective service files:
// - SoundEffect: lib/core/sound/sound_service.dart (includes asset paths)
// - HapticType: lib/core/haptics/haptics_service.dart (includes selection type)

/// Supported languages with their codes.
enum AppLanguage {
  english('en', 'English', '🇺🇸'),
  chinese('zh', 'Mandarin Chinese', '🇨🇳'),
  spanish('es', 'Spanish', '🇪🇸'),
  hindi('hi', 'Hindi', '🇮🇳'),
  arabic('ar', 'Arabic', '🇸🇦'),
  french('fr', 'French', '🇫🇷'),
  portuguese('pt', 'Portuguese', '🇵🇹'),
  bengali('bn', 'Bengali', '🇧🇩'),
  russian('ru', 'Russian', '🇷🇺'),
  urdu('ur', 'Urdu', '🇵🇰');

  final String code;
  final String name;
  final String flag;

  const AppLanguage(this.code, this.name, this.flag);

  /// Get language by code.
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AppLanguage.english,
    );
  }

  /// Get all language codes.
  static List<String> get allCodes => values.map((e) => e.code).toList();
}

/// Game modes (same as age groups but for display).
enum GameMode {
  kids('kids', '👶', 'Safe & fun for kids'),
  teen('teen', '🧑', 'Exciting for teenagers'),
  adults('adults', '🔥', 'Spicy for adults');

  final String value;
  final String emoji;
  final String description;

  const GameMode(this.value, this.emoji, this.description);

  /// Convert to AgeGroup.
  AgeGroup get ageGroup => AgeGroup.fromString(value);

  /// Parse from string.
  static GameMode fromString(String value) {
    return GameMode.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => GameMode.adults,
    );
  }
}
