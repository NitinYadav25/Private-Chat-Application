import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/ghost_button.dart';

class ChatEndedScreen extends StatelessWidget {
  const ChatEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.danger.withAlpha(90)),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.flame,
                        size: 44,
                        color: AppColors.danger,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Chat Ended',
                    style: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'All Data Deleted',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'All messages, media attachments, and room records have been permanently wiped from the server and local storage. No trace remains.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  GhostButton(
                    label: 'Return to Home',
                    isFullWidth: true,
                    height: 52,
                    variant: GhostButtonVariant.primary,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
