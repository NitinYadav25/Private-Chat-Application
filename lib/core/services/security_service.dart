import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final securityServiceProvider =
    StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier();
});

class SecurityState {
  const SecurityState({
    this.isBlockScreenshotsEnabled = true, // Default enabled for GhostConv privacy
  });

  final bool isBlockScreenshotsEnabled;

  SecurityState copyWith({bool? isBlockScreenshotsEnabled}) {
    return SecurityState(
      isBlockScreenshotsEnabled:
          isBlockScreenshotsEnabled ?? this.isBlockScreenshotsEnabled,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(const SecurityState()) {
    _init();
  }

  static const _channel = MethodChannel('com.ghostconv.ghostconv/security');
  static const _prefKey = 'ghostconv_block_screenshots';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKey) ?? true;
    state = state.copyWith(isBlockScreenshotsEnabled: enabled);
    _applyFlagSecure(enabled);
  }

  Future<void> toggleBlockScreenshots(bool enabled) async {
    state = state.copyWith(isBlockScreenshotsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    await _applyFlagSecure(enabled);
  }

  Future<void> _applyFlagSecure(bool enabled) async {
    try {
      await _channel.invokeMethod('setBlockScreenshots', {'enabled': enabled});
    } catch (_) {
      // Graceful fallback for non-Android platforms / widget tests
    }
  }
}

