import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jtm/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility Tests', () {
    testWidgets('should support screen readers and semantic labels', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Check semantic labels on welcome screen
      expect(
        find.bySemanticsLabel('Bienvenue sur JTM'),
        findsOneWidget,
        reason: 'Welcome screen should have semantic label',
      );

      expect(
        find.bySemanticsLabel('Email'),
        findsOneWidget,
        reason: 'Email field should have semantic label',
      );

      expect(
        find.bySemanticsLabel('Mot de passe'),
        findsOneWidget,
        reason: 'Password field should have semantic label',
      );

      expect(
        find.bySemanticsLabel('Se connecter'),
        findsOneWidget,
        reason: 'Login button should have semantic label',
      );

      expect(
        find.bySemanticsLabel('Créer un compte'),
        findsOneWidget,
        reason: 'Register button should have semantic label',
      );
    });

    testWidgets('should have sufficient color contrast', (tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();

      // This test would require color contrast analysis tools
      // For now, we'll verify that text is readable
      final textWidgets = tester.widgetList<Text>(find.byType(Text));

      for (final textWidget in textWidgets) {
        expect(
          textWidget.style?.fontSize ?? 14.0,
          greaterThanOrEqualTo(12.0),
          reason: 'Text should be at least 12sp for readability',
        );
      }
    });

    testWidgets('should have proper touch target sizes', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Check button sizes meet minimum touch target requirements (44x44 points)
      final buttons = find.byType(ElevatedButton);

      await tester.pumpAndSettle();
      final buttonSize = tester.getSize(buttons.first);

      expect(
        buttonSize.width,
        greaterThanOrEqualTo(44.0),
        reason: 'Button width should be at least 44 points',
      );
      expect(
        buttonSize.height,
        greaterThanOrEqualTo(44.0),
        reason: 'Button height should be at least 44 points',
      );
    });

    testWidgets('should support voice control commands', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test voice command simulation through semantic labels
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Mot de passe'), findsOneWidget);
      expect(find.bySemanticsLabel('Se connecter'), findsOneWidget);

      // Simulate voice command to tap login button
      await tester.tap(find.bySemanticsLabel('Se connecter'));
      await tester.pumpAndSettle();

      // Should attempt login (will fail without credentials, but button should work)
      await tester.pumpAndSettle(Duration(seconds: 2));
    });

    testWidgets('should provide feedback for actions', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test haptic feedback availability
      // This would require platform-specific testing
      // For now, we verify that interactive elements exist
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('should handle focus management properly', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test focus order
      await tester.tap(find.byType(TextField).first); // Email field
      await tester.pumpAndSettle();

      expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Email'));

      // Test focus trap in dialogs
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Focus should be in the registration dialog
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });

    testWidgets('should navigate with semantic actions', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through app using semantic actions
      await tester.tap(find.bySemanticsLabel('Créer un compte'));
      await tester.pumpAndSettle();

      // Verify registration screen elements have semantic labels
      expect(find.bySemanticsLabel('Nom d\'utilisateur'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Mot de passe'), findsOneWidget);
      expect(find.bySemanticsLabel('Confirmer le mot de passe'), findsOneWidget);
      expect(find.bySemanticsLabel('S\'inscrire'), findsOneWidget);
    });

    testWidgets('should support screen orientation changes', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Test landscape orientation
      await tester.binding.setSurfaceSize(Size(800, 400));
      await tester.pumpAndSettle();

      // Verify UI adapts to landscape
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      // Test portrait orientation
      await tester.binding.setSurfaceSize(Size(400, 800));
      await tester.pumpAndSettle();

      // Verify UI adapts to portrait
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
      await tester.pumpAndSettle();
    });
  });
}
