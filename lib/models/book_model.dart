class BookModel {
  final String id;
  final String title;
  final String author;
  final String isbn; // ISBN / Inventar kodi
  final String category; // Janr: Badiiy, Tarixiy, Ilmiy, Taktik/Harbiy...
  final String type; // Turi: Darslik, O'quv-uslubiy qo'llanma, Badiiy adabiyot, Lug'at
  final int totalCopies; // Kutubxona fondidagi jami nusxa soni
  final int availableCopies; // Hozirda kutubxonada bor nusxa soni
  final int publishedYear;
  final String? publisher;
  final String? locationRack; // Javon kodi / joylashuvi

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.type,
    required this.totalCopies,
    required this.availableCopies,
    required this.publishedYear,
    this.publisher,
    this.locationRack,
  });

  bool get isAvailable => availableCopies > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'category': category,
      'type': type,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'publishedYear': publishedYear,
      'publisher': publisher,
      'locationRack': locationRack,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      isbn: map['isbn'] as String,
      category: map['category'] as String,
      type: map['type'] as String,
      totalCopies: (map['totalCopies'] as num).toInt(),
      availableCopies: (map['availableCopies'] as num).toInt(),
      publishedYear: (map['publishedYear'] as num).toInt(),
      publisher: map['publisher'] as String?,
      locationRack: map['locationRack'] as String?,
    );
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? category,
    String? type,
    int? totalCopies,
    int? availableCopies,
    int? publishedYear,
    String? publisher,
    String? locationRack,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      category: category ?? this.category,
      type: type ?? this.type,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      publishedYear: publishedYear ?? this.publishedYear,
      publisher: publisher ?? this.publisher,
      locationRack: locationRack ?? this.locationRack,
    );
  }
}
