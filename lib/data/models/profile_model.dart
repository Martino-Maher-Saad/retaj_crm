import 'package:retaj_crm/core/constants/app_roles.dart';

class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? imageUrl;
  final String? teamId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.imageUrl,
    this.teamId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'sales',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      imageUrl: json['image_url'],
      teamId: json['team_id'],
      isActive: json['is_active'] ?? true,
      createdAt:
          json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'image_url': imageUrl,
      'team_id': teamId,
      'is_active': isActive,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? phone,
    String? imageUrl,
    String? teamId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      teamId: teamId ?? this.teamId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── الاسم الكامل ───
  String get fullName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? 'مستخدم بدون اسم' : name;
  }

  // ─── AppRole ───
  AppRole get appRole => AppRole.fromString(role);

  // ─── Helpers للتحقق من الدور ───
  bool get isSales => role == 'sales';
  bool get isLeader => role == 'leader';
  bool get isManager => role == 'manager';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';

  /// هل لديه صلاحيات admin أو أعلى
  bool get isAdminOrAbove => appRole.isAtLeast(AppRole.admin);

  /// هل لديه صلاحيات manager أو أعلى
  bool get isManagerOrAbove => appRole.isAtLeast(AppRole.manager);

  /// هل لديه صلاحيات leader أو أعلى
  bool get isLeaderOrAbove => appRole.isAtLeast(AppRole.leader);

  // ─── الاسم العربي للدور ───
  String get roleNameAr => appRole.nameAr;

  @override
  String toString() =>
      'ProfileModel(id: $id, email: $email, role: $role, name: $fullName)';
}
