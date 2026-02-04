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
  final String descAr;
  final String listingTypeAr;
  final String propertyTypeAr;
  final String governorateAr;
  final String cityAr;
  final String regionAr;
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
    required this.descAr,
    required this.listingTypeAr,
    required this.propertyTypeAr,
    required this.governorateAr,
    required this.cityAr,
    required this.regionAr,
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
      descAr: json['desc_ar'] ?? '',
      listingTypeAr: json['listing_type_ar'] ?? '',
      propertyTypeAr: json['property_type_ar'] ?? '',
      governorateAr: json['governorate_ar'] ?? '',
      cityAr: json['city_ar'] ?? '',
      regionAr: json['region_ar'] ?? '',
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
      'desc_ar': descAr,
      'listing_type_ar': listingTypeAr,
      'property_type_ar': propertyTypeAr,
      'governorate_ar': governorateAr,
      'city_ar': cityAr,
      'region_ar': regionAr,
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
    String? descAr,
    String? listingTypeAr,
    String? propertyTypeAr,
    String? governorateAr,
    String? cityAr,
    String? regionAr,
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
      descAr: descAr ?? this.descAr,
      listingTypeAr: listingTypeAr ?? this.listingTypeAr,
      propertyTypeAr: propertyTypeAr ?? this.propertyTypeAr,
      governorateAr: governorateAr ?? this.governorateAr,
      cityAr: cityAr ?? this.cityAr,
      regionAr: regionAr ?? this.regionAr,
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
