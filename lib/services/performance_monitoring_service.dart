import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_service.dart';

class PerformanceMonitoringService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Performance traces
  static Trace? _appStartupTrace;
  static Trace? _screenLoadTrace;
  static Trace? _networkTrace;
  static Trace? _databaseTrace;

  // Initialize performance monitoring
  static Future<void> initialize() async {
    try {
      // Enable performance monitoring
      await _performance.setPerformanceCollectionEnabled(true);

      // Enable crash reporting
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set user identifier
      final user = FirebaseService.instance.auth.currentUser;
      if (user != null) {
        await _crashlytics.setUserIdentifier(user.uid);
      }

      debugPrint('✅ Performance monitoring initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize performance monitoring: $e');
    }
  }

  // Start app startup trace
  static void startAppStartupTrace() {
    _appStartupTrace = _performance.newTrace('app_startup');
    _appStartupTrace?.start();
    debugPrint('📊 Started app startup trace');
  }

  // Stop app startup trace
  static void stopAppStartupTrace() {
    _appStartupTrace?.stop();
    _appStartupTrace = null;
    debugPrint('📊 Stopped app startup trace');
  }

  // Start screen load trace
  static void startScreenLoadTrace(String screenName) {
    _screenLoadTrace = _performance.newTrace('screen_load_${screenName.toLowerCase()}');
    _screenLoadTrace?.setMetric('screen_name', screenName);
    _screenLoadTrace?.start();
    debugPrint('📊 Started screen load trace: $screenName');
  }

  // Stop screen load trace
  static void stopScreenLoadTrace() {
    _screenLoadTrace?.stop();
    _screenLoadTrace = null;
    debugPrint('📊 Stopped screen load trace');
  }

  // Start network trace
  static void startNetworkTrace(String operation) {
    _networkTrace = _performance.newTrace('network_${operation.toLowerCase()}');
    _networkTrace?.start();
    debugPrint('📊 Started network trace: $operation');
  }

  // Stop network trace
  static void stopNetworkTrace() {
    _networkTrace?.stop();
    _networkTrace = null;
    debugPrint('📊 Stopped network trace');
  }

  // Start database trace
  static void startDatabaseTrace(String operation) {
    _databaseTrace = _performance.newTrace('database_${operation.toLowerCase()}');
    _databaseTrace?.start();
    debugPrint('📊 Started database trace: $operation');
  }

  // Stop database trace
  static void stopDatabaseTrace() {
    _databaseTrace?.stop();
    _databaseTrace = null;
    debugPrint('📊 Stopped database trace');
  }

  // Log custom metric
  static void logMetric(String name, int value) {
    _performance.newTrace('custom_metric').setMetric(name, value);
    debugPrint('📊 Logged metric: $name = $value');
  }

  // Log custom event
  static void logEvent(String eventName, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      debugPrint('📊 Logged event: $eventName');
    } catch (e) {
      debugPrint('❌ Failed to log event: $e');
    }
  }

  // Log user property
  static void setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 Set user property: $name = $value');
    } catch (e) {
      debugPrint('❌ Failed to set user property: $e');
    }
  }

  // Log error
  static void logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
    Map<String, dynamic>? extraInfo,
  }) async {
    try {
      // Log to Crashlytics
      await _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        information: [
          DiagnosticsProperty('context', context),
          DiagnosticsProperty('timestamp', DateTime.now().toIso8601String()),
          if (extraInfo != null)
            for (var entry in extraInfo.entries) DiagnosticsProperty(entry.key, entry.value),
        ],
      );

      // Log to analytics
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': exception.runtimeType.toString(),
          'context': context ?? 'unknown',
          'fatal': fatal,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('📊 Logged error: ${exception.runtimeType}');
    } catch (e) {
      debugPrint('❌ Failed to log error: $e');
    }
  }

  // Log performance metrics
  static void logPerformanceMetrics({
    int? appStartupTime,
    int? screenLoadTime,
    int? networkResponseTime,
    int? databaseQueryTime,
    int? memoryUsage,
    double? batteryLevel,
  }) {
    if (appStartupTime != null) {
      logMetric('app_startup_time_ms', appStartupTime);
    }
    if (screenLoadTime != null) {
      logMetric('screen_load_time_ms', screenLoadTime);
    }
    if (networkResponseTime != null) {
      logMetric('network_response_time_ms', networkResponseTime);
    }
    if (databaseQueryTime != null) {
      logMetric('database_query_time_ms', databaseQueryTime);
    }
    if (memoryUsage != null) {
      logMetric('memory_usage_mb', memoryUsage);
    }
    if (batteryLevel != null) {
      logMetric('battery_level_percent', (batteryLevel * 100).round());
    }
  }

  // Monitor app lifecycle
  static void monitorAppLifecycle() {
    // This would be called from main.dart or app lifecycle observer
    logEvent(
      'app_lifecycle',
      parameters: {'action': 'app_started', 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // Monitor user interactions
  static void logUserInteraction(
    String action, {
    String? screen,
    Map<String, dynamic>? parameters,
  }) {
    logEvent(
      'user_interaction',
      parameters: {
        'action': action,
        'screen': screen ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
  }

  // Monitor API calls
  static void logApiCall(String endpoint, {int? duration, int? statusCode, bool? success}) {
    logEvent(
      'api_call',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': duration ?? 0,
        'status_code': statusCode ?? 0,
        'success': success ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Monitor database operations
  static void logDatabaseOperation(
    String operation, {
    String? collection,
    int? duration,
    int? documentCount,
    bool? success,
  }) {
    logEvent(
      'database_operation',
      parameters: {
        'operation': operation,
        'collection': collection ?? 'unknown',
        'duration_ms': duration ?? 0,
        'document_count': documentCount ?? 0,
        'success': success ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Monitor authentication events
  static void logAuthEvent(String action, {String? method, bool? success, String? error}) {
    logEvent(
      'auth_event',
      parameters: {
        'action': action,
        'method': method ?? 'unknown',
        'success': success ?? false,
        'error': error ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Monitor notification events
  static void logNotificationEvent(String action, {String? type, bool? delivered, bool? opened}) {
    logEvent(
      'notification_event',
      parameters: {
        'action': action,
        'type': type ?? 'unknown',
        'delivered': delivered ?? false,
        'opened': opened ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Monitor location events
  static void logLocationEvent(
    String action, {
    double? latitude,
    double? longitude,
    double? accuracy,
    bool? success,
  }) {
    logEvent(
      'location_event',
      parameters: {
        'action': action,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'accuracy': accuracy ?? 0.0,
        'success': success ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Monitor feature usage
  static void logFeatureUsage(String feature, {String? action, Map<String, dynamic>? parameters}) {
    logEvent(
      'feature_usage',
      parameters: {
        'feature': feature,
        'action': action ?? 'used',
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
  }

  // Monitor performance benchmarks
  static void checkPerformanceBenchmarks() {
    // This would be called periodically to check if performance meets benchmarks
    logEvent('performance_check', parameters: {'timestamp': DateTime.now().toIso8601String()});
  }

  // Get performance summary
  static Future<Map<String, dynamic>> getPerformanceSummary() async {
    try {
      // This would fetch performance data from Firebase
      // For now, return a placeholder
      return {
        'app_startup_time': 2500, // ms
        'screen_load_time': 1500, // ms
        'network_response_time': 800, // ms
        'database_query_time': 300, // ms
        'memory_usage': 120, // MB
        'battery_level': 85, // %
        'error_rate': 0.5, // %
        'crash_rate': 0.1, // %
      };
    } catch (e) {
      debugPrint('❌ Failed to get performance summary: $e');
      return {};
    }
  }

  // Set performance alerts
  static void setPerformanceAlerts({
    int? maxAppStartupTime,
    int? maxScreenLoadTime,
    int? maxNetworkResponseTime,
    int? maxMemoryUsage,
    double? minBatteryLevel,
  }) {
    // This would configure performance alerts
    logEvent(
      'performance_alerts_configured',
      parameters: {
        'max_app_startup_time': maxAppStartupTime ?? 3000,
        'max_screen_load_time': maxScreenLoadTime ?? 2000,
        'max_network_response_time': maxNetworkResponseTime ?? 1000,
        'max_memory_usage': maxMemoryUsage ?? 200,
        'min_battery_level': minBatteryLevel ?? 20,
      },
    );
  }

  // Report performance issues
  static void reportPerformanceIssue(
    String issue, {
    String? severity,
    Map<String, dynamic>? details,
  }) {
    logEvent(
      'performance_issue',
      parameters: {
        'issue': issue,
        'severity': severity ?? 'medium',
        'timestamp': DateTime.now().toIso8601String(),
        ...?details,
      },
    );
  }
}
