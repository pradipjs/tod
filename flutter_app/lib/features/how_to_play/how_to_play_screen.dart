import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';

/// How to play tutorial screen.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('howToPlay')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game overview
            _buildSection(
              theme,
              '🎮',
              context.tr('gameOverview'),
              context.tr('gameOverviewDesc'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Game modes
            _buildSection(
              theme,
              '🎯',
              context.tr('gameModes'),
              null,
            ),
            _buildGameMode(
              context,
              theme,
              '🍾',
              context.tr('spinBottle'),
              context.tr('spinBottleDesc'),
            ),
            _buildGameMode(
              context,
              theme,
              '🔄',
              context.tr('passAndPlay'),
              context.tr('passAndPlayDesc'),
            ),
            _buildGameMode(
              context,
              theme,
              '🎲',
              context.tr('randomTurn'),
              context.tr('randomTurnDesc'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Steps
            _buildSection(
              theme,
              '📋',
              context.tr('howToPlaySteps'),
              null,
            ),
            _buildStep(
              context,
              theme,
              1,
              context.tr('step1Title'),
              context.tr('step1Desc'),
            ),
            _buildStep(
              context,
              theme,
              2,
              context.tr('step2Title'),
              context.tr('step2Desc'),
            ),
            _buildStep(
              context,
              theme,
              3,
              context.tr('step3Title'),
              context.tr('step3Desc'),
            ),
            _buildStep(
              context,
              theme,
              4,
              context.tr('step4Title'),
              context.tr('step4Desc'),
            ),
            _buildStep(
              context,
              theme,
              5,
              context.tr('step5Title'),
              context.tr('step5Desc'),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Scoring
            _buildSection(
              theme,
              '⭐',
              context.tr('scoring'),
              null,
            ),
            _buildScoringRule(
              context,
              theme,
              Icons.check_circle,
              AppColors.success,
              context.tr('completeTruth'),
              '+10',
            ),
            _buildScoringRule(
              context,
              theme,
              Icons.local_fire_department,
              AppColors.primary,
              context.tr('completeDare'),
              '+15',
            ),
            _buildScoringRule(
              context,
              theme,
              Icons.cancel,
              AppColors.error,
              context.tr('forfeitTask'),
              '-5',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Tips
            _buildSection(
              theme,
              '💡',
              context.tr('tips'),
              null,
            ),
            _buildTip(context, theme, context.tr('tip1')),
            _buildTip(context, theme, context.tr('tip2')),
            _buildTip(context, theme, context.tr('tip3')),
            _buildTip(context, theme, context.tr('tip4')),

            const SizedBox(height: AppSpacing.xl * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String emoji,
    String title,
    String? description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGameMode(
    BuildContext context,
    ThemeData theme,
    String emoji,
    String title,
    String description,
  ) {
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    ThemeData theme,
    int number,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringRule(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    Color color,
    String description,
    String points,
  ) {
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                points,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(
    BuildContext context,
    ThemeData theme,
    String tip,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
