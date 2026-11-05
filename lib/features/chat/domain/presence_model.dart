import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceModel {
  const PresenceModel({
    required this.userId,
    this.isOnline = false,
    this.isTyping = false,
    required this.lastSeen,
  });

  final String userId;
  final bool isOnline;
  final bool isTyping;
  final DateTime lastSeen;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isOnline': isOnline,
      'isTyping': isTyping,
      'lastSeen': FieldValue.serverTimestamp(),
    };
  }

  factory PresenceModel.fromMap(Map<String, dynamic> map, {String? userId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PresenceModel(
      userId: userId ?? (map['userId'] as String? ?? ''),
      isOnline: map['isOnline'] as bool? ?? false,
      isTyping: map['isTyping'] as bool? ?? false,
      lastSeen: parseDate(map['lastSeen']),
    );
  }
}

