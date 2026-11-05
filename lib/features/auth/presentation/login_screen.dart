import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/ghost_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _localError = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _localError = 'Please enter your password.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );

    if (success && mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.isEmailVerified) {
        context.go('/home');
      } else {
        context.go('/verify-email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final authState = ref.watch(authControllerProvider);
    final errorMessage = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing Logo
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.sentBubbleGradient,
                      shape: BoxShape.circle,
                      boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.ghost,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.space24),

                // Title & Subtitle
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to join your temporary private rooms',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.muted,
                  ),
                ),

                const SizedBox(height: 32),

                // Error Banner
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                      border: Border.all(color: AppColors.danger.withAlpha(90)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 18, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Input
                Text(
                  'Email',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                    border: Border.all(color: colors.border),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.bodyMedium.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.space16),

                // Password Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                    border: Border.all(color: colors.border),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.bodyMedium.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 20,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.space24),

                // Sign In Button
                GhostButton(
                  label: 'Sign In',
                  isFullWidth: true,
                  height: 50,
                  isLoading: authState.isLoading,
                  variant: GhostButtonVariant.primary,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: AppConstants.space24),

                // Switch to Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodySmall.copyWith(color: colors.muted),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: Text(
                        'Sign Up',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

