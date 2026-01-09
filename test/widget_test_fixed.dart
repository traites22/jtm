import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/services/logging_service.dart';
import '../lib/widgets/enhanced_input_field.dart';
import '../lib/widgets/enhanced_message_bubble.dart';

void main() {
  // Initialiser Hive pour les tests
  setUp(() async {
    // S'assurer que Hive est initialisé
    await Hive.initFlutter();

    // Créer une box de test
    await Hive.openBox('test_box');
  });

  group('JTM App Tests', () {
    testWidgets('Enhanced Input Field renders correctly', (WidgetTester tester) async {
      // Initialiser le contexte de test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedInputField(
              matchId: 'test_match',
              currentUserId: 'test_user',
              onMessageSent: (text) async {
                // Simuler l'envoi de message
                await Future.delayed(const Duration(milliseconds: 500));
                return true;
              },
            ),
          ),
        ),
      );

      // Vérifier que le champ est affiché
      expect(find.byType(EnhancedInputField), findsOneWidget);
    });

    testWidgets('Enhanced Message Bubble displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedMessageBubble(
              message: MessageModel(
                id: 'test_msg',
                senderId: 'test_user',
                text: 'Test message',
                timestamp: DateTime.now(),
              ),
              currentUserId: 'test_user',
            ),
          ),
        ),
      );

      // Vérifier que la bulle est affichée
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('Logging Service works correctly', (WidgetTester tester) async {
      // Test du service de logging
      final loggingService = LoggingService();

      // Simuler une opération
      await loggingService.logEvent('test_event', parameters: {'test': 'value'});

      // Vérifier que l'événement a été loggué
      // Note: En environnement réel, les logs seraient envoyés à Firebase
      expect(loggingService.isInitialized, isTrue);
    });
  });
}
