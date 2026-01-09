/*
class ProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? image;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.image,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'sales',
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
      json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'image': image,
    };
  }

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSales => role == 'sales';
}
*/


class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;

  ProfileModel({this.firstName, this.lastName,required this.id, required this.email, required this.role});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      email: json['email'],
      role: json['role'] ?? 'sales',
      firstName: json['first_name'] ?? 'user',
      lastName: json['last_name'] ?? 'name',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

}
