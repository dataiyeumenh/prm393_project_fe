import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;

  Future<void> checkAuthStatus() async {
    // Mock — no persisted session
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await AuthService.login(email, password);
      _user = AppUser(
        id: response.user.id,
        email: response.user.email,
        fullName: response.user.fullName,
      );
    } catch (e) {
      throw AuthException(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      if (fullName.trim().isEmpty) {
        throw const AuthException('Please enter your full name.');
      }
      if (email.isEmpty || !email.contains('@')) {
        throw const AuthException('Please enter a valid email address.');
      }
      if (password.length < 6) {
        throw const AuthException('Password must be at least 6 characters.');
      }
      if (password != confirmPassword) {
        throw const AuthException('Passwords do not match.');
      }

      final response = await AuthService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      _user = AppUser(
        id: response.user.id,
        email: response.user.email,
        fullName: response.user.fullName,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
