import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Sound effect types available in the game.
enum SoundEffect {
  buttonTap('sounds/button_tap.mp3'),
  spinStart('sounds/spin_start.mp3'),
  spinStop('sounds/spin_stop.mp3'),
  timerTick('sounds/timer_tick.mp3'),
  success('sounds/success.mp3'),
  forfeit('sounds/forfeit.mp3'),
  countdown('sounds/countdown.mp3');

  const SoundEffect(this.assetPath);
  final String assetPath;
}

/// Service for managing sound effects.
/// 
/// Handles playing and caching of game sounds.
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  final Map<SoundEffect, AudioPlayer> _cachedPlayers = {};
  bool _enabled = true;

  /// Sets whether sound is enabled.
  set enabled(bool value) => _enabled = value;

  /// Plays a sound effect.
  Future<void> play(SoundEffect sound) async {
    if (!_enabled) return;

    try {
      // Use cached player if available
      if (_cachedPlayers.containsKey(sound)) {
        await _cachedPlayers[sound]!.seek(Duration.zero);
        await _cachedPlayers[sound]!.resume();
      } else {
        final player = AudioPlayer();
        _cachedPlayers[sound] = player;
        await player.setSource(AssetSource(sound.assetPath));
        await player.resume();
      }
    } catch (e) {
      // Silent fail for missing audio files
    }
  }

  /// Stops all playing sounds.
  Future<void> stopAll() async {
    for (final player in _cachedPlayers.values) {
      await player.stop();
    }
  }

  /// Disposes all audio resources.
  void dispose() {
    _player.dispose();
    for (final player in _cachedPlayers.values) {
      player.dispose();
    }
    _cachedPlayers.clear();
  }
}

/// Provider for sound service.
final soundServiceProvider = Provider<SoundService>((ref) {
  final settings = ref.watch(settingsProvider);
  final service = SoundService();
  service.enabled = settings.soundEnabled;
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
