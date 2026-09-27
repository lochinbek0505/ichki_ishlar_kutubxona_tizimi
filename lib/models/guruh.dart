class Guruh {
  final String id;
  final String name; // Masalan: "101-guruh", "102-guruh", "201-guruh"
  final String bosqichId; // Qaysi bosqichga tegishliligi
  final String? bosqichName;

  Guruh({
    required this.id,
    required this.name,
    required this.bosqichId,
    this.bosqichName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bosqichId': bosqichId,
      if (bosqichName != null) 'bosqichName': bosqichName,
    };
  }

  factory Guruh.fromMap(Map<String, dynamic> map) {
    return Guruh(
      id: map['id'] as String,
      name: map['name'] as String,
      bosqichId: map['bosqichId'] as String,
      bosqichName: map['bosqichName'] as String?,
    );
  }

  Guruh copyWith({
    String? id,
    String? name,
    String? bosqichId,
    String? bosqichName,
  }) {
    return Guruh(
      id: id ?? this.id,
      name: name ?? this.name,
      bosqichId: bosqichId ?? this.bosqichId,
      bosqichName: bosqichName ?? this.bosqichName,
    );
  }
}
