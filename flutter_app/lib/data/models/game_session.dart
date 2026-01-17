import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';
import 'player.dart';

part 'game_session.g.dart';

/// Represents a game session.
/// 
/// Tracks all game state including players, settings, and progress.
@HiveType(typeId: 4)
class GameSession extends Equatable {
  /// Unique session identifier.
  @HiveField(0)
  final String id;

  /// Game mode (kids, teen, adult).
  @HiveField(1)
  final String mode;

  /// Turn selection mode.
  @HiveField(2)
  final String turnMode;

  /// Selected category IDs.
  @HiveField(3)
  final List<String> categoryIds;

  /// Timer duration in seconds.
  @HiveField(5)
  final int timerSeconds;

  /// List of players in the session.
  @HiveField(6)
  final List<Player> players;

  /// Index of current player.
  @HiveField(7)
  final int currentPlayerIndex;

  /// Total rounds played.
  @HiveField(8)
  final int roundsPlayed;

  /// Session start time.
  @HiveField(9)
  final DateTime startedAt;

  /// Session end time (null if ongoing).
  @HiveField(10)
  final DateTime? endedAt;

  /// Whether adult consent was given.
  @HiveField(11)
  final bool adultConsentGiven;

  /// IDs of tasks already used in this session.
  @HiveField(12)
  final List<String> usedTaskIds;

  /// Age group for task filtering (kids, teen, adults).
  @HiveField(13)
  final String ageGroup;

  /// Language code for task content.
  @HiveField(14)
  final String language;

  const GameSession({
    required this.id,
    required this.mode,
    required this.turnMode,
    required this.categoryIds,
    required this.players,
    required this.startedAt,
    this.timerSeconds = 60,
    this.currentPlayerIndex = 0,
    this.roundsPlayed = 0,
    this.endedAt,
    this.adultConsentGiven = false,
    this.usedTaskIds = const [],
    this.ageGroup = 'adults',
    this.language = 'en',
  });

  /// Creates a GameSession from JSON.
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      mode: json['mode'] as String,
      turnMode: json['turn_mode'] as String,
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      startedAt: DateTime.parse(json['started_at'] as String),
      timerSeconds: json['timer_seconds'] as int? ?? 60,
      currentPlayerIndex: json['current_player_index'] as int? ?? 0,
      roundsPlayed: json['rounds_played'] as int? ?? 0,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      adultConsentGiven: json['adult_consent_given'] as bool? ?? false,
      usedTaskIds: List<String>.from(json['used_task_ids'] ?? []),
      ageGroup: json['age_group'] as String? ?? 'adults',
      language: json['language'] as String? ?? 'en',
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'turn_mode': turnMode,
      'category_ids': categoryIds,
      'players': players.map((p) => p.toJson()).toList(),
      'started_at': startedAt.toIso8601String(),
      'timer_seconds': timerSeconds,
      'current_player_index': currentPlayerIndex,
      'rounds_played': roundsPlayed,
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      'adult_consent_given': adultConsentGiven,
      'used_task_ids': usedTaskIds,
      'age_group': ageGroup,
      'language': language,
    };
  }

  /// Gets game mode as enum.
  GameMode get gameMode => GameMode.fromString(mode);

  /// Gets turn mode as enum.
  TurnMode get turnModeEnum => TurnMode.fromString(turnMode);

  /// Gets the current player.
  Player get currentPlayer => players[currentPlayerIndex];

  /// Gets player count.
  int get playerCount => players.length;

  /// Gets current round number (1-based).
  int get currentRound => roundsPlayed + 1;

  /// Gets total score across all players.
  int get totalScore => players.fold(0, (sum, p) => sum + p.score);

  /// Gets session duration.
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Checks if session is ongoing.
  bool get isOngoing => endedAt == null;

  /// Gets the MVP (player with highest score).
  Player? get mvp {
    if (players.isEmpty) return null;
    return players.reduce((a, b) => a.score >= b.score ? a : b);
  }

  /// Gets players sorted by score (descending).
  List<Player> get leaderboard {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  /// Checks if a task has been used.
  bool isTaskUsed(String taskId) => usedTaskIds.contains(taskId);

  GameSession copyWith({
    String? id,
    String? mode,
    String? turnMode,
    List<String>? categoryIds,
    int? timerSeconds,
    List<Player>? players,
    int? currentPlayerIndex,
    int? roundsPlayed,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? adultConsentGiven,
    List<String>? usedTaskIds,
    String? ageGroup,
    String? language,
  }) {
    return GameSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      turnMode: turnMode ?? this.turnMode,
      categoryIds: categoryIds ?? this.categoryIds,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      adultConsentGiven: adultConsentGiven ?? this.adultConsentGiven,
      usedTaskIds: usedTaskIds ?? this.usedTaskIds,
      ageGroup: ageGroup ?? this.ageGroup,
      language: language ?? this.language,
    );
  }

  /// Moves to the next player.
  GameSession nextPlayer() {
    final nextIndex = (currentPlayerIndex + 1) % players.length;
    return copyWith(
      currentPlayerIndex: nextIndex,
      roundsPlayed: nextIndex == 0 ? roundsPlayed + 1 : roundsPlayed,
    );
  }

  /// Updates a player in the session.
  GameSession updatePlayer(Player updatedPlayer) {
    final updatedPlayers = players.map((p) {
      return p.id == updatedPlayer.id ? updatedPlayer : p;
    }).toList();
    return copyWith(players: updatedPlayers);
  }

  /// Marks a task as used.
  GameSession markTaskUsed(String taskId) {
    if (usedTaskIds.contains(taskId)) return this;
    return copyWith(usedTaskIds: [...usedTaskIds, taskId]);
  }

  /// Ends the session.
  GameSession endSession() {
    return copyWith(endedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        mode,
        turnMode,
        categoryIds,
        timerSeconds,
        players,
        currentPlayerIndex,
        roundsPlayed,
        startedAt,
        endedAt,
        adultConsentGiven,
        usedTaskIds,
        ageGroup,
        language,
      ];
}
