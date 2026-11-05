import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../domain/message_model.dart';
import '../domain/presence_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final cacheService = ref.watch(localCacheServiceProvider);
  return ChatRepository(cacheService);
});

class ChatRepository {
  ChatRepository(this._cacheService);

  final LocalCacheService _cacheService;

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Loads cached messages instantly from local Hive cache for 0-latency cold start
  Future<List<MessageModel>> loadCachedMessages(String roomId) async {
    final cached = await _cacheService.getCachedMessages(roomId);
    return cached.map((map) => MessageModel.fromMap(map)).toList();
  }

  /// Listens to real-time messages in the room subcollection
  Stream<List<MessageModel>> watchMessages(String roomId, {int limit = 30}) {
    final firestore = _firestore;
    if (firestore != null) {
      return firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limitToLast(limit)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data(), docId: doc.id);
        }).toList();

        // Save batch to local cache asynchronously
        _cacheService.cacheMessages(
          roomId,
          messages.map((m) => m.toMap()).toList(),
        );

        return messages;
      });
    }

    // Fallback: poll or stream from local cache
    return Stream.fromFuture(loadCachedMessages(roomId));
  }

  /// Sends a new message to the room
  Future<void> sendMessage(MessageModel message) async {
    final firestore = _firestore;
    final map = message.toMap();

    // Cache locally immediately (optimistic UI)
    await _cacheService.appendCachedMessage(message.roomId, map);

    if (firestore != null) {
      final docRef = firestore
          .collection('rooms')
          .doc(message.roomId)
          .collection('messages')
          .doc(message.id);

      final dataToSave = Map<String, dynamic>.from(map);
      dataToSave['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(dataToSave);
    }
  }

  /// Marks all incoming unread messages as 'seen'
  Future<void> markMessagesSeen(String roomId, String currentUserId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final snapshot = await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('status', isNotEqualTo: MessageDeliveryStatus.seen.name)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': MessageDeliveryStatus.seen.name});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Updates typing status and online presence in Firestore
  Future<void> updatePresence(
    String roomId,
    String userId, {
    required bool isOnline,
    required bool isTyping,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('rooms')
          .doc(roomId)
          .collection('presence')
          .doc(userId)
          .set({
        'userId': userId,
        'isOnline': isOnline,
        'isTyping': isTyping,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Watches presence and typing status of partner
  Stream<PresenceModel?> watchPresence(String roomId, String partnerId) {
    final firestore = _firestore;
    if (firestore != null && partnerId.isNotEmpty) {
      return firestore
          .collection('rooms')
          .doc(roomId)
          .collection('presence')
          .doc(partnerId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return PresenceModel.fromMap(doc.data()!, userId: partnerId);
      });
    }

    return Stream.value(null);
  }

  /// Irreversibly clears all local messages and temporary media for this room
  Future<void> clearRoomData(String roomId) async {
    await _cacheService.clearRoomCache(roomId);
    await _cacheService.clearLocalMedia();
  }
}
