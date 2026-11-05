import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/password_strength.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final result = PasswordStrengthResult.calculate(password);
    final score = result.level.score;

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 1; i <= 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: AppConstants.durationFast,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= score ? result.level.color : colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strength: ${result.level.label}',
              style: AppTypography.bodySmall.copyWith(
                color: result.level.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '8+ chars, upper, number & symbol',
              style: AppTypography.bodySmall.copyWith(
                color: colors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

