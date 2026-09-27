class BookTypeModel {
  final String id;
  final String name; // Masalan: "Darslik", "O'quv-uslubiy qo'llanma", "Badiiy adabiyot", "Lug'at"

  BookTypeModel({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory BookTypeModel.fromMap(Map<String, dynamic> map) {
    return BookTypeModel(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}
