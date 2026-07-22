/// موديل لخيارات الـ Dropdown القادمة من جدول dropdown_options في قاعدة البيانات
class DropdownOptionModel {
  final String id;
  final String category;
  final String valueAr;
  final bool isActive;

  const DropdownOptionModel({
    required this.id,
    required this.category,
    required this.valueAr,
    this.isActive = true,
  });

  factory DropdownOptionModel.fromJson(Map<String, dynamic> json) {
    return DropdownOptionModel(
      id: json['id']?.toString() ?? '',
      category: json['category'] ?? '',
      valueAr: json['value_ar'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'value_ar': valueAr,
    'is_active': isActive,
  };
}
