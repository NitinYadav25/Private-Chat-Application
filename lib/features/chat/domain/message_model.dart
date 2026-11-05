import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/chat_bubble.dart';

enum MessageType {
  text,
  image,
  video,
  file,
  link,
}

class ReplyMessageModel {
  const ReplyMessageModel({
    required this.id,
    required this.authorName,
    required this.text,
  });

  final String id;
  final String authorName;
  final String text;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorName': authorName,
      'text': text,
    };
  }

  factory ReplyMessageModel.fromMap(Map<String, dynamic> map) {
    return ReplyMessageModel(
      id: map['id'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'User',
      text: map['text'] as String? ?? '',
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.text,
    this.mediaUrl,
    this.mediaPublicId,
    this.resourceType,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.replyTo,
    this.status = MessageDeliveryStatus.sent,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? mediaUrl;
  final String? mediaPublicId;
  final String? resourceType;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final ReplyMessageModel? replyTo;
  final MessageDeliveryStatus status;
  final DateTime createdAt;

  bool isMe(String currentUserId) => senderId == currentUserId;

  String get formattedTime => DateFormat('h:mm a').format(createdAt);

  String get dateGroupKey {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(createdAt);
    }
  }

  MessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    MessageType? type,
    String? text,
    String? mediaUrl,
    String? mediaPublicId,
    String? resourceType,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    ReplyMessageModel? replyTo,
    MessageDeliveryStatus? status,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaPublicId: mediaPublicId ?? this.mediaPublicId,
      resourceType: resourceType ?? this.resourceType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaPublicId': mediaPublicId,
      'resourceType': resourceType,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'replyTo': replyTo?.toMap(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    MessageType parseType(String? val) {
      switch (val) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'file':
          return MessageType.file;
        case 'link':
          return MessageType.link;
        default:
          return MessageType.text;
      }
    }

    MessageDeliveryStatus parseStatus(String? val) {
      switch (val) {
        case 'sending':
          return MessageDeliveryStatus.sending;
        case 'delivered':
          return MessageDeliveryStatus.delivered;
        case 'seen':
          return MessageDeliveryStatus.seen;
        case 'failed':
          return MessageDeliveryStatus.failed;
        default:
          return MessageDeliveryStatus.sent;
      }
    }

    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageModel(
      id: (docId ?? map['id'] ?? '') as String,
      roomId: (map['roomId'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      type: parseType(map['type'] as String?),
      text: (map['text'] ?? '') as String,
      mediaUrl: map['mediaUrl'] as String?,
      mediaPublicId: map['mediaPublicId'] as String?,
      resourceType: map['resourceType'] as String?,
      fileName: map['fileName'] as String?,
      fileSize: map['fileSize'] as int?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      replyTo: map['replyTo'] != null
          ? ReplyMessageModel.fromMap(Map<String, dynamic>.from(map['replyTo'] as Map))
          : null,
      status: parseStatus(map['status'] as String?),
      createdAt: parseDate(map['createdAt']),
    );
  }
}

