import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Top-level background message handler. Must be a top-level function to be
/// registered with `FirebaseMessaging.onBackgroundMessage`.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Background init failed or already initialized
  }

  // Initialize a local notifications plugin in the background isolate
  final bgLocal = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await bgLocal.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

  // Ensure Android channel exists so notifications are visible
  final androidPlugin = bgLocal
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    const channel = AndroidNotificationChannel(
      'jtm',
      'JTM',
      description: 'Notifications',
      importance: Importance.max,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  final title = message.notification?.title ?? message.data['title'] ?? 'JTM';
  final body = message.notification?.body ?? message.data['body'] ?? 'Nouveau message';

  const androidDetails = AndroidNotificationDetails(
    'jtm',
    'JTM',
    importance: Importance.max,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  await bgLocal.show(message.hashCode & 0x7fffffff, title, body, details);

  // Try to persist last notification from the background isolate (best-effort)
  try {
    await Hive.initFlutter();
    final box = await Hive.openBox('settingsBox');
    await box.put('last_notification', {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
    });
    await box.close();
  } catch (e) {
    // Best-effort persistence failed in background; ignore silently
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Initialize Firebase with generated options if available
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // App may run without Firebase config; continue but FCM won't be available
    }

    // Local notifications initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Register background message handler (must be a top-level function)
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      // Ignore registration failure in environments without Firebase messaging
    }

    // Ensure Android notification channel exists and request runtime permission on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'jtm',
          'JTM',
          description: 'Notifications',
          importance: Importance.max,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      // Request runtime notification permission (Android 13+)
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        // permission result intentionally not printed
      }
    }

    // Request permissions for FCM (iOS)
    try {
      final fcm = FirebaseMessaging.instance;
      if (Platform.isIOS) {
        await fcm.requestPermission(alert: true, badge: true, sound: true);
      }

      // register handlers
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        // Message received

        final notification = msg.notification;
        if (notification != null) {
          final t = notification.title ?? 'JTM';
          final b = notification.body ?? '';
          try {
            final box = Hive.box('settingsBox');
            box.put('last_notification', {
              'title': t,
              'body': b,
              'time': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            // ignore persistence error
          }
          _show(t, b);
        } else if (msg.data.isNotEmpty) {
          // Fallback for data-only messages: try to extract title/body from data
          final title = msg.data['title'] ?? 'JTM';
          final body = msg.data['body'] ?? msg.data['message'] ?? msg.data.values.join(' ');
          try {
            final box = Hive.box('settingsBox');
            box.put('last_notification', {
              'title': title,
              'body': body,
              'time': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            // ignore persistence error
          }
          _show(title, body);
        } else {
          // Generic fallback to ensure user sees something
          final t = 'JTM';
          final b = 'Nouveau message reçu';
          try {
            final box = Hive.box('settingsBox');
            box.put('last_notification', {
              'title': t,
              'body': b,
              'time': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            // ignore persistence error
          }
          _show(t, b);
        }
      });

      final token = await fcm.getToken();
      if (token != null) {
        // store token locally so a backend (if any) can pick it up
        final box = Hive.box('settingsBox');
        box.put('fcm_token', token);
        // Token stored in Hive for debugging; not printed in logs
      }
    } catch (e) {
      // Ignore: running without Firebase configuration
    }

    _initialized = true;
  }

  /// Persist a last notification entry to Hive (public for testing and reuse)
  static Future<void> persistLastNotification(String title, String body) async {
    try {
      final box = Hive.box('settingsBox');
      await box.put('last_notification', {
        'title': title,
        'body': body,
        'time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // ignore persistence error
    }
  }

  static Future<void> _show(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'jtm',
      'JTM',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Persist last notification for UI display (best-effort)
    await persistLastNotification(title, body);

    await _local.show(0, title, body, details);
  }

  // Public helper to display notifications when a message is received locally
  static Future<void> showLocalNotification({required String title, required String body}) async {
    await _show(title, body);
  }
}
