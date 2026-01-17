import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Available bottle skins for spin the bottle game.
enum BottleSkin {
  classic('classic', 'Classic Bottle'),
  modern('modern', 'Modern Bottle'),
  neon('neon', 'Neon Bottle'),
  golden('golden', 'Golden Bottle');

  final String id;
  final String label;

  const BottleSkin(this.id, this.label);

  /// Get BottleSkin from id string.
  static BottleSkin fromId(String id) {
    return BottleSkin.values.firstWhere(
      (skin) => skin.id == id,
      orElse: () => BottleSkin.classic,
    );
  }
}

/// Application settings model.
/// 
/// Stores user preferences that persist across sessions.
class AppSettings extends Equatable {
  /// Current locale/language code.
  final String languageCode;

  /// Theme mode (system, light, dark).
  final ThemeMode themeMode;

  /// Primary theme color.
  final int themeColorValue;

  /// Whether sound is enabled.
  final bool soundEnabled;

  /// Whether haptic feedback is enabled.
  final bool hapticsEnabled;

  /// Default timer duration in seconds.
  final int defaultTimerSeconds;

  /// Selected bottle skin.
  final String bottleSkin;

  /// Default age group.
  final String defaultAgeGroup;

  /// Whether onboarding has been completed.
  final bool onboardingCompleted;

  /// Last used game mode.
  final String? lastGameMode;

  /// Last used turn mode.
  final String? lastTurnMode;

  const AppSettings({
    this.languageCode = 'en',
    this.themeMode = ThemeMode.system,
    this.themeColorValue = 0xFF6366F1,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.defaultTimerSeconds = 60,
    this.bottleSkin = 'classic',
    this.defaultAgeGroup = 'adults',
    this.onboardingCompleted = false,
    this.lastGameMode,
    this.lastTurnMode,
  });

  /// Creates AppSettings from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      languageCode: json['language_code'] as String? ?? 'en',
      themeMode: ThemeMode.values[json['theme_mode'] as int? ?? 0],
      themeColorValue: json['theme_color_value'] as int? ?? 0xFF6366F1,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      hapticsEnabled: json['haptics_enabled'] as bool? ?? true,
      defaultTimerSeconds: json['default_timer_seconds'] as int? ?? 60,
      bottleSkin: json['bottle_skin'] as String? ?? 'classic',
      defaultAgeGroup: json['default_age_group'] as String? ?? 'adults',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      lastGameMode: json['last_game_mode'] as String?,
      lastTurnMode: json['last_turn_mode'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'language_code': languageCode,
      'theme_mode': themeMode.index,
      'theme_color_value': themeColorValue,
      'sound_enabled': soundEnabled,
      'haptics_enabled': hapticsEnabled,
      'default_timer_seconds': defaultTimerSeconds,
      'bottle_skin': bottleSkin,
      'default_age_group': defaultAgeGroup,
      'onboarding_completed': onboardingCompleted,
      if (lastGameMode != null) 'last_game_mode': lastGameMode,
      if (lastTurnMode != null) 'last_turn_mode': lastTurnMode,
    };
  }

  /// Gets locale from language code.
  Locale get locale => Locale(languageCode);

  /// Alias for languageCode (for compatibility).
  String get language => languageCode;

  /// Gets theme color.
  Color get themeColor => Color(themeColorValue);

  /// Gets bottle skin enum.
  BottleSkin get bottleSkinEnum => BottleSkin.fromId(bottleSkin);

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    int? themeColorValue,
    bool? soundEnabled,
    bool? hapticsEnabled,
    int? defaultTimerSeconds,
    String? bottleSkin,
    String? defaultAgeGroup,
    bool? onboardingCompleted,
    String? lastGameMode,
    String? lastTurnMode,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      themeColorValue: themeColorValue ?? this.themeColorValue,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      defaultTimerSeconds: defaultTimerSeconds ?? this.defaultTimerSeconds,
      bottleSkin: bottleSkin ?? this.bottleSkin,
      defaultAgeGroup: defaultAgeGroup ?? this.defaultAgeGroup,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastGameMode: lastGameMode ?? this.lastGameMode,
      lastTurnMode: lastTurnMode ?? this.lastTurnMode,
    );
  }

  @override
  List<Object?> get props => [
        languageCode,
        themeMode,
        themeColorValue,
        soundEnabled,
        hapticsEnabled,
        defaultTimerSeconds,
        bottleSkin,
        defaultAgeGroup,
        onboardingCompleted,
        lastGameMode,
        lastTurnMode,
      ];
}
