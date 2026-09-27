class Bosqich {
  final String id;
  final String name; // Masalan: "1-bosqich", "2-bosqich"
  final int levelNumber; // 1, 2

  Bosqich({
    required this.id,
    required this.name,
    required this.levelNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'levelNumber': levelNumber,
    };
  }

  factory Bosqich.fromMap(Map<String, dynamic> map) {
    return Bosqich(
      id: map['id'] as String,
      name: map['name'] as String,
      levelNumber: (map['levelNumber'] as num).toInt(),
    );
  }

  Bosqich copyWith({
    String? id,
    String? name,
    int? levelNumber,
  }) {
    return Bosqich(
      id: id ?? this.id,
      name: name ?? this.name,
      levelNumber: levelNumber ?? this.levelNumber,
    );
  }
}
