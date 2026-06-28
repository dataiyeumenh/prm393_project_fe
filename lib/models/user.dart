class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
}
