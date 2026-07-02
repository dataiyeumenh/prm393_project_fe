import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Restore session if a valid token is already stored.
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      await ApiService.clearTokens();
      return;
    }
    // Token exists — re-hydrate minimal user from preferences
    // A full profile fetch could go here; for now we mark as authenticated
    // so the UI doesn't flash the login screen.
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
        role: response.user.role ?? 'USER',
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

      await AuthService.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await AuthService.verifyOtp(
        email: email,
        otpCode: otpCode,
      );
      _user = AppUser(
        id: response.user.id,
        email: response.user.email,
        fullName: response.user.fullName,
        role: response.user.role ?? 'USER',
      );
    } catch (e) {
      throw AuthException(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await AuthService.resendOtp(email: email);
    } catch (e) {
      throw AuthException(e.toString());
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
