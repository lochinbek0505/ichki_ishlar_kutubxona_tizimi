import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/book_issue_model.dart';
import '../models/book_model.dart';
import '../models/book_type_model.dart';
import '../models/bosqich.dart';
import '../models/genre_model.dart';
import '../models/guruh.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported for local FFI sqlite');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'litsey_kutubxona.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS janrlar (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
          await db.execute('CREATE TABLE IF NOT EXISTS turlar (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
        }
        if (oldVersion < 3) {
          await _createAdminTable(db);
          // Avvalgi versiyalardagi demo (namuna) yozuvlarni o'chiramiz
          await db.delete('book_issues', where: "id IN ('iss_001','iss_002','iss_003','iss_004')");
          await db.delete('books', where: "id IN ('bk_001','bk_002','bk_003','bk_004','bk_005')");
          await db.delete('users', where: "id IN ('usr_001','usr_002','usr_003','usr_004','usr_005')");
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bosqichlar (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        levelNumber INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE guruhlar (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bosqichId TEXT NOT NULL,
        bosqichName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE janrlar (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE turlar (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        username TEXT,
        role TEXT,
        bosqichId TEXT,
        bosqichName TEXT,
        guruhId TEXT,
        guruhName TEXT,
        phone TEXT,
        readerCardId TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        totalCopies INTEGER NOT NULL,
        availableCopies INTEGER NOT NULL,
        publishedYear INTEGER NOT NULL,
        publisher TEXT,
        locationRack TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE book_issues (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        bookTitle TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userGroup TEXT,
        userStage TEXT,
        issueDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        returnDate TEXT,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await _createAdminTable(db);
    await _seedInitialData(db);
  }

  Future<void> _createAdminTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS admin (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        username TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        salt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Bosqichlar
    final bosqichlar = [
      Bosqich(id: 'b_1', name: '1-bosqich (1-kurs)', levelNumber: 1),
      Bosqich(id: 'b_2', name: '2-bosqich (2-kurs)', levelNumber: 2),
    ];
    for (var b in bosqichlar) {
      await db.insert('bosqichlar', b.toMap());
    }

    // 2. Guruhlar
    final guruhlar = [
      Guruh(id: 'g_101', name: '101-guruh', bosqichId: 'b_1', bosqichName: '1-bosqich (1-kurs)'),
      Guruh(id: 'g_102', name: '102-guruh', bosqichId: 'b_1', bosqichName: '1-bosqich (1-kurs)'),
      Guruh(id: 'g_201', name: '201-guruh', bosqichId: 'b_2', bosqichName: '2-bosqich (2-kurs)'),
      Guruh(id: 'g_202', name: '202-guruh', bosqichId: 'b_2', bosqichName: '2-bosqich (2-kurs)'),
    ];
    for (var g in guruhlar) {
      await db.insert('guruhlar', g.toMap());
    }

    // 3. Janrlar
    final janrlar = [
      GenreModel(id: 'j_1', name: 'Huquqshunoslik'),
      GenreModel(id: 'j_2', name: 'Taktik / Harbiy'),
      GenreModel(id: 'j_3', name: 'Axborot Texnologiyalari'),
      GenreModel(id: 'j_4', name: 'Badiiy Adabiyot'),
      GenreModel(id: 'j_5', name: 'Tarix / Jamiyat'),
    ];
    for (var j in janrlar) {
      await db.insert('janrlar', j.toMap());
    }

    // 4. Kitob Turlari
    final turlar = [
      BookTypeModel(id: 't_1', name: 'Darslik'),
      BookTypeModel(id: 't_2', name: 'O\'quv-uslubiy qo\'llanma'),
      BookTypeModel(id: 't_3', name: 'Badiiy adabiyot'),
      BookTypeModel(id: 't_4', name: 'Lug\'at'),
    ];
    for (var t in turlar) {
      await db.insert('turlar', t.toMap());
    }
  }

  // --- ADMIN (LOGIN / PAROL) ---
  Future<Map<String, dynamic>?> getAdmin() async {
    final db = await database;
    final rows = await db.query('admin', where: 'id = 1');
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveAdmin({required String username, required String passwordHash, required String salt}) async {
    final db = await database;
    await db.insert(
      'admin',
      {'id': 1, 'username': username, 'passwordHash': passwordHash, 'salt': salt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- BOSQICHLAR CRUD ---
  Future<List<Bosqich>> getBosqichlar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bosqichlar', orderBy: 'levelNumber ASC');
    return maps.map((e) => Bosqich.fromMap(e)).toList();
  }

  Future<void> insertBosqich(Bosqich bosqich) async {
    final db = await database;
    await db.insert('bosqichlar', bosqich.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Bosqich nomi kursantlar va guruhlar jadvalida ham saqlangani uchun birga yangilanadi
  Future<void> updateBosqich(Bosqich bosqich) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('bosqichlar', bosqich.toMap(), where: 'id = ?', whereArgs: [bosqich.id]);
      await txn.update('guruhlar', {'bosqichName': bosqich.name}, where: 'bosqichId = ?', whereArgs: [bosqich.id]);
      await txn.update('users', {'bosqichName': bosqich.name}, where: 'bosqichId = ?', whereArgs: [bosqich.id]);
    });
  }

  Future<void> deleteBosqich(String id) async {
    final db = await database;
    await db.delete('bosqichlar', where: 'id = ?', whereArgs: [id]);
  }

  // --- GURUHLAR CRUD ---
  Future<List<Guruh>> getGuruhlar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('guruhlar', orderBy: 'name ASC');
    return maps.map((e) => Guruh.fromMap(e)).toList();
  }

  Future<void> insertGuruh(Guruh guruh) async {
    final db = await database;
    await db.insert('guruhlar', guruh.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Guruh nomi/bosqichi o'zgarsa, unga biriktirilgan kursantlar ham yangilanadi
  Future<void> updateGuruh(Guruh guruh) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('guruhlar', guruh.toMap(), where: 'id = ?', whereArgs: [guruh.id]);
      await txn.update(
        'users',
        {'guruhName': guruh.name, 'bosqichId': guruh.bosqichId, 'bosqichName': guruh.bosqichName},
        where: 'guruhId = ?',
        whereArgs: [guruh.id],
      );
    });
  }

  Future<void> deleteGuruh(String id) async {
    final db = await database;
    await db.delete('guruhlar', where: 'id = ?', whereArgs: [id]);
  }

  // --- JANRLAR (GENRES) CRUD ---
  Future<List<GenreModel>> getJanrlar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('janrlar', orderBy: 'name ASC');
    return maps.map((e) => GenreModel.fromMap(e)).toList();
  }

  Future<void> insertJanr(GenreModel genre) async {
    final db = await database;
    await db.insert('janrlar', genre.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteJanr(String id) async {
    final db = await database;
    await db.delete('janrlar', where: 'id = ?', whereArgs: [id]);
  }

  // --- TURLAR (BOOK TYPES) CRUD ---
  Future<List<BookTypeModel>> getTurlar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('turlar', orderBy: 'name ASC');
    return maps.map((e) => BookTypeModel.fromMap(e)).toList();
  }

  Future<void> insertTur(BookTypeModel type) async {
    final db = await database;
    await db.insert('turlar', type.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTur(String id) async {
    final db = await database;
    await db.delete('turlar', where: 'id = ?', whereArgs: [id]);
  }

  // --- USERS CRUD (STRICTLY ALPHABETICAL BY FULLNAME) ---
  Future<List<UserModel>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'fullName ASC');
    return maps.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- BOOKS CRUD ---
  Future<List<BookModel>> getBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'title ASC');
    return maps.map((e) => BookModel.fromMap(e)).toList();
  }

  Future<void> insertBook(BookModel book) async {
    final db = await database;
    await db.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBook(BookModel book) async {
    final db = await database;
    await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// Ko'p kitoblarni bitta tranzaksiyada qo'shish/yangilash (Excel import uchun)
  Future<void> upsertBooks(List<BookModel> books) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final book in books) {
        batch.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  // --- BOOK ISSUES CRUD ---
  Future<List<BookIssueModel>> getBookIssues() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('book_issues', orderBy: 'issueDate DESC');
    return maps.map((e) => BookIssueModel.fromMap(e)).toList();
  }

  Future<void> insertBookIssue(BookIssueModel issue) async {
    final db = await database;
    await db.insert('book_issues', issue.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Book available copies kamaytirish
    final books = await db.query('books', where: 'id = ?', whereArgs: [issue.bookId]);
    if (books.isNotEmpty) {
      final book = BookModel.fromMap(books.first);
      final newAvailable = (book.availableCopies - 1).clamp(0, book.totalCopies);
      await db.update(
        'books',
        {'availableCopies': newAvailable},
        where: 'id = ?',
        whereArgs: [issue.bookId],
      );
    }
  }

  Future<void> returnBookIssue(String issueId, String returnDate, {String? notes}) async {
    final db = await database;
    final issues = await db.query('book_issues', where: 'id = ?', whereArgs: [issueId]);
    if (issues.isNotEmpty) {
      final issue = BookIssueModel.fromMap(issues.first);
      await db.update(
        'book_issues',
        {
          'returnDate': returnDate,
          'status': 'RETURNED',
          if (notes != null) 'notes': notes,
        },
        where: 'id = ?',
        whereArgs: [issueId],
      );

      // Book available copies ko'paytirish
      final books = await db.query('books', where: 'id = ?', whereArgs: [issue.bookId]);
      if (books.isNotEmpty) {
        final book = BookModel.fromMap(books.first);
        final newAvailable = (book.availableCopies + 1).clamp(0, book.totalCopies);
        await db.update(
          'books',
          {'availableCopies': newAvailable},
          where: 'id = ?',
          whereArgs: [issue.bookId],
        );
      }
    }
  }

  Future<void> extendDueDate(String issueId, String newDueDate) async {
    final db = await database;
    await db.update(
      'book_issues',
      {'dueDate': newDueDate},
      where: 'id = ?',
      whereArgs: [issueId],
    );
  }
}
