import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;

  bool login(String username, String password) {
    // Standard librarian/admin credentials for offline desktop system
    if ((username.trim().toLowerCase() == 'admin' || username.trim().toLowerCase() == 'kutubxona') &&
        (password.trim() == '123456' || password.trim() == 'admin123')) {
      _isLoggedIn = true;
      _currentUser = 'Kutubxona Administratori';
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
