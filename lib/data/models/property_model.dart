import 'property_image_model.dart';

/// مدخل منصة إعلانية مرتبطة بعقار — من جدول property_platforms
class PropertyPlatformEntry {
  final String id;
  final String platformId;
  final String nameAr;
  final bool isPublished;

  const PropertyPlatformEntry({
    required this.id,
    required this.platformId,
    required this.nameAr,
    this.isPublished = false,
  });

  factory PropertyPlatformEntry.fromJson(Map<String, dynamic> json) {
    final platformData = json['advertising_platforms'] as Map<String, dynamic>?;
    return PropertyPlatformEntry(
      id: json['id']?.toString() ?? '',
      platformId: json['platform_id']?.toString() ?? '',
      nameAr: platformData?['name_ar']?.toString() ?? '',
      isPublished: json['is_published'] == true,
    );
  }
}

class PropertyModel {
  final String id;
  final String? propertyCode;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final bool status;
  final bool isPinned;

  // حقول العرض النصية
  final String titleAr;
  final String descAr;
  final String listingTypeAr;
  final String propertyTypeAr;
  final String governorateAr;
  final String cityAr;
  final String? regionAr;
  final String? locationInDetails;
  final String? locationMap;
  final String? internalNotes;
  final String? managerNotes;
  final num price;
  final String? ownerName;
  final String? ownerPhone;
  final List<PropertyImageModel> images;
  final List<double>? embedding;
  final List<double>? embeddingV2;
  final String? source;
  final List<PropertyPlatformEntry> advertisingPlatforms;

  // حقول الـ IDs الجديدة (للحفظ)
  final String? propertyTypeId;
  final String? listingTypeId;
  final String? sourceId;
  final int? cityId;
  final int? governorateId;
  final String? approvalStatusId;
  final String? approvalStatusName;

  const PropertyModel({
    this.embedding,
    this.embeddingV2,
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
    this.managerNotes,
    required this.price,
    this.ownerName,
    this.ownerPhone,
    this.images = const [],
    this.source,
    this.advertisingPlatforms = const [],
    this.propertyTypeId,
    this.listingTypeId,
    this.sourceId,
    this.cityId,
    this.governorateId,
    this.approvalStatusId,
    this.approvalStatusName,
    this.isPinned = false,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final createdByName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : null;

    final imagesList = (json['property_images'] as List?)
            ?.map((e) => PropertyImageModel.fromJson(e))
            .take(10)
            .toList() ??
        [];

    // النصوص: من الجداول الجديدة أو Fallback للقديمة
    final propTypeMap = json['property_types'] as Map<String, dynamic>?;
    final listTypeMap = json['listing_types'] as Map<String, dynamic>?;
    final sourceMap   = json['property_sources'] as Map<String, dynamic>?;
    final govMap      = json['governorates'] as Map<String, dynamic>?;
    final cityMapData = json['cities'] as Map<String, dynamic>?;

    // المنصات الإعلانية من جدول property_platforms
    final rawPlatforms = json['property_platforms'] as List?;
    final advertisingPlatforms = rawPlatforms != null
        ? rawPlatforms
            .map((p) => PropertyPlatformEntry.fromJson(p as Map<String, dynamic>))
            .toList()
        : <PropertyPlatformEntry>[];

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
      listingTypeAr:  listTypeMap?['name_ar'] ?? json['listing_type_ar'] ?? '',
      propertyTypeAr: propTypeMap?['name_ar'] ?? json['property_type_ar'] ?? '',
      governorateAr:  govMap?['name'] ?? json['governorate_ar'] ?? '',
      cityAr:         cityMapData?['name'] ?? json['city_ar'] ?? '',
      source:         sourceMap?['name_ar'] ?? json['source'],
      regionAr: json['region_ar'],
      locationInDetails: json['location_in_details'],
      locationMap: json['location_map'],
      internalNotes: json['internal_notes'],
      managerNotes: json['manager_notes'],
      price: (json['price'] as num?) ?? 0,
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      images: imagesList,
      advertisingPlatforms: advertisingPlatforms,
      embedding: json['embedding'] != null
          ? (json['embedding'] is String
              ? (json['embedding'] as String)
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .split(',')
                  .map((e) => double.parse(e.trim()))
                  .toList()
              : (json['embedding'] as List).map((e) => (e as num).toDouble()).toList())
          : null,
      embeddingV2: json['embedding_v2'] != null
          ? (json['embedding_v2'] is String
              ? (json['embedding_v2'] as String)
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .split(',')
                  .map((e) => double.parse(e.trim()))
                  .toList()
              : (json['embedding_v2'] as List).map((e) => (e as num).toDouble()).toList())
          : null,
      // الـ IDs الجديدة
      propertyTypeId: json['property_type_id']?.toString(),
      listingTypeId:  json['listing_type_id']?.toString(),
      sourceId:       json['source_id']?.toString(),
      cityId:         json['city_id'] != null ? int.tryParse(json['city_id'].toString()) : null,
      governorateId:  json['governorate_id'] != null ? int.tryParse(json['governorate_id'].toString()) : null,
      approvalStatusId: json['approval_status_id']?.toString(),
      approvalStatusName: json['property_approval_statuses']?['name_ar']?.toString(),
      isPinned:       json['is_pinned'] == true,
    );
  }

  /// toJson: يرسل الـ IDs الجديدة للأعمدة المرتبطة
  /// toJson: يرسل الـ IDs للأعمدة المرتبطة — المنصات تُدار بشكل منفصل عبر property_platforms
  Map<String, dynamic> toJson() {
    return {
      'embedding': embedding,
      'embedding_v2': embeddingV2,
      'property_code': propertyCode,
      'created_by': createdBy,
      'status': status,
      'title_ar': titleAr,
      'desc_ar': descAr,
      'region_ar': regionAr,
      'location_in_details': locationInDetails,
      'location_map': locationMap,
      'internal_notes': internalNotes,
      'manager_notes': managerNotes,
      'price': price,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      if (propertyTypeId != null) 'property_type_id': propertyTypeId,
      if (listingTypeId != null) 'listing_type_id': listingTypeId,
      if (sourceId != null) 'source_id': sourceId,
      if (cityId != null) 'city_id': cityId,
      if (governorateId != null) 'governorate_id': governorateId,
      if (approvalStatusId != null) 'approval_status_id': approvalStatusId,
      'is_pinned': isPinned,
    };
  }

  PropertyModel copyWith({
    List<double>? embedding,
    List<double>? embeddingV2,
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
    String? managerNotes,
    num? price,
    String? ownerName,
    String? ownerPhone,
    List<PropertyImageModel>? images,
    String? source,
    List<PropertyPlatformEntry>? advertisingPlatforms,
    String? propertyTypeId,
    String? listingTypeId,
    String? sourceId,
    int? cityId,
    int? governorateId,
    String? approvalStatusId,
    String? approvalStatusName,
  }) {
    return PropertyModel(
      embedding: embedding ?? this.embedding,
      embeddingV2: embeddingV2 ?? this.embeddingV2,
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
      managerNotes: managerNotes ?? this.managerNotes,
      price: price ?? this.price,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      images: images ?? this.images,
      source: source ?? this.source,
      advertisingPlatforms: advertisingPlatforms ?? this.advertisingPlatforms,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      sourceId: sourceId ?? this.sourceId,
      cityId: cityId ?? this.cityId,
      governorateId: governorateId ?? this.governorateId,
      approvalStatusId: approvalStatusId ?? this.approvalStatusId,
      approvalStatusName: approvalStatusName ?? this.approvalStatusName,
    );
  }
}
