enum UserRole { admin, user }

class AppUser {
  final int id;
  final String username;
  final UserRole role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      username: map['username'] as String,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.user,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }
}
