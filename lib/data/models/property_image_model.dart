class PropertyImageModel {
  final String? id;
  final String propertyId;
  final String imageUrl;

  PropertyImageModel({
    this.id,
    required this.propertyId,
    required this.imageUrl,
  });

  // المعالج لتحويل JSON القادم من قاعدة البيانات إلى كائن Dart
  factory PropertyImageModel.fromJson(Map<String, dynamic> json) {
    print("Debug Image JSON: $json");
    return PropertyImageModel(
      id: json['id']?.toString(),
      propertyId: json['property_id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  // المعالج لتحويل الكائن إلى JSON لإرساله لقاعدة البيانات
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'property_id': propertyId,
      'image_url': imageUrl,
    };
    // لا نرسل الـ ID عند الإضافة الجديدة لأن السيرفر يولده تلقائياً
    if (id != null) data['id'] = id;
    return data;
  }

  // --- Logic تحسين الصور (Image Optimization) ---

  // رابط الصور المصغرة: للكروت وقائمة العقارات (توفر مساحة وسرعة تحميل)
  String get thumbnail => "$imageUrl?width=300&quality=40";

  // رابط المعاينة: لصفحة التفاصيل (جودة متوازنة)
  String get preview => "$imageUrl?width=800&quality=60";

  // الرابط الأصلي: يستخدم فقط عند تكبير الصورة بالكامل
  String get original => imageUrl;

  // ميثود copyWith لتعديل كائن الصورة إذا لزم الأمر
  PropertyImageModel copyWith({
    String? id,
    String? propertyId,
    String? imageUrl,
  }) {
    return PropertyImageModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
