import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/features/auth/domain/password_strength.dart';

void main() {
  group('PasswordStrengthResult tests', () {
    test('Empty password returns none', () {
      final result = PasswordStrengthResult.calculate('');
      expect(result.level, PasswordStrengthLevel.none);
    });

    test('Short simple password returns weak', () {
      final result = PasswordStrengthResult.calculate('pass');
      expect(result.level, PasswordStrengthLevel.weak);
      expect(result.hasMinLength, isFalse);
    });

    test('8 character password with numbers returns fair or good', () {
      final result = PasswordStrengthResult.calculate('Password123');
      expect(result.hasMinLength, isTrue);
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasNumber, isTrue);
      expect(result.level.score >= PasswordStrengthLevel.fair.score, isTrue);
    });

    test('Complex 12+ char password with symbols returns strong', () {
      final result = PasswordStrengthResult.calculate('GhostConv@2026!');
      expect(result.hasMinLength, isTrue);
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasNumber, isTrue);
      expect(result.hasSpecialChar, isTrue);
      expect(result.level, PasswordStrengthLevel.strong);
    });
  });
}

