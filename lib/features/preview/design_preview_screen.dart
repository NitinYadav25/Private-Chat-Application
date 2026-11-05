import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/chat_bubble.dart';
import '../../core/widgets/code_input_field.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/media_grid.dart';
import '../../core/widgets/message_input_bar.dart';
import '../../core/widgets/room_card.dart';
import '../../core/widgets/upload_progress_bubble.dart';

class DesignPreviewScreen extends ConsumerStatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  ConsumerState<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends ConsumerState<DesignPreviewScreen> {
  final GlobalKey<CodeInputFieldState> _codeKey = GlobalKey<CodeInputFieldState>();
  String _enteredCode = '';
  bool _codeHasError = false;
  String? _codeErrorMessage;
  String? _repliedMessage;
  double _uploadProgress = 0.65;

  void _showWipeConfirmDialog(BuildContext context) {
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
              'This action is irreversible. All messages, photos, videos, files and room metadata will be permanently deleted from the server and both devices.',
              style: AppTypography.bodySmall,
            ),
          ),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            _WipeHoldConfirmButton(
              onConfirmed: () {
                Navigator.of(dialogContext).pop();
                ShadToaster.of(context).show(
                  const ShadToast.destructive(
                    title: Text('Wipe Initiated'),
                    description: Text('All data deleted permanently.'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showAttachSheet(BuildContext context) {
    final colors = context.ghostColors;
    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (sheetContext) {
        return ShadSheet(
          title: Text('Share Attachment', style: AppTypography.titleLarge),
          description: Text('Choose media or document to send', style: AppTypography.bodySmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSheetAction(LucideIcons.camera, 'Camera', AppColors.primary, () {
                  Navigator.of(sheetContext).pop();
                  ShadToaster.of(context).show(
                    const ShadToast(title: Text('Camera opened')),
                  );
                }),
                _buildSheetAction(LucideIcons.image, 'Gallery', AppColors.secondary, () {
                  Navigator.of(sheetContext).pop();
                  ShadToaster.of(context).show(
                    const ShadToast(title: Text('Gallery opened')),
                  );
                }),
                _buildSheetAction(LucideIcons.video, 'Video', AppColors.accent, () {
                  Navigator.of(sheetContext).pop();
                  ShadToaster.of(context).show(
                    const ShadToast(title: Text('Video picker opened')),
                  );
                }),
                _buildSheetAction(LucideIcons.fileText, 'Document', colors.text, () {
                  Navigator.of(sheetContext).pop();
                  ShadToaster.of(context).show(
                    const ShadToast(title: Text('File picker opened')),
                  );
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final currentTheme = ref.watch(themeModeProvider);
    final isDark = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.sentBubbleGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.ghost, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('GhostConv Design System', style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          Row(
            children: [
              Icon(
                isDark ? LucideIcons.moon : LucideIcons.sun,
                size: 18,
                color: isDark ? AppColors.primaryGlow : AppColors.warning,
              ),
              const SizedBox(width: 6),
              ShadSwitch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Design Tokens
          _buildSectionHeader('1. COLOR TOKENS & SYSTEM PALETTE', colors),
          _buildColorTokensSection(colors),

          const SizedBox(height: AppConstants.space24),

          // Section 2: Typography Scale
          _buildSectionHeader('2. TYPOGRAPHY SCALE (Jakarta & Inter)', colors),
          _buildTypographySection(colors),

          const SizedBox(height: AppConstants.space24),

          // Section 3: Shadcn UI Core Components
          _buildSectionHeader('3. SHADCN_UI COMPONENTS', colors),
          _buildShadcnComponentsSection(context, colors),

          const SizedBox(height: AppConstants.space24),

          // Section 4: 8-Box Security Code Input
          _buildSectionHeader('4. 8-BOX CODE INPUT FIELD (Mono, Paste, Shake)', colors),
          _buildCodeInputSection(colors),

          const SizedBox(height: AppConstants.space24),

          // Section 5: Chat Bubbles & Micro-Animations
          _buildSectionHeader('5. CHAT BUBBLES (Gradients, Ticks & Swipe)', colors),
          _buildChatBubblesSection(colors),

          const SizedBox(height: AppConstants.space24),

          // Section 6: Room Cards
          _buildSectionHeader('6. ROOM CARDS (Active & Pulsing Waiting)', colors),
          _buildRoomCardsSection(),

          const SizedBox(height: AppConstants.space24),

          // Section 7: Media & Upload Progress
          _buildSectionHeader('7. ATTACHMENT & PROGRESS INDICATORS', colors),
          _buildMediaAndProgressSection(colors),

          const SizedBox(height: AppConstants.space24),

          // Section 8: Interactive Input Bar
          _buildSectionHeader('8. MESSAGE INPUT BAR', colors),
          MessageInputBar(
            onSendText: (text) {
              ShadToaster.of(context).show(
                ShadToast(title: Text('Sent: $text')),
              );
            },
            replyToAuthor: _repliedMessage != null ? 'Sarah Connor' : null,
            replyToText: _repliedMessage,
            onCancelReply: () => setState(() => _repliedMessage = null),
            onAttachPressed: () => _showAttachSheet(context),
            onCameraPressed: () {
              ShadToaster.of(context).show(
                const ShadToast(title: Text('Camera tapped')),
              );
            },
            onVoiceNotePressed: () {
              ShadToaster.of(context).show(
                const ShadToast(title: Text('Voice note tapped')),
              );
            },
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, GhostConvColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.sentBubbleGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorTokensSection(GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildColorChip('Primary', AppColors.primary, Colors.white),
              _buildColorChip('Primary Glow', AppColors.primaryGlow, Colors.white),
              _buildColorChip('Secondary', AppColors.secondary, Colors.white),
              _buildColorChip('Accent', AppColors.accent, Colors.black),
              _buildColorChip('Danger', AppColors.danger, Colors.white),
              _buildColorChip('Success', AppColors.success, Colors.black),
              _buildColorChip('Warning', AppColors.warning, Colors.black),
              _buildColorChip('Background', colors.background, colors.text),
              _buildColorChip('Surface', colors.surface, colors.text),
              _buildColorChip('Elevated', colors.elevated, colors.text),
              _buildColorChip('Border', colors.border, colors.text),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.sentBubbleGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusButton),
              boxShadow: colors.isDark ? AppColors.darkGlowShadow : null,
            ),
            child: Center(
              child: Text(
                'Sent Bubble Gradient (#7C5CFF → #5B8CFF)',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(String label, Color color, Color textCol) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textCol, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: TextStyle(color: textCol.withAlpha(200), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographySection(GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Headline Large (28px) - GhostConv', style: AppTypography.headlineLarge),
          const SizedBox(height: 6),
          Text('Headline Medium (22px) - Encrypted Ephemeral Chat', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text('Title Large (18px) - 1-to-1 Temporary Rooms', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text('Body Large (16px) - Permanent wipe when either participant ends the chat.', style: AppTypography.bodyLarge),
          const SizedBox(height: 6),
          Text('Body Medium (14px) - Crockford Base32 8-character single-use code security.', style: AppTypography.bodyMedium),
          const SizedBox(height: 6),
          Text('Body Small (12px) - Cloud Firestore Spark tier with Cloudinary signed uploads.', style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text('JetBrains Mono (24px): ', style: AppTypography.bodySmall),
                Text('K7M2-9QXP', style: AppTypography.codeMedium.copyWith(color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadcnComponentsSection(BuildContext context, GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ShadButton Variants:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton(
                child: const Text('Primary'),
                onPressed: () {},
              ),
              ShadButton.secondary(
                child: const Text('Secondary'),
                onPressed: () {},
              ),
              ShadButton.outline(
                child: const Text('Outline'),
                onPressed: () {},
              ),
              ShadButton.ghost(
                child: const Text('Ghost'),
                onPressed: () {},
              ),
              ShadButton.destructive(
                child: const Text('Destructive'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('ShadBadge Status Badges:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            children: [
              ShadBadge(child: Text('Active')),
              ShadBadge.secondary(child: Text('Waiting for Friend')),
              ShadBadge.destructive(child: Text('Wipe Pending')),
            ],
          ),
          const SizedBox(height: 16),
          Text('ShadInput:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ShadInput(
            placeholder: Text('Enter optional room name...'),
          ),
          const SizedBox(height: 16),
          Text('Interactive Modals & Triggers:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Trigger Wipe Dialog',
                icon: Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                variant: GhostButtonVariant.destructive,
                onPressed: () => _showWipeConfirmDialog(context),
              ),
              GhostButton(
                label: 'Open Attach Sheet',
                icon: Icon(LucideIcons.paperclip, size: 16),
                variant: GhostButtonVariant.secondary,
                onPressed: () => _showAttachSheet(context),
              ),
              GhostButton(
                label: 'Show Toast',
                icon: Icon(LucideIcons.bell, size: 16),
                variant: GhostButtonVariant.outline,
                onPressed: () {
                  ShadToaster.of(context).show(
                    const ShadToast(
                      title: Text('Code Copied!'),
                      description: Text('Share this code with your friend.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInputSection(GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CodeInputField(
            key: _codeKey,
            autofocus: false,
            hasError: _codeHasError,
            errorMessage: _codeErrorMessage,
            onChanged: (val) {
              setState(() {
                _enteredCode = val;
                if (_codeHasError) {
                  _codeHasError = false;
                  _codeErrorMessage = null;
                }
              });
            },
            onCompleted: (code) {
              ShadToaster.of(context).show(
                ShadToast(
                  title: const Text('Code Complete!'),
                  description: Text('Entered security code: $code'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Current Code: ${_enteredCode.isEmpty ? "None" : _enteredCode}',
            style: AppTypography.codeMedium.copyWith(
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Paste "K7M2-9QXP"',
                icon: Icon(LucideIcons.clipboard, size: 16),
                variant: GhostButtonVariant.secondary,
                height: 38,
                onPressed: () {
                  _codeKey.currentState?.setCode('K7M29QXP');
                },
              ),
              GhostButton(
                label: 'Trigger Error Shake',
                icon: Icon(LucideIcons.alertTriangle, size: 16, color: Colors.white),
                variant: GhostButtonVariant.destructive,
                height: 38,
                onPressed: () {
                  setState(() {
                    _codeHasError = true;
                    _codeErrorMessage = 'Invalid or expired room code';
                  });
                  _codeKey.currentState?.triggerShake();
                },
              ),
              GhostButton(
                label: 'Clear',
                icon: Icon(LucideIcons.eraser, size: 16),
                variant: GhostButtonVariant.outline,
                height: 38,
                onPressed: () {
                  _codeKey.currentState?.clear();
                  setState(() {
                    _codeHasError = false;
                    _codeErrorMessage = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubblesSection(GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Received Message with swipe to reply
          ChatBubble(
            message: 'Hey! I joined with code K7M2-9QXP. Can you see this?',
            isMe: false,
            timestamp: '10:42 AM',
            onSwipeReply: () {
              setState(() {
                _repliedMessage = 'Hey! I joined with code K7M2-9QXP. Can you see this?';
              });
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(height: 6),
          // Sent Message with Delivered tick
          const ChatBubble(
            message: 'Yes! GhostConv is completely live and encrypted. Swipe right to reply.',
            isMe: true,
            timestamp: '10:43 AM',
            status: MessageDeliveryStatus.delivered,
          ),
          const SizedBox(height: 6),
          // Sent Message with Seen (teal tick)
          const ChatBubble(
            message: 'When either of us taps "End Chat", everything gets wiped permanently!',
            isMe: true,
            timestamp: '10:44 AM',
            status: MessageDeliveryStatus.seen,
          ),
          const SizedBox(height: 6),
          // Received with Reply Banner
          const ChatBubble(
            message: 'That is awesome. No servers keeping logs, no trace left behind.',
            isMe: false,
            timestamp: '10:45 AM',
            replyToAuthor: 'You',
            replyToText: 'When either of us taps "End Chat", everything gets wiped permanently!',
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCardsSection() {
    return Column(
      children: [
        RoomCard(
          roomId: 'room_123',
          roomCode: 'K7M29QXP',
          roomName: 'Confidential Sync',
          partnerName: 'Sarah Connor',
          lastMessage: 'When either of us taps End Chat, everything gets wiped.',
          lastMessageTime: '10:44 AM',
          unreadCount: 2,
          status: RoomStatus.active,
          onTap: () {
            ShadToaster.of(context).show(
              const ShadToast(title: Text('Opened Active Room')),
            );
          },
        ),
        RoomCard(
          roomId: 'room_456',
          roomCode: 'W8P42YTR',
          roomName: 'Design Sprint',
          status: RoomStatus.waiting,
          onTap: () {
            ShadToaster.of(context).show(
              const ShadToast(title: Text('Opened Waiting Room (Pulsing)')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMediaAndProgressSection(GhostConvColors colors) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Progress Bubble:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          UploadProgressBubble(
            fileName: 'confidential_brief.pdf',
            progress: _uploadProgress,
            status: UploadStatus.uploading,
            onCancel: () {
              ShadToaster.of(context).show(
                const ShadToast.destructive(title: Text('Upload Cancelled')),
              );
            },
          ),
          const SizedBox(height: 8),
          Slider(
            value: _uploadProgress,
            min: 0.0,
            max: 1.0,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _uploadProgress = val),
          ),
          const SizedBox(height: 12),
          Text('Document Attachment Tile:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const MediaGrid(
            item: MediaAttachmentItem(
              type: MediaType.file,
              fileName: 'architecture_diagram.pdf',
              fileSize: 4823400, // ~4.6 MB
            ),
          ),
          const SizedBox(height: 12),
          Text('Video Preview with Overlay:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const MediaGrid(
            item: MediaAttachmentItem(
              type: MediaType.video,
              durationSeconds: 142,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1.5-second Press-and-Hold Button for Wipe Confirmation
class _WipeHoldConfirmButton extends StatefulWidget {
  const _WipeHoldConfirmButton({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_WipeHoldConfirmButton> createState() => _WipeHoldConfirmButtonState();
}

class _WipeHoldConfirmButtonState extends State<_WipeHoldConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: AppConstants.wipeHoldDuration,
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.mediumImpact();
    _holdController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
    }
  }

  void _onTapCancel() {
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final progress = _holdController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                width: 170,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(40),
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
                  Icon(LucideIcons.flame, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    progress > 0.05
                        ? 'Holding (${(progress * 100).toInt()}%)'
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
