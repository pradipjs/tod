import 'dart:convert';

import '../local_db/hive_boxes.dart';
import '../models/app_settings.dart';

/// Repository for managing application settings.
/// 
/// Persists user preferences to local storage.
class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  /// Loads settings from local storage.
  AppSettings loadSettings() {
    try {
      final box = HiveBoxes.settings;
      final data = box.get(_settingsKey);
      if (data == null) return const AppSettings();

      final json = jsonDecode(data as String) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return const AppSettings();
    }
  }

  /// Saves settings to local storage.
  Future<void> saveSettings(AppSettings settings) async {
    final box = HiveBoxes.settings;
    final json = jsonEncode(settings.toJson());
    await box.put(_settingsKey, json);
  }

  /// Clears all settings.
  Future<void> clearSettings() async {
    final box = HiveBoxes.settings;
    await box.delete(_settingsKey);
  }
}
