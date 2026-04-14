class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final bool isBlocked;
  final String? blockedBy;
  final bool modifiedBySuperAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.isBlocked = false,
    this.blockedBy,
    this.modifiedBySuperAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isBlocked: json['isBlocked'] ?? false,
      blockedBy: json['blockedBy'],
      modifiedBySuperAdmin: json['modifiedBySuperAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isBlocked': isBlocked,
      'modifiedBySuperAdmin': modifiedBySuperAdmin,
    };
  }
}
