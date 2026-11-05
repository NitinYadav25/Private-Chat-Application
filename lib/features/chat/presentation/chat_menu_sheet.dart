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
import 'chat_controller.dart';

class ChatMenuSheet extends ConsumerStatefulWidget {
  const ChatMenuSheet({
    super.key,
    required this.roomId,
    this.roomCode,
    this.roomName,
  });

  final String roomId;
  final String? roomCode;
  final String? roomName;

  @override
  ConsumerState<ChatMenuSheet> createState() => _ChatMenuSheetState();
}

class _ChatMenuSheetState extends ConsumerState<ChatMenuSheet> {
  bool _revealCode = false;

  void _showWipeConfirmationDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (dialogContext) {
        return ShadDialog.alert(
          title: Text(
            'End Chat & Wipe All Data?',
            style: AppTypography.titleLarge.copyWith(color: AppColors.danger),
          ),
          description: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This action is irreversible. All messages, media, and room metadata will be permanently eradicated from the server and both phones immediately.',
              style: AppTypography.bodySmall.copyWith(height: 1.4),
            ),
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            _WipeHoldConfirmAction(
              onConfirmed: () async {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // close sheet

                // Execute wipe through chat controller
                await ref
                    .read(chatControllerProvider(widget.roomId).notifier)
                    .endChatAndWipe();

                if (context.mounted) {
                  HapticFeedback.heavyImpact();
                  context.go('/chat-ended');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final chatState = ref.watch(chatControllerProvider(widget.roomId));
    final code = widget.roomCode ?? chatState.roomCode ?? 'K7M29QXP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Room Name & Status
            Text(
              widget.roomName ?? chatState.roomName ?? 'Temporary Room',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'End-to-End Ephemeral Room',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security Code Tile (Hidden with tap to reveal)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Security Code',
                        style: AppTypography.bodySmall.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _revealCode ? code : '••••••••',
                        style: AppTypography.codeMedium.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.bold,
                          letterSpacing: _revealCode ? 2.0 : 4.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _revealCode ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: colors.muted,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _revealCode = !_revealCode);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mute Notifications Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        chatState.isMuted ? LucideIcons.bellOff : LucideIcons.bell,
                        size: 20,
                        color: colors.muted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mute Notifications',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                  ShadSwitch(
                    value: chatState.isMuted,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(chatControllerProvider(widget.roomId).notifier).toggleMute();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // End Chat & Wipe Data Button (Red Danger)
            GhostButton(
              label: 'End Chat & Wipe Data',
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white),
              variant: GhostButtonVariant.destructive,
              height: 52,
              onPressed: () => _showWipeConfirmationDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1.5-second Press-and-Hold Button for Wipe Confirmation
class _WipeHoldConfirmAction extends StatefulWidget {
  const _WipeHoldConfirmAction({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_WipeHoldConfirmAction> createState() => _WipeHoldConfirmActionState();
}

class _WipeHoldConfirmActionState extends State<_WipeHoldConfirmAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.wipeHoldDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (_controller.status != AnimationStatus.completed) {
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 42,
                width: 170,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                  border: Border.all(color: AppColors.danger),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 170 * progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.flame, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    progress > 0.05
                        ? 'Holding ${(progress * 100).toInt()}%'
                        : 'Hold 1.5s to Wipe',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
