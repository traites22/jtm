import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _isInitialized = true;
      logInfo('Logging service initialized');
    } catch (e, stackTrace) {
      logError('Failed to initialize logging service', error: e, stackTrace: stackTrace);
    }
  }

  bool get isInitialized => _isInitialized;

  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_isInitialized) return;

    try {
      _analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      logError('Failed to log event: $eventName', error: e);
    }
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_isInitialized) return;

    try {
      final errorInfo = {
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'error': error?.toString(),
      };

      _crashlytics.recordError(
        error: error ?? Exception(message),
        fatal: false,
        information: [
          DiagnosticsProperty('error_message', message),
          DiagnosticsProperty('timestamp', DateTime.now().toIso8601String()),
          if (error != null) DiagnosticsProperty('error_details', error.toString()),
        ],
        stackTrace: stackTrace,
      );
    } catch (e) {
      debugPrint('Error logging failed: $message - $e');
    }
  }

  void logScreenView(String screenName) {
    if (!_isInitialized) return;

    try {
      _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      logError('Failed to log screen view: $screenName', error: e);
    }
  }

  void setUserProperty(String name, dynamic value) {
    if (!_isInitialized) return;

    try {
      _analytics.setUserProperty(name: name, value: value.toString());
    } catch (e) {
      logError('Failed to set user property: $name', error: e);
    }
  }

  void logInfo(String message) {
    debugPrint('INFO: $message');
  }

  void logWarning(String message) {
    debugPrint('WARNING: $message');
  }
}
