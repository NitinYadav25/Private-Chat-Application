import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../../core/widgets/media_grid.dart';
import '../../../core/widgets/message_input_bar.dart';
import '../../../core/widgets/upload_progress_bubble.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media/data/media_picker_service.dart';
import '../../media/presentation/full_image_viewer.dart';
import '../../media/presentation/video_player_modal.dart';
import '../../rooms/domain/room_model.dart';
import '../domain/message_model.dart';
import 'chat_controller.dart';
import 'chat_menu_sheet.dart';
import 'widgets/link_preview_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isFarFromBottom = (maxScroll - currentScroll) > 300;

    if (isFarFromBottom != _showScrollToBottom) {
      setState(() => _showScrollToBottom = isFarFromBottom);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AppConstants.durationNormal,
      curve: AppConstants.defaultCurve,
    );
  }

  void _showChatMenu(BuildContext context, ChatState chatState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatMenuSheet(
        roomId: widget.roomId,
        roomCode: chatState.roomCode,
        roomName: chatState.roomName,
      ),
    );
  }

  Future<void> _handleMediaSelection(
    Future<File?> Function() picker,
    MessageType type,
  ) async {
    try {
      final file = await picker();
      if (file != null) {
        await ref
            .read(chatControllerProvider(widget.roomId).notifier)
            .sendMediaMessage(file, type);
        Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Attachment Error'),
            description: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _openAttachSheet(BuildContext context) {
    final pickerService = ref.read(mediaPickerServiceProvider);

    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (sheetContext) {
        return ShadSheet(
          title: Text('Share Media & Files', style: AppTypography.titleLarge),
          description: Text(
            'Securely upload photos, videos, and documents to this temporary room',
            style: AppTypography.bodySmall,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachAction(LucideIcons.camera, 'Camera', AppColors.primary, () async {
                  Navigator.of(sheetContext).pop();
                  await _handleMediaSelection(pickerService.pickImageFromCamera, MessageType.image);
                }),
                _buildAttachAction(LucideIcons.image, 'Gallery', AppColors.secondary, () async {
                  Navigator.of(sheetContext).pop();
                  await _handleMediaSelection(pickerService.pickImageFromGallery, MessageType.image);
                }),
                _buildAttachAction(LucideIcons.video, 'Video', AppColors.accent, () async {
                  Navigator.of(sheetContext).pop();
                  await _handleMediaSelection(pickerService.pickVideo, MessageType.video);
                }),
                _buildAttachAction(LucideIcons.fileText, 'Document', AppColors.warning, () async {
                  Navigator.of(sheetContext).pop();
                  await _handleMediaSelection(pickerService.pickDocument, MessageType.file);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
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

  void _openFullImageViewer(String? url, String? title) {
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullImageViewer(imageUrl: url, title: title),
      ),
    );
  }

  void _openVideoPlayer(String? url, String? title) {
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerModal(videoUrl: url, title: title),
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final currentUserId = ref.watch(authControllerProvider).user?.id ?? '';
    final chatState = ref.watch(chatControllerProvider(widget.roomId));

    // Listen for room ended flag: if ended, automatically redirect to ChatEndedScreen
    if (chatState.roomStatus == RoomLifecycleStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/chat-ended');
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Partner Avatar with Presence Dot
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppColors.sentBubbleGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chatState.partnerName.isNotEmpty
                          ? chatState.partnerName[0].toUpperCase()
                          : 'P',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (chatState.isPartnerOnline)
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Partner Name & Typing/Online status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatState.roomName ?? chatState.partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  if (chatState.isPartnerTyping) ...[
                    Text(
                      'typing...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ] else if (chatState.isPartnerOnline) ...[
                    Text(
                      'Online',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 11,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Encrypted Room',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical),
            onPressed: () => _showChatMenu(context, chatState),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Day-grouped Messages List
                Expanded(
                  child: chatState.isLoading && chatState.messages.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : chatState.messages.isEmpty
                          ? _buildEmptyState(colors)
                          : _buildMessagesList(chatState, currentUserId, colors),
                ),

                // Message Input Bar
                MessageInputBar(
                  onSendText: (text) {
                    ref.read(chatControllerProvider(widget.roomId).notifier).sendTextMessage(text);
                    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                  },
                  onAttachPressed: () => _openAttachSheet(context),
                  onCameraPressed: () => _handleMediaSelection(
                    ref.read(mediaPickerServiceProvider).pickImageFromCamera,
                    MessageType.image,
                  ),
                  replyToAuthor: chatState.replyingTo != null
                      ? (chatState.replyingTo!.isMe(currentUserId)
                          ? 'You'
                          : chatState.partnerName)
                      : null,
                  replyToText: chatState.replyingTo?.text,
                  onCancelReply: () =>
                      ref.read(chatControllerProvider(widget.roomId).notifier).cancelReply(),
                ),
              ],
            ),

            // Floating Scroll to Bottom Button
            if (_showScrollToBottom)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: colors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _scrollToBottom,
                  child: const Icon(LucideIcons.chevronDown, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(GhostConvColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: const Center(
                child: Icon(LucideIcons.shieldCheck, size: 30, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Private Room Active',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages and media sent in this room are encrypted and ephemeral. When either of you taps "End Chat", everything will vanish permanently.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: colors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    ChatState chatState,
    String currentUserId,
    GhostConvColors colors,
  ) {
    final messages = chatState.messages;
    final List<Widget> items = [];
    String? lastDateGroup;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateGroup = msg.dateGroupKey;

      if (dateGroup != lastDateGroup) {
        lastDateGroup = dateGroup;
        items.add(_buildDateChip(dateGroup, colors));
      }

      // Check for in-flight uploading message
      if (msg.status == MessageDeliveryStatus.sending &&
          chatState.uploadProgress.containsKey(msg.id)) {
        final progress = chatState.uploadProgress[msg.id] ?? 0.05;
        items.add(
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UploadProgressBubble(
                fileName: msg.fileName ?? 'Uploading media...',
                progress: progress,
                status: UploadStatus.uploading,
                onCancel: () => ref
                    .read(chatControllerProvider(widget.roomId).notifier)
                    .cancelUpload(msg.id),
              ),
            ),
          ),
        );
        continue;
      }

      // Check for failed upload
      if (msg.status == MessageDeliveryStatus.failed) {
        items.add(
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UploadProgressBubble(
                fileName: msg.fileName ?? 'Upload failed',
                progress: 1.0,
                status: UploadStatus.failed,
                onRetry: () => ref
                    .read(chatControllerProvider(widget.roomId).notifier)
                    .retryUpload(msg.id),
                onCancel: () => ref
                    .read(chatControllerProvider(widget.roomId).notifier)
                    .removeMessage(msg.id),
              ),
            ),
          ),
        );
        continue;
      }

      // Build media attachment widget if present
      Widget? mediaWidget;
      String displayText = msg.text;

      if (msg.type == MessageType.image) {
        mediaWidget = MediaGrid(
          item: MediaAttachmentItem(
            type: MediaType.image,
            url: msg.mediaUrl,
            localPath: msg.mediaUrl,
          ),
          onTap: () => _openFullImageViewer(msg.mediaUrl, msg.fileName),
        );
        if (displayText == msg.fileName) displayText = '';
      } else if (msg.type == MessageType.video) {
        mediaWidget = MediaGrid(
          item: MediaAttachmentItem(
            type: MediaType.video,
            url: msg.mediaUrl,
            localPath: msg.mediaUrl,
            thumbnailUrl: msg.thumbnailUrl,
          ),
          onTap: () => _openVideoPlayer(msg.mediaUrl, msg.fileName),
        );
        if (displayText == msg.fileName) displayText = '';
      } else if (msg.type == MessageType.file) {
        mediaWidget = MediaGrid(
          item: MediaAttachmentItem(
            type: MediaType.file,
            url: msg.mediaUrl,
            fileName: msg.fileName,
            fileSize: msg.fileSize,
          ),
          onTap: () => _openFile(msg.mediaUrl),
        );
        displayText = '';
      }

      // Extract URL for inline link preview
      Widget? linkPreviewWidget;
      if (displayText.isNotEmpty) {
        final extractedUrl = LinkPreviewCard.extractUrl(displayText);
        if (extractedUrl != null) {
          linkPreviewWidget = LinkPreviewCard(url: extractedUrl);
        }
      }

      items.add(
        ChatBubble(
          key: ValueKey(msg.id),
          message: displayText,
          isMe: msg.isMe(currentUserId),
          timestamp: msg.formattedTime,
          status: msg.status,
          mediaWidget: mediaWidget,
          linkPreviewWidget: linkPreviewWidget,
          replyToAuthor: msg.replyTo?.authorName,
          replyToText: msg.replyTo?.text,
          onSwipeReply: () {
            HapticFeedback.lightImpact();
            ref.read(chatControllerProvider(widget.roomId).notifier).setReplyingTo(msg);
          },
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: items,
    );
  }

  Widget _buildDateChip(String dateLabel, GhostConvColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withAlpha(80)),
        ),
        child: Text(
          dateLabel,
          style: AppTypography.bodySmall.copyWith(
            color: colors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
