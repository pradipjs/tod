import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';
import 'providers/languages_provider.dart';
import 'providers/sync_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';

/// Root application widget.
/// 
/// Configures theme, localization, and routing for the entire app.
class TruthOrDareApp extends ConsumerStatefulWidget {
  const TruthOrDareApp({super.key});

  @override
  ConsumerState<TruthOrDareApp> createState() => _TruthOrDareAppState();
}

class _TruthOrDareAppState extends ConsumerState<TruthOrDareApp> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Trigger background sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performBackgroundSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trigger sync when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _performBackgroundSync();
    }
  }

  void _performBackgroundSync() async {
    // Run sync in background
    await ref.read(syncStateProvider.notifier).performSyncIfNeeded();
    
    // Reload languages from cache after sync completes
    ref.read(languagesProvider.notifier).reloadFromCache();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Truth or Dare',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme(settings.themeColor),
      darkTheme: AppTheme.darkTheme(settings.themeColor),
      themeMode: settings.themeMode,
      
      // Localization configuration
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Router configuration
      routerConfig: router,
    );
  }
}
