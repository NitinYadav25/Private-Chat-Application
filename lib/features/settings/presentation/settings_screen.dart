import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/ghost_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media/data/media_picker_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await ref.read(notificationServiceProvider).isNotificationsEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showShadDialog(
      context: context,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text('Edit Display Name', style: AppTypography.titleLarge),
          description: Text(
            'This name is shown to your friend when you create or join a temporary room.',
            style: AppTypography.bodySmall,
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ShadButton(
              child: const Text('Save'),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  await ref.read(authControllerProvider.notifier).updateProfile(name: newName);
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      const ShadToast(title: Text('Display name updated')),
                    );
                  }
                }
              },
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ShadInput(
              controller: controller,
              placeholder: const Text('Enter display name'),
              autofocus: true,
            ),
          ),
        );
      },
    );
  }

  void _showChangePhotoSheet(BuildContext context) {
    final picker = ref.read(mediaPickerServiceProvider);

    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (sheetContext) {
        return ShadSheet(
          title: Text('Update Profile Photo', style: AppTypography.titleLarge),
          description: Text('Select a photo from camera or gallery', style: AppTypography.bodySmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSheetAction(LucideIcons.camera, 'Camera', AppColors.primary, () async {
                  Navigator.of(sheetContext).pop();
                  final file = await picker.pickImageFromCamera();
                  if (file != null) {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateProfile(photoUrl: file.path);
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        const ShadToast(title: Text('Profile photo updated')),
                      );
                    }
                  }
                }),
                _buildSheetAction(LucideIcons.image, 'Gallery', AppColors.secondary, () async {
                  Navigator.of(sheetContext).pop();
                  final file = await picker.pickImageFromGallery();
                  if (file != null) {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateProfile(photoUrl: file.path);
                    if (context.mounted) {
                      ShadToaster.of(context).show(
                        const ShadToast(title: Text('Profile photo updated')),
                      );
                    }
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(child: Icon(icon, color: color, size: 26)),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showPurgeCacheDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (dialogContext) {
        return ShadDialog.alert(
          title: Text('Purge All Ephemeral Cache?', style: AppTypography.titleLarge),
          description: Text(
            'This will permanently delete all cached message history and temporary media files stored on this device. Active room metadata on the server will not be affected.',
            style: AppTypography.bodySmall.copyWith(height: 1.4),
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ShadButton.destructive(
              child: const Text('Purge All'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(localCacheServiceProvider).clearAllCache();
                if (context.mounted) {
                  HapticFeedback.mediumImpact();
                  ShadToaster.of(context).show(
                    const ShadToast(
                      title: Text('Cache Purged'),
                      description: Text('All local ephemeral data eradicated from this device.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (dialogContext) {
        return ShadDialog(
          title: Text('Log Out?', style: AppTypography.titleLarge),
          description: Text(
            'Are you sure you want to sign out of GhostConv? You can sign back in at any time.',
            style: AppTypography.bodySmall,
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ShadButton.destructive(
              child: const Text('Log Out'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (dialogContext) {
        return ShadDialog.alert(
          title: Text(
            'Delete Account Permanently?',
            style: AppTypography.titleLarge.copyWith(color: AppColors.danger),
          ),
          description: Text(
            'WARNING: This action is permanent and cannot be reversed. Your account credentials, profile data, and associated keys will be permanently deleted.',
            style: AppTypography.bodySmall.copyWith(height: 1.4),
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ShadButton.destructive(
              child: const Text('Delete Account Forever'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(authControllerProvider.notifier).deleteAccount();
                await ref.read(localCacheServiceProvider).clearAllCache();
                if (context.mounted) {
                  HapticFeedback.heavyImpact();
                  context.go('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(String? photoUrl, String name, GhostConvColors colors) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isLocal = photoUrl.startsWith('/') ||
          photoUrl.startsWith('file:') ||
          photoUrl.contains(Platform.pathSeparator);

      return ClipOval(
        child: SizedBox(
          width: 80,
          height: 80,
          child: isLocal
              ? Image.file(File(photoUrl), fit: BoxFit.cover)
              : Image.network(photoUrl, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        gradient: AppColors.sentBubbleGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: AppTypography.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final name = user?.name ?? 'Ghost User';
    final email = user?.email ?? '';
    final isEmailVerified = user?.isEmailVerified ?? false;
    final photoUrl = user?.photoUrl;

    final currentTheme = ref.watch(themeModeProvider);
    final securityState = ref.watch(securityServiceProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Settings & Privacy', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // 1. Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
                boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildAvatar(photoUrl, name, colors),
                      GestureDetector(
                        onTap: () => _showChangePhotoSheet(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.camera, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.pencil, size: 16),
                        color: colors.muted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditNameDialog(context, name),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(email, style: AppTypography.bodySmall.copyWith(color: colors.muted)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isEmailVerified
                              ? AppColors.success.withAlpha(25)
                              : AppColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isEmailVerified ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEmailVerified ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                              size: 11,
                              color: isEmailVerified ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEmailVerified ? 'Verified' : 'Unverified',
                              style: AppTypography.bodySmall.copyWith(
                                color: isEmailVerified ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Appearance Section
            _buildSectionHeader('Appearance', colors),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    'Dark Theme',
                    'High contrast dark palette with violet accents',
                    LucideIcons.moon,
                    currentTheme == ThemeMode.dark,
                    () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                    colors,
                  ),
                  const Divider(height: 20),
                  _buildThemeOption(
                    'Light Theme',
                    'Clean minimalist light palette',
                    LucideIcons.sun,
                    currentTheme == ThemeMode.light,
                    () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                    colors,
                  ),
                  const Divider(height: 20),
                  _buildThemeOption(
                    'Follow System',
                    'Automatically match Android device theme',
                    LucideIcons.smartphone,
                    currentTheme == ThemeMode.system,
                    () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
                    colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Privacy & Security Section
            _buildSectionHeader('Privacy & Security', colors),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  // Block Screenshots (FLAG_SECURE)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.shield, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Block Screenshots (FLAG_SECURE)',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Prevents screenshots, screen recording, and blanks recent app previews.',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShadSwitch(
                        value: securityState.isBlockScreenshotsEnabled,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          ref.read(securityServiceProvider.notifier).toggleBlockScreenshots(val);
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Notifications Toggle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.bell, color: AppColors.secondary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Push Notifications',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Receive high-priority sound and vibration for new messages.',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShadSwitch(
                        value: _notificationsEnabled,
                        onChanged: (val) async {
                          HapticFeedback.selectionClick();
                          setState(() => _notificationsEnabled = val);
                          await ref
                              .read(notificationServiceProvider)
                              .setNotificationsEnabled(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Ephemeral Storage Section
            _buildSectionHeader('Storage & Ephemeral Cache', colors),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.hardDrive, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Ephemeral Cache',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Encrypted Hive message store and temporary media previews',
                              style: AppTypography.bodySmall.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GhostButton(
                    label: 'Purge Local Cache',
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    variant: GhostButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () => _showPurgeCacheDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Danger Zone Section
            _buildSectionHeader('Danger Zone', colors),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: AppColors.danger.withAlpha(80)),
              ),
              child: Column(
                children: [
                  GhostButton(
                    label: 'Log Out of GhostConv',
                    icon: const Icon(LucideIcons.logOut, size: 18),
                    variant: GhostButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () => _showLogoutDialog(context),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'Delete Account Permanently',
                    icon: const Icon(LucideIcons.flame, size: 18, color: Colors.white),
                    variant: GhostButtonVariant.destructive,
                    isFullWidth: true,
                    onPressed: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // 6. App Metadata & Disclaimer Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'GhostConv v1.0.0 (API 26+)',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Private Ephemeral Rooms • Zero-Knowledge • Instant Wipe',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.muted.withAlpha(160),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, GhostConvColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.bodySmall.copyWith(
          color: colors.muted,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    GhostConvColors colors,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withAlpha(30) : colors.elevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : colors.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(LucideIcons.check, size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}
