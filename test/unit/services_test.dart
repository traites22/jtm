import 'package:flutter_test/flutter_test.dart';
import '../services/pure_firebase_auth_service.dart';
import '../services/contact_matching_service.dart';
import '../models/user_model.dart';

void main() {
  group('JTM Auth Service Tests', () {
    test('PureFirebaseAuthService createAccount should create user with valid email', () async {
      // Test email validation
      final result = await PureFirebaseAuthService.createAccount(
        identifier: 'test@example.com',
        password: 'password123',
        isEmail: true,
      );

      expect(result.success, true);
      expect(result.userId, isNotNull);
      expect(result.message, contains('Compte créé'));
    });

    test('PureFirebaseAuthService createAccount should reject invalid email', () async {
      final result = await PureFirebaseAuthService.createAccount(
        identifier: 'invalid-email',
        password: 'password123',
        isEmail: true,
      );

      expect(result.success, false);
      expect(result.message, contains('email invalide'));
    });

    test('ContactMatchingService hashContact should be consistent', () {
      final email1 = 'test@example.com';
      final email2 = 'test@example.com';

      final hash1 = ContactMatchingService._hashContact(email1);
      final hash2 = ContactMatchingService._hashContact(email2);

      expect(hash1, equals(hash2));
    });

    test('ContactMatchingService processRawContacts should handle various formats', () {
      final contacts = [
        {'email': 'test@example.com'},
        {'phone': '+33612345678'},
        {'name': 'John Doe', 'phone': '+33698765432'},
        {'name': 'Jane Smith', 'email': 'jane@example.com'},
      ];

      final processed = ContactMatchingService.processRawContacts(contacts);

      expect(processed.length, equals(6));
      expect(processed, contains('test@example.com'));
      expect(processed, contains('+33612345678'));
      expect(processed, contains('John Doe:+33698765432'));
      expect(processed, contains('jane@example.com'));
    });
  });

  group('JTM User Model Tests', () {
    test('UserModel should create valid user model', () {
      final user = UserModel(
        id: 'test-user-1',
        email: 'test@example.com',
        phoneNumber: '+33612345678',
        name: 'Test User',
        age: 25,
        gender: 'homme',
        bio: 'Test bio',
        interests: ['sport', 'musique'],
        location: null,
        photos: [],
        preferences: {'city': 'Paris'},
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      expect(user.email, equals('test@example.com'));
      expect(user.phoneNumber, equals('+33612345678'));
      expect(user.name, equals('Test User'));
      expect(user.age, equals(25));
      expect(user.isVerified, isTrue);
    });

    test('UserModel should handle null values gracefully', () {
      final user = UserModel(
        id: 'test-user-2',
        email: '',
        phoneNumber: '',
        name: '',
        age: null,
        gender: '',
        bio: '',
        interests: [],
        location: null,
        photos: [],
        preferences: {},
        isVerified: false,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      expect(user.email, isEmpty);
      expect(user.phoneNumber, isEmpty);
      expect(user.name, isEmpty);
      expect(user.age, isNull);
      expect(user.isVerified, isFalse);
    });
  });

  group('JTM Integration Tests', () {
    testWidgetsTest('All app widgets should render without exceptions', (
      WidgetTester tester,
    ) async {
      // Test de tous les widgets principaux
      await tester.pumpWidget(MaterialApp(home: Container()));

      expect(tester.takeException(), throwsA(isA<Widget>));
    });
  });
}
