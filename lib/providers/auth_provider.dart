import 'package:flutter/foundation.dart';

/// Mock authentication — no real auth API exists yet for the MVP.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _userName = email.split('@').first;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    notifyListeners();
  }
}
