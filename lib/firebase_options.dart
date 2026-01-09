// Generated manually from provided google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
    appId: '1:401147120494:android:6ab47f840302b796a10f7f',
    messagingSenderId: '401147120494',
    projectId: 'jtm-dev',
    storageBucket: 'jtm-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
    appId: '1:401147120494:ios:xxxxxxxx',
    messagingSenderId: '401147120494',
    projectId: 'jtm-dev',
    storageBucket: 'jtm-dev.firebasestorage.app',
    iosBundleId: 'com.example.jtm',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
    appId: '1:401147120494:web:xxxxxxxx',
    messagingSenderId: '401147120494',
    projectId: 'jtm-dev',
    storageBucket: 'jtm-dev.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
    appId: '1:401147120494:macos:xxxxxxxx',
    messagingSenderId: '401147120494',
    projectId: 'jtm-dev',
    storageBucket: 'jtm-dev.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static FirebaseOptions getPlatformOptions(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
        return const FirebaseOptions(
          apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
          appId: '1:401147120494:android:6ab47f840302b796a10f7f',
          messagingSenderId: '401147120494',
          projectId: 'jtm-dev',
          storageBucket: 'jtm-dev.firebasestorage.app',
        );
      case 'production':
        return FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '1:401147120494:android:6ab47f840302b796a10f7f',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '401147120494',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        );
      default:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCT7eNY-OGfPJzjkjkENZDh891LffIZ8t0',
          appId: '1:401147120494:android:6ab47f840302b796a10f7f',
          messagingSenderId: '401147120494',
          projectId: 'jtm-dev',
          storageBucket: 'jtm-dev.firebasestorage.app',
        );
    }
  }
}
