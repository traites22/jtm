import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([MockFirebaseAuth])
void main() {
  group('Authentication Service Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
    });

    group('User Registration', () {
      test('should register user successfully with valid data', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'password123';
        final mockUser = MockUser(uid: 'test123', email: email);

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(email: email, password: password),
        ).thenAnswer((_) async => MockUserCredential(user: mockUser));

        // Act
        final result = await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.user?.email, equals(email));
        expect(result.user?.uid, equals('test123'));
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(email: email, password: password),
        ).called(1);
      });

      test('should throw error for weak password', () async {
        // Arrange
        final email = 'test@example.com';
        final weakPassword = '123';

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(email: email, password: weakPassword),
        ).thenThrow(FirebaseAuthException(code: 'weak-password', message: 'Password is too weak'));

        // Act & Assert
        expect(
          () =>
              mockFirebaseAuth.createUserWithEmailAndPassword(email: email, password: weakPassword),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('should throw error for invalid email format', () async {
        // Arrange
        final invalidEmail = 'invalid-email';
        final password = 'password123';

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(email: invalidEmail, password: password),
        ).thenThrow(
          FirebaseAuthException(code: 'invalid-email', message: 'Email format is invalid'),
        );

        // Act & Assert
        expect(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: invalidEmail,
            password: password,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('User Login', () {
      test('should login successfully with correct credentials', () async {
        // Arrange
        final email = 'test@example.com';
        final password = 'password123';
        final mockUser = MockUser(uid: 'test123', email: email);

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password),
        ).thenAnswer((_) async => MockUserCredential(user: mockUser));

        // Act
        final result = await mockFirebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.user?.email, equals(email));
        expect(result.user?.uid, equals('test123'));
      });

      test('should throw error for incorrect password', () async {
        // Arrange
        final email = 'test@example.com';
        final wrongPassword = 'wrongpassword';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: wrongPassword),
        ).thenThrow(
          FirebaseAuthException(code: 'wrong-password', message: 'Password is incorrect'),
        );

        // Act & Assert
        expect(
          () => mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: wrongPassword),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('should throw error for non-existent user', () async {
        // Arrange
        final email = 'nonexistent@example.com';
        final password = 'password123';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'User not found'));

        // Act & Assert
        expect(
          () => mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Password Reset', () {
      test('should send password reset email successfully', () async {
        // Arrange
        final email = 'test@example.com';

        when(mockFirebaseAuth.sendPasswordResetEmail(email: email)).thenAnswer((_) async {});

        // Act & Assert
        expect(() => mockFirebaseAuth.sendPasswordResetEmail(email: email), returnsNormally);
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
      });

      test('should throw error for invalid email in password reset', () async {
        // Arrange
        final invalidEmail = 'invalid-email';

        when(mockFirebaseAuth.sendPasswordResetEmail(email: invalidEmail)).thenThrow(
          FirebaseAuthException(code: 'invalid-email', message: 'Email format is invalid'),
        );

        // Act & Assert
        expect(
          () => mockFirebaseAuth.sendPasswordResetEmail(email: invalidEmail),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('User Session Management', () {
      test('should detect when user is logged in', () async {
        // Arrange
        final mockUser = MockUser(uid: 'test123', email: 'test@example.com');
        when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = mockFirebaseAuth.authStateChanges();

        // Assert
        await expectLater(stream, emits(mockUser));
      });

      test('should detect when user is logged out', () async {
        // Arrange
        when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        // Act
        final stream = mockFirebaseAuth.authStateChanges();

        // Assert
        await expectLater(stream, emits(null));
      });
    });

    group('Email Verification', () {
      test('should send email verification successfully', () async {
        // Arrange
        final mockUser = MockUser(uid: 'test123', email: 'test@example.com');

        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.sendEmailVerification()).thenAnswer((_) async {});

        // Act & Assert
        expect(() => mockUser.sendEmailVerification(), returnsNormally);
      });

      test('should handle email verification sending failure', () async {
        // Arrange
        final mockUser = MockUser(uid: 'test123', email: 'test@example.com');

        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(
          mockUser.sendEmailVerification(),
        ).thenThrow(FirebaseAuthException(code: 'too-many-requests', message: 'Too many requests'));

        // Act & Assert
        expect(() => mockUser.sendEmailVerification(), throwsA(isA<FirebaseAuthException>()));
      });
    });
  });
}
