import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/game_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/player.dart';
import '../category_select/category_select_screen.dart';
import '../game_mode_select/game_mode_screen.dart';
import '../widgets/animated_button.dart';
import '../widgets/game_background.dart';

/// State for players during setup.
final playersProvider = StateProvider<List<Player>>((ref) => []);

/// Player setup screen with game-like UI.
class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _nameController = TextEditingController();
  final _uuid = const Uuid();
  int _selectedColorIndex = 0;
  String _selectedEmoji = '😊';

  static const _emojis = [
    '😊', '😎', '🤓', '😜', '🤩', '😇', '🥳', '😈',
    '🦊', '🐱', '🐶', '🦁', '🐯', '🐻', '🐼', '🦄',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = ref.watch(playersProvider);

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
          text: context.tr('addPlayers'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (players.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(playersProvider.notifier).state = [];
              },
              child: Text(
                'Clear',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Player input
                _buildPlayerInput(context, theme),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Player count indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_rounded, 
                        color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${players.length}/${AppConstants.maxPlayers} Players',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Players list
                Expanded(
                  child: players.isEmpty
                      ? _buildEmptyState(context, theme)
                      : _buildPlayersList(context, players),
                ),
                
                // Continue button
                const SizedBox(height: AppSpacing.lg),
                _buildContinueButton(context, players),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInput(BuildContext context, ThemeData theme) {
    return NeonContainer(
      glowColor: AppColors.secondary,
      glowIntensity: 0.3,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar selection
          Row(
            children: [
              // Selected avatar with glow
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.avatarColors[_selectedColorIndex].withValues(alpha: 0.4),
                            AppColors.avatarColors[_selectedColorIndex].withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.avatarColors[_selectedColorIndex],
                            AppColors.avatarColors[_selectedColorIndex].withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.avatarColors[_selectedColorIndex].withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Color selection
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppColors.avatarColors.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.avatarColors[index],
                                AppColors.avatarColors[index].withValues(alpha: 0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.avatarColors[index].withValues(alpha: 0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Name input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: context.tr('playerName'),
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.darkCard.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              NeonIconButton(
                icon: Icons.add_rounded,
                onPressed: _addPlayer,
                color: AppColors.success,
                size: 52,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 60,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Add at least ${AppConstants.minPlayers} players',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap + to add a player',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(BuildContext context, List<Player> players) {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final playerColor = Color(player.avatarColor);
        
        return Dismissible(
          key: Key(player.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removePlayer(player.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.error.withValues(alpha: 0.5), AppColors.error],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: playerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar with glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        playerColor,
                        playerColor.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: playerColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      player.avatar,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Player ${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: playerColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                NeonIconButton(
                  icon: Icons.close_rounded,
                  onPressed: () => _removePlayer(player.id),
                  color: AppColors.error,
                  size: 40,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton(BuildContext context, List<Player> players) {
    final canContinue = players.length >= AppConstants.minPlayers;

    return SizedBox(
      width: double.infinity,
      child: GameButton(
        text: context.tr('startGame'),
        icon: Icons.play_arrow_rounded,
        onPressed: canContinue ? () => _startGame(context) : null,
        gradient: canContinue ? AppColors.primaryGradient : null,
        backgroundColor: canContinue ? null : Colors.white12,
        height: 60,
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GradientText(
              text: 'Select Avatar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: _emojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary
                            : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final players = ref.read(playersProvider);
    if (players.length >= AppConstants.maxPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('maxPlayersError'))),
      );
      return;
    }

    final player = Player(
      id: _uuid.v4(),
      name: name,
      avatar: _selectedEmoji,
      colorIndex: _selectedColorIndex,
    );

    ref.read(playersProvider.notifier).state = [...players, player];
    _nameController.clear();

    // Cycle to next color
    setState(() {
      _selectedColorIndex = (_selectedColorIndex + 1) % AppColors.avatarColors.length;
    });
  }

  void _removePlayer(String id) {
    final players = ref.read(playersProvider);
    ref.read(playersProvider.notifier).state =
        players.where((p) => p.id != id).toList();
  }

  void _startGame(BuildContext context) {
    final players = ref.read(playersProvider);
    final gameMode = ref.read(selectedGameModeProvider);
    final turnMode = ref.read(selectedTurnModeProvider);
    var categoryIds = ref.read(selectedCategoriesProvider).toList();
    final settings = ref.read(settingsProvider);

    // If no categories selected, use all
    if (categoryIds.isEmpty) {
      categoryIds = ref.read(categoriesProvider).categories.map((c) => c.id).toList();
    }

    // Start game session
    ref.read(gameProvider.notifier).startSession(
      players: players,
      mode: gameMode ?? GameMode.teen,
      turnMode: turnMode,
      categoryIds: categoryIds,
      ageGroup: gameMode?.ageGroup ?? AgeGroup.teen,
      language: settings.language,
      timerSeconds: settings.defaultTimerSeconds,
      adultConsentGiven: gameMode == GameMode.adults,
    );

    // Navigate based on turn mode
    if (turnMode == TurnMode.spinBottle) {
      context.go(AppRoutes.spinBottle);
    } else {
      context.go(AppRoutes.question);
    }
  }
}
