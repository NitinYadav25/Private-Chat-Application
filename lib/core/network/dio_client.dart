import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          String? token;

          if (Firebase.apps.isNotEmpty) {
            token = await FirebaseAuth.instance.currentUser?.getIdToken();
          }

          if (token == null) {
            // Local fallback token for dev mode
            final prefs = await SharedPreferences.getInstance();
            final mockUid = prefs.getString('mock_auth_uid') ?? 'mock_guest';
            token = 'mock_$mockUid';
          }

          options.headers['Authorization'] = 'Bearer $token';
        } catch (_) {}

        return handler.next(options);
      },
    ),
  );

  return dio;
});

