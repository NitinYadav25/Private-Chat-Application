import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extension.dart';

class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({
    super.key,
    required this.url,
  });

  final String url;

  static final RegExp urlRegExp = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  static String? extractUrl(String text) {
    final match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ghostColors;
    final uri = Uri.tryParse(url);
    final domain = uri?.host ?? url;

    return GestureDetector(
      onTap: _launch,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(LucideIcons.globe, size: 18, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.externalLink, size: 16, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

