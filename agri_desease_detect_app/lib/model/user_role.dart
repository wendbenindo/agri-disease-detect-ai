class UserRole {
  final String id;
  final String userId;
  final String role; // 'buyer', 'vendor', 'admin'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRole({
    required this.id,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isBuyer => role == 'buyer';
  bool get isVendor => role == 'vendor';
  bool get isAdmin => role == 'admin';
}
