import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/features/rooms/domain/room_model.dart';

void main() {
  group('RoomModel Tests', () {
    test('Formatted code displays with hyphen XXXX-XXXX', () {
      final room = RoomModel(
        id: 'test_room_1',
        creatorId: 'user_a',
        participants: ['user_a'],
        code: 'K7M29QXP',
        status: RoomLifecycleStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(room.formattedCode, 'K7M2-9QXP');
      expect(room.isWaiting, isTrue);
      expect(room.isActive, isFalse);
      expect(room.isEnded, isFalse);
    });

    test('getPartnerId identifies the other participant correctly', () {
      final room = RoomModel(
        id: 'test_room_2',
        creatorId: 'user_a',
        participants: ['user_a', 'user_b'],
        status: RoomLifecycleStatus.active,
        createdAt: DateTime.now(),
      );

      expect(room.isActive, isTrue);
      expect(room.getPartnerId('user_a'), 'user_b');
      expect(room.getPartnerId('user_b'), 'user_a');
      expect(room.getPartnerId('stranger'), 'user_a');
    });

    test('Serialization to/from Map preserves state', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(hours: 24));

      final room = RoomModel(
        id: 'room_100',
        name: 'Secret Mission',
        creatorId: 'user_agent_1',
        participants: ['user_agent_1'],
        status: RoomLifecycleStatus.waiting,
        createdAt: now,
        expiresAt: expires,
        code: 'W8P42YTR',
      );

      final map = room.toMap();
      final restored = RoomModel.fromMap(map, code: room.code);

      expect(restored.id, room.id);
      expect(restored.name, 'Secret Mission');
      expect(restored.creatorId, 'user_agent_1');
      expect(restored.status, RoomLifecycleStatus.waiting);
      expect(restored.formattedCode, 'W8P4-2YTR');
    });
  });
}

