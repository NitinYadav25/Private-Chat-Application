import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

class LocalCacheService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _initialized = true;
  }

  String _boxName(String roomId) => 'room_messages_$roomId';

  Future<Box<String>> _getBox(String roomId) async {
    await init();
    final name = _boxName(roomId);
    if (Hive.isBoxOpen(name)) {
      return Hive.box<String>(name);
    }
    return Hive.openBox<String>(name);
  }

  /// Caches a batch of messages for immediate cold start display
  Future<void> cacheMessages(String roomId, List<Map<String, dynamic>> messages) async {
    try {
      final box = await _getBox(roomId);
      final Map<String, String> entries = {};
      for (final msg in messages) {
        final id = msg['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString();
        entries[id] = jsonEncode(msg);
      }
      await box.putAll(entries);
    } catch (_) {}
  }

  /// Appends or updates a single message in cache
  Future<void> appendCachedMessage(String roomId, Map<String, dynamic> message) async {
    try {
      final box = await _getBox(roomId);
      final id = message['id'] as String;
      await box.put(id, jsonEncode(message));
    } catch (_) {}
  }

  /// Retrieves all cached messages sorted chronologically
  Future<List<Map<String, dynamic>>> getCachedMessages(String roomId) async {
    try {
      final box = await _getBox(roomId);
      final List<Map<String, dynamic>> list = [];
      for (final raw in box.values) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        list.add(decoded);
      }
      // Sort by createdAt ascending
      list.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Completely deletes all cached messages for a room (used during wipe)
  Future<void> clearRoomCache(String roomId) async {
    try {
      final name = _boxName(roomId);
      if (Hive.isBoxOpen(name)) {
        final box = Hive.box<String>(name);
        await box.clear();
        await box.close();
      }
      await Hive.deleteBoxFromDisk(name);
    } catch (_) {}
  }

  /// Deletes all cached temporary media files
  Future<void> clearLocalMedia() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Deletes all cached data across all rooms and media files
  Future<void> clearAllCache() async {
    try {
      await Hive.deleteFromDisk();
      await clearLocalMedia();
      _initialized = false;
    } catch (_) {}
  }
}
