import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/ghost_button.dart';
import 'auth_controller.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Auto-check every 5 seconds as specified in requirements
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    _isChecking = true;

    final isVerified = await ref.read(authControllerProvider.notifier).checkEmailVerification();
    _isChecking = false;

    if (isVerified && mounted) {
      _pollingTimer?.cancel();
      HapticFeedback.heavyImpact();
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Email Verified!'),
          description: Text('Welcome to GhostConv.'),
        ),
      );
      context.go('/home');
    }
  }

  Future<void> _resendVerification() async {
    if (_cooldownSeconds > 0) return;

    final success = await ref.read(authControllerProvider.notifier).resendVerificationEmail();
    if (success && mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Verification Link Sent'),
          description: Text('Please check your inbox or spam folder.'),
        ),
      );

      setState(() => _cooldownSeconds = 30);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_cooldownSeconds <= 1) {
          timer.cancel();
          setState(() => _cooldownSeconds = 0);
        } else {
          setState(() => _cooldownSeconds--);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final authState = ref.watch(authControllerProvider);
    final userEmail = authState.user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              _pollingTimer?.cancel();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Mail Icon
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                      boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.mail,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'We sent a verification link to:\n$userEmail\n\nPlease check your inbox and tap the link to activate your GhostConv account.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.muted,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Auto-checking badge indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Checking status automatically every 5s...',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Manual Check Now button
                GhostButton(
                  label: 'I Have Verified',
                  isFullWidth: true,
                  height: 50,
                  variant: GhostButtonVariant.primary,
                  onPressed: _checkVerification,
                ),

                const SizedBox(height: 12),

                // Resend button with cooldown
                GhostButton(
                  label: _cooldownSeconds > 0
                      ? 'Resend Email in ${_cooldownSeconds}s'
                      : 'Resend Verification Email',
                  isFullWidth: true,
                  height: 50,
                  variant: GhostButtonVariant.outline,
                  onPressed: _cooldownSeconds > 0 ? null : _resendVerification,
                ),

                const SizedBox(height: 24),

                // Logout / Change account
                Center(
                  child: TextButton(
                    onPressed: () async {
                      _pollingTimer?.cancel();
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      'Wrong email? Switch account',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

