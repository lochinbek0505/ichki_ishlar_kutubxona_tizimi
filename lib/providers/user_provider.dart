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

  int allUsersCountInGuruh(String guruhId) => _users.where((u) => u.guruhId == guruhId).length;

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

  // --- BOSQICHLAR CRUD ---
  Future<void> addBosqich(String name, int levelNumber) async {
    await _db.insertBosqich(Bosqich(id: 'b_${DateTime.now().millisecondsSinceEpoch}', name: name, levelNumber: levelNumber));
    await loadData();
  }

  Future<void> updateBosqich(Bosqich bosqich) async {
    await _db.updateBosqich(bosqich);
    await loadData();
  }

  /// O'chirib bo'lmasa sababini qaytaradi
  Future<String?> deleteBosqich(String id) async {
    final groupCount = _guruhlar.where((g) => g.bosqichId == id).length;
    if (groupCount > 0) return 'Bu bosqichda $groupCount ta guruh bor. Avval guruhlarni o\'chiring yoki boshqa bosqichga o\'tkazing.';
    final userCount = _users.where((u) => u.bosqichId == id).length;
    if (userCount > 0) return 'Bu bosqichga $userCount nafar kursant biriktirilgan.';

    await _db.deleteBosqich(id);
    if (_selectedBosqichIdFilter == id) setBosqichFilter(null);
    await loadData();
    return null;
  }

  // --- GURUHLAR CRUD ---
  Future<void> addGuruh(String name, Bosqich bosqich) async {
    await _db.insertGuruh(Guruh(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      bosqichId: bosqich.id,
      bosqichName: bosqich.name,
    ));
    await loadData();
  }

  Future<void> updateGuruh(Guruh guruh) async {
    await _db.updateGuruh(guruh);
    await loadData();
  }

  Future<String?> deleteGuruh(String id) async {
    final userCount = _users.where((u) => u.guruhId == id).length;
    if (userCount > 0) return 'Bu guruhga $userCount nafar kursant biriktirilgan. Avval ularni boshqa guruhga o\'tkazing.';

    await _db.deleteGuruh(id);
    if (_selectedGuruhIdFilter == id) setGuruhFilter(null);
    await loadData();
    return null;
  }
}
