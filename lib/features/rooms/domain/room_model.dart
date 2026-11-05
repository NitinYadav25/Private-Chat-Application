import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomLifecycleStatus {
  waiting,
  active,
  ended,
}

class RoomModel {
  const RoomModel({
    required this.id,
    this.name,
    required this.creatorId,
    required this.participants,
    this.status = RoomLifecycleStatus.waiting,
    required this.createdAt,
    this.expiresAt,
    this.code, // Only available to creator immediately upon creation
  });

  final String id;
  final String? name;
  final String creatorId;
  final List<String> participants;
  final RoomLifecycleStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? code;

  bool get isWaiting => status == RoomLifecycleStatus.waiting;
  bool get isActive => status == RoomLifecycleStatus.active;
  bool get isEnded => status == RoomLifecycleStatus.ended;

  String? getPartnerId(String currentUserId) {
    for (final p in participants) {
      if (p != currentUserId) return p;
    }
    return null;
  }

  String get formattedCode {
    if (code == null || code!.length != 8) return code ?? '';
    return '${code!.substring(0, 4)}-${code!.substring(4)}';
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? creatorId,
    List<String>? participants,
    RoomLifecycleStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? code,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': id,
      'name': name,
      'creatorId': creatorId,
      'participants': participants,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, {String? docId, String? code}) {
    RoomLifecycleStatus parseStatus(String? val) {
      switch (val) {
        case 'active':
          return RoomLifecycleStatus.active;
        case 'ended':
          return RoomLifecycleStatus.ended;
        default:
          return RoomLifecycleStatus.waiting;
      }
    }

    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic date) {
      if (date == null) return null;
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    return RoomModel(
      id: (docId ?? map['roomId'] ?? map['id'] ?? '') as String,
      name: map['name'] as String?,
      creatorId: (map['creatorId'] ?? '') as String,
      participants: List<String>.from(map['participants'] as List? ?? []),
      status: parseStatus(map['status'] as String?),
      createdAt: parseDate(map['createdAt']),
      expiresAt: parseNullableDate(map['expiresAt']),
      code: code ?? map['code'] as String?,
    );
  }
}

