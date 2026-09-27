import 'package:flutter/material.dart';

import '../models/bosqich.dart';
import '../models/guruh.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<UserModel> _users = [];
  List<Bosqich> _bosqichlar = [];
  List<Guruh> _guruhlar = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedBosqichIdFilter;
  String? _selectedGuruhIdFilter;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedBosqichIdFilter => _selectedBosqichIdFilter;
  String? get selectedGuruhIdFilter => _selectedGuruhIdFilter;

  List<Bosqich> get bosqichlar => _bosqichlar;
  List<Guruh> get guruhlar => _guruhlar;

  List<UserModel> get users {
    final filtered = _users.where((u) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          u.fullName.toLowerCase().contains(query) ||
          u.readerCardId.toLowerCase().contains(query);

      final matchesBosqich = _selectedBosqichIdFilter == null || u.bosqichId == _selectedBosqichIdFilter;
      final matchesGuruh = _selectedGuruhIdFilter == null || u.guruhId == _selectedGuruhIdFilter;

      return matchesQuery && matchesBosqich && matchesGuruh;
    }).toList();

    // Strictly sort alphabetically by Full Name
    filtered.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return filtered;
  }

  UserProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _bosqichlar = await _db.getBosqichlar();
    _guruhlar = await _db.getGuruhlar();
    _users = await _db.getUsers();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBosqichFilter(String? bosqichId) {
    _selectedBosqichIdFilter = bosqichId;
    _selectedGuruhIdFilter = null; // Reset guruh filter when bosqich changes
    notifyListeners();
  }

  void setGuruhFilter(String? guruhId) {
    _selectedGuruhIdFilter = guruhId;
    notifyListeners();
  }

  Future<void> addUser(UserModel user) async {
    await _db.insertUser(user);
    await loadData();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.updateUser(user);
    await loadData();
  }

  Future<void> deleteUser(String id) async {
    await _db.deleteUser(id);
    await loadData();
  }

  Future<void> addGuruh(Guruh guruh) async {
    await _db.insertGuruh(guruh);
    await loadData();
  }

  Future<void> addBosqich(Bosqich bosqich) async {
    await _db.insertBosqich(bosqich);
    await loadData();
  }
}
