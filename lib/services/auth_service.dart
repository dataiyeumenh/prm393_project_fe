class AuthService {
  AuthService._();

  /// Mock login — accepts any non-empty email/password.
  /// Returns an [AuthResponse] with a fake JWT token.
  static Future<AuthResponse> login(
    String email,
    String password, {
    String? fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return AuthResponse(
      accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
      user: AuthUser(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName ?? email.split('@').first,
      ),
    );
  }

  /// Mock register — accepts any non-empty form.
  static Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return AuthResponse(
      accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
      user: AuthUser(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
      ),
    );
  }

  /// Mock logout — does nothing.
  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Lightweight auth models used only by the mock service.
class AuthResponse {
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
  });
  final String id;
  final String email;
  final String fullName;
}
