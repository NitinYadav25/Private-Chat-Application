class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    this.isEmailVerified = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? fcmToken;
  final bool isEmailVerified;
  final DateTime createdAt;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? fcmToken,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

