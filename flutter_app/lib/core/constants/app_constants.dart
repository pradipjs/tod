/// Application-wide constants.
/// 
/// Contains all magic numbers and configuration values.
class AppConstants {
  AppConstants._();

  // Game rules
  static const int minPlayers = 2;
  static const int maxPlayers = 16;
  static const int defaultTimerSeconds = 60;
  static const int minTimerSeconds = 30;
  static const int maxTimerSeconds = 120;

  // Points
  static const int pointsForCompletion = 1;
  static const int pointsForForfeit = 0;
  static const int streakBonusThreshold = 3;
  static const int streakBonusPoints = 1;

  // Animation durations (milliseconds)
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int spinMinDuration = 2000;
  static const int spinMaxDuration = 5000;

  // Spin bottle physics
  static const double spinFriction = 0.98;
  static const double minAngularVelocity = 0.5;
  static const double maxAngularVelocity = 25.0;

  // API
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const int apiTimeoutSeconds = 30;

  // Storage keys
  static const String settingsBoxKey = 'settings';
  static const String playersBoxKey = 'players';
  static const String questionsBoxKey = 'questions';
  static const String categoriesBoxKey = 'categories';
  static const String sessionsBoxKey = 'sessions';

  // Default values
  static const String defaultLanguage = 'en';
  static const String defaultBottleSkin = 'classic';
}
