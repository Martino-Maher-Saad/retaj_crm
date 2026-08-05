import 'property_image_model.dart';

/// مدخل منصة إعلانية مرتبطة بعقار — من جدول property_platforms
class PropertyModel {
  final String id;
  final String? propertyCode;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final bool isPinned;

  // حقول العرض النصية
  final String titleAr;
  final String descAr;
  final String listingTypeAr;
  final String propertyTypeAr;
  final String governorateAr;
  final String cityAr;
  final String? locationInDetails;
  final String? internalNotes;
  final String? managerNotes;
  final num price;
  final String? ownerName;
  final String? ownerPhone;
  final List<PropertyImageModel> images;
  final List<double>? embeddingV2;
  final String? source;
  final List<String> targetPlatforms;
  final List<String> suspendedPlatforms;
  final List<String> waitingPlatforms;

  // حقول الـ IDs الجديدة (للحفظ)
  final String? propertyTypeId;
  final String? listingTypeId;
  final String? sourceId;
  final int? cityId;
  final String? approvalStatusId;
  final String? approvalStatusName;

  // حقول النشر
  final String? publishedBy;
  final DateTime? publishedAt;

  const PropertyModel({
    this.embeddingV2,
    required this.id,
    this.propertyCode,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    required this.titleAr,
    required this.descAr,
    required this.listingTypeAr,
    required this.propertyTypeAr,
    required this.governorateAr,
    required this.cityAr,
    this.locationInDetails,
    this.internalNotes,
    this.managerNotes,
    required this.price,
    this.ownerName,
    this.ownerPhone,
    this.images = const [],
    this.source,
    this.targetPlatforms = const [],
    this.suspendedPlatforms = const [],
    this.waitingPlatforms = const [],
    this.propertyTypeId,
    this.listingTypeId,
    this.sourceId,
    this.cityId,
    this.approvalStatusId,
    this.approvalStatusName,
    this.isPinned = false,
    this.publishedBy,
    this.publishedAt,
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

    final targetPlatforms = (json['target_platforms'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final suspendedPlatforms = (json['suspended_platforms'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final waitingPlatforms = (json['waiting_platforms'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return PropertyModel(
      id: json['id']?.toString() ?? '',
      propertyCode: json['property_code'],
      createdBy: json['created_by'],
      createdByName: createdByName?.isNotEmpty == true ? createdByName : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      titleAr: json['title_ar'] ?? '',
      descAr: json['desc_ar'] ?? '',
      listingTypeAr:  listTypeMap?['name_ar'] ?? json['listing_type_ar'] ?? '',
      propertyTypeAr: propTypeMap?['name_ar'] ?? json['property_type_ar'] ?? '',
      governorateAr:  govMap?['name'] ?? json['governorate_ar'] ?? '',
      cityAr:         cityMapData?['name'] ?? json['city_ar'] ?? '',
      source:         sourceMap?['name_ar'] ?? json['source'],
      locationInDetails: json['location_in_details'],
      internalNotes: json['internal_notes'],
      managerNotes: json['manager_notes'],
      price: (json['price'] as num?) ?? 0,
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      images: imagesList,
      targetPlatforms: targetPlatforms,
      suspendedPlatforms: suspendedPlatforms,
      waitingPlatforms: waitingPlatforms,
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
      approvalStatusId: json['approval_status_id']?.toString(),
      approvalStatusName: json['property_approval_statuses']?['name_ar']?.toString(),
      isPinned:       json['is_pinned'] == true,
      publishedBy:    json['published_by']?.toString(),
      publishedAt:    json['published_at'] != null ? DateTime.parse(json['published_at']).toLocal() : null,
    );
  }

  /// toJson: يرسل الـ IDs الجديدة للأعمدة المرتبطة
  /// toJson: يرسل الـ IDs للأعمدة المرتبطة — المنصات تُدار بشكل منفصل عبر property_platforms
  Map<String, dynamic> toJson() {
    return {
      'target_platforms': targetPlatforms,
      'suspended_platforms': suspendedPlatforms,
      'waiting_platforms': waitingPlatforms,
      'embedding_v2': embeddingV2,
      'property_code': propertyCode,
      'created_by': createdBy,
      'title_ar': titleAr,
      'desc_ar': descAr,
      'location_in_details': locationInDetails,
      'internal_notes': internalNotes,
      'manager_notes': managerNotes,
      'price': price,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      if (propertyTypeId != null) 'property_type_id': propertyTypeId,
      if (listingTypeId != null) 'listing_type_id': listingTypeId,
      if (sourceId != null) 'source_id': sourceId,
      if (cityId != null) 'city_id': cityId,
      if (approvalStatusId != null) 'approval_status_id': approvalStatusId,
      'is_pinned': isPinned,
      if (publishedBy != null) 'published_by': publishedBy,
      if (publishedAt != null) 'published_at': publishedAt!.toUtc().toIso8601String(),
    };
  }

  PropertyModel copyWith({
    List<double>? embeddingV2,
    String? id,
    String? propertyCode,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    String? titleAr,
    String? descAr,
    String? listingTypeAr,
    String? propertyTypeAr,
    String? governorateAr,
    String? cityAr,
    String? locationInDetails,
    String? internalNotes,
    String? managerNotes,
    num? price,
    String? ownerName,
    String? ownerPhone,
    List<PropertyImageModel>? images,
    String? source,
    List<String>? targetPlatforms,
    List<String>? suspendedPlatforms,
    List<String>? waitingPlatforms,
    String? propertyTypeId,
    String? listingTypeId,
    String? sourceId,
    int? cityId,
    String? approvalStatusId,
    String? approvalStatusName,
    String? publishedBy,
    DateTime? publishedAt,
  }) {
    return PropertyModel(
      embeddingV2: embeddingV2 ?? this.embeddingV2,
      id: id ?? this.id,
      propertyCode: propertyCode ?? this.propertyCode,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      titleAr: titleAr ?? this.titleAr,
      descAr: descAr ?? this.descAr,
      listingTypeAr: listingTypeAr ?? this.listingTypeAr,
      propertyTypeAr: propertyTypeAr ?? this.propertyTypeAr,
      governorateAr: governorateAr ?? this.governorateAr,
      cityAr: cityAr ?? this.cityAr,
      locationInDetails: locationInDetails ?? this.locationInDetails,
      internalNotes: internalNotes ?? this.internalNotes,
      managerNotes: managerNotes ?? this.managerNotes,
      price: price ?? this.price,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      images: images ?? this.images,
      source: source ?? this.source,
      targetPlatforms: targetPlatforms ?? this.targetPlatforms,
      suspendedPlatforms: suspendedPlatforms ?? this.suspendedPlatforms,
      waitingPlatforms: waitingPlatforms ?? this.waitingPlatforms,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      sourceId: sourceId ?? this.sourceId,
      cityId: cityId ?? this.cityId,
      approvalStatusId: approvalStatusId ?? this.approvalStatusId,
      approvalStatusName: approvalStatusName ?? this.approvalStatusName,
      publishedBy: publishedBy ?? this.publishedBy,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
