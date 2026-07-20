class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    this.avatarUrl,
    this.role = 'USER',
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String role;

  // Handles both 'ADMIN' and 'ROLE_ADMIN' formats from backend
  bool get isAdmin {
    final r = role.toUpperCase();
    return r == 'ADMIN' || r == 'ROLE_ADMIN';
  }
}
