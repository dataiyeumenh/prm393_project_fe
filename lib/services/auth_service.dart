import 'package:dio/dio.dart';

import '../models/api/auth_dto.dart' as dto;
import 'api_service.dart';

class AuthService {
  AuthService._();

  static const _loginEndpoint = '/api/v1/auth/login';
  static const _registerEndpoint = '/api/v1/auth/register';
  static const _logoutEndpoint = '/api/v1/auth/logout';

  /// Login with real backend. Saves tokens to SharedPreferences on success.
  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await ApiService.dio.post(
        _loginEndpoint,
        data: dto.LoginRequest(email: email, password: password).toJson(),
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final payload =
            (body['data'] is Map ? body['data'] : body) as Map<String, dynamic>;
        final authResp = _parseResponse(payload);
        await ApiService.saveTokens(
          authResp.accessToken,
          authResp.refreshToken,
        );
        return authResp;
      }

      final msg =
          (response.data as Map?)?['message'] as String? ?? 'Login failed';
      throw AuthServiceException(msg);
    } on DioException catch (e) {
      throw AuthServiceException(_extractMessage(e));
    }
  }

  /// Register with real backend.
  static Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.dio.post(
        _registerEndpoint,
        data: dto.RegisterRequest(
          fullName: fullName,
          email: email,
          password: password,
        ).toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        final payload =
            (body['data'] is Map ? body['data'] : body) as Map<String, dynamic>;
        final authResp = _parseResponse(payload);
        await ApiService.saveTokens(
          authResp.accessToken,
          authResp.refreshToken,
        );
        return authResp;
      }

      final msg =
          (response.data as Map?)?['message'] as String? ??
          'Registration failed';
      throw AuthServiceException(msg);
    } on DioException catch (e) {
      throw AuthServiceException(_extractMessage(e));
    }
  }

  /// Logout — clears local tokens. Calls backend endpoint if available.
  static Future<void> logout() async {
    try {
      await ApiService.dio.post(_logoutEndpoint);
    } catch (_) {
      // Ignore backend errors — always clear local tokens
    } finally {
      await ApiService.clearTokens();
    }
  }

  static AuthResponse _parseResponse(Map<String, dynamic> payload) {
    final userRaw = payload['user'];
    final user = AuthUser(
      id: (userRaw?['id'] ?? payload['id'] ?? '') as String,
      email: (userRaw?['email'] ?? payload['email'] ?? '') as String,
      fullName:
          (userRaw?['fullName'] ??
                  userRaw?['name'] ??
                  payload['fullName'] ??
                  '')
              as String,
      role: (userRaw?['role'] ?? payload['role']) as String?,
    );
    return AuthResponse(
      accessToken: payload['accessToken'] as String? ?? '',
      refreshToken: payload['refreshToken'] as String? ?? '',
      user: user,
    );
  }

  static String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}

    final code = e.response?.statusCode;
    if (code == 401) return 'Invalid email or password.';
    if (code == 403) return 'Account not authorized.';
    if (code == 409) return 'Email already registered.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Check your internet.';
    }
    return 'An error occurred. Please try again.';
  }
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Auth models kept compatible with AuthState's existing usage.
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
    this.role,
  });
  final String id;
  final String email;
  final String fullName;
  final String? role;
}
