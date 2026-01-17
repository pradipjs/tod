import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/game_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/player.dart';
import '../widgets/animated_button.dart';

/// Game results and scoreboard screen.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    // ignore: unused_local_variable
    final settings = ref.watch(settingsProvider);
    final session = gameState.session;

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('No game session')),
      );
    }

    // Sort players by score
    final sortedPlayers = List<Player>.from(session.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final winner = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    final hasWinner = winner != null && winner.score > 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Trophy and winner
              if (hasWinner) ...[
                _buildWinnerSection(context, theme, winner),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                Text(
                  context.tr('gameComplete'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('🎉', style: TextStyle(fontSize: 80)),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Stats row
              _buildStatsRow(context, theme, session),

              const SizedBox(height: AppSpacing.xl),

              // Scoreboard
              Text(
                context.tr('scoreboard'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    return _buildPlayerCard(
                      context,
                      theme,
                      player,
                      index + 1,
                    );
                  },
                ),
              ),

              // Action buttons
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      text: context.tr('playAgain'),
                      icon: Icons.replay,
                      onPressed: () {
                        ref.read(gameProvider.notifier).restartGame();
                        context.go(AppRoutes.gameMode);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GameButton(
                      text: context.tr('home'),
                      icon: Icons.home,
                      isOutlined: true,
                      onPressed: () {
                        ref.read(gameProvider.notifier).endGame();
                        context.go(AppRoutes.home);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerSection(
    BuildContext context,
    ThemeData theme,
    Player winner,
  ) {
    return Column(
      children: [
        // Crown
        const Text('👑', style: TextStyle(fontSize: 60)),
        const SizedBox(height: AppSpacing.sm),

        Text(
          context.tr('winner'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Winner avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Color(winner.avatarColor),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              winner.avatar,
              style: const TextStyle(fontSize: 50),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          winner.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          '${winner.score} ${context.tr('points')}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    ThemeData theme,
    dynamic session,
  ) {
    final totalTasks = session.players.fold<int>(
      0,
      (sum, p) => sum + p.completedTasks + p.forfeitedTasks,
    );
    final completedTasks = session.players.fold<int>(
      0,
      (sum, p) => sum + p.completedTasks,
    );
    final forfeitedTasks = session.players.fold<int>(
      0,
      (sum, p) => sum + p.forfeitedTasks,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            theme,
            context.tr('totalTasks'),
            totalTasks.toString(),
            Icons.assignment,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            context,
            theme,
            context.tr('completed'),
            completedTasks.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            context,
            theme,
            context.tr('forfeited'),
            forfeitedTasks.toString(),
            Icons.cancel,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    ThemeData theme,
    Player player,
    int rank,
  ) {
    final isTop3 = rank <= 3;
    final rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                rankEmoji,
                style: isTop3
                    ? const TextStyle(fontSize: 24)
                    : theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Color(player.avatarColor),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  player.avatar,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          player.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${player.completedTasks} ${context.tr("completed")} • ${player.forfeitedTasks} ${context.tr("forfeited")}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '${player.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Live scoreboard widget that can be embedded during game.
/// Note: The main ScoreboardScreen is in features/scoreboard/scoreboard_screen.dart
class LiveScoreboardWidget extends ConsumerWidget {
  const LiveScoreboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final session = gameState.session;

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('No game session')),
      );
    }

    final sortedPlayers = List<Player>.from(session.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('scoreboard')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: sortedPlayers.length,
        itemBuilder: (context, index) {
          final player = sortedPlayers[index];
          final isTop3 = index < 3;
          final rankEmoji = switch (index) {
            0 => '🥇',
            1 => '🥈',
            2 => '🥉',
            _ => '#${index + 1}',
          };

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      rankEmoji,
                      style: isTop3
                          ? const TextStyle(fontSize: 24)
                          : theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Color(player.avatarColor),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        player.avatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                player.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                '${player.completedTasks} ✓  •  ${player.forfeitedTasks} ✗',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                '${player.score}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
