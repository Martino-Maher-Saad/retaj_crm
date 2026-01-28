import 'property_image_model.dart';

class PropertyModel {
  // 1. المعرفات والبيانات الأساسية
  final String id;
  final String? propertyCode;
  final String? createdBy;
  final DateTime? createdAt;
  final bool status; // تم استبدال isAvailable بـ status (Required)
  final bool? negotiable;

  // 2. النصوص والعناوين (Localization)
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  final String listingTypeAr;
  final String listingTypeEn;
  final String propertyTypeAr;
  final String propertyTypeEn;
  final String unitTypeAr;
  final String unitTypeEn;
  final String governorateAr;
  final String governorateEn;
  final String cityAr;
  final String cityEn;
  final String regionAr;
  final String regionEn;
  final String locationInDetails;
  final String? locationMap;

  // 3. المواصفات الفنية (smallint في DB -> int في Dart)
  final int? floor;
  final int? builtArea;
  final int? bedrooms;
  final int? bathrooms;
  final int? totalFloors;
  final int? totalApartments;
  final int? kitchens;
  final int? balconies;
  final int? landArea;
  final int? gardenArea;
  final int? buildingAge;

  // 4. الحقول المالية (integer في DB -> num في Dart)
  final num? price;
  final num? downPayment;
  final num? monthlyInstallation;
  final num? insurance;
  final int? monthsInstallations;
  final String? rentalFrequency;

  // 5. الحالة والمواعيد والملاحظات
  final String? completionStatus;
  final String? furnished;
  final DateTime? deliveryDate;
  final String? ownerName;
  final String? ownerPhone;
  final String? internalNotes;

  // 6. قائمة الصور
  final List<PropertyImageModel> images;

  PropertyModel({
    required this.id,
    this.propertyCode,
    this.createdBy,
    this.createdAt,
    required this.status,
    this.negotiable,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.listingTypeAr,
    required this.listingTypeEn,
    required this.propertyTypeAr,
    required this.propertyTypeEn,
    required this.unitTypeAr,
    required this.unitTypeEn,
    required this.governorateAr,
    required this.governorateEn,
    required this.cityAr,
    required this.cityEn,
    required this.regionAr,
    required this.regionEn,
    required this.locationInDetails,
    this.locationMap,
    this.floor,
    this.builtArea,
    this.bedrooms,
    this.bathrooms,
    this.totalFloors,
    this.totalApartments,
    this.kitchens,
    this.balconies,
    this.landArea,
    this.gardenArea,
    this.buildingAge,
    this.price,
    this.downPayment,
    this.monthlyInstallation,
    this.insurance,
    this.monthsInstallations,
    this.rentalFrequency,
    this.completionStatus,
    this.furnished,
    this.deliveryDate,
    this.ownerName,
    this.ownerPhone,
    this.internalNotes,
    this.images = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    var imagesList = (json['property_images'] as List?)
        ?.map((e) => PropertyImageModel.fromJson(e))
        .take(10)
        .toList() ?? [];

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      propertyCode: json['property_code'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : null,
      status: json['status'] ?? false,
      negotiable: json['negotiable'],
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'] ?? '',
      descAr: json['desc_ar'] ?? '',
      descEn: json['desc_en'] ?? '',
      listingTypeAr: json['listing_type_ar'] ?? '',
      listingTypeEn: json['listing_type_en'] ?? '',
      propertyTypeAr: json['property_type_ar'] ?? '',
      propertyTypeEn: json['property_type_en'] ?? '',
      unitTypeAr: json['unit_type_ar'] ?? '',
      unitTypeEn: json['unit_type_en'] ?? '',
      governorateAr: json['governorate_ar'] ?? '',
      governorateEn: json['governorate_en'] ?? '',
      cityAr: json['city_ar'] ?? '',
      cityEn: json['city_en'] ?? '',
      regionAr: json['region_ar'] ?? '',
      regionEn: json['region_en'] ?? '',
      locationInDetails: json['location_in_details'] ?? '',
      locationMap: json['location_map'],
      floor: _toInt(json['floor']),
      builtArea: _toInt(json['built_area']),
      bedrooms: _toInt(json['bedrooms']),
      bathrooms: _toInt(json['bathrooms']),
      totalFloors: _toInt(json['total_floors']),
      totalApartments: _toInt(json['total_apartments']),
      kitchens: _toInt(json['kitchens']),
      balconies: _toInt(json['balconies']),
      landArea: _toInt(json['land_area']),
      gardenArea: _toInt(json['garden_area']),
      buildingAge: _toInt(json['building_age']),
      price: json['price'] as num?,
      downPayment: json['down_payment'] as num?,
      monthlyInstallation: json['monthly_installation'] as num?,
      insurance: json['insurance'] as num?,
      monthsInstallations: _toInt(json['months_installations']),
      rentalFrequency: json['rental_frequency'],
      completionStatus: json['completion_status'],
      furnished: json['furnished'],
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      internalNotes: json['internal_notes'],
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_code': propertyCode,
      'created_by': createdBy,
      'status': status,
      'negotiable': negotiable,
      'title_ar': titleAr,
      'title_en': titleEn,
      'desc_ar': descAr,
      'desc_en': descEn,
      'listing_type_ar': listingTypeAr,
      'listing_type_en': listingTypeEn,
      'property_type_ar': propertyTypeAr,
      'property_type_en': propertyTypeEn,
      'unit_type_ar': unitTypeAr,
      'unit_type_en': unitTypeEn,
      'governorate_ar': governorateAr,
      'governorate_en': governorateEn,
      'city_ar': cityAr,
      'city_en': cityEn,
      'region_ar': regionAr,
      'region_en': regionEn,
      'location_in_details': locationInDetails,
      'location_map': locationMap,
      'floor': floor,
      'built_area': builtArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'total_floors': totalFloors,
      'total_apartments': totalApartments,
      'kitchens': kitchens,
      'balconies': balconies,
      'land_area': landArea,
      'garden_area': gardenArea,
      'building_age': buildingAge,
      'price': price,
      'down_payment': downPayment,
      'monthly_installation': monthlyInstallation,
      'insurance': insurance,
      'months_installations': monthsInstallations,
      'rental_frequency': rentalFrequency,
      'completion_status': completionStatus,
      'furnished': furnished,
      'delivery_date': deliveryDate?.toIso8601String(),
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'internal_notes': internalNotes,
    };
  }

  // دالة مساعدة خاصة للتحويل الرقمي الآمن داخل الـ Factory
  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  PropertyModel copyWith({
    String? id,
    String? propertyCode,
    String? createdBy,
    DateTime? createdAt,
    bool? status,
    bool? negotiable,
    String? titleAr,
    String? titleEn,
    String? descAr,
    String? descEn,
    String? listingTypeAr,
    String? listingTypeEn,
    String? propertyTypeAr,
    String? propertyTypeEn,
    String? unitTypeAr,
    String? unitTypeEn,
    String? governorateAr,
    String? governorateEn,
    String? cityAr,
    String? cityEn,
    String? regionAr,
    String? regionEn,
    String? locationInDetails,
    String? locationMap,
    int? floor,
    int? builtArea,
    int? bedrooms,
    int? bathrooms,
    int? totalFloors,
    int? totalApartments,
    int? kitchens,
    int? balconies,
    int? landArea,
    int? gardenArea,
    int? buildingAge,
    num? price,
    num? downPayment,
    num? monthlyInstallation,
    num? insurance,
    int? monthsInstallations,
    String? rentalFrequency,
    String? completionStatus,
    String? furnished,
    DateTime? deliveryDate,
    String? ownerName,
    String? ownerPhone,
    String? internalNotes,
    List<PropertyImageModel>? images,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      propertyCode: propertyCode ?? this.propertyCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      negotiable: negotiable ?? this.negotiable,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      descAr: descAr ?? this.descAr,
      descEn: descEn ?? this.descEn,
      listingTypeAr: listingTypeAr ?? this.listingTypeAr,
      listingTypeEn: listingTypeEn ?? this.listingTypeEn,
      propertyTypeAr: propertyTypeAr ?? this.propertyTypeAr,
      propertyTypeEn: propertyTypeEn ?? this.propertyTypeEn,
      unitTypeAr: unitTypeAr ?? this.unitTypeAr,
      unitTypeEn: unitTypeEn ?? this.unitTypeEn,
      governorateAr: governorateAr ?? this.governorateAr,
      governorateEn: governorateEn ?? this.governorateEn,
      cityAr: cityAr ?? this.cityAr,
      cityEn: cityEn ?? this.cityEn,
      regionAr: regionAr ?? this.regionAr,
      regionEn: regionEn ?? this.regionEn,
      locationInDetails: locationInDetails ?? this.locationInDetails,
      locationMap: locationMap ?? this.locationMap,
      floor: floor ?? this.floor,
      builtArea: builtArea ?? this.builtArea,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      totalFloors: totalFloors ?? this.totalFloors,
      totalApartments: totalApartments ?? this.totalApartments,
      kitchens: kitchens ?? this.kitchens,
      balconies: balconies ?? this.balconies,
      landArea: landArea ?? this.landArea,
      gardenArea: gardenArea ?? this.gardenArea,
      buildingAge: buildingAge ?? this.buildingAge,
      price: price ?? this.price,
      downPayment: downPayment ?? this.downPayment,
      monthlyInstallation: monthlyInstallation ?? this.monthlyInstallation,
      insurance: insurance ?? this.insurance,
      monthsInstallations: monthsInstallations ?? this.monthsInstallations,
      rentalFrequency: rentalFrequency ?? this.rentalFrequency,
      completionStatus: completionStatus ?? this.completionStatus,
      furnished: furnished ?? this.furnished,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      internalNotes: internalNotes ?? this.internalNotes,
      images: images ?? this.images,
    );
  }
}