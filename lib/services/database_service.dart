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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS janrlar (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
          await db.execute('CREATE TABLE IF NOT EXISTS turlar (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
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

    await _seedInitialData(db);
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

    // 5. Kursantlar (Strictly Alphabetical)
    final users = [
      UserModel(
        id: 'usr_003',
        fullName: 'Karimov Jasur Anvarovich',
        bosqichId: 'b_1',
        bosqichName: '1-bosqich (1-kurs)',
        guruhId: 'g_102',
        guruhName: '102-guruh',
        phone: '+998 93 345-67-89',
        readerCardId: 'IIL-CARD-2025-003',
        createdAt: '2025-01-12T08:00:00.000',
      ),
      UserModel(
        id: 'usr_002',
        fullName: 'Mamasarulov Sharof Olimovich',
        bosqichId: 'b_1',
        bosqichName: '1-bosqich (1-kurs)',
        guruhId: 'g_101',
        guruhName: '101-guruh',
        phone: '+998 91 234-56-78',
        readerCardId: 'IIL-CARD-2025-002',
        createdAt: '2025-01-11T08:00:00.000',
      ),
      UserModel(
        id: 'usr_001',
        fullName: 'Narzullaev Daler Baxrullaevich',
        bosqichId: 'b_1',
        bosqichName: '1-bosqich (1-kurs)',
        guruhId: 'g_101',
        guruhName: '101-guruh',
        phone: '+998 90 123-45-67',
        readerCardId: 'IIL-CARD-2025-001',
        createdAt: '2025-01-10T08:00:00.000',
      ),
      UserModel(
        id: 'usr_004',
        fullName: 'Oripov Sardor Farxodovich',
        bosqichId: 'b_2',
        bosqichName: '2-bosqich (2-kurs)',
        guruhId: 'g_201',
        guruhName: '201-guruh',
        phone: '+998 94 456-78-90',
        readerCardId: 'IIL-CARD-2025-004',
        createdAt: '2025-01-13T08:00:00.000',
      ),
      UserModel(
        id: 'usr_005',
        fullName: 'Tursunov Alisher Rustamovich',
        bosqichId: 'b_2',
        bosqichName: '2-bosqich (2-kurs)',
        guruhId: 'g_202',
        guruhName: '202-guruh',
        phone: '+998 97 567-89-01',
        readerCardId: 'IIL-CARD-2025-101',
        createdAt: '2025-01-05T08:00:00.000',
      ),
    ];
    for (var u in users) {
      await db.insert('users', u.toMap());
    }

    // 6. Kitoblar
    final books = [
      BookModel(
        id: 'bk_001',
        title: 'O\'zbekiston Respublikasi Konstitutsiyasi va Huquq Asoslari',
        author: 'Sh.M. Mirziyoyev jamoasi',
        isbn: 'ISBN-978-9943-01-100-1',
        category: 'Huquqshunoslik',
        type: 'Darslik',
        totalCopies: 40,
        availableCopies: 37,
        publishedYear: 2024,
        publisher: 'O\'zbekiston NMIU',
        locationRack: 'A-1-01',
      ),
      BookModel(
        id: 'bk_002',
        title: 'Kriminalistika va Tergov Taktikasi Asoslari',
        author: 'Prof. A.R. Qodirov',
        isbn: 'ISBN-978-9943-01-200-2',
        category: 'Taktik / Harbiy',
        type: 'O\'quv-uslubiy qo\'llanma',
        totalCopies: 25,
        availableCopies: 22,
        publishedYear: 2023,
        publisher: 'IIV Akademiyasi Nashriyoti',
        locationRack: 'B-2-05',
      ),
      BookModel(
        id: 'bk_003',
        title: 'Informatika va Axborot Xavfsizligi Litsey Darsligi',
        author: 'T.X. Xolmatov, N.I. Tayloqov',
        isbn: 'ISBN-978-9943-01-300-3',
        category: 'Axborot Texnologiyalari',
        type: 'Darslik',
        totalCopies: 50,
        availableCopies: 48,
        publishedYear: 2024,
        publisher: 'Turon-Iqbol',
        locationRack: 'C-3-12',
      ),
      BookModel(
        id: 'bk_004',
        title: 'O\'tkan Kunlar (Tarixiy Badiiy Asar)',
        author: 'Abdulla Qodiriy',
        isbn: 'ISBN-978-9943-01-400-4',
        category: 'Badiiy Adabiyot',
        type: 'Badiiy adabiyot',
        totalCopies: 30,
        availableCopies: 27,
        publishedYear: 2022,
        publisher: 'G\'afur G\'ulom',
        locationRack: 'D-1-08',
      ),
      BookModel(
        id: 'bk_005',
        title: 'Maxsus Jismoniy va Jangovar Tayyorgarlik Qo\'llanmasi',
        author: 'Polkovnik B.S. Yusupov',
        isbn: 'ISBN-978-9943-01-500-5',
        category: 'Taktik / Harbiy',
        type: 'O\'quv-uslubiy qo\'llanma',
        totalCopies: 20,
        availableCopies: 18,
        publishedYear: 2023,
        publisher: 'IIV Litseylari Nashriyoti',
        locationRack: 'B-3-01',
      ),
    ];
    for (var bk in books) {
      await db.insert('books', bk.toMap());
    }

    // 7. Berilgan Kitoblar (Book Issues)
    final now = DateTime.now();
    String dateStr(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final issues = [
      BookIssueModel(
        id: 'iss_001',
        bookId: 'bk_001',
        bookTitle: 'O\'zbekiston Respublikasi Konstitutsiyasi va Huquq Asoslari',
        userId: 'usr_001',
        userName: 'Narzullaev Daler Baxrullaevich',
        userGroup: '101-guruh',
        userStage: '1-bosqich (1-kurs)',
        issueDate: dateStr(now.subtract(const Duration(days: 10))),
        dueDate: dateStr(now.add(const Duration(days: 5))),
        status: 'ISSUED',
        notes: 'Semesterlik o\'quv mashg\'uloti uchun',
      ),
      BookIssueModel(
        id: 'iss_002',
        bookId: 'bk_002',
        bookTitle: 'Kriminalistika va Tergov Taktikasi Asoslari',
        userId: 'usr_002',
        userName: 'Mamasarulov Sharof Olimovich',
        userGroup: '101-guruh',
        userStage: '1-bosqich (1-kurs)',
        issueDate: dateStr(now.subtract(const Duration(days: 20))),
        dueDate: dateStr(now.subtract(const Duration(days: 5))), // OVERDUE!
        status: 'ISSUED',
        notes: 'Kriminalistika fani amaliyoti uchun',
      ),
      BookIssueModel(
        id: 'iss_003',
        bookId: 'bk_003',
        bookTitle: 'Informatika va Axborot Xavfsizligi Litsey Darsligi',
        userId: 'usr_004',
        userName: 'Oripov Sardor Farxodovich',
        userGroup: '201-guruh',
        userStage: '2-bosqich (2-kurs)',
        issueDate: dateStr(now.subtract(const Duration(days: 15))),
        dueDate: dateStr(now.subtract(const Duration(days: 1))), // OVERDUE!
        status: 'ISSUED',
        notes: 'Informatika fani imtihoniga tayyorgarlik',
      ),
      BookIssueModel(
        id: 'iss_004',
        bookId: 'bk_004',
        bookTitle: 'O\'tkan Kunlar (Tarixiy Badiiy Asar)',
        userId: 'usr_003',
        userName: 'Karimov Jasur Anvarovich',
        userGroup: '102-guruh',
        userStage: '1-bosqich (1-kurs)',
        issueDate: dateStr(now.subtract(const Duration(days: 25))),
        dueDate: dateStr(now.subtract(const Duration(days: 10))),
        returnDate: dateStr(now.subtract(const Duration(days: 2))),
        status: 'RETURNED',
        notes: 'A\'lo holatda qaytarildi',
      ),
    ];
    for (var iss in issues) {
      await db.insert('book_issues', iss.toMap());
    }
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
