import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../providers/settings_provider.dart';

/// Haptic feedback types.
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
}

/// Service for managing haptic feedback.
/// 
/// Provides various haptic patterns for different interactions.
class HapticsService {
  bool _enabled = true;
  bool _hasVibrator = false;

  /// Initializes the haptics service.
  Future<void> initialize() async {
    _hasVibrator = await Vibration.hasVibrator() ?? false;
  }

  /// Sets whether haptics are enabled.
  set enabled(bool value) => _enabled = value;

  /// Triggers haptic feedback.
  Future<void> trigger(HapticType type) async {
    if (!_enabled) return;

    switch (type) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticType.success:
        if (_hasVibrator) {
          await Vibration.vibrate(duration: 50, amplitude: 128);
        } else {
          await HapticFeedback.mediumImpact();
        }
        break;
      case HapticType.warning:
        if (_hasVibrator) {
          await Vibration.vibrate(pattern: [0, 50, 50, 50], intensities: [128, 128]);
        } else {
          await HapticFeedback.mediumImpact();
        }
        break;
      case HapticType.error:
        if (_hasVibrator) {
          await Vibration.vibrate(pattern: [0, 100, 50, 100], intensities: [255, 255]);
        } else {
          await HapticFeedback.heavyImpact();
        }
        break;
    }
  }

  /// Triggers custom vibration pattern.
  Future<void> customVibrate({
    int duration = 50,
    int amplitude = 128,
  }) async {
    if (!_enabled || !_hasVibrator) return;
    await Vibration.vibrate(duration: duration, amplitude: amplitude);
  }

  /// Triggers spin stop haptic (heavy impact).
  Future<void> spinStop() async {
    await trigger(HapticType.heavy);
  }

  /// Triggers button tap haptic.
  Future<void> buttonTap() async {
    await trigger(HapticType.light);
  }
}

/// Provider for haptics service.
final hapticsServiceProvider = Provider<HapticsService>((ref) {
  final settings = ref.watch(settingsProvider);
  final service = HapticsService();
  service.enabled = settings.hapticsEnabled;
  return service;
});
