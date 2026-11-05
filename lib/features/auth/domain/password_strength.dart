import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum PasswordStrengthLevel {
  none(0, 'Enter password', Colors.transparent),
  weak(1, 'Weak', AppColors.danger),
  fair(2, 'Fair', AppColors.warning),
  good(3, 'Good', AppColors.secondary),
  strong(4, 'Strong', AppColors.accent);

  const PasswordStrengthLevel(this.score, this.label, this.color);
  final int score;
  final String label;
  final Color color;
}

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.level,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });

  final PasswordStrengthLevel level;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  static PasswordStrengthResult calculate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        level: PasswordStrengthLevel.none,
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false,
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);

    int points = 0;
    if (hasMinLength) points++;
    if (hasUppercase && hasLowercase) points++;
    if (hasNumber) points++;
    if (hasSpecialChar) points++;
    if (password.length >= 12) points++;

    PasswordStrengthLevel level;
    if (points <= 1) {
      level = PasswordStrengthLevel.weak;
    } else if (points == 2) {
      level = PasswordStrengthLevel.fair;
    } else if (points == 3 || points == 4) {
      level = PasswordStrengthLevel.good;
    } else {
      level = PasswordStrengthLevel.strong;
    }

    return PasswordStrengthResult(
      level: level,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
    );
  }
}

