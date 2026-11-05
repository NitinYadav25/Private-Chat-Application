import 'package:flutter/material.dart';

/// Design tokens for GhostConv as specified in design system.
/// Values are defined once and never hardcoded in widgets.
abstract final class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryGlow = Color(0xFF9B8CFF);
  static const Color secondary = Color(0xFF5B8CFF);
  static const Color accent = Color(0xFF22D3B7);

  // Status colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF43F5E);

  // Sent bubble gradient
  static const LinearGradient sentBubbleGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark palette
  static const Color darkBackground = Color(0xFF0B0B14);
  static const Color darkSurface = Color(0xFF14141F);
  static const Color darkElevated = Color(0xFF1C1C2B);
  static const Color darkBorder = Color(0xFF2A2A3D);
  static const Color darkText = Color(0xFFF4F4FB);
  static const Color darkMuted = Color(0xFF9A9AB5);
  static const Color darkReceivedBubble = Color(0xFF1E1E2E);

  // Light palette
  static const Color lightBackground = Color(0xFFF7F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF0F0FA);
  static const Color lightBorder = Color(0xFFE4E4F0);
  static const Color lightText = Color(0xFF12121C);
  static const Color lightMuted = Color(0xFF6B6B85);
  static const Color lightReceivedBubble = Color(0xFFEEEEF7);

  // Dark mode soft shadow tinted with primary at 15% opacity
  static const List<BoxShadow> darkGlowShadow = [
    BoxShadow(
      color: Color(0x267C5CFF), // 15% opacity primary
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  // Subtle glassmorphism border highlight
  static const Color glassHighlight = Color(0x1AFFFFFF);
}

