// Options Firebase pour tester avec un projet de démonstration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptionsTest {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgBHX9lKNYqDzL9a2kH8xL3mN4oP5qR6s',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'test-demo-project',
    storageBucket: 'test-demo-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgBHX9lKNYqDzL9a2kH8xL3mN4oP5qR6s',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'test-demo-project',
    storageBucket: 'test-demo-project.appspot.com',
  );

  static FirebaseOptions getPlatformOptions(String environment) {
    return android;
  }
}
