import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/features/auth/data/auth_repository.dart';
import 'package:ghostconv/features/auth/domain/password_strength.dart';
import 'package:ghostconv/features/auth/presentation/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Session Persistence tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Signing in persists user session in SharedPreferences', () async {
      final repository = AuthRepository();
      final user = await repository.signIn(
        email: 'test@ghostconv.com',
        password: 'Password123!',
      );

      expect(user.email, 'test@ghostconv.com');

      // Verify session was persisted
      final restored = await repository.getCurrentUser();
      expect(restored, isNotNull);
      expect(restored!.email, 'test@ghostconv.com');
      expect(restored.isEmailVerified, isTrue);
    });

    test('AuthController automatically restores persisted user across app restarts', () async {
      final repository = AuthRepository();
      await repository.signIn(
        email: 'persistent@ghostconv.com',
        password: 'Password123!',
      );

      // Simulate a fresh app startup by creating a new AuthController
      final controller = AuthController(repository);
      await controller.initialize();

      expect(controller.state.isInitialized, isTrue);
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.user?.email, 'persistent@ghostconv.com');
      expect(controller.state.hasCompletedOnboarding, isTrue);
    });

    test('Explicit signOut completely clears persistent session', () async {
      final repository = AuthRepository();
      await repository.signIn(
        email: 'logout@ghostconv.com',
        password: 'Password123!',
      );

      expect(await repository.getCurrentUser(), isNotNull);

      // Perform explicit logout
      await repository.signOut();

      // Session must now be null
      expect(await repository.getCurrentUser(), isNull);
    });
  });
}

