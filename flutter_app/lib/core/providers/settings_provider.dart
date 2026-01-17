import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../constants/enums.dart';
import '../di/service_locator.dart';

/// Provider for settings repository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return ServiceLocator.instance.settingsRepository;
});

/// Notifier for managing app settings state.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(_repository.loadSettings());

  /// Updates language.
  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(languageCode: languageCode);
    await _repository.saveSettings(state);
  }

  /// Updates theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.saveSettings(state);
  }

  /// Updates theme color.
  Future<void> setThemeColor(Color color) async {
    state = state.copyWith(themeColorValue: color.value);
    await _repository.saveSettings(state);
  }

  /// Toggles sound.
  Future<void> toggleSound() async {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    await _repository.saveSettings(state);
  }

  /// Toggles haptics.
  Future<void> toggleHaptics() async {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
    await _repository.saveSettings(state);
  }

  /// Updates default timer duration.
  Future<void> setDefaultTimer(int seconds) async {
    state = state.copyWith(defaultTimerSeconds: seconds);
    await _repository.saveSettings(state);
  }

  /// Updates bottle skin.
  Future<void> setBottleSkin(String skinId) async {
    state = state.copyWith(bottleSkin: skinId);
    await _repository.saveSettings(state);
  }

  /// Marks onboarding as completed.
  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
    await _repository.saveSettings(state);
  }

  /// Saves last used game mode.
  Future<void> setLastGameMode(String mode) async {
    state = state.copyWith(lastGameMode: mode);
    await _repository.saveSettings(state);
  }

  /// Saves last used turn mode.
  Future<void> setLastTurnMode(String turnMode) async {
    state = state.copyWith(lastTurnMode: turnMode);
    await _repository.saveSettings(state);
  }

  /// Updates default age group.
  Future<void> setDefaultAgeGroup(AgeGroup ageGroup) async {
    state = state.copyWith(defaultAgeGroup: ageGroup.name);
    await _repository.saveSettings(state);
  }

  /// Resets all settings to defaults.
  Future<void> resetSettings() async {
    state = const AppSettings();
    await _repository.saveSettings(state);
  }
}

/// Provider for app settings.
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
