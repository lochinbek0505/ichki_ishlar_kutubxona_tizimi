import 'package:flutter/material.dart';

import '../models/book_issue_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class GroupStat {
  final String groupName;
  final int totalIssued;
  final int activeIssued;
  final int overdue;

  GroupStat({
    required this.groupName,
    required this.totalIssued,
    required this.activeIssued,
    required this.overdue,
  });
}

class StageStat {
  final String stageName;
  final int totalIssued;
  final int activeIssued;
  final int overdue;

  StageStat({
    required this.stageName,
    required this.totalIssued,
    required this.activeIssued,
    required this.overdue,
  });
}

class TopReaderStat {
  final UserModel user;
  final int booksReadCount;
  final int activeBooksCount;

  TopReaderStat({
    required this.user,
    required this.booksReadCount,
    required this.activeBooksCount,
  });
}

class BookTypeStat {
  final String typeName;
  final int totalCount;
  final double percentage;

  BookTypeStat({
    required this.typeName,
    required this.totalCount,
    required this.percentage,
  });
}

class StatisticsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoading = false;
  List<GroupStat> _groupStats = [];
  List<StageStat> _stageStats = [];
  List<TopReaderStat> _topReaders = [];
  List<BookIssueModel> _overdueIssues = [];
  List<BookTypeStat> _bookTypeStats = [];

  bool get isLoading => _isLoading;
  List<GroupStat> get groupStats => _groupStats;
  List<StageStat> get stageStats => _stageStats;
  List<TopReaderStat> get topReaders => _topReaders;
  List<BookIssueModel> get overdueIssues => _overdueIssues;
  List<BookTypeStat> get bookTypeStats => _bookTypeStats;

  StatisticsProvider() {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    final users = await _db.getUsers();
    final books = await _db.getBooks();
    final issues = await _db.getBookIssues();

    // 1. Group Stats
    Map<String, List<BookIssueModel>> groupMap = {};
    for (var iss in issues) {
      final grp = iss.userGroup ?? 'Noma\'lum guruh';
      groupMap.putIfAbsent(grp, () => []).add(iss);
    }

    _groupStats = groupMap.entries.map((entry) {
      final grpIssues = entry.value;
      final active = grpIssues.where((i) => !i.isReturned).length;
      final overdue = grpIssues.where((i) => i.isOverdue).length;
      return GroupStat(
        groupName: entry.key,
        totalIssued: grpIssues.length,
        activeIssued: active,
        overdue: overdue,
      );
    }).toList();

    _groupStats.sort((a, b) => b.totalIssued.compareTo(a.totalIssued));

    // 2. Stage Stats
    Map<String, List<BookIssueModel>> stageMap = {};
    for (var iss in issues) {
      final stg = iss.userStage ?? 'Noma\'lum bosqich';
      stageMap.putIfAbsent(stg, () => []).add(iss);
    }

    _stageStats = stageMap.entries.map((entry) {
      final stgIssues = entry.value;
      final active = stgIssues.where((i) => !i.isReturned).length;
      final overdue = stgIssues.where((i) => i.isOverdue).length;
      return StageStat(
        stageName: entry.key,
        totalIssued: stgIssues.length,
        activeIssued: active,
        overdue: overdue,
      );
    }).toList();

    // 3. Top Readers & Overdue Students
    Map<String, List<BookIssueModel>> userIssuesMap = {};
    for (var iss in issues) {
      userIssuesMap.putIfAbsent(iss.userId, () => []).add(iss);
    }

    _topReaders = [];
    for (var usr in users) {
      final uIssues = userIssuesMap[usr.id] ?? [];
      if (uIssues.isNotEmpty) {
        final active = uIssues.where((i) => !i.isReturned).length;
        _topReaders.add(TopReaderStat(
          user: usr,
          booksReadCount: uIssues.length,
          activeBooksCount: active,
        ));
      }
    }
    _topReaders.sort((a, b) => b.booksReadCount.compareTo(a.booksReadCount));

    _overdueIssues = issues.where((i) => i.isOverdue).toList();

    // 4. Book Types Stats
    int totalBooksCopies = books.fold(0, (sum, b) => sum + b.totalCopies);
    Map<String, int> typeMap = {};
    for (var b in books) {
      typeMap[b.type] = (typeMap[b.type] ?? 0) + b.totalCopies;
    }

    _bookTypeStats = typeMap.entries.map((e) {
      final pct = totalBooksCopies > 0 ? (e.value / totalBooksCopies) * 100 : 0.0;
      return BookTypeStat(
        typeName: e.key,
        totalCount: e.value,
        percentage: pct,
      );
    }).toList();

    _isLoading = false;
    notifyListeners();
  }
}
