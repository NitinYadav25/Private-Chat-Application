import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/local_cache_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive offline cache
  try {
    await LocalCacheService().init();
  } catch (e) {
    debugPrint('Hive cache initialization non-fatal: $e');
  }

  // Initialize Firebase & notifications if configured
  try {
    await Firebase.initializeApp();
    await NotificationService().init(null);
  } catch (e) {
    debugPrint('Firebase configuration pending: $e');
  }

  // Set system UI overlay style for dark-first aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B0B14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: GhostConvApp(),
    ),
  );
}
