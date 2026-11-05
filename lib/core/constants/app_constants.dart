import 'package:flutter/material.dart';

abstract final class AppConstants {
  // App Identity
  static const String appName = 'GhostConv';
  static const String appTagline = 'Private, Ephemeral & Secure 1-to-1 Chat';

  // Room Security Code
  // Base32 Crockford alphabet excluding confusing chars (I, L, O, 1, 0)
  static const String codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int codeLength = 8;
  static const int maxWrongAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration roomCodeExpiry = Duration(hours: 24);

  // Border Radii
  static const double radiusInput = 12.0;
  static const double radiusButton = 12.0;
  static const double radiusCard = 20.0;
  static const double radiusSheet = 20.0;
  static const double radiusBubble = 18.0;
  static const double radiusBubbleTail = 6.0;

  // Spacing Grid
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Motion & Animation
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration wipeHoldDuration = Duration(milliseconds: 1500);
  static const Curve defaultCurve = Curves.easeOut;

  // Media Limits
  static const int maxFileSizeMb = 10;
  static const int maxFileSizeBytes = maxFileSizeMb * 1024 * 1024;
  static const int messagePageSize = 30;
}

