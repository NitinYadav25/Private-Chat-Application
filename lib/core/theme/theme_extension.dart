import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

@immutable
class GhostConvColors extends ThemeExtension<GhostConvColors> {
  const GhostConvColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.sentBubbleGradient,
    required this.receivedBubble,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glowShadow,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final LinearGradient sentBubbleGradient;
  final Color receivedBubble;
  final Color success;
  final Color warning;
  final Color danger;
  final List<BoxShadow> glowShadow;
  final bool isDark;

  static const dark = GhostConvColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    elevated: AppColors.darkElevated,
    border: AppColors.darkBorder,
    text: AppColors.darkText,
    muted: AppColors.darkMuted,
    accent: AppColors.accent,
    sentBubbleGradient: AppColors.sentBubbleGradient,
    receivedBubble: AppColors.darkReceivedBubble,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    glowShadow: AppColors.darkGlowShadow,
    isDark: true,
  );

  static const light = GhostConvColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    elevated: AppColors.lightElevated,
    border: AppColors.lightBorder,
    text: AppColors.lightText,
    muted: AppColors.lightMuted,
    accent: AppColors.accent,
    sentBubbleGradient: AppColors.sentBubbleGradient,
    receivedBubble: AppColors.lightReceivedBubble,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    glowShadow: [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 12,
        spreadRadius: 0,
        offset: Offset(0, 3),
      ),
    ],
    isDark: false,
  );

  @override
  ThemeExtension<GhostConvColors> copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    LinearGradient? sentBubbleGradient,
    Color? receivedBubble,
    Color? success,
    Color? warning,
    Color? danger,
    List<BoxShadow>? glowShadow,
    bool? isDark,
  }) {
    return GhostConvColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      sentBubbleGradient: sentBubbleGradient ?? this.sentBubbleGradient,
      receivedBubble: receivedBubble ?? this.receivedBubble,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      glowShadow: glowShadow ?? this.glowShadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  ThemeExtension<GhostConvColors> lerp(
    covariant ThemeExtension<GhostConvColors>? other,
    double t,
  ) {
    if (other is! GhostConvColors) {
      return this;
    }
    return GhostConvColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      elevated: Color.lerp(elevated, other.elevated, t) ?? elevated,
      border: Color.lerp(border, other.border, t) ?? border,
      text: Color.lerp(text, other.text, t) ?? text,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      sentBubbleGradient: LinearGradient.lerp(sentBubbleGradient, other.sentBubbleGradient, t) ?? sentBubbleGradient,
      receivedBubble: Color.lerp(receivedBubble, other.receivedBubble, t) ?? receivedBubble,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      glowShadow: t < 0.5 ? glowShadow : other.glowShadow,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension GhostConvThemeContext on BuildContext {
  GhostConvColors get ghostColors =>
      Theme.of(this).extension<GhostConvColors>() ?? GhostConvColors.dark;
}

