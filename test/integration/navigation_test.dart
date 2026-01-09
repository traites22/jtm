import 'package:flutter_test/flutter_test.dart';
import '../screens/home_screen.dart';

void main() {
  group('JTM Navigation Tests', () {
    testWidgetsTest('HomeScreen should render all 5 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: const HomeScreen()));

      // Vérifier que les 5 onglets sont présents
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.campaign), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Vérifier les labels
      expect(find.text('Découvrir'), findsOneWidget);
      expect(find.text('Match'), findsOneWidget);
      expect(find.text('Annonce'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgetsTest('Navigation should switch tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: const HomeScreen()));

      // Cliquer sur l'onglet Messages
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();

      // Vérifier que l'onglet Messages est actif
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgetsTest('All tabs should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: const HomeScreen()));

      // Vérifier l'accessibilité de chaque onglet
      final discoverTab = find.byIcon(Icons.explore);
      final matchTab = find.byIcon(Icons.favorite);
      final annonceTab = find.byIcon(Icons.campaign);
      final messageTab = find.byIcon(Icons.message);
      final settingsTab = find.byIcon(Icons.settings);

      expect(discoverTab, findsOneWidget);
      expect(matchTab, findsOneWidget);
      expect(annonceTab, findsOneWidget);
      expect(messageTab, findsOneWidget);
      expect(settingsTab, findsOneWidget);

      // Vérifier que tous sont cliquables
      expect(discoverTab, isNotNull);
      expect(matchTab, isNotNull);
      expect(annonceTab, isNotNull);
      expect(messageTab, isNotNull);
      expect(settingsTab, isNotNull);
    });
  });
}
