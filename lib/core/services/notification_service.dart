import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const _prefKey = 'ghostconv_notifications_enabled';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ghostconv_messages',
    'GhostConv Messages',
    description: 'Notifications for new temporary room messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> init(String? userId) async {
    if (_initialized) return;

    // 1. Initialize local notifications for Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Notification tap handling
      },
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // 2. Initialize FCM if Firebase is active
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // ignore: deprecated_member_use
        final token = await messaging.getToken();
        if (token != null && userId != null) {
          await _updateUserToken(userId, token);
        }

        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((newToken) {
          if (userId != null) {
            _updateUserToken(userId, newToken);
          }
        });

        // Foreground messages listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          if (await isNotificationsEnabled()) {
            showNotification(
              title: message.notification?.title ?? 'New Message',
              body: message.notification?.body ?? 'Encrypted message received',
              payload: message.data['roomId'] as String?,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('NotificationService init non-fatal: $e');
    }

    _initialized = true;
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  Future<void> _updateUserToken(String userId, String token) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (_) {}
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await isNotificationsEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
