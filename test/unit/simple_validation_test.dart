import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple Validation Tests', () {
    test('should validate basic email formats', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('should validate password strength', () {
      expect(isValidPassword('Password123!'), isTrue);
      expect(isValidPassword('weak'), isFalse);
      expect(isValidPassword(''), isFalse);
    });

    test('should validate age range', () {
      expect(isValidAge(18), isTrue);
      expect(isValidAge(25), isTrue);
      expect(isValidAge(99), isTrue);
      expect(isValidAge(17), isFalse);
      expect(isValidAge(100), isFalse);
    });

    test('should validate phone numbers', () {
      expect(isValidPhoneNumber('+33612345678'), isTrue);
      expect(isValidPhoneNumber('+14155552671'), isTrue);
      expect(isValidPhoneNumber('123'), isFalse);
      expect(isValidPhoneNumber(''), isFalse);
    });

    test('should validate bio length', () {
      expect(isValidBio('Short bio'), isTrue);
      expect(isValidBio(''), isTrue);
      expect(isValidBio('A' * 500), isTrue);
      expect(isValidBio('A' * 501), isFalse);
    });
  });
}

// Simple validation functions
bool isValidEmail(String email) {
  return email.contains('@') && email.contains('.');
}

bool isValidPassword(String password) {
  return password.length >= 8 &&
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[0-9]'));
}

bool isValidAge(int age) {
  return age >= 18 && age <= 99;
}

bool isValidPhoneNumber(String phone) {
  return phone.startsWith('+') && phone.length >= 10;
}

bool isValidBio(String bio) {
  return bio.length <= 500;
}
