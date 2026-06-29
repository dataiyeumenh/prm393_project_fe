class UserSummaryDTO {
  final String id;
  final String fullName;
  final String email;
  final String? role;

  UserSummaryDTO({
    required this.id,
    required this.fullName,
    required this.email,
    this.role,
  });

  factory UserSummaryDTO.fromJson(Map<String, dynamic> json) {
    return UserSummaryDTO(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserSummaryDTO user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserSummaryDTO.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserProfileDTO {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? role;

  UserProfileDTO({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    this.avatarUrl,
    this.role,
  });

  factory UserProfileDTO.fromJson(Map<String, dynamic> json) {
    return UserProfileDTO(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
    };
  }
}

class VerifyOtpRequest {
  final String email;
  final String otpCode;

  VerifyOtpRequest({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otpCode': otpCode,
    };
  }
}

class UpdateProfileRequest {
  final String fullName;
  final String? phone;
  final String? address;

  UpdateProfileRequest({
    required this.fullName,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
    };
  }
}
