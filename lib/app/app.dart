import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import 'router/app_router.dart';

class GhostConvApp extends ConsumerWidget {
  const GhostConvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return ShadApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightShadTheme,
      darkTheme: AppTheme.darkShadTheme,
      materialThemeBuilder: (context, theme) {
        return themeMode == ThemeMode.light
            ? AppTheme.lightMaterialTheme
            : AppTheme.darkMaterialTheme;
      },
      routerConfig: router,
    );
  }
}
