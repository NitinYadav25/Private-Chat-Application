import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.status = MessageDeliveryStatus.sent,
    this.replyToAuthor,
    this.replyToText,
    this.mediaWidget,
    this.onTap,
    this.onLongPress,
    this.onSwipeReply,
    this.linkPreviewWidget,
  });

  final String message;
  final bool isMe;
  final String timestamp;
  final MessageDeliveryStatus status;
  final String? replyToAuthor;
  final String? replyToText;
  final Widget? mediaWidget;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final Widget? linkPreviewWidget;

  Widget _buildStatusIcon(GhostConvColors colors) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case MessageDeliveryStatus.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.white70,
        );
      case MessageDeliveryStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white70,
        );
      case MessageDeliveryStatus.seen:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: AppColors.accent, // Accent teal
        );
      case MessageDeliveryStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: AppColors.danger,
        );
    }
  }

  BorderRadius _getBorderRadius() {
    if (isMe) {
      // Sent: tail bottom-right (radius 6)
      return const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.radiusBubble),
        topRight: Radius.circular(AppConstants.radiusBubble),
        bottomLeft: Radius.circular(AppConstants.radiusBubble),
        bottomRight: Radius.circular(AppConstants.radiusBubbleTail),
      );
    } else {
      // Received: tail bottom-left (radius 6)
      return const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.radiusBubble),
        topRight: Radius.circular(AppConstants.radiusBubble),
        bottomLeft: Radius.circular(AppConstants.radiusBubbleTail),
        bottomRight: Radius.circular(AppConstants.radiusBubble),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    final bubble = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.sentBubbleGradient : null,
          color: isMe ? null : colors.receivedBubble,
          borderRadius: _getBorderRadius(),
          boxShadow: isMe && colors.isDark ? AppColors.darkGlowShadow : null,
          border: isMe ? null : Border.all(color: colors.border.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply quote preview banner
            if (replyToAuthor != null && replyToText != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.black.withAlpha(40)
                      : colors.surface.withAlpha(180),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: isMe ? Colors.white : AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyToAuthor!,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      replyToText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isMe ? Colors.white.withAlpha(200) : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Optional media attachment widget
            if (mediaWidget != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: mediaWidget!,
              ),
              if (message.isNotEmpty) const SizedBox(height: 6),
            ],

            // Text message
            if (message.isNotEmpty)
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMe ? Colors.white : colors.text,
                  height: 1.35,
                ),
              ),

            // Optional link preview widget
            if (linkPreviewWidget != null) ...[
              const SizedBox(height: 6),
              linkPreviewWidget!,
            ],

            const SizedBox(height: 4),

            // Timestamp and delivery status
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Text(
                  timestamp,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: isMe ? Colors.white.withAlpha(180) : colors.muted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(colors),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    // Micro-animation: animate in with fade and slight scale
    final animatedBubble = bubble
        .animate()
        .fadeIn(duration: AppConstants.durationFast, curve: AppConstants.defaultCurve)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.0, 1.0),
          duration: AppConstants.durationFast,
          curve: AppConstants.defaultCurve,
        );

    final alignedBubble = Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: animatedBubble,
      ),
    );

    if (onSwipeReply != null) {
      return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          onSwipeReply?.call();
          return false;
        },
        background: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.reply, color: AppColors.primary, size: 24),
          ),
        ),
        child: alignedBubble,
      );
    }

    return alignedBubble;
  }
}

