import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/logging_service_minimal.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'main_app.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase with environment-specific options first
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      String environment = dotenv.env['ENVIRONMENT'] ?? 'development';
      await Firebase.initializeApp(options: DefaultFirebaseOptions.getPlatformOptions(environment));
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize logging service after Firebase
    await LoggingService().initialize();

    // Demander la permission pour les notifications
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // S'abonner aux topics si nécessaire
    await messaging.subscribeToTopic('matches');
    await messaging.subscribeToTopic('messages');
    await messaging.subscribeToTopic('invitations');

    LoggingService().logEvent(
      'app_initialized',
      parameters: {
        'environment': dotenv.env['ENVIRONMENT'] ?? 'development',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  } catch (e, stackTrace) {
    // Initialize logging service even if Firebase fails
    try {
      await LoggingService().initialize();
    } catch (_) {}
    LoggingService().logError('Firebase initialization failed', error: e, stackTrace: stackTrace);
  }

  // Initialize Hive
  try {
    await Hive.initFlutter();
    await Hive.openBox('profileBox');
    await Hive.openBox('likesBox');
    await Hive.openBox('matchesBox');
    await Hive.openBox('messagesBox');
    await Hive.openBox('requestsBox');
    await Hive.openBox('announcementsBox');
    await Hive.openBox('settingsBox');
    await Hive.openBox('usersBox');
    await Hive.openBox('pendingRegistrationsBox');
    await Hive.openBox('invitationsBox');
    await Hive.openBox('themeBox');
    LoggingService().logEvent('hive_initialized');
  } catch (e, stackTrace) {
    LoggingService().logError('Hive initialization failed', error: e, stackTrace: stackTrace);
  }

  // Initialize notifications
  try {
    await Future.delayed(const Duration(milliseconds: 50));
    await NotificationService.init();
    LoggingService().logEvent('notifications_initialized');
  } catch (e, stackTrace) {
    LoggingService().logError(
      'Notification service initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(const MainApp());
}
