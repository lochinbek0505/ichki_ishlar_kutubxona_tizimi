import 'package:flutter/material.dart';

import '../models/book_model.dart';
import '../models/book_type_model.dart';
import '../models/genre_model.dart';
import '../services/database_service.dart';
import '../services/excel_import_service.dart';

class BookProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<BookModel> _books = [];
  List<GenreModel> _genres = [];
  List<BookTypeModel> _types = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _selectedTypeFilter;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String? get selectedTypeFilter => _selectedTypeFilter;

  List<BookModel> get allBooks => _books;
  List<GenreModel> get genres => _genres;
  List<BookTypeModel> get types => _types;

  List<String> get availableCategories {
    final list = _genres.map((g) => g.name).toList();
    for (var b in _books) {
      if (!list.contains(b.category)) {
        list.add(b.category);
      }
    }
    list.sort();
    return list;
  }

  List<String> get availableTypes {
    final list = _types.map((t) => t.name).toList();
    for (var b in _books) {
      if (!list.contains(b.type)) {
        list.add(b.type);
      }
    }
    list.sort();
    return list;
  }

  List<BookModel> get books {
    return _books.where((b) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query) ||
          b.isbn.toLowerCase().contains(query);

      final matchesCategory = _selectedCategoryFilter == null || b.category == _selectedCategoryFilter;
      final matchesType = _selectedTypeFilter == null || b.type == _selectedTypeFilter;

      return matchesQuery && matchesCategory && matchesType;
    }).toList();
  }

  int get totalBooksCount => _books.fold(0, (sum, item) => sum + item.totalCopies);
  int get availableBooksCount => _books.fold(0, (sum, item) => sum + item.availableCopies);
  int get issuedBooksCount => totalBooksCount - availableBooksCount;

  BookProvider() {
    loadBooks();
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();

    _genres = await _db.getJanrlar();
    _types = await _db.getTurlar();
    _books = await _db.getBooks();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  Future<void> addBook(BookModel book) async {
    await _db.insertBook(book);
    await loadBooks();
  }

  Future<void> updateBook(BookModel book) async {
    await _db.updateBook(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _db.deleteBook(id);
    await loadBooks();
  }

  /// Excel hisobotidagi kitoblarni fondga yuklaydi.
  /// Nomi va nashr yili bir xil kitob mavjud bo'lsa, nusxalar soni yangilanadi
  /// (berilgan kitoblar hisobi saqlanib qoladi). Qaytaradi: (qo'shildi, yangilandi).
  Future<(int, int)> importBooksFromExcel(
    List<ExcelBookRow> rows, {
    required String category,
    required String type,
    required String author,
  }) async {
    String key(String title, int year) => '${title.trim().toLowerCase()}|$year';

    final existing = {for (final b in _books) key(b.title, b.publishedYear): b};

    // Faylning o'zida takrorlangan kitoblarni birlashtiramiz
    final merged = <String, ExcelBookRow>{};
    for (final row in rows) {
      final k = key(row.title, row.publishedYear);
      final prev = merged[k];
      merged[k] = prev == null
          ? row
          : ExcelBookRow(
              rowNumber: prev.rowNumber,
              title: prev.title,
              publishedYear: prev.publishedYear,
              copies: prev.copies + row.copies,
              sum: prev.sum + row.sum,
            );
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final toSave = <BookModel>[];
    var added = 0, updated = 0;
    var i = 0;
    for (final entry in merged.entries) {
      final row = entry.value;
      final old = existing[entry.key];
      if (old != null) {
        final issued = old.totalCopies - old.availableCopies;
        toSave.add(old.copyWith(
          totalCopies: row.copies,
          availableCopies: (row.copies - issued).clamp(0, row.copies),
        ));
        updated++;
      } else {
        toSave.add(BookModel(
          id: 'bk_xl_${ts}_${i++}',
          title: row.title,
          author: author,
          isbn: 'INV-${row.rowNumber}',
          category: category,
          type: type,
          totalCopies: row.copies,
          availableCopies: row.copies,
          publishedYear: row.publishedYear,
        ));
        added++;
      }
    }

    await _db.upsertBooks(toSave);
    await loadBooks();
    return (added, updated);
  }

  // --- JANRLAR CRUD ---
  Future<void> addGenre(String name) async {
    final newGenre = GenreModel(id: 'j_${DateTime.now().millisecondsSinceEpoch}', name: name);
    await _db.insertJanr(newGenre);
    await loadBooks();
  }

  Future<void> deleteGenre(String id) async {
    await _db.deleteJanr(id);
    await loadBooks();
  }

  // --- TURLAR CRUD ---
  Future<void> addBookType(String name) async {
    final newType = BookTypeModel(id: 't_${DateTime.now().millisecondsSinceEpoch}', name: name);
    await _db.insertTur(newType);
    await loadBooks();
  }

  Future<void> deleteBookType(String id) async {
    await _db.deleteTur(id);
    await loadBooks();
  }
}
