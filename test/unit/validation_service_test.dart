import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validation Service Tests', () {
    group('Email Validation', () {
      test('should validate correct email formats', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          'user123@test-domain.com',
          'firstname.lastname@company.com',
        ];

        for (final email in validEmails) {
          expect(isValidEmail(email), isTrue, reason: '$email should be valid');
        }
      });

      test('should reject invalid email formats', () {
        final invalidEmails = [
          '',
          'invalid-email',
          '@domain.com',
          'user@',
          'user..name@domain.com',
          'user name@domain.com',
          'user@domain',
          'user@domain..com',
          'user@.domain.com',
          'user@domain.',
          'user..name@domain.com', // double dots
        ];

        for (final email in invalidEmails) {
          expect(isValidEmail(email), isFalse, reason: '$email should be invalid');
        }
      });
    });

    group('Password Validation', () {
      test('should validate strong passwords', () {
        final validPasswords = [
          'Password123!',
          'MySecureP@ssw0rd',
          'Str0ng#Pass',
          'ComplexP@ssw0rd2024',
        ];

        for (final password in validPasswords) {
          expect(isValidPassword(password), isTrue, reason: '$password should be valid');
        }
      });

      test('should reject weak passwords', () {
        final invalidPasswords = [
          '',
          '123',
          'password',
          'PASSWORD',
          '12345678',
          'abcdefgh',
          'Pass123',
          'Password',
          'password123',
        ];

        for (final password in invalidPasswords) {
          expect(isValidPassword(password), isFalse, reason: '$password should be invalid');
        }
      });

      test('should check password strength levels', () {
        expect(getPasswordStrength(''), equals(PasswordStrength.weak));
        expect(getPasswordStrength('123'), equals(PasswordStrength.weak));
        expect(getPasswordStrength('password'), equals(PasswordStrength.weak));
        expect(getPasswordStrength('Password123'), equals(PasswordStrength.medium));
        expect(getPasswordStrength('Password123!'), equals(PasswordStrength.strong));
      });
    });

    group('Username Validation', () {
      test('should validate correct usernames', () {
        final validUsernames = [
          'johndoe',
          'user123',
          'john_doe',
          'jane-doe',
          'testuser',
          'user123', // minimum length for 2+ chars
          'user123456789', // maximum reasonable length
        ];

        for (final username in validUsernames) {
          expect(isValidUsername(username), isTrue, reason: '$username should be valid');
        }
      });

      test('should reject invalid usernames', () {
        final invalidUsernames = [
          '',
          'ab', // too short
          'user@name',
          'user name',
          'user.name',
          '123username',
          'user123456789012345', // too long
          '-username',
          'username-',
          '_username',
          'username_',
        ];

        for (final username in invalidUsernames) {
          expect(isValidUsername(username), isFalse, reason: '$username should be invalid');
        }
      });
    });

    group('Age Validation', () {
      test('should validate valid ages', () {
        final validAges = [18, 25, 30, 50, 99];

        for (final age in validAges) {
          expect(isValidAge(age), isTrue, reason: '$age should be valid');
        }
      });

      test('should reject invalid ages', () {
        final invalidAges = [-1, 0, 17, 100, 150];

        for (final age in invalidAges) {
          expect(isValidAge(age), isFalse, reason: '$age should be invalid');
        }
      });
    });

    group('Phone Number Validation', () {
      test('should validate correct phone numbers', () {
        final validPhones = ['+33612345678', '+14155552671', '+442071838750', '+493012345678'];

        for (final phone in validPhones) {
          expect(isValidPhoneNumber(phone), isTrue, reason: '$phone should be valid');
        }
      });

      test('should reject invalid phone numbers', () {
        final invalidPhones = [
          '',
          '123456789',
          '+123',
          '+12345678901234567890',
          'phone',
          '+3361234567a',
        ];

        for (final phone in invalidPhones) {
          expect(isValidPhoneNumber(phone), isFalse, reason: '$phone should be invalid');
        }
      });
    });

    group('Bio Validation', () {
      test('should validate bio within length limits', () {
        final validBios = [
          'Short bio',
          'This is a medium length bio that describes the user well.',
          'A'.padRight(500, 'x'), // maximum length
        ];

        for (final bio in validBios) {
          expect(isValidBio(bio), isTrue, reason: 'Bio should be valid');
        }
      });

      test('should reject bio that exceeds length limit', () {
        final invalidBio = 'A'.padRight(501, 'x');
        expect(isValidBio(invalidBio), isFalse);
      });

      test('should accept empty bio', () {
        expect(isValidBio(''), isTrue);
      });
    });
  });
}

// Helper validation functions (these would typically be in a separate service file)
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return emailRegex.hasMatch(email);
}

bool isValidPassword(String password) {
  if (password.length < 8) return false;

  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  final hasDigits = RegExp(r'[0-9]').hasMatch(password);
  final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

  return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
}

enum PasswordStrength { weak, medium, strong }

PasswordStrength getPasswordStrength(String password) {
  if (password.length < 6) return PasswordStrength.weak;

  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score <= 4) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

bool isValidUsername(String username) {
  if (username.length < 3 || username.length > 20) return false;

  final usernameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$');
  return usernameRegex.hasMatch(username);
}

bool isValidAge(int age) {
  return age >= 18 && age <= 99;
}

bool isValidPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
  return phoneRegex.hasMatch(phone);
}

bool isValidBio(String bio) {
  return bio.length <= 500;
}
