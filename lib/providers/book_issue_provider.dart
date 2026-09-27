import 'package:flutter/material.dart';

import '../models/book_issue_model.dart';
import '../services/database_service.dart';

class BookIssueProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<BookIssueModel> _issues = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'ISSUED', 'RETURNED', 'OVERDUE'

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;

  List<BookIssueModel> get issues {
    return _issues.where((iss) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          iss.bookTitle.toLowerCase().contains(query) ||
          iss.userName.toLowerCase().contains(query) ||
          (iss.userGroup ?? '').toLowerCase().contains(query);

      bool matchesStatus = true;
      if (_selectedStatusFilter == 'ISSUED') {
        matchesStatus = !iss.isReturned;
      } else if (_selectedStatusFilter == 'RETURNED') {
        matchesStatus = iss.isReturned;
      } else if (_selectedStatusFilter == 'OVERDUE') {
        matchesStatus = iss.isOverdue;
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get activeIssuedCount => _issues.where((i) => !i.isReturned).length;
  int get overdueCount => _issues.where((i) => i.isOverdue).length;

  BookIssueProvider() {
    loadIssues();
  }

  Future<void> loadIssues() async {
    _isLoading = true;
    notifyListeners();

    _issues = await _db.getBookIssues();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<bool> issueBook({
    required String bookId,
    required String bookTitle,
    required String userId,
    required String userName,
    String? userGroup,
    String? userStage,
    required String dueDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    final issueDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final newIssue = BookIssueModel(
      id: 'iss_${DateTime.now().millisecondsSinceEpoch}',
      bookId: bookId,
      bookTitle: bookTitle,
      userId: userId,
      userName: userName,
      userGroup: userGroup,
      userStage: userStage,
      issueDate: issueDate,
      dueDate: dueDate,
      status: 'ISSUED',
      notes: notes,
    );

    await _db.insertBookIssue(newIssue);
    await loadIssues();
    return true;
  }

  Future<void> returnBook(String issueId, {String? notes}) async {
    final now = DateTime.now();
    final returnDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await _db.returnBookIssue(issueId, returnDate, notes: notes);
    await loadIssues();
  }

  Future<void> extendDueDate(String issueId, String newDueDate) async {
    await _db.extendDueDate(issueId, newDueDate);
    await loadIssues();
  }
}
