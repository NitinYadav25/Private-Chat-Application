import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/ghost_button.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';
import 'room_controller.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  RoomModel? _createdRoom;
  StreamSubscription<RoomModel?>? _roomSubscription;

  @override
  void dispose() {
    _nameController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final room = await ref
        .read(roomControllerProvider.notifier)
        .createRoom(name: name.isEmpty ? null : name);

    if (room != null && mounted) {
      setState(() => _createdRoom = room);

      // Listen for partner joining to auto-transition to chat
      _roomSubscription?.cancel();
      _roomSubscription = ref
          .read(roomRepositoryProvider)
          .watchRoom(room.id)
          .listen((updatedRoom) {
        if (updatedRoom != null && updatedRoom.isActive && mounted) {
          HapticFeedback.heavyImpact();
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('Partner Joined!'),
              description: Text('Security code burned. Starting encrypted chat.'),
            ),
          );
          context.go('/chat/${room.id}');
        }
      });
    }
  }

  void _copyCode() {
    if (_createdRoom?.code == null) return;
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: _createdRoom!.code!));
    ShadToaster.of(context).show(
      const ShadToast(
        title: Text('Code Copied!'),
        description: Text('Share this code with your friend.'),
      ),
    );
  }

  void _shareCode() {
    if (_createdRoom?.code == null) return;
    HapticFeedback.lightImpact();
    final code = _createdRoom!.formattedCode;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my private encrypted room on GhostConv!\nSecurity Code: $code\n(This code is single-use and will burn immediately once joined)',
        subject: 'GhostConv Chat Invitation',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final roomState = ref.watch(roomControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Create Room'),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft),
          onPressed: () {
            ref.read(roomControllerProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _createdRoom != null
              ? _buildSuccessView(colors)
              : _buildCreateForm(colors, roomState),
        ),
      ),
    );
  }

  Widget _buildCreateForm(GhostConvColors colors, RoomState roomState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.sentBubbleGradient,
              shape: BoxShape.circle,
              boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
            ),
            child: Center(
              child: Icon(LucideIcons.plus, size: 36, color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'New Temporary Room',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Generates a unique 8-character code. The code is single-use and will be permanently erased once your partner joins.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: colors.muted,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 32),

        // Error Banner
        if (roomState.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(25),
              borderRadius: BorderRadius.circular(AppConstants.radiusInput),
              border: Border.all(color: AppColors.danger.withAlpha(90)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 18, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    roomState.errorMessage!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Optional Room Name
        Text(
          'Room Name (Optional)',
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
            style: AppTypography.bodyMedium.copyWith(color: colors.text),
            decoration: InputDecoration(
              hintText: 'e.g. Project Sync, Confidential',
              hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Create Room Button
        GhostButton(
          label: roomState.isLoading ? 'Waking Server & Creating...' : 'Generate Room & Code',
          isFullWidth: true,
          height: 52,
          isLoading: roomState.isLoading,
          variant: GhostButtonVariant.primary,
          onPressed: _handleCreate,
        ),
      ],
    );
  }

  Widget _buildSuccessView(GhostConvColors colors) {
    final code = _createdRoom?.formattedCode ?? '••••-••••';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        // Security Code Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.5),
            boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
          ),
          child: Column(
            children: [
              Text(
                'SECURITY CODE',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                code,
                style: AppTypography.codeLarge.copyWith(
                  color: colors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Single-use. Expires in 24 hours.',
                style: AppTypography.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: Copy & Share
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Copy Code',
                icon: Icon(LucideIcons.copy, size: 18),
                variant: GhostButtonVariant.secondary,
                height: 48,
                onPressed: _copyCode,
              ),
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: GhostButton(
                label: 'Share Code',
                icon: Icon(LucideIcons.share2, size: 18, color: Colors.white),
                variant: GhostButtonVariant.primary,
                height: 48,
                onPressed: _shareCode,
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Pulsing radar "Waiting for your friend..."
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(LucideIcons.userCheck, color: AppColors.primary, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Waiting for your friend to join...',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This screen will automatically transition into chat the moment they enter this code.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Manual Chat transition fallback
        GhostButton(
          label: 'Enter Chat Room Now',
          variant: GhostButtonVariant.outline,
          isFullWidth: true,
          height: 46,
          onPressed: () {
            if (_createdRoom != null) {
              context.go('/chat/${_createdRoom!.id}');
            }
          },
        ),
      ],
    );
  }
}
