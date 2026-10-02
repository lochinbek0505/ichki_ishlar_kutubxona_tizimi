import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoggedIn = false;
  String? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;

  /// Administrator hisobi yaratilganmi (birinchi ishga tushirishda yo'q bo'ladi)
  Future<bool> hasAccount() async => await _db.getAdmin() != null;

  Future<bool> login(String username, String password) async {
    final admin = await _db.getAdmin();
    if (admin == null) return false;

    final ok = admin['username'] == username.trim() &&
        admin['passwordHash'] == _hash(password, admin['salt'] as String);
    if (ok) {
      _isLoggedIn = true;
      _currentUser = admin['username'] as String;
      notifyListeners();
    }
    return ok;
  }

  /// Birinchi ishga tushirishda administrator hisobini yaratish
  Future<void> createAccount(String username, String password) async {
    await _saveCredentials(username.trim(), password);
    _isLoggedIn = true;
    _currentUser = username.trim();
    notifyListeners();
  }

  /// Login va parolni o'zgartirish. Xatolik bo'lsa xabar matnini qaytaradi.
  Future<String?> changeCredentials({
    required String currentPassword,
    required String newUsername,
    required String newPassword,
  }) async {
    final admin = await _db.getAdmin();
    if (admin == null || admin['passwordHash'] != _hash(currentPassword, admin['salt'] as String)) {
      return 'Joriy parol noto\'g\'ri';
    }
    final error = validate(newUsername, newPassword);
    if (error != null) return error;

    await _saveCredentials(newUsername.trim(), newPassword);
    _currentUser = newUsername.trim();
    notifyListeners();
    return null;
  }

  static String? validate(String username, String password) {
    if (username.trim().length < 3) return 'Login kamida 3 ta belgidan iborat bo\'lishi kerak';
    if (password.length < 6) return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
    return null;
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveCredentials(String username, String password) async {
    final random = Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await _db.saveAdmin(username: username, passwordHash: _hash(password, salt), salt: salt);
  }

  String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();
}
