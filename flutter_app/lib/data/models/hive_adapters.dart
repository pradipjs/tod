/// Hive Type Adapters
/// 
/// Note: Currently, models are stored as JSON strings in Hive boxes.
/// Type adapters are defined here for potential future use with typed boxes.
/// 
/// Type IDs:
/// - 1: Category
/// - 2: Task
/// - 3: Player
/// - 4: GameSession
/// - 5: AppSettings

// Type IDs for Hive (reserved for future use)
class HiveTypeIds {
  static const int category = 1;
  static const int task = 2;
  static const int player = 3;
  static const int gameSession = 4;
  static const int appSettings = 5;
}

// Note: Type adapters are not currently used because we store
// data as JSON strings. If typed storage is needed in the future,
// run `flutter packages pub run build_runner build` to generate
// adapters from the @HiveType and @HiveField annotations on models.
