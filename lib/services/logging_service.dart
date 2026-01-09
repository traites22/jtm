import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebasePerformance _performance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;
      _isInitialized = true;
      logEvent('logging_service_initialized');
    } catch (e, stackTrace) {
      logError('Failed to initialize logging service', error: e, stackTrace: stackTrace);
    }
  }

  bool get isInitialized => _isInitialized;

  bool get isCrashlyticsEnabled => dotenv.env['ENABLE_CRASHLYTICS'] == 'true';
  bool get isAnalyticsEnabled => dotenv.env['ENABLE_ANALYTICS'] == 'true';
  bool get isPerformanceMonitoringEnabled => dotenv.env['ENABLE_PERFORMANCE_MONITORING'] == 'true';

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
      _crashlytics.recordError(
        error ?? Exception(message),
        fatal: false,
        information: [DiagnosticsProperty('message', message)],
        stackTrace: stackTrace,
      );
    } catch (e) {
      // Fallback si Crashlytics échoue
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

  Future<void> logPerformanceMetric(String metricName, int value) async {
    if (!_isInitialized) return;

    try {
      final trace = _performance.newTrace(metricName);
      await trace.start();
      trace.putMetric(metricName, value);
      await trace.stop();
    } catch (e) {
      logError('Failed to log performance metric: $metricName', error: e);
    }
  }

  void logInfo(String message) {
    debugPrint('INFO: $message');
  }

  void logWarning(String message) {
    debugPrint('WARNING: $message');
  }

  void setUserIdentifier(String userId) {
    if (isCrashlyticsEnabled) {
      _crashlytics.setUserIdentifier(userId);
    }
    if (isAnalyticsEnabled) {
      _analytics.setUserId(id: userId);
    }
  }

  void setUserProperty(String name, String value) {
    if (isAnalyticsEnabled) {
      _analytics.setUserProperty(name: name, value: value);
    }
  }

  Trace startTrace(String name) {
    if (isPerformanceMonitoringEnabled) {
      return _performance.newTrace(name);
    }
    return NoOpTrace();
  }

  void logScreenView(String screenName, {String? screenClass}) {
    if (isAnalyticsEnabled) {
      _analytics.logScreenView(screenName: screenName, screenClassOverride: screenClass);
    }
  }

  void logLogin(String loginMethod) {
    if (isAnalyticsEnabled) {
      _analytics.logLogin(loginMethod: loginMethod);
    }
  }

  void logSignUp(String signUpMethod) {
    if (isAnalyticsEnabled) {
      _analytics.logSignUp(signUpMethod: signUpMethod);
    }
  }

  void logMatch(String userId, String matchedUserId) {
    logEvent(
      'match',
      parameters: {
        'user_id': userId,
        'matched_user_id': matchedUserId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void logMessage(String matchId, String messageType) {
    logEvent(
      'message_sent',
      parameters: {
        'match_id': matchId,
        'message_type': messageType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void logProfileUpdate(String field) {
    logEvent(
      'profile_update',
      parameters: {'field': field, 'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  void logSearch(String type, Map<String, dynamic> filters) {
    logEvent(
      'search',
      parameters: {
        'search_type': type,
        'filters': filters.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void setCustomKey(String key, String value) {
    if (isCrashlyticsEnabled) {
      _crashlytics.setCustomKey(key, value);
    }
  }
}

class NoOpTrace implements Trace {
  @override
  Future<void> stop() async {}

  @override
  void incrementMetric(String name, {int value = 1}) {}

  @override
  void setMetric(String name, int value) {}

  @override
  void putAttribute(String name, String value) {}

  @override
  String? getAttribute(String name) => null;

  @override
  Map<String, String> getAttributes() => {};

  @override
  void removeAttribute(String name) {}

  @override
  TraceHandle getHandle() => throw UnimplementedError();
}
