class GenreModel {
  final String id;
  final String name; // Masalan: "Huquqshunoslik", "Taktik / Harbiy", "Axborot Texnologiyalari"

  GenreModel({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory GenreModel.fromMap(Map<String, dynamic> map) {
    return GenreModel(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}
