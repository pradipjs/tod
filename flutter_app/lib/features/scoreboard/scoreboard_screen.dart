import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/game_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/player.dart';

/// Live scoreboard displayed during game.
class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final session = gameState.session;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('scoreboard'))),
        body: Center(child: Text(context.tr('noGameSession'))),
      );
    }

    final sortedPlayers = List<Player>.from(session.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('scoreboard')),
      ),
      body: Column(
        children: [
          // Game stats header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  theme,
                  context.tr('round'),
                  '${session.currentRound}',
                  Icons.loop,
                ),
                _buildStatItem(
                  context,
                  theme,
                  context.tr('players'),
                  '${session.players.length}',
                  Icons.people,
                ),
                _buildStatItem(
                  context,
                  theme,
                  context.tr('timer'),
                  '${session.timerSeconds}s',
                  Icons.timer,
                ),
              ],
            ),
          ),

          // Player list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final isCurrentPlayer = player.id == session.currentPlayer.id;

                return _buildPlayerRow(
                  context,
                  theme,
                  player,
                  index + 1,
                  isCurrentPlayer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    ThemeData theme,
    Player player,
    int rank,
    bool isCurrentPlayer,
  ) {
    final rankEmoji = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isCurrentPlayer
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                rankEmoji,
                style: rank <= 3
                    ? const TextStyle(fontSize: 24)
                    : theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(player.avatarColor),
                shape: BoxShape.circle,
                border: isCurrentPlayer
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isCurrentPlayer)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  context.tr('currentTurn'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              '${player.completedTasks}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.cancel_outlined,
              size: 16,
              color: AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              '${player.forfeitedTasks}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            '${player.score}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
