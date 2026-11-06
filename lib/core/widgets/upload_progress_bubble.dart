import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

enum UploadStatus {
  uploading,
  downloading,
  completed,
  failed,
}

class UploadProgressBubble extends StatelessWidget {
  const UploadProgressBubble({
    super.key,
    required this.fileName,
    required this.progress,
    this.status = UploadStatus.uploading,
    this.onCancel,
    this.onRetry,
  });

  final String fileName;
  final double progress; // 0.0 to 1.0
  final UploadStatus status;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final isFailed = status == UploadStatus.failed;
    final percent = (progress * 100).toInt();

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppConstants.radiusBubble),
        border: Border.all(
          color: isFailed ? AppColors.danger.withAlpha(120) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFailed ? AppColors.danger.withAlpha(30) : AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isFailed ? LucideIcons.alertCircle : LucideIcons.uploadCloud,
                    color: isFailed ? AppColors.danger : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFailed
                          ? 'Upload failed'
                          : '${status == UploadStatus.uploading ? "Uploading" : "Downloading"} ($percent%)',
                      style: AppTypography.bodySmall.copyWith(
                        color: isFailed ? AppColors.danger : colors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFailed && onRetry != null) ...[
                IconButton(
                  icon: const Icon(LucideIcons.rotateCw, size: 18),
                  color: AppColors.primary,
                  onPressed: onRetry,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ] else if (onCancel != null) ...[
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: colors.muted,
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppConstants.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isFailed ? 1.0 : progress,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFailed ? AppColors.danger : AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

