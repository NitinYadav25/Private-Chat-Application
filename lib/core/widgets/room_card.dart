import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

enum RoomStatus {
  waiting,
  active,
  ended,
}

class RoomCard extends StatefulWidget {
  const RoomCard({
    super.key,
    required this.roomId,
    required this.roomCode,
    this.roomName,
    this.partnerName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.status = RoomStatus.active,
    this.onTap,
  });

  final String roomId;
  final String roomCode;
  final String? roomName;
  final String? partnerName;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final RoomStatus status;
  final VoidCallback? onTap;

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final isWaiting = widget.status == RoomStatus.waiting;
    final displayName = widget.roomName ?? widget.partnerName ?? 'Room ${widget.roomCode}';

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: AppConstants.durationFast,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(
              color: isWaiting ? AppColors.primary.withAlpha(120) : colors.border,
            ),
            boxShadow: colors.isDark && isWaiting ? AppColors.darkGlowShadow : null,
          ),
          child: Row(
            children: [
              // Avatar or Status Pulse
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isWaiting ? null : AppColors.sentBubbleGradient,
                      color: isWaiting ? colors.elevated : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Center(
                      child: isWaiting
                          ? const Icon(LucideIcons.userPlus, size: 22, color: AppColors.primary)
                          : Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (isWaiting)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 1200.ms)
                          .fadeOut(duration: 1200.ms),
                    ),
                ],
              ),

              const SizedBox(width: AppConstants.space16),

              // Title, Last Message or Waiting status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.lastMessageTime != null)
                          Text(
                            widget.lastMessageTime!,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.muted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isWaiting) ...[
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Waiting for your friend to join...',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        widget.lastMessage ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: widget.unreadCount > 0 ? colors.text : colors.muted,
                          fontWeight: widget.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Unread Badge
              if (widget.unreadCount > 0) ...[
                const SizedBox(width: AppConstants.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.sentBubbleGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

