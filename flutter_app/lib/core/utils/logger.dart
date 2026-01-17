import 'package:flutter/foundation.dart';

/// Simple logging utility for the app.
/// 
/// Only logs in debug mode to avoid exposing sensitive info in production.
class AppLogger {
  static const String _tag = 'TruthOrDare';

  /// Log an info message.
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  /// Log a warning message.
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ⚠️ $message');
      if (error != null) {
        debugPrint('[$_tag] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_tag] StackTrace: $stackTrace');
      }
    }
  }

  /// Log an error message.
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ❌ $message');
      if (error != null) {
        debugPrint('[$_tag] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_tag] StackTrace: $stackTrace');
      }
    }
  }

  /// Log a debug message (only in debug mode).
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] 🔍 $message');
    }
  }

  /// Log a success message.
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ✅ $message');
    }
  }
}
