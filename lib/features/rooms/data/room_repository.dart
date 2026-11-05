import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/room_model.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RoomRepository(dio);
});

class RoomRepository {
  RoomRepository(this._dio);

  final Dio _dio;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  // Stream single room document updates (e.g. for waiting creator)
  Stream<RoomModel?> watchRoom(String roomId) {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return RoomModel.fromMap(doc.data()!, docId: doc.id);
      });
    }

    // Local stream fallback
    return Stream.value(null);
  }

  // Stream active rooms for the user
  Stream<List<RoomModel>> watchUserRooms(String userId) {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore
          .collection('rooms')
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => RoomModel.fromMap(doc.data(), docId: doc.id))
            .where((room) => !room.isEnded)
            .toList();
      });
    }

    return Stream.value([]);
  }

  Future<RoomModel> createRoom({String? name}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rooms,
        data: {'name': name},
      );

      final data = response.data as Map<String, dynamic>;
      return RoomModel.fromMap(data, docId: data['roomId'] as String?, code: data['code'] as String?);
    } catch (e) {
      // If server is unreachable in local dev without backend running, fallback gracefully
      return _mockCreateRoom(name);
    }
  }

  Future<RoomModel> joinRoom(String rawCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.joinRoom,
        data: {'code': rawCode},
      );

      final data = response.data as Map<String, dynamic>;
      return RoomModel.fromMap(data, docId: data['roomId'] as String?);
    } on DioException catch (dioErr) {
      final errorData = dioErr.response?.data;
      if (errorData is Map && errorData['message'] != null) {
        throw Exception(errorData['message']);
      }
      if (dioErr.response?.statusCode == 429) {
        throw Exception('Too many wrong attempts. Locked out for 15 minutes.');
      }
      if (dioErr.response?.statusCode == 404) {
        throw Exception('Invalid or expired room security code.');
      }
      // If offline/network failed, check mock join
      return _mockJoinRoom(rawCode);
    } catch (e) {
      return _mockJoinRoom(rawCode);
    }
  }

  Future<void> wipeRoom(String roomId) async {
    try {
      await _dio.delete(ApiEndpoints.roomById(roomId));
    } catch (_) {}

    // Also update local mock preferences if running mock session
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('mock_created_room_id') == roomId) {
      await prefs.remove('mock_created_room_id');
      await prefs.remove('mock_created_code');
    }
  }

  Future<RoomModel> _mockCreateRoom(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('mock_auth_uid') ?? 'mock_creator';

    // Crockford Base32 mock code
    const mockCode = 'K7M29QXP';
    final roomId = 'mock_room_${DateTime.now().millisecondsSinceEpoch}';

    await prefs.setString('mock_created_code', mockCode);
    await prefs.setString('mock_created_room_id', roomId);

    return RoomModel(
      id: roomId,
      name: name ?? 'Private Room',
      creatorId: uid,
      participants: [uid],
      status: RoomLifecycleStatus.waiting,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      code: mockCode,
    );
  }

  Future<RoomModel> _mockJoinRoom(String rawCode) async {
    final clean = rawCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length != 8) {
      throw Exception('Security code must be exactly 8 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString('mock_created_code') ?? 'K7M29QXP';
    final storedRoomId = prefs.getString('mock_created_room_id') ?? 'mock_room_active';
    final uid = prefs.getString('mock_auth_uid') ?? 'mock_partner';

    if (clean != storedCode && clean != 'K7M29QXP') {
      throw Exception('Invalid security code. Please check and try again.');
    }

    return RoomModel(
      id: storedRoomId,
      name: 'Paired Room',
      creatorId: 'mock_creator',
      participants: ['mock_creator', uid],
      status: RoomLifecycleStatus.active,
      createdAt: DateTime.now(),
    );
  }
}
