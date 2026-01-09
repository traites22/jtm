import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart';
import 'package:jtm/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete User Journey E2E Tests', () {
    testWidgets('complete user registration and profile setup flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the welcome/login screen
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Créer un compte'), findsOneWidget);

      // Tap on create account
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.enterText(find.byKey(Key('confirm_password_field')), 'Password123!');
      await tester.enterText(find.byKey(Key('username_field')), 'testuser');

      // Tap register button
      await tester.tap(find.byKey(Key('register_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify email verification screen
      expect(find.text('Vérifiez votre email'), findsOneWidget);

      // Simulate email verification (in real test, this would involve email service)
      await tester.tap(find.byKey(Key('continue_button')));
      await tester.pumpAndSettle();

      // Profile setup screen
      expect(find.text('Complétez votre profil'), findsOneWidget);

      // Fill profile information
      await tester.enterText(find.byKey(Key('age_field')), '25');
      await tester.enterText(find.byKey(Key('bio_field')), 'Test user bio');

      // Select interests
      await tester.tap(find.byKey(Key('interest_sports')));
      await tester.tap(find.byKey(Key('interest_music')));
      await tester.tap(find.byKey(Key('interest_travel')));

      // Upload profile picture (simulated)
      await tester.tap(find.byKey(Key('upload_photo_button')));
      await tester.pumpAndSettle();

      // Select photo from gallery (simulated)
      await tester.tap(find.text('Galerie'));
      await tester.pumpAndSettle();

      // Save profile
      await tester.tap(find.byKey(Key('save_profile_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify we're on the main app screen
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Découvrir'), findsOneWidget);
    });

    testWidgets('complete matching and messaging flow', (tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();

      // Login with existing user
      await tester.enterText(find.byKey(Key('email_field')), 'existing@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to discover screen
      await tester.tap(find.text('Découvrir'));
      await tester.pumpAndSettle();

      // Verify we see potential matches
      expect(find.byType(Card), findsWidgets);

      // Swipe right on first profile (like)
      await tester.drag(find.byType(Card), Offset(300, 0));
      await tester.pumpAndSettle();

      // Check if it's a match (in real scenario, this would check backend)
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Navigate to matches screen
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Verify matches list
      expect(find.text('Vos matches'), findsOneWidget);

      // Tap on first match to open chat
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Verify chat screen
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Send a message
      await tester.enterText(find.byType(TextField), 'Hello! How are you?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message appears in chat
      expect(find.text('Hello! How are you?'), findsOneWidget);
    });

    testWidgets('settings and preferences flow', (tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(Key('email_field')), 'existing@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to profile/settings
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify settings screen
      expect(find.text('Paramètres'), findsOneWidget);

      // Test notification settings
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      // Toggle push notifications
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test privacy settings
      await tester.tap(find.text('Confidentialité'));
      await tester.pumpAndSettle();

      // Toggle profile visibility
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test account settings
      await tester.tap(find.text('Compte'));
      await tester.pumpAndSettle();

      // Change password
      await tester.tap(find.text('Changer le mot de passe'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('current_password')), 'Password123!');
      await tester.enterText(find.byKey(Key('new_password')), 'NewPassword123!');
      await tester.enterText(find.byKey(Key('confirm_new_password')), 'NewPassword123!');

      await tester.tap(find.text('Mettre à jour'));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify success message
      expect(find.text('Mot de passe mis à jour'), findsOneWidget);
    });

    testWidgets('offline mode and sync behavior', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enable offline mode (simulated)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        StringCodec().encodeMessage('none'),
        (data) {},
      );

      // Try to login offline
      await tester.enterText(find.byKey(Key('email_field')), 'existing@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should show offline message
      expect(find.text('Pas de connexion internet'), findsOneWidget);

      // Enable online mode
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        StringCodec().encodeMessage('wifi'),
        (data) {},
      );

      // Retry login
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should login successfully
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('error handling and recovery', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Try to login with invalid credentials
      await tester.enterText(find.byKey(Key('email_field')), 'invalid@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'wrongpassword');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should show error message
      expect(find.text('Email ou mot de passe incorrect'), findsOneWidget);

      // Clear and enter correct credentials
      await tester.tap(find.byKey(Key('clear_email')));
      await tester.tap(find.byKey(Key('clear_password')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('email_field')), 'valid@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Should login successfully
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test network error during message sending
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Simulate network loss
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        StringCodec().encodeMessage('none'),
        (data) {},
      );

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Should show offline message
      expect(find.text('Message sera envoyé lorsque la connexion sera rétablie'), findsOneWidget);

      // Restore connection
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/connectivity',
        StringCodec().encodeMessage('wifi'),
        (data) {},
      );

      // Message should send automatically
      await tester.pumpAndSettle(Duration(seconds: 2));
      expect(find.text('Test message'), findsOneWidget);
    });
  });
}
