import 'dart:convert';

import '../local_db/hive_boxes.dart';
import '../models/game_session.dart';

/// Repository for managing game sessions.
/// 
/// Handles session persistence and history.
class SessionRepository {
  static const String _currentSessionKey = 'current_session';
  static const String _sessionHistoryKey = 'session_history';

  /// Gets the current active session.
  GameSession? getCurrentSession() {
    try {
      final box = HiveBoxes.sessions;
      final data = box.get(_currentSessionKey);
      if (data == null) return null;

      final json = jsonDecode(data as String) as Map<String, dynamic>;
      return GameSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Saves the current session.
  Future<void> saveCurrentSession(GameSession session) async {
    final box = HiveBoxes.sessions;
    final json = jsonEncode(session.toJson());
    await box.put(_currentSessionKey, json);
  }

  /// Clears the current session.
  Future<void> clearCurrentSession() async {
    final box = HiveBoxes.sessions;
    await box.delete(_currentSessionKey);
  }

  /// Gets session history.
  List<GameSession> getSessionHistory() {
    try {
      final box = HiveBoxes.sessions;
      final data = box.get(_sessionHistoryKey);
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data as String);
      return list
          .map((json) => GameSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Adds a session to history.
  Future<void> addToHistory(GameSession session) async {
    final history = getSessionHistory();
    history.insert(0, session);

    // Keep only last 50 sessions
    final trimmed = history.take(50).toList();

    final box = HiveBoxes.sessions;
    final json = jsonEncode(trimmed.map((s) => s.toJson()).toList());
    await box.put(_sessionHistoryKey, json);
  }

  /// Clears session history.
  Future<void> clearHistory() async {
    final box = HiveBoxes.sessions;
    await box.delete(_sessionHistoryKey);
  }
}
