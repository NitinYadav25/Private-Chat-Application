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
import 'widgets/password_strength_meter.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _password = '';
  String? _localError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() => _localError = null);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _localError = 'Please enter your name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters long.');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signUp(
          name: name,
          email: email,
          password: password,
        );

    if (success && mounted) {
      context.go('/verify-email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final authState = ref.watch(authControllerProvider);
    final errorMessage = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join GhostConv for private, temporary 1-to-1 rooms',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.muted,
                  ),
                ),

                const SizedBox(height: 28),

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

                // Name
                Text(
                  'Full Name',
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
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.bodyMedium.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'John Doe',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.space16),

                // Email
                Text(
                  'Email Address',
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

                // Password
                Text(
                  'Password',
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
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.bodyMedium.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'At least 8 characters',
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

                // Password Strength Meter
                PasswordStrengthMeter(password: _password),

                const SizedBox(height: AppConstants.space16),

                // Confirm Password
                Text(
                  'Confirm Password',
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
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: AppTypography.bodyMedium.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        child: Icon(
                          _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 20,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.space24),

                // Sign Up Button
                GhostButton(
                  label: 'Create Account',
                  isFullWidth: true,
                  height: 50,
                  isLoading: authState.isLoading,
                  variant: GhostButtonVariant.primary,
                  onPressed: _handleSignUp,
                ),

                const SizedBox(height: AppConstants.space24),

                // Switch to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodySmall.copyWith(color: colors.muted),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Sign In',
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

