import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'app_typography.dart';
import 'theme_extension.dart';

abstract final class AppTheme {
  // Dark ShadColorScheme
  static const ShadColorScheme darkColorScheme = ShadColorScheme(
    background: AppColors.darkBackground,
    foreground: AppColors.darkText,
    card: AppColors.darkSurface,
    cardForeground: AppColors.darkText,
    popover: AppColors.darkElevated,
    popoverForeground: AppColors.darkText,
    primary: AppColors.primary,
    primaryForeground: Color(0xFFFFFFFF),
    secondary: AppColors.darkElevated,
    secondaryForeground: AppColors.darkText,
    muted: AppColors.darkElevated,
    mutedForeground: AppColors.darkMuted,
    accent: AppColors.darkElevated,
    accentForeground: AppColors.darkText,
    destructive: AppColors.danger,
    destructiveForeground: Color(0xFFFFFFFF),
    border: AppColors.darkBorder,
    input: AppColors.darkBorder,
    ring: AppColors.primary,
    selection: AppColors.primary,
  );

  // Light ShadColorScheme
  static const ShadColorScheme lightColorScheme = ShadColorScheme(
    background: AppColors.lightBackground,
    foreground: AppColors.lightText,
    card: AppColors.lightSurface,
    cardForeground: AppColors.lightText,
    popover: AppColors.lightElevated,
    popoverForeground: AppColors.lightText,
    primary: AppColors.primary,
    primaryForeground: Color(0xFFFFFFFF),
    secondary: AppColors.lightElevated,
    secondaryForeground: AppColors.lightText,
    muted: AppColors.lightElevated,
    mutedForeground: AppColors.lightMuted,
    accent: AppColors.lightElevated,
    accentForeground: AppColors.lightText,
    destructive: AppColors.danger,
    destructiveForeground: Color(0xFFFFFFFF),
    border: AppColors.lightBorder,
    input: AppColors.lightBorder,
    ring: AppColors.primary,
    selection: AppColors.primary,
  );

  static ShadThemeData get darkShadTheme => ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        radius: BorderRadius.circular(AppConstants.radiusButton),
      );

  static ShadThemeData get lightShadTheme => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: lightColorScheme,
        radius: BorderRadius.circular(AppConstants.radiusButton),
      );

  static ThemeData get darkMaterialTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkText,
        onError: Colors.white,
      ),
      textTheme: AppTypography.createTextTheme(
        AppColors.darkText,
        AppColors.darkMuted,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        GhostConvColors.dark,
      ],
      dividerColor: AppColors.darkBorder,
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusCard)),
          side: BorderSide(color: AppColors.darkBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.darkText),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
    );
  }

  static ThemeData get lightMaterialTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightText,
        onError: Colors.white,
      ),
      textTheme: AppTypography.createTextTheme(
        AppColors.lightText,
        AppColors.lightMuted,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        GhostConvColors.light,
      ],
      dividerColor: AppColors.lightBorder,
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppConstants.radiusCard)),
          side: BorderSide(color: AppColors.lightBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.lightText),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
    );
  }
}

