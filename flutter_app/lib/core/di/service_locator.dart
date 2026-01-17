import '../../data/remote_api/api_client.dart';
import '../../data/remote_api/truth_or_dare_api.dart';
import '../../data/repositories/language_repository.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/background_sync_manager.dart';
import '../../data/services/sync_service.dart';

/// Service locator for dependency injection.
/// 
/// Provides singleton instances of services and repositories.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  // API clients
  late final ApiClient _apiClient;
  late final TruthOrDareApi _api;

  // Repositories
  late final CategoryRepository _categoryRepository;
  late final TaskRepository _taskRepository;
  late final SettingsRepository _settingsRepository;
  late final SessionRepository _sessionRepository;
  late final LanguageRepository _languageRepository;

  // Services
  late final SyncService _syncService;
  late final BackgroundSyncManager _backgroundSyncManager;

  /// Initializes all services.
  static Future<void> initialize() async {
    final locator = _instance;

    // Initialize API
    locator._apiClient = ApiClient();
    locator._api = TruthOrDareApi(locator._apiClient);

    // Initialize repositories
    locator._categoryRepository = CategoryRepository(locator._api);
    locator._taskRepository = TaskRepository(locator._api);
    locator._settingsRepository = SettingsRepository();
    locator._sessionRepository = SessionRepository();
    locator._languageRepository = LanguageRepository();

    // Initialize services
    locator._syncService = SyncService(
      locator._api,
      locator._categoryRepository,
      locator._taskRepository,
    );
    
    locator._backgroundSyncManager = BackgroundSyncManager(
      api: locator._api,
      categoryRepository: locator._categoryRepository,
      taskRepository: locator._taskRepository,
      languageRepository: locator._languageRepository,
    );
  }

  // Getters
  ApiClient get apiClient => _apiClient;
  TruthOrDareApi get api => _api;
  CategoryRepository get categoryRepository => _categoryRepository;
  TaskRepository get taskRepository => _taskRepository;
  SettingsRepository get settingsRepository => _settingsRepository;
  SessionRepository get sessionRepository => _sessionRepository;
  LanguageRepository get languageRepository => _languageRepository;
  SyncService get syncService => _syncService;
  BackgroundSyncManager get backgroundSyncManager => _backgroundSyncManager;
}
