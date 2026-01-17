import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/theme/app_colors.dart';

part 'player.g.dart';

/// Represents a player in the game.
/// 
/// Players are created during game setup and tracked throughout
/// the game session for scoring and turn management.
@HiveType(typeId: 3)
class Player extends Equatable {
  /// Unique identifier for the player.
  @HiveField(0)
  final String id;

  /// Player's display name.
  @HiveField(1)
  final String name;

  /// Avatar identifier (emoji, icon name, or image path).
  @HiveField(2)
  final String avatar;

  /// Avatar color index.
  @HiveField(3)
  final int colorIndex;

  /// Current score in the session.
  @HiveField(4)
  final int score;

  /// Number of truths completed.
  @HiveField(5)
  final int truthsCompleted;

  /// Number of dares completed.
  @HiveField(6)
  final int daresCompleted;

  /// Number of forfeits.
  @HiveField(7)
  final int forfeits;

  /// Current streak count.
  @HiveField(8)
  final int streak;

  /// Highest streak achieved.
  @HiveField(9)
  final int bestStreak;

  const Player({
    required this.id,
    required this.name,
    this.avatar = '😊',
    this.colorIndex = 0,
    this.score = 0,
    this.truthsCompleted = 0,
    this.daresCompleted = 0,
    this.forfeits = 0,
    this.streak = 0,
    this.bestStreak = 0,
  });

  /// Creates a Player from JSON.
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? '😊',
      colorIndex: json['color_index'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      truthsCompleted: json['truths_completed'] as int? ?? 0,
      daresCompleted: json['dares_completed'] as int? ?? 0,
      forfeits: json['forfeits'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'color_index': colorIndex,
      'score': score,
      'truths_completed': truthsCompleted,
      'dares_completed': daresCompleted,
      'forfeits': forfeits,
      'streak': streak,
      'best_streak': bestStreak,
    };
  }

  /// Gets the avatar color based on index.
  int get avatarColor {
    final colors = AppColors.avatarColors;
    return colors[colorIndex % colors.length].value;
  }

  /// Total tasks completed.
  int get tasksCompleted => truthsCompleted + daresCompleted;

  /// Alias for tasksCompleted (for compatibility).
  int get completedTasks => tasksCompleted;

  /// Alias for forfeits (for compatibility).
  int get forfeitedTasks => forfeits;

  /// Completion rate as percentage.
  double get completionRate {
    final total = tasksCompleted + forfeits;
    if (total == 0) return 0;
    return (tasksCompleted / total) * 100;
  }

  /// Gets player initials (up to 2 characters).
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Player copyWith({
    String? id,
    String? name,
    String? avatar,
    int? colorIndex,
    int? score,
    int? truthsCompleted,
    int? daresCompleted,
    int? forfeits,
    int? streak,
    int? bestStreak,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      colorIndex: colorIndex ?? this.colorIndex,
      score: score ?? this.score,
      truthsCompleted: truthsCompleted ?? this.truthsCompleted,
      daresCompleted: daresCompleted ?? this.daresCompleted,
      forfeits: forfeits ?? this.forfeits,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  /// Records a completed task.
  Player recordCompletion({required bool isTruth, int points = 1}) {
    final newStreak = streak + 1;
    return copyWith(
      score: score + points,
      truthsCompleted: isTruth ? truthsCompleted + 1 : truthsCompleted,
      daresCompleted: isTruth ? daresCompleted : daresCompleted + 1,
      streak: newStreak,
      bestStreak: newStreak > bestStreak ? newStreak : bestStreak,
    );
  }

  /// Records a forfeit.
  Player recordForfeit() {
    return copyWith(
      forfeits: forfeits + 1,
      streak: 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatar,
        colorIndex,
        score,
        truthsCompleted,
        daresCompleted,
        forfeits,
        streak,
        bestStreak,
      ];
}
