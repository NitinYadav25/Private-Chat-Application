import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    if (!authState.hasCompletedOnboarding) {
      context.go('/onboarding');
    } else if (!authState.isAuthenticated) {
      context.go('/login');
    } else if (!authState.isEmailVerified) {
      context.go('/verify-email');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Logo Container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.sentBubbleGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withAlpha(120),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.ghost,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 600.ms),

            const SizedBox(height: AppConstants.space24),

            // App Name
            Text(
              AppConstants.appName,
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colors.text,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

            const SizedBox(height: AppConstants.space8),

            // Subtitle
            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 48),

            // Subtle loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
