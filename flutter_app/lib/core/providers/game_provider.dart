import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/sync_service.dart';
import '../constants/enums.dart';
import '../di/service_locator.dart';
import '../utils/logger.dart';

/// Provider for session repository.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return ServiceLocator.instance.sessionRepository;
});

/// Provider for task repository.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ServiceLocator.instance.taskRepository;
});

/// Provider for sync service.
final syncServiceProvider = Provider<SyncService>((ref) {
  return ServiceLocator.instance.syncService;
});

/// Result of task availability check.
class TaskAvailabilityResult {
  final int truthCount;
  final int dareCount;
  final int total;
  final bool hasEnough;
  final bool syncRequired;
  final String? message;

  const TaskAvailabilityResult({
    required this.truthCount,
    required this.dareCount,
    required this.total,
    required this.hasEnough,
    this.syncRequired = false,
    this.message,
  });
}

/// State for the game.
class GameState {
  final GameSession? session;
  final Task? currentTask;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final int timerSeconds;
  final TimerState timerState;
  final TaskAvailabilityResult? availability;

  const GameState({
    this.session,
    this.currentTask,
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.timerSeconds = 60,
    this.timerState = TimerState.idle,
    this.availability,
  });

  GameState copyWith({
    GameSession? session,
    Task? currentTask,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    int? timerSeconds,
    TimerState? timerState,
    TaskAvailabilityResult? availability,
  }) {
    return GameState(
      session: session ?? this.session,
      currentTask: currentTask ?? this.currentTask,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerState: timerState ?? this.timerState,
      availability: availability ?? this.availability,
    );
  }
}

/// Notifier for managing game state.
class GameNotifier extends StateNotifier<GameState> {
  static const _tag = 'GameNotifier';
  final SessionRepository _sessionRepository;
  final TaskRepository _taskRepository;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  GameNotifier(this._sessionRepository, this._taskRepository, this._syncService)
      : super(const GameState()) {
    // Load any existing session
    _loadExistingSession();
  }

  void _loadExistingSession() {
    final session = _sessionRepository.getCurrentSession();
    if (session != null && session.isOngoing) {
      state = state.copyWith(session: session);
    }
  }

  /// Checks task availability for the selected game presets.
  /// This should be called when user clicks the play button.
  /// 
  /// Returns true if enough tasks are available, false otherwise.
  /// If tasks are not available, it will attempt to sync from backend.
  Future<TaskAvailabilityResult> checkAndPrepareTasksForGame({
    required List<String> categoryIds,
    required AgeGroup ageGroup,
    required String language,
    int minimumTaskCount = 5,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // First check local availability
      final localTruthCount = await _taskRepository.countLocalTasks(
        categoryIds: categoryIds,
        ageGroup: ageGroup.value,
        language: language,
        type: TaskType.truth,
      );

      final localDareCount = await _taskRepository.countLocalTasks(
        categoryIds: categoryIds,
        ageGroup: ageGroup.value,
        language: language,
        type: TaskType.dare,
      );

      final localTotal = localTruthCount + localDareCount;
      final localHasEnough = localTruthCount >= minimumTaskCount && 
                            localDareCount >= minimumTaskCount;

      // If local has enough, we're good
      if (localHasEnough) {
        final result = TaskAvailabilityResult(
          truthCount: localTruthCount,
          dareCount: localDareCount,
          total: localTotal,
          hasEnough: true,
          syncRequired: false,
          message: 'Ready to play!',
        );
        state = state.copyWith(isLoading: false, availability: result);
        return result;
      }

      // Not enough local tasks, need to sync from backend
      state = state.copyWith(isSyncing: true);

      final syncSuccess = await _syncService.syncForGamePresets(
        ageGroups: [ageGroup.value],
        languages: [language],
        categoryIds: categoryIds,
      );

      // Re-check availability after sync
      final newTruthCount = await _taskRepository.countLocalTasks(
        categoryIds: categoryIds,
        ageGroup: ageGroup.value,
        language: language,
        type: TaskType.truth,
      );

      final newDareCount = await _taskRepository.countLocalTasks(
        categoryIds: categoryIds,
        ageGroup: ageGroup.value,
        language: language,
        type: TaskType.dare,
      );

      final newTotal = newTruthCount + newDareCount;
      final newHasEnough = newTruthCount >= minimumTaskCount && 
                          newDareCount >= minimumTaskCount;

      String? message;
      if (!syncSuccess) {
        message = 'Failed to sync tasks. Using cached data.';
      } else if (!newHasEnough) {
        message = 'Not enough tasks available for selected options.';
      } else {
        message = 'Tasks synced successfully!';
      }

      final result = TaskAvailabilityResult(
        truthCount: newTruthCount,
        dareCount: newDareCount,
        total: newTotal,
        hasEnough: newHasEnough,
        syncRequired: true,
        message: message,
      );

      state = state.copyWith(
        isLoading: false, 
        isSyncing: false, 
        availability: result,
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking task availability', tag: _tag, error: e, stackTrace: stackTrace);
      final result = TaskAvailabilityResult(
        truthCount: 0,
        dareCount: 0,
        total: 0,
        hasEnough: false,
        syncRequired: true,
        message: 'Error checking tasks: ${e.toString()}',
      );
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        error: e.toString(),
        availability: result,
      );
      return result;
    }
  }

  /// Starts a new game session after verifying task availability.
  Future<bool> startSession({
    required List<Player> players,
    required GameMode mode,
    required TurnMode turnMode,
    required List<String> categoryIds,
    required AgeGroup ageGroup,
    required String language,
    int timerSeconds = 60,
    bool adultConsentGiven = false,
  }) async {
    // Check task availability first
    final availability = await checkAndPrepareTasksForGame(
      categoryIds: categoryIds,
      ageGroup: ageGroup,
      language: language,
    );

    if (!availability.hasEnough) {
      state = state.copyWith(
        error: availability.message ?? 'Not enough tasks available',
      );
      return false;
    }

    final session = GameSession(
      id: _uuid.v4(),
      mode: mode.value,
      turnMode: turnMode.value,
      categoryIds: categoryIds,
      timerSeconds: timerSeconds,
      players: players,
      startedAt: DateTime.now(),
      adultConsentGiven: adultConsentGiven,
      ageGroup: ageGroup.value,
      language: language,
    );

    await _sessionRepository.saveCurrentSession(session);
    state = state.copyWith(
      session: session,
      timerSeconds: timerSeconds,
      timerState: TimerState.idle,
      error: null,
    );
    return true;
  }

  /// Gets the next task for the current player.
  Future<void> getNextTask(TaskType type) async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final task = await _taskRepository.getRandomTask(
        categoryIds: session.categoryIds.isEmpty ? null : session.categoryIds,
        ageGroup: session.ageGroup,
        language: session.language,
        type: type,
        usedTaskIds: session.usedTaskIds,
      );

      if (task != null) {
        // Mark task as used
        final updatedSession = session.markTaskUsed(task.id);
        await _sessionRepository.saveCurrentSession(updatedSession);

        state = state.copyWith(
          session: updatedSession,
          currentTask: task,
          isLoading: false,
          timerSeconds: session.timerSeconds,
          timerState: TimerState.idle,
        );
      } else {
        AppLogger.warning('No tasks available for current filters', tag: _tag);
        state = state.copyWith(
          isLoading: false,
          error: 'No tasks available',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get next task', tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Records task completion.
  Future<void> completeTask() async {
    final session = state.session;
    final task = state.currentTask;
    if (session == null || task == null) return;

    final currentPlayer = session.currentPlayer;
    final updatedPlayer = currentPlayer.recordCompletion(
      isTruth: task.isTruth,
    );

    final updatedSession = session
        .updatePlayer(updatedPlayer)
        .nextPlayer();

    await _sessionRepository.saveCurrentSession(updatedSession);
    state = state.copyWith(
      session: updatedSession,
      currentTask: null,
      timerState: TimerState.completed,
    );
  }

  /// Records task forfeit.
  Future<void> forfeitTask() async {
    final session = state.session;
    if (session == null) return;

    final currentPlayer = session.currentPlayer;
    final updatedPlayer = currentPlayer.recordForfeit();

    final updatedSession = session
        .updatePlayer(updatedPlayer)
        .nextPlayer();

    await _sessionRepository.saveCurrentSession(updatedSession);
    state = state.copyWith(
      session: updatedSession,
      currentTask: null,
      timerState: TimerState.forfeited,
    );
  }

  /// Moves to next player (for spin the bottle).
  Future<void> selectPlayer(int playerIndex) async {
    final session = state.session;
    if (session == null) return;

    final updatedSession = session.copyWith(currentPlayerIndex: playerIndex);
    await _sessionRepository.saveCurrentSession(updatedSession);
    state = state.copyWith(session: updatedSession);
  }

  /// Gets a random player index (for random turn mode).
  int getRandomPlayerIndex() {
    final session = state.session;
    if (session == null) return 0;
    return _random.nextInt(session.players.length);
  }

  /// Updates timer state.
  void updateTimerState(TimerState timerState) {
    state = state.copyWith(timerState: timerState);
  }

  /// Updates timer seconds.
  void updateTimerSeconds(int seconds) {
    state = state.copyWith(timerSeconds: seconds);
  }

  /// Ends the current session.
  Future<void> endSession() async {
    final session = state.session;
    if (session == null) return;

    final endedSession = session.endSession();
    await _sessionRepository.addToHistory(endedSession);
    await _sessionRepository.clearCurrentSession();

    state = const GameState();
  }

  /// Alias for endSession (for compatibility).
  Future<void> endGame() => endSession();

  /// Restarts the game by clearing current session.
  Future<void> restartGame() async {
    await _sessionRepository.clearCurrentSession();
    state = const GameState();
  }

  /// Clears current task without affecting session.
  void clearCurrentTask() {
    state = state.copyWith(currentTask: null);
  }
}

/// Provider for game state.
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final syncService = ref.watch(syncServiceProvider);
  return GameNotifier(sessionRepo, taskRepo, syncService);
});

/// Provider for current player.
final currentPlayerProvider = Provider<Player?>((ref) {
  final gameState = ref.watch(gameProvider);
  return gameState.session?.currentPlayer;
});

/// Provider for leaderboard.
final leaderboardProvider = Provider<List<Player>>((ref) {
  final gameState = ref.watch(gameProvider);
  return gameState.session?.leaderboard ?? [];
});
