class ProfileModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool canMakeAds;
  final String? propertyPrefix;
  final bool isActive;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.canMakeAds = false,
    this.propertyPrefix,
    this.isActive = true,
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      canMakeAds: json['can_make_ads'] ?? false,
      propertyPrefix: json['property_prefix'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'can_make_ads': canMakeAds,
      'property_prefix': propertyPrefix,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? canMakeAds,
    String? propertyPrefix,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canMakeAds: canMakeAds ?? this.canMakeAds,
      propertyPrefix: propertyPrefix ?? this.propertyPrefix,
    );
  }

  String get fullName {
    final name = "${firstName ?? ''} ${lastName ?? ''}".trim();
    return name.isEmpty ? "مستخدم بدون اسم" : name;
  }
  
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSales => role == 'sales' || role == 'marketing';
  bool get isCeo => role == 'ceo';
  bool get isMarketing => role == 'marketing';

  /// يقدر يعدل حالة المنصات وحالة العقار (للادمن والمدير والـ CEO والتسويق وأي موظف canMakeAds)
  bool get canManagePlatforms =>
      isAdmin || isManager || isCeo || isMarketing || canMakeAds;

  /// يقدر يشوف كل بيانات العقار بما فيها رقم المالك
  bool get canViewOwnerDetails => !isMarketing;
}
