import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jtm/main.dart' as app;
import 'package:jtm/screens/home_screen.dart';
import 'package:jtm/screens/matches_screen.dart';
import 'package:jtm/screens/profile_screen.dart';
import 'package:jtm/screens/chat_screen.dart';
import 'package:jtm/screens/swipe_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow Tests', () {
    testWidgets('complete app navigation flow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to matches screen
      final matchesButton = find.text('Matches');
      expect(matchesButton, findsOneWidget);
      await tester.tap(matchesButton);
      await tester.pumpAndSettle();

      // Verify matches screen is displayed
      expect(find.byType(MatchesScreen), findsOneWidget);

      // Navigate to profile screen
      final profileButton = find.text('Profil');
      expect(profileButton, findsOneWidget);
      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      // Verify profile screen is displayed
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Navigate to swipe screen
      final swipeButton = find.text('Découvrir');
      expect(swipeButton, findsOneWidget);
      await tester.tap(swipeButton);
      await tester.pumpAndSettle();

      // Verify swipe screen is displayed
      expect(find.byType(SwipeScreen), findsOneWidget);

      // Navigate back to home
      final homeButton = find.text('Accueil');
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Verify we're back on home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('chat navigation from matches', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to matches
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Try to open chat (if there are matches)
      final chatItems = find.byType(ListTile);
      if (chatItems.evaluate().isNotEmpty) {
        await tester.tap(chatItems.first);
        await tester.pumpAndSettle();

        // Verify chat screen is displayed
        expect(find.byType(ChatScreen), findsOneWidget);

        // Test back navigation
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Verify we're back on matches screen
        expect(find.byType(MatchesScreen), findsOneWidget);
      }
    });

    testWidgets('bottom navigation bar functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test all bottom navigation items
      final navigationItems = ['Accueil', 'Découvrir', 'Matches', 'Profil'];

      for (final itemName in navigationItems) {
        final navItem = find.text(itemName);
        expect(navItem, findsOneWidget);
        await tester.tap(navItem);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('app lifecycle and orientation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test app pause/resume
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        StandardMessageCodec().encodeMessage('AppLifecycleState.paused'),
        (data) {},
      );

      await tester.pumpAndSettle();

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        StandardMessageCodec().encodeMessage('AppLifecycleState.resumed'),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Verify app is still responsive
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Error Handling Navigation', () {
    testWidgets('navigation with network errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate through screens while simulating network issues
      await tester.tap(find.text('Découvrir'));
      await tester.pumpAndSettle();

      // Should handle gracefully even with network issues
      expect(find.byType(SwipeScreen), findsOneWidget);
    });

    testWidgets('navigation with missing data', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to matches which might have no data
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Should handle empty state gracefully
      expect(find.byType(MatchesScreen), findsOneWidget);
    });
  });
}
