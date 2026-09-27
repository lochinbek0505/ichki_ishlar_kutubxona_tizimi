class UserModel {
  final String id;
  final String fullName;
  final String? bosqichId;
  final String? bosqichName;
  final String? guruhId;
  final String? guruhName;
  final String? phone;
  final String readerCardId; // Masalan: "IIL-CARD-2025-001"
  final String? imagePath; // Lokal rasm fayli yo'li
  final String createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.bosqichId,
    this.bosqichName,
    this.guruhId,
    this.guruhName,
    this.phone,
    required this.readerCardId,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': id, // Fallback for DB compatibility
      'role': 'STUDENT', // Fallback for DB compatibility
      'bosqichId': bosqichId,
      'bosqichName': bosqichName,
      'guruhId': guruhId,
      'guruhName': guruhName,
      'phone': phone,
      'readerCardId': readerCardId,
      'imagePath': imagePath,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      bosqichId: map['bosqichId'] as String?,
      bosqichName: map['bosqichName'] as String?,
      guruhId: map['guruhId'] as String?,
      guruhName: map['guruhName'] as String?,
      phone: map['phone'] as String?,
      readerCardId: map['readerCardId'] as String? ?? map['id'] as String,
      imagePath: map['imagePath'] as String?,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? bosqichId,
    String? bosqichName,
    String? guruhId,
    String? guruhName,
    String? phone,
    String? readerCardId,
    String? imagePath,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      bosqichId: bosqichId ?? this.bosqichId,
      bosqichName: bosqichName ?? this.bosqichName,
      guruhId: guruhId ?? this.guruhId,
      guruhName: guruhName ?? this.guruhName,
      phone: phone ?? this.phone,
      readerCardId: readerCardId ?? this.readerCardId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
