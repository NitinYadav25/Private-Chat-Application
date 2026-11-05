import 'package:flutter_test/flutter_test.dart';
import 'package:ghostconv/core/widgets/chat_bubble.dart';
import 'package:ghostconv/features/chat/domain/message_model.dart';
import 'package:ghostconv/features/chat/domain/presence_model.dart';

void main() {
  group('MessageModel Tests', () {
    test('Formats date and timestamp correctly', () {
      final now = DateTime.now();
      final msg = MessageModel(
        id: 'msg_1',
        roomId: 'room_1',
        senderId: 'user_a',
        type: MessageType.text,
        text: 'Encrypted message on GhostConv',
        status: MessageDeliveryStatus.seen,
        createdAt: now,
      );

      expect(msg.isMe('user_a'), isTrue);
      expect(msg.isMe('user_b'), isFalse);
      expect(msg.dateGroupKey, 'Today');
      expect(msg.status, MessageDeliveryStatus.seen);
    });

    test('Yesterday date grouping formats correctly', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final msg = MessageModel(
        id: 'msg_2',
        roomId: 'room_1',
        senderId: 'user_b',
        type: MessageType.text,
        text: 'Previous day message',
        createdAt: yesterday,
      );

      expect(msg.dateGroupKey, 'Yesterday');
    });

    test('Serialization to/from Map with reply quotation', () {
      final now = DateTime.now();
      final msg = MessageModel(
        id: 'msg_3',
        roomId: 'room_1',
        senderId: 'user_a',
        type: MessageType.text,
        text: 'Replying to your point',
        replyTo: const ReplyMessageModel(
          id: 'msg_2',
          authorName: 'Sarah Connor',
          text: 'Previous day message',
        ),
        createdAt: now,
      );

      final map = msg.toMap();
      final restored = MessageModel.fromMap(map);

      expect(restored.id, 'msg_3');
      expect(restored.text, 'Replying to your point');
      expect(restored.replyTo, isNotNull);
      expect(restored.replyTo!.authorName, 'Sarah Connor');
      expect(restored.replyTo!.text, 'Previous day message');
    });
  });

  group('PresenceModel Tests', () {
    test('Encodes and decodes presence correctly', () {
      final now = DateTime.now();
      final presence = PresenceModel(
        userId: 'user_a',
        isOnline: true,
        isTyping: true,
        lastSeen: now,
      );

      expect(presence.isOnline, isTrue);
      expect(presence.isTyping, isTrue);
      expect(presence.userId, 'user_a');
    });
  });
}

