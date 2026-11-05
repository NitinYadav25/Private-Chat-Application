import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FullImageViewer extends StatelessWidget {
  const FullImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
  });

  final String imageUrl;
  final String? title;

  bool get _isLocalFile =>
      imageUrl.startsWith('/') ||
      imageUrl.startsWith('file:') ||
      imageUrl.contains(Platform.pathSeparator);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(200),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title ?? 'Photo',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'Shared photo from GhostConv temporary room:\n$imageUrl',
                  subject: 'GhostConv Shared Media',
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.5,
          child: _isLocalFile
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(LucideIcons.imageOff, color: AppColors.danger, size: 48),
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total = loadingProgress.expectedTotalBytes;
                    final loaded = loadingProgress.cumulativeBytesLoaded;
                    final percent = total != null ? loaded / total : null;
                    return Center(
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(LucideIcons.imageOff, color: AppColors.danger, size: 48),
                  ),
                ),
        ),
      ),
    );
  }
}

