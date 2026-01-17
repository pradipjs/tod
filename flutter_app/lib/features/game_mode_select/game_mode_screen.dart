import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/settings_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/game_background.dart';

/// Temporary state for game mode (age group) selection.
final selectedGameModeProvider = StateProvider<GameMode?>((ref) => null);

/// Age group selection screen with attractive game UI.
class GameModeScreen extends ConsumerWidget {
  const GameModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedMode = ref.watch(selectedGameModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: NeonIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
          color: AppColors.primary,
          size: 44,
        ),
        title: GradientText(
          text: context.tr('selectAgeGroup'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                
                // Subtitle
                Text(
                  'Choose your adventure level',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                Expanded(
                  child: ListView(
                    children: [
                      _buildModeCard(
                        context,
                        ref,
                        mode: GameMode.kids,
                        title: context.tr('kids'),
                        description: context.tr('kidsDesc'),
                        emoji: '🧒',
                        color: AppColors.kidsMode,
                        gradientColors: [AppColors.kidsMode, AppColors.kidsMode.withValues(alpha: 0.7)],
                        isSelected: selectedMode == GameMode.kids,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildModeCard(
                        context,
                        ref,
                        mode: GameMode.teen,
                        title: context.tr('teen'),
                        description: context.tr('teenDesc'),
                        emoji: '😎',
                        color: AppColors.teenMode,
                        gradientColors: [AppColors.teenMode, AppColors.teenMode.withValues(alpha: 0.7)],
                        isSelected: selectedMode == GameMode.teen,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildModeCard(
                        context,
                        ref,
                        mode: GameMode.adults,
                        title: context.tr('adult'),
                        description: context.tr('adultDesc'),
                        emoji: '🔥',
                        color: AppColors.adultMode,
                        gradientColors: AppColors.fireGradient,
                        isSelected: selectedMode == GameMode.adults,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    text: context.tr('continue'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: selectedMode != null
                        ? () => _onContinue(context, ref, selectedMode)
                        : null,
                    gradient: selectedMode != null 
                        ? AppColors.primaryGradient 
                        : null,
                    backgroundColor: selectedMode != null
                        ? null
                        : Colors.white12,
                    height: 60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    WidgetRef ref, {
    required GameMode mode,
    required String title,
    required String description,
    required String emoji,
    required Color color,
    required List<Color> gradientColors,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return AnimatedButton(
      onPressed: () {
        ref.read(selectedGameModeProvider.notifier).state = mode;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors.first.withValues(alpha: 0.3),
                    gradientColors.last.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.darkCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 25,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji container with glow
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: isSelected ? 0.4 : 0.2),
                    color.withValues(alpha: isSelected ? 0.2 : 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.white30,
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ] : null,
              ),
              child: isSelected 
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue(
    BuildContext context,
    WidgetRef ref,
    GameMode mode,
  ) async {
    // Show consent dialog for adult mode
    if (mode == GameMode.adults) {
      final confirmed = await _showConsentDialog(context);
      if (!confirmed) return;
    }

    // Save last used mode
    ref.read(settingsProvider.notifier).setLastGameMode(mode.value);

    // Navigate to category selection (next step in flow)
    if (context.mounted) {
      context.push(AppRoutes.categorySelect);
    }
  }

  Future<bool> _showConsentDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                const Text('🔞', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  context.tr('adultConsentTitle'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
            content: Text(
              context.tr('adultConsentMessage'),
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.tr('cancel'),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              GameButton(
                text: context.tr('confirm'),
                backgroundColor: AppColors.error,
                onPressed: () => Navigator.pop(context, true),
                height: 44,
              ),
            ],
          ),
        ) ??
        false;
  }
}
