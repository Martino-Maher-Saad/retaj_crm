import 'property_image_model.dart';

class PropertyModel {
  // 1. المعرفات والبيانات الأساسية
  final String id;
  final String? propertyCode;
  final String? createdBy;
  final String? createdByName; // اسم الموظف - يأتي من JOIN على جدول profiles
  final DateTime? createdAt;
  final bool status;

  // 2. بيانات العقار الأساسية
  final String titleAr;
  final String descAr;
  final String listingTypeAr;
  final String propertyTypeAr;
  final String governorateAr;
  final String cityAr;

  // 3. الأعمدة الاختيارية
  final String? regionAr;
  final String? locationInDetails;
  final String? locationMap;
  final String? internalNotes;

  // 4. السعر (إجباري)
  final num price;

  // 5. بيانات المالك (تظهر فقط للمالك أو المدير)
  final String? ownerName;
  final String? ownerPhone;

  // 6. قائمة الصور
  final List<PropertyImageModel> images;

  // 7. الـ Embedding للبحث بالذكاء الاصطناعي
  final List<double>? embedding;

  // 8. مصدر العقار ومنصات الإعلان
  final String? source;       // المصدر (من أين جاء العقار)
  final List<String> platforms; // المنصات التي نُزّل فيها إعلان

  const PropertyModel({
    this.embedding,
    required this.id,
    this.propertyCode,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    required this.status,
    required this.titleAr,
    required this.descAr,
    required this.listingTypeAr,
    required this.propertyTypeAr,
    required this.governorateAr,
    required this.cityAr,
    this.regionAr,
    this.locationInDetails,
    this.locationMap,
    this.internalNotes,
    required this.price,
    this.ownerName,
    this.ownerPhone,
    this.images = const [],
    this.source,
    this.platforms = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // جلب اسم الموظف من الـ JOIN
    final creator = json['creator'] as Map<String, dynamic>?;
    final createdByName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : null;

    final imagesList = (json['property_images'] as List?)
            ?.map((e) => PropertyImageModel.fromJson(e))
            .take(10)
            .toList() ??
        [];

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      propertyCode: json['property_code'],
      createdBy: json['created_by'],
      createdByName: createdByName?.isNotEmpty == true ? createdByName : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      status: json['status'] ?? false,
      titleAr: json['title_ar'] ?? '',
      descAr: json['desc_ar'] ?? '',
      listingTypeAr: json['listing_type_ar'] ?? '',
      propertyTypeAr: json['property_type_ar'] ?? '',
      governorateAr: json['governorate_ar'] ?? '',
      cityAr: json['city_ar'] ?? '',
      regionAr: json['region_ar'],
      locationInDetails: json['location_in_details'],
      locationMap: json['location_map'],
      internalNotes: json['internal_notes'],
      price: (json['price'] as num?) ?? 0,
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      images: imagesList,
      source: json['source'],
      platforms: json['platforms'] != null
          ? List<String>.from(json['platforms'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'embedding': embedding,
      'property_code': propertyCode,
      'created_by': createdBy,
      'status': status,
      'title_ar': titleAr,
      'desc_ar': descAr,
      'listing_type_ar': listingTypeAr,
      'property_type_ar': propertyTypeAr,
      'governorate_ar': governorateAr,
      'city_ar': cityAr,
      'region_ar': regionAr,
      'location_in_details': locationInDetails,
      'location_map': locationMap,
      'internal_notes': internalNotes,
      'price': price,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'source': source,
      'platforms': platforms,
    };
  }

  PropertyModel copyWith({
    List<double>? embedding,
    String? id,
    String? propertyCode,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    bool? status,
    String? titleAr,
    String? descAr,
    String? listingTypeAr,
    String? propertyTypeAr,
    String? governorateAr,
    String? cityAr,
    String? regionAr,
    String? locationInDetails,
    String? locationMap,
    String? internalNotes,
    num? price,
    String? ownerName,
    String? ownerPhone,
    List<PropertyImageModel>? images,
    String? source,
    List<String>? platforms,
  }) {
    return PropertyModel(
      embedding: embedding ?? this.embedding,
      id: id ?? this.id,
      propertyCode: propertyCode ?? this.propertyCode,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      titleAr: titleAr ?? this.titleAr,
      descAr: descAr ?? this.descAr,
      listingTypeAr: listingTypeAr ?? this.listingTypeAr,
      propertyTypeAr: propertyTypeAr ?? this.propertyTypeAr,
      governorateAr: governorateAr ?? this.governorateAr,
      cityAr: cityAr ?? this.cityAr,
      regionAr: regionAr ?? this.regionAr,
      locationInDetails: locationInDetails ?? this.locationInDetails,
      locationMap: locationMap ?? this.locationMap,
      internalNotes: internalNotes ?? this.internalNotes,
      price: price ?? this.price,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      images: images ?? this.images,
      source: source ?? this.source,
      platforms: platforms ?? this.platforms,
    );
  }
}
