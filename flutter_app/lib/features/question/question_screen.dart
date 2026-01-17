import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/haptics/haptics_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/game_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/game_background.dart';

/// Question display screen with timer.
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with TickerProviderStateMixin {
  TaskType? _selectedType;
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _timerRunning = false;
  // Used for tracking task fetch state (set in _selectType, reset in _navigateToNext)
  bool _taskFetched = false; // ignore: unused_field

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectType(TaskType type) {
    setState(() {
      _selectedType = type;
    });
    
    // Fetch task
    ref.read(gameProvider.notifier).getNextTask(type);
    _taskFetched = true;
    
    // Start timer
    final gameState = ref.read(gameProvider);
    _remainingSeconds = gameState.timerSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerRunning = true;
    ref.read(gameProvider.notifier).updateTimerState(TimerState.running);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerRunning) return;

      setState(() {
        _remainingSeconds--;
      });

      // Tick sound in last 10 seconds
      if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
        ref.read(soundServiceProvider).play(SoundEffect.timerTick);
      }

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _onTimeUp();
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _timerRunning = !_timerRunning;
    });
    
    ref.read(gameProvider.notifier).updateTimerState(
      _timerRunning ? TimerState.running : TimerState.paused,
    );
  }

  void _onTimeUp() {
    ref.read(soundServiceProvider).play(SoundEffect.forfeit);
    ref.read(hapticsServiceProvider).trigger(HapticType.error);
    _onForfeit();
  }

  void _onComplete() {
    _timer?.cancel();
    ref.read(soundServiceProvider).play(SoundEffect.success);
    ref.read(hapticsServiceProvider).trigger(HapticType.success);
    ref.read(gameProvider.notifier).completeTask();
    _navigateToNext();
  }

  void _onForfeit() {
    _timer?.cancel();
    ref.read(gameProvider.notifier).forfeitTask();
    _navigateToNext();
  }

  void _navigateToNext() {
    final gameState = ref.read(gameProvider);
    final turnMode = gameState.session?.turnModeEnum;

    setState(() {
      _selectedType = null;
      _taskFetched = false;
    });

    if (turnMode == TurnMode.spinBottle) {
      context.go(AppRoutes.spinBottle);
    } else {
      // Stay on this screen for next player
      _remainingSeconds = gameState.session?.timerSeconds ?? 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final currentPlayer = gameState.session?.currentPlayer;
    final currentTask = gameState.currentTask;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: currentPlayer != null 
            ? GradientText(
                text: currentPlayer.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        leading: NeonIconButton(
          icon: Icons.close_rounded,
          onPressed: () => _showExitConfirmation(context),
          color: AppColors.error,
          size: 44,
        ),
        actions: [
          NeonIconButton(
            icon: Icons.leaderboard_rounded,
            onPressed: () => context.push(AppRoutes.scoreboard),
            color: AppColors.gold,
            size: 44,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _selectedType == null
                ? _buildChoiceView(context, theme, currentPlayer)
                : _buildTaskView(context, theme, currentTask, settings.languageCode),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceView(
    BuildContext context,
    ThemeData theme,
    dynamic currentPlayer,
  ) {
    return Column(
      children: [
        // Player avatar with glow
        if (currentPlayer != null) ...[
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(currentPlayer.avatarColor).withValues(alpha: 0.4),
                      Color(currentPlayer.avatarColor).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Avatar container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(currentPlayer.avatarColor),
                      Color(currentPlayer.avatarColor).withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(currentPlayer.avatarColor).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    currentPlayer.avatar,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GradientText(
            text: currentPlayer.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        
        const Spacer(),
        
        Text(
          context.tr('chooseOption').toUpperCase(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Choice buttons with enhanced styling
        Row(
          children: [
            Expanded(
              child: ChoiceButton(
                text: context.tr('truth'),
                emoji: '🎯',
                gradientColors: AppColors.truthGradient,
                onPressed: () => _selectType(TaskType.truth),
                height: 160,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ChoiceButton(
                text: context.tr('dare'),
                emoji: '🔥',
                gradientColors: AppColors.dareGradient,
                onPressed: () => _selectType(TaskType.dare),
                height: 160,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Random button with gradient border
        SizedBox(
          width: double.infinity,
          child: GameButton(
            text: context.tr('random'),
            icon: Icons.shuffle_rounded,
            isOutlined: true,
            backgroundColor: AppColors.accent,
            onPressed: () {
              final random = DateTime.now().millisecond % 2 == 0
                  ? TaskType.truth
                  : TaskType.dare;
              _selectType(random);
            },
          ),
        ),
        
        const Spacer(),
      ],
    );
  }

  Widget _buildTaskView(
    BuildContext context,
    ThemeData theme,
    dynamic currentTask,
    String languageCode,
  ) {
    final isLoading = ref.watch(gameProvider).isLoading;

    return Column(
      children: [
        // Timer
        GestureDetector(
          onTap: _toggleTimer,
          child: ScaleTransition(
            scale: _remainingSeconds <= 10
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: _buildTimer(theme),
          ),
        ),
        
        const Spacer(),
        
        // Task type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _selectedType == TaskType.truth
                  ? AppColors.truthGradient
                  : AppColors.dareGradient,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            _selectedType == TaskType.truth
                ? context.tr('truth')
                : context.tr('dare'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Task text
        if (isLoading)
          const CircularProgressIndicator()
        else if (currentTask != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              currentTask.getText(languageCode),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Text(
            context.tr('noTasksAvailable'),
            style: theme.textTheme.bodyLarge,
          ),
        
        const Spacer(),
        
        // Action buttons
        if (currentTask != null) ...[
          Row(
            children: [
              Expanded(
                child: GameButton(
                  text: context.tr('forfeit'),
                  backgroundColor: theme.colorScheme.error,
                  onPressed: _onForfeit,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GameButton(
                  text: context.tr('done'),
                  backgroundColor: AppColors.success,
                  onPressed: _onComplete,
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildTimer(ThemeData theme) {
    final progress = _remainingSeconds / (ref.read(gameProvider).timerSeconds);
    final color = _remainingSeconds <= 10
        ? AppColors.error
        : AppColors.accent;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Progress ring
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        // Inner container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkCard,
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (!_timerRunning)
                Text(
                  context.tr('timerPaused'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Exit Game?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your progress will be saved.',
          style: TextStyle(color: Colors.white70),
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
            text: 'Exit',
            backgroundColor: AppColors.error,
            onPressed: () => Navigator.pop(context, true),
            height: 44,
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}
