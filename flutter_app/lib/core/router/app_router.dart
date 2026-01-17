import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/player_setup/player_setup_screen.dart';
import '../../features/game_mode_select/game_mode_screen.dart';
import '../../features/category_select/category_select_screen.dart';
import '../../features/spin_bottle/spin_bottle_screen.dart';
import '../../features/question/question_screen.dart';
import '../../features/scoreboard/scoreboard_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/how_to_play/how_to_play_screen.dart';
import '../../features/add_truth_dare/add_truth_dare_screen.dart';

/// Route names for navigation.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String gameMode = '/game-mode';
  static const String playerSetup = '/player-setup';
  static const String categorySelect = '/category-select';
  static const String spinBottle = '/spin-bottle';
  static const String question = '/question';
  static const String scoreboard = '/scoreboard';
  static const String results = '/results';
  static const String settings = '/settings';
  static const String howToPlay = '/how-to-play';
  static const String addTruthDare = '/add-truth-dare';
}

/// Router configuration provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.gameMode,
        name: 'gameMode',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GameModeScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.playerSetup,
        name: 'playerSetup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlayerSetupScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.categorySelect,
        name: 'categorySelect',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CategorySelectScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.spinBottle,
        name: 'spinBottle',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SpinBottleScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.question,
        name: 'question',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const QuestionScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.scoreboard,
        name: 'scoreboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ScoreboardScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.results,
        name: 'results',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ResultsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.howToPlay,
        name: 'howToPlay',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HowToPlayScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.addTruthDare,
        name: 'addTruthDare',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddTruthDareScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
    ],
  );
});

// Transition animations

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
    child: child,
  );
}
