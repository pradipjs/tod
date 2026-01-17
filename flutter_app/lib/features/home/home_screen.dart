import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../category_select/category_select_screen.dart';
import '../widgets/animated_button.dart';
import '../widgets/game_background.dart';
import '../widgets/language_selector.dart';

/// Home screen - main entry point of the app with game-like UI.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Top bar with settings
                _buildTopBar(context, ref),
                
                const Spacer(flex: 2),
                
                // Animated logo
                _buildAnimatedLogo(context, theme),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Title with gradient
                GradientText(
                  text: context.tr('appName'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                  colors: AppColors.primaryGradient,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Tagline
                Text(
                  'The Ultimate Party Game',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Play button with glow
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: GameButton(
                    text: context.tr('play'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _showTurnModePopup(context, ref),
                    width: size.width * 0.7,
                    height: 64,
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Bottom buttons
                _buildBottomButtons(context, theme),
                
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Language selector
        const LanguageSelector(),
        
        // Settings buttons
        Row(
          children: [
            NeonIconButton(
              icon: settings.soundEnabled 
                  ? Icons.volume_up_rounded 
                  : Icons.volume_off_rounded,
              onPressed: () => ref.read(settingsProvider.notifier).toggleSound(),
              color: settings.soundEnabled ? AppColors.accent : Colors.white38,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.xs),
            NeonIconButton(
              icon: settings.hapticsEnabled 
                  ? Icons.vibration_rounded 
                  : Icons.smartphone_rounded,
              onPressed: () => ref.read(settingsProvider.notifier).toggleHaptics(),
              color: settings.hapticsEnabled ? AppColors.accent : Colors.white38,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.xs),
            NeonIconButton(
              icon: Icons.settings_rounded,
              onPressed: () => context.push(AppRoutes.settings),
              color: AppColors.primary,
              size: 40,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo(BuildContext context, ThemeData theme) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Main logo container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎯',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBottomButton(
          context,
          icon: Icons.help_outline_rounded,
          label: context.tr('howToPlay'),
          onTap: () => context.push(AppRoutes.howToPlay),
          color: AppColors.truthGradient[0],
        ),
        _buildBottomButton(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: context.tr('addCustom'),
          onTap: () => context.push(AppRoutes.addTruthDare),
          color: AppColors.dareGradient[0],
        ),
        _buildBottomButton(
          context,
          icon: Icons.share_rounded,
          label: context.tr('share'),
          onTap: () {
            // Share functionality
          },
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildBottomButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return AnimatedButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show turn mode selection popup
  void _showTurnModePopup(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TurnModeSelectionSheet(
        onModeSelected: (mode) {
          ref.read(selectedTurnModeProvider.notifier).state = mode;
          Navigator.pop(context);
          context.push(AppRoutes.gameMode);
        },
      ),
    );
  }
}

/// Turn mode selection bottom sheet
class _TurnModeSelectionSheet extends StatefulWidget {
  final Function(TurnMode) onModeSelected;

  const _TurnModeSelectionSheet({required this.onModeSelected});

  @override
  State<_TurnModeSelectionSheet> createState() => _TurnModeSelectionSheetState();
}

class _TurnModeSelectionSheetState extends State<_TurnModeSelectionSheet> {
  TurnMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Title
                GradientText(
                  text: context.tr('selectGameMode'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  colors: AppColors.primaryGradient,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  'How do you want to play?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Turn mode options
                _buildModeOption(
                  context,
                  mode: TurnMode.spinBottle,
                  title: 'Spin the Bottle',
                  description: 'Spin to pick the next player',
                  icon: Icons.rotate_right_rounded,
                  color: AppColors.neonPink,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                _buildModeOption(
                  context,
                  mode: TurnMode.sequential,
                  title: 'Auto Next',
                  description: 'Players take turns in order',
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.neonBlue,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                _buildModeOption(
                  context,
                  mode: TurnMode.random,
                  title: 'Random',
                  description: 'Randomly pick the next player',
                  icon: Icons.shuffle_rounded,
                  color: AppColors.neonPurple,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    text: context.tr('continue'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _selectedMode != null
                        ? () => widget.onModeSelected(_selectedMode!)
                        : null,
                    gradient: _selectedMode != null
                        ? AppColors.primaryGradient
                        : null,
                    backgroundColor: _selectedMode != null
                        ? null
                        : Colors.white12,
                    height: 56,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required TurnMode mode,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedMode == mode;

    return AnimatedButton(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? color 
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? color : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            
            // Check indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
