import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.onSendText,
    this.onAttachPressed,
    this.onCameraPressed,
    this.replyToAuthor,
    this.replyToText,
    this.onCancelReply,
    this.onVoiceNotePressed,
    this.isBlocked = false,
  });

  final ValueChanged<String> onSendText;
  final VoidCallback? onAttachPressed;
  final VoidCallback? onCameraPressed;
  final String? replyToAuthor;
  final String? replyToText;
  final VoidCallback? onCancelReply;
  final VoidCallback? onVoiceNotePressed;
  final bool isBlocked;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSendText(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withAlpha(90)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replying to banner
            if (widget.replyToAuthor != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${widget.replyToAuthor}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            widget.replyToText ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onCancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            // Input Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button (+)
                IconButton(
                  icon: const Icon(LucideIcons.paperclip, size: 22),
                  color: colors.muted,
                  onPressed: widget.isBlocked
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onAttachPressed?.call();
                        },
                ),

                // Camera button
                IconButton(
                  icon: const Icon(LucideIcons.camera, size: 22),
                  color: colors.muted,
                  onPressed: widget.isBlocked
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          widget.onCameraPressed?.call();
                        },
                ),

                // Text Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.elevated,
                      borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                      border: Border.all(color: colors.border),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !widget.isBlocked,
                      maxLines: 5,
                      minLines: 1,
                      style: AppTypography.bodyMedium.copyWith(color: colors.text),
                      decoration: InputDecoration(
                        hintText: widget.isBlocked ? 'Chat ended' : 'Type a message...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: colors.muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppConstants.space8),

                // Send or Voice Note Button
                GestureDetector(
                  onTap: widget.isBlocked
                      ? null
                      : () {
                          if (_hasText) {
                            _handleSend();
                          } else {
                            widget.onVoiceNotePressed?.call();
                          }
                        },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _hasText ? AppColors.sentBubbleGradient : null,
                      color: _hasText ? null : colors.elevated,
                      shape: BoxShape.circle,
                      boxShadow: _hasText && colors.isDark ? AppColors.darkGlowShadow : null,
                      border: _hasText ? null : Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: Icon(
                        _hasText ? LucideIcons.send : LucideIcons.mic,
                        size: 20,
                        color: _hasText ? Colors.white : colors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

