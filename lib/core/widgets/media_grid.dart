import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_typography.dart';
import '../theme/theme_extension.dart';

enum MediaType {
  image,
  video,
  file,
}

class MediaAttachmentItem {
  const MediaAttachmentItem({
    required this.type,
    this.url,
    this.localPath,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.durationSeconds,
  });

  final MediaType type;
  final String? url;
  final String? localPath;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? durationSeconds;
}

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.item,
    this.onTap,
  });

  final MediaAttachmentItem item;
  final VoidCallback? onTap;

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildImageWidget(GhostConvColors colors) {
    final path = item.localPath ?? item.url;
    if (path != null && path.isNotEmpty) {
      final isLocal = path.startsWith('/') ||
          path.startsWith('file:') ||
          path.contains(Platform.pathSeparator);

      if (isLocal) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors, LucideIcons.image),
        );
      } else {
        return Image.network(
          path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: colors.elevated,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors, LucideIcons.image),
        );
      }
    }
    return _buildPlaceholder(colors, LucideIcons.image);
  }

  Widget _buildPlaceholder(GhostConvColors colors, IconData icon) {
    return Container(
      height: 180,
      color: colors.elevated,
      child: Center(
        child: Icon(icon, size: 36, color: colors.muted),
      ),
    );
  }

  Widget _buildVideoThumbnail(GhostConvColors colors) {
    final thumb = item.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      if (thumb.startsWith('http')) {
        return Image.network(
          thumb,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.black54),
        );
      } else {
        return Image.file(
          File(thumb),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.black54),
        );
      }
    }
    return Container(
      height: 180,
      color: Colors.black54,
      child: Center(
        child: Icon(LucideIcons.video, size: 40, color: colors.muted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;

    switch (item.type) {
      case MediaType.image:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 260),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(colors),
            ),
          ),
        );

      case MediaType.video:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 260),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildVideoThumbnail(colors),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                  if (item.durationSeconds != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(item.durationSeconds),
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case MediaType.file:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.fileName ?? 'Document',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(item.fileSize),
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.muted,
                        ),
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
}
