import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/ghost_button.dart';
import '../../auth/presentation/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Private 1-to-1 Rooms',
      description:
          'Temporary chat rooms designed strictly for two participants. No third-party snooping, no group clutter, and no data mining.',
      icon: LucideIcons.shieldCheck,
      gradientColors: [AppColors.primary, AppColors.secondary],
    ),
    _OnboardingItem(
      title: 'Single-Use Security Code',
      description:
          'Create a room and share a unique 8-character code. The moment your partner joins, the room locks and the code vanishes forever.',
      icon: LucideIcons.keyRound,
      gradientColors: [AppColors.secondary, AppColors.accent],
    ),
    _OnboardingItem(
      title: 'Irreversible Data Wipe',
      description:
          'When either participant ends the chat, all messages, photos, videos, files and metadata are immediately and permanently destroyed on both devices.',
      icon: LucideIcons.flame,
      gradientColors: [AppColors.danger, AppColors.warning],
    ),
  ];

  Future<void> _finishOnboarding() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              'Skip',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon card
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.gradientColors.first.withAlpha(80),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              item.icon,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: AppConstants.durationFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : colors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Button
                  GhostButton(
                    label: isLastPage ? 'Get Started' : 'Next',
                    isFullWidth: true,
                    height: 52,
                    variant: GhostButtonVariant.primary,
                    onPressed: () {
                      if (isLastPage) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: AppConstants.durationNormal,
                          curve: AppConstants.defaultCurve,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
}

