import 'package:flutter/foundation.dart';

import '../models/user.dart';

class MockAccount {
  const MockAccount({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.address,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String address;
}

/// Mock "API" — pretends to authenticate over the network.
class MockAuthApi {
  MockAuthApi._();

  static const List<MockAccount> accounts = [
    MockAccount(
      email: 'trieu@gmail.com',
      password: '123456',
      fullName: 'Trieu Nguyen',
      phone: '+84 901 234 567',
      address: '12 Le Loi, District 1, Ho Chi Minh City',
    ),
    MockAccount(
      email: 'minh@pawfuel.com',
      password: 'woof2026',
      fullName: 'Minh Tran',
      phone: '+84 909 111 222',
      address: '88 Nguyen Hue, District 1, Ho Chi Minh City',
    ),
  ];

  static MockAccount? find(String email, String password) {
    final e = email.trim().toLowerCase();
    for (final a in accounts) {
      if (a.email.toLowerCase() == e && a.password == password) {
        return a;
      }
    }
    return null;
  }
}

class AuthState extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    final account = MockAuthApi.find(email, password);
    if (account == null) {
      throw const AuthException(
        'Email or password is incorrect. Try trieu@gmail.com / 123456',
      );
    }
    _user = AppUser(
      id: 'u_${account.email.hashCode}',
      email: account.email,
      fullName: account.fullName,
      phone: account.phone,
      address: account.address,
    );
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
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
    _user = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName.trim(),
    );
    notifyListeners();
  }

  void logout() {
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