import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // Heading font family: Plus Jakarta Sans
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
      );

  // Body font family: Inter
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // Monospace font for security code display & verification
  static TextStyle get codeLarge => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 4.0,
      );

  static TextStyle get codeMedium => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      );

  static TextTheme createTextTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      headlineLarge: headlineLarge.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
      titleLarge: titleLarge.copyWith(color: textColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: bodySmall.copyWith(color: mutedColor),
    );
  }
}

