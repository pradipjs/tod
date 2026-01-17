import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app.dart';
import 'core/di/service_locator.dart';
import 'data/local_db/hive_boxes.dart';

/// Application entry point.
/// 
/// Initializes all required services and dependencies before
/// launching the Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Hive boxes
  await HiveBoxes.initialize();
  
  // Initialize service locator for dependency injection
  await ServiceLocator.initialize();
  
  runApp(
    const ProviderScope(
      child: TruthOrDareApp(),
    ),
  );
}
