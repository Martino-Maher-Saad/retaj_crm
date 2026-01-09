class PropertyModel {
  // معرفات وسجلات السيرفر (Nullable لأن السيرفر ينشئها)
  final String? id;
  final DateTime? createdAt;

  // البيانات الأساسية (Required)
  final String titleAr;
  final String titleEn;
  final int rooms;
  final int baths;
  final String locationAr;
  final String locationEn;
  final String ownerName;
  final String ownerPhone;
  final String createdBy; // معرف الموظف الذي أنشأ العقار
  final double price;
  final double area;
  final String city;
  final bool isAvailable;
  final String type;

  // البيانات الاختيارية
  final String? descAr;
  final String? descEn;
  final String? locationMap;

  // قائمة الصور (قادمة من جدول property_images)
  final List<String> images;

  PropertyModel({
    this.id,
    this.createdAt,
    required this.titleAr,
    required this.titleEn,
    required this.rooms,
    required this.baths,
    required this.locationAr,
    required this.locationEn,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdBy,
    required this.price,
    required this.area,
    required this.city,
    required this.isAvailable,
    required this.type,
    this.descAr,
    this.descEn,
    this.locationMap,
    this.images = const [],
  });

  // تحويل البيانات القادمة من Supabase (مع الصور المرتبطة)
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // استخراج روابط الصور من جدول property_images المرتبط عبر الـ Join
    // ملاحظة: سوبا بيز يعيد الصور كقائمة خرائط [{image_url: '...'}]
    final List<dynamic>? imagesData = json['property_images'];
    final List<String> imageUrls = imagesData != null
        ? imagesData.map((img) => img['image_url'] as String).toList()
        : [];

    return PropertyModel(
      id: json['id'], // تأكد أن الاسم في الداتا بيز 'id'
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'] ?? '',
      rooms: json['rooms'] ?? 0,
      baths: json['baths'] ?? 0,
      locationAr: json['location_ar'] ?? '',
      locationEn: json['location_en'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
      createdBy: json['created_by'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] ?? '',
      isAvailable: json['is_available'] ?? true,
      type: json['type'] ?? '',
      descAr: json['desc_ar'],
      descEn: json['desc_en'],
      locationMap: json['location_map'],
      images: imageUrls,
    );
  }

  // تحويل الكائن إلى Map لإرساله للسيرفر (للإضافة والتعديل)
  Map<String, dynamic> toJson() {
    return {
      // لا نرسل الـ id ولا الـ createdAt لأن السيرفر يولدهما
      'title_ar': titleAr,
      'title_en': titleEn,
      'rooms': rooms,
      'baths': baths,
      'location_ar': locationAr,
      'location_en': locationEn,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'created_by': createdBy,
      'price': price,
      'area': area,
      'city': city,
      'is_available': isAvailable,
      'type': type,
      'desc_ar': descAr,
      'desc_en': descEn,
      'location_map': locationMap,
      // ملاحظة: الصور تُرفع وتربط في جدول منفصل، لذا لا نرسلها هنا
    };
  }

  // دالة النسخ للتعديل الذكي
  PropertyModel copyWith({
    String? id,
    List<String>? images,
    double? price,
    bool? isAvailable,
    // ... يمكنك إضافة باقي الحقول هنا عند الحاجة للتعديل
  }) {
    return PropertyModel(
      id: id ?? this.id,
      titleAr: this.titleAr,
      titleEn: this.titleEn,
      rooms: this.rooms,
      baths: this.baths,
      locationAr: this.locationAr,
      locationEn: this.locationEn,
      ownerName: this.ownerName,
      ownerPhone: this.ownerPhone,
      createdBy: this.createdBy,
      price: price ?? this.price,
      area: this.area,
      city: this.city,
      isAvailable: isAvailable ?? this.isAvailable,
      type: this.type,
      descAr: this.descAr,
      descEn: this.descEn,
      locationMap: this.locationMap,
      images: images ?? this.images,
      createdAt: this.createdAt,
    );
  }
}