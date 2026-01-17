import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/category.dart';
import '../game_mode_select/game_mode_screen.dart';
import '../widgets/animated_button.dart';
import '../widgets/game_background.dart';

/// Selected categories state.
final selectedCategoriesProvider = StateProvider<Set<String>>((ref) => {});

/// Selected turn mode (set from home screen popup).
final selectedTurnModeProvider = StateProvider<TurnMode>((ref) => TurnMode.spinBottle);

/// Category selection screen with game-like UI.
class CategorySelectScreen extends ConsumerStatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  ConsumerState<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends ConsumerState<CategorySelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameMode = ref.read(selectedGameModeProvider);
      ref.read(categoriesProvider.notifier).loadCategories(
        ageGroups: gameMode != null ? [gameMode.value] : null,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = ref.watch(categoriesProvider);
    final selectedCategories = ref.watch(selectedCategoriesProvider);
    final gameMode = ref.watch(selectedGameModeProvider);

    // Filter categories by game mode
    final categories = gameMode != null
        ? categoriesState.categories
            .where((c) => c.isAvailableForMode(gameMode.value))
            .toList()
        : categoriesState.categories;

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
          text: context.tr('selectCategories'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final allIds = categories.map((c) => c.id).toSet();
              if (selectedCategories.length == allIds.length) {
                ref.read(selectedCategoriesProvider.notifier).state = {};
              } else {
                ref.read(selectedCategoriesProvider.notifier).state = allIds;
              }
            },
            child: Text(
              selectedCategories.length == categories.length
                  ? context.tr('deselectAll')
                  : context.tr('selectAll'),
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: GameBackground(
        child: SafeArea(
          child: categoriesState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        // Section header
                        Row(
                          children: [
                            const Icon(Icons.category_rounded, 
                              color: AppColors.accent, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'CATEGORIES',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                '${selectedCategories.length}/${categories.length}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Categories grid
                        Expanded(
                          child: _buildCategoriesGrid(
                            context,
                            theme,
                            categories,
                            selectedCategories,
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Continue button (goes to player setup)
                        _buildContinueButton(context, selectedCategories, categories),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    ThemeData theme,
    List<Category> categories,
    Set<String> selectedCategories,
  ) {
    final settings = ref.watch(settingsProvider);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategories.contains(category.id);
        final categoryColor = AppColors.categoryColors[index % AppColors.categoryColors.length];

        return AnimatedButton(
          onPressed: () => _toggleCategory(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor.withValues(alpha: 0.3),
                        categoryColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isSelected ? null : AppColors.darkCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? categoryColor 
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with glow
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withValues(alpha: isSelected ? 0.4 : 0.2),
                              categoryColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          _getIconForCategory(category.icon),
                          color: isSelected ? categoryColor : categoryColor.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.getName(settings.languageCode),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // 18+ badge
                      if (category.requiresConsent)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '🔥 18+',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(
    BuildContext context, 
    Set<String> selectedCategories,
    List<Category> categories,
  ) {
    final hasSelection = selectedCategories.isNotEmpty || categories.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: GameButton(
        text: context.tr('continue'),
        icon: Icons.arrow_forward_rounded,
        gradient: hasSelection ? AppColors.primaryGradient : null,
        backgroundColor: hasSelection ? null : Colors.grey,
        onPressed: hasSelection ? () => context.push(AppRoutes.playerSetup) : null,
        height: 60,
      ),
    );
  }

  void _toggleCategory(Category category) async {
    // Show consent dialog if needed
    if (category.requiresConsent) {
      final confirmed = await _showConsentDialog(context, category);
      if (!confirmed) return;
    }

    final categories = ref.read(selectedCategoriesProvider);
    if (categories.contains(category.id)) {
      ref.read(selectedCategoriesProvider.notifier).state = 
          categories.where((id) => id != category.id).toSet();
    } else {
      ref.read(selectedCategoriesProvider.notifier).state = 
          {...categories, category.id};
    }
  }

  Future<bool> _showConsentDialog(BuildContext context, Category category) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('adultConsentTitle')),
            content: Text(context.tr('categoryConsentRequired')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }

  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'sentiment_very_dissatisfied':
        return Icons.sentiment_very_dissatisfied;
      case 'explore':
        return Icons.explore;
      case 'favorite':
        return Icons.favorite;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'school':
        return Icons.school;
      case 'compare_arrows':
        return Icons.compare_arrows;
      default:
        return Icons.category;
    }
  }
}
