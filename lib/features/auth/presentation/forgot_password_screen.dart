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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() => _localError = null);
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);

    if (success && mounted) {
      setState(() => _sent = true);
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _sent ? _buildSuccessView(colors) : _buildFormView(colors, authState, errorMessage),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(GhostConvColors colors, AuthState authState, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: const Center(
              child: Icon(LucideIcons.keyRound, size: 28, color: AppColors.primary),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Forgot Password',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we will send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: colors.muted,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 32),

        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(25),
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              border: Border.all(color: AppColors.danger.withAlpha(90)),
            ),
            child: Text(
              errorMessage,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 16),
        ],

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

        const SizedBox(height: 24),

        GhostButton(
          label: 'Send Reset Link',
          isFullWidth: true,
          height: 50,
          isLoading: authState.isLoading,
          variant: GhostButtonVariant.primary,
          onPressed: _handleReset,
        ),
      ],
    );
  }

  Widget _buildSuccessView(GhostConvColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: const Center(
              child: Icon(LucideIcons.mailCheck, size: 36, color: AppColors.success),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Inbox',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A reset link was sent to ${_emailController.text.trim()}. Open the link to set a new password.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.muted,
          ),
        ),
        const SizedBox(height: 32),
        GhostButton(
          label: 'Back to Login',
          isFullWidth: true,
          height: 50,
          variant: GhostButtonVariant.outline,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}

