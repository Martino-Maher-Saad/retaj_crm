/// موديل رقم هاتف العميل — من جدول lead_phones
class LeadPhoneModel {
  final String? id;
  final String phoneNumber;
  final bool isPrimary;

  const LeadPhoneModel({
    this.id,
    required this.phoneNumber,
    this.isPrimary = false,
  });

  factory LeadPhoneModel.fromJson(Map<String, dynamic> json) {
    return LeadPhoneModel(
      id: json['id']?.toString(),
      phoneNumber: json['phone_number'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'is_primary': isPrimary,
  };

  @override
  bool operator ==(Object other) =>
      other is LeadPhoneModel &&
      other.phoneNumber == phoneNumber &&
      other.isPrimary == isPrimary;

  @override
  int get hashCode => Object.hash(phoneNumber, isPrimary);
}

/// موديل ملاحظة العميل — من جدول lead_notes
class LeadNoteModel {
  final String? id;
  final String noteText;
  final DateTime? createdAt;
  final String? userId;
  final String? userName;

  const LeadNoteModel({
    this.id,
    required this.noteText,
    this.createdAt,
    this.userId,
    this.userName,
  });

  factory LeadNoteModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final userName = userMap != null
        ? '${userMap['first_name'] ?? ''} ${userMap['last_name'] ?? ''}'.trim()
        : null;

    return LeadNoteModel(
      id: json['id']?.toString(),
      noteText: json['note_text'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      userId: json['user_id']?.toString(),
      userName: userName?.isNotEmpty == true ? userName : null,
    );
  }
}

class LeadModel {
  final String? id;
  final String clientName;
  final List<LeadPhoneModel> phones;
  final String createdBy;
  final String? createdByName;
  final String assignedTo;
  final String? assignedToName;
  final String? transferredFrom;
  final String? transferredFromName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // حقول العرض النصية
  final String? listingType;
  final String? propertyType;
  final String? governorate;
  final String? city;
  final String? platform;
  final String? leadStatus;
  final String? communicationChannel;
  final String? exclusionReasonName;

  // حقول أخرى
  final String? descLeadNeed;
  final String? propertyCode;
  final List<LeadNoteModel> notes;
  final num? budgetFrom;
  final num? budgetTo;

  // حقول الـ IDs والحالات الجديدة
  final String? statusId;
  final String? platformId;
  final String? propertyTypeId;
  final String? listingTypeId;
  final String? channelId;
  final int? cityId;
  final int? governorateId;
  final String? exclusionReasonId;
  
  final bool isActive;
  final bool isArchived;
  final bool isPinned;

  LeadModel({
    this.id,
    required this.clientName,
    this.phones = const [],
    required this.createdBy,
    this.createdByName,
    required this.assignedTo,
    this.assignedToName,
    this.transferredFrom,
    this.transferredFromName,
    this.createdAt,
    this.updatedAt,
    this.listingType,
    this.propertyType,
    this.governorate,
    this.city,
    this.platform,
    this.leadStatus,
    this.communicationChannel,
    this.exclusionReasonName,
    this.descLeadNeed,
    this.propertyCode,
    this.notes = const [],
    this.budgetFrom,
    this.budgetTo,
    this.statusId,
    this.platformId,
    this.propertyTypeId,
    this.listingTypeId,
    this.channelId,
    this.cityId,
    this.governorateId,
    this.exclusionReasonId,
    this.isActive = true,
    this.isArchived = false,
    this.isPinned = false,
  });

  LeadModel copyWith({
    String? id,
    String? clientName,
    List<LeadPhoneModel>? phones,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    String? transferredFrom,
    String? transferredFromName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? listingType,
    String? propertyType,
    String? governorate,
    String? city,
    String? platform,
    String? leadStatus,
    String? communicationChannel,
    String? exclusionReasonName,
    String? descLeadNeed,
    String? propertyCode,
    List<LeadNoteModel>? notes,
    num? budgetFrom,
    num? budgetTo,
    String? statusId,
    String? platformId,
    String? propertyTypeId,
    String? listingTypeId,
    String? channelId,
    int? cityId,
    int? governorateId,
    String? exclusionReasonId,
    bool? isActive,
    bool? isArchived,
    bool? isPinned,
  }) {
    return LeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      phones: phones ?? this.phones,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      transferredFrom: transferredFrom ?? this.transferredFrom,
      transferredFromName: transferredFromName ?? this.transferredFromName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      listingType: listingType ?? this.listingType,
      propertyType: propertyType ?? this.propertyType,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      platform: platform ?? this.platform,
      leadStatus: leadStatus ?? this.leadStatus,
      communicationChannel: communicationChannel ?? this.communicationChannel,
      exclusionReasonName: exclusionReasonName ?? this.exclusionReasonName,
      descLeadNeed: descLeadNeed ?? this.descLeadNeed,
      propertyCode: propertyCode ?? this.propertyCode,
      notes: notes ?? this.notes,
      budgetFrom: budgetFrom ?? this.budgetFrom,
      budgetTo: budgetTo ?? this.budgetTo,
      statusId: statusId ?? this.statusId,
      platformId: platformId ?? this.platformId,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      channelId: channelId ?? this.channelId,
      cityId: cityId ?? this.cityId,
      governorateId: governorateId ?? this.governorateId,
      exclusionReasonId: exclusionReasonId ?? this.exclusionReasonId,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // دعم قراءة الأسماء إما من الـ JSON المتداخل (Relations) أو من الـ View المسطح
    
    final creator = json['creator'] as Map<String, dynamic>?;
    final createdByName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : json['created_by_name']?.toString();

    final assignee = json['assignee'] as Map<String, dynamic>?;
    final assignedToName = assignee != null
        ? '${assignee['first_name'] ?? ''} ${assignee['last_name'] ?? ''}'.trim()
        : json['assigned_to_name']?.toString();

    final transferrer = json['transferrer'] as Map<String, dynamic>?;
    final transferredFromName = transferrer != null
        ? '${transferrer['first_name'] ?? ''} ${transferrer['last_name'] ?? ''}'.trim()
        : json['transferred_from_name']?.toString();

    // جداول الـ lookup المتداخلة
    final leadStatusMap = json['lead_statuses'] as Map<String, dynamic>?;
    final platformMap   = json['lead_platforms'] as Map<String, dynamic>?;
    final propTypeMap   = json['property_types'] as Map<String, dynamic>?;
    final listTypeMap   = json['listing_types'] as Map<String, dynamic>?;
    final channelMap    = json['communication_channels'] as Map<String, dynamic>?;
    final govMap        = json['governorates'] as Map<String, dynamic>?;
    final cityMapData   = json['cities'] as Map<String, dynamic>?;
    final exclusionMap  = json['lead_exclusion_reasons'] as Map<String, dynamic>?;

    // أرقام الهاتف من lead_phones
    final rawPhones = json['lead_phones'] as List?;
    final phones = rawPhones != null
        ? rawPhones
            .map((p) => LeadPhoneModel.fromJson(p as Map<String, dynamic>))
            .toList()
        : <LeadPhoneModel>[];

    // الملاحظات من lead_notes
    final rawNotes = json['lead_notes'] as List?;
    final notes = rawNotes != null
        ? rawNotes
            .map((n) => LeadNoteModel.fromJson(n as Map<String, dynamic>))
            .toList()
        : <LeadNoteModel>[];

    return LeadModel(
      id: json['id']?.toString(),
      clientName: json['client_name'] ?? '',
      phones: phones,
      createdBy: json['created_by'] ?? '',
      createdByName: createdByName?.isNotEmpty == true ? createdByName : null,
      assignedTo: json['assigned_to'] ?? '',
      assignedToName: assignedToName?.isNotEmpty == true ? assignedToName : null,
      transferredFrom: json['transferred_from']?.toString(),
      transferredFromName: transferredFromName?.isNotEmpty == true ? transferredFromName : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toLocal()
          : null,
          
      // قراءة الاسم سواء من Relation أو من الـ View المسطح
      leadStatus:           leadStatusMap?['name_ar'] ?? json['status_name'],
      platform:             platformMap?['name_ar'] ?? json['platform_name'],
      propertyType:         propTypeMap?['name_ar'] ?? json['property_type_name'],
      listingType:          listTypeMap?['name_ar'] ?? json['listing_type_name'],
      communicationChannel: channelMap?['name_ar'] ?? json['channel_name'],
      governorate:          govMap?['name'] ?? json['governorate_name'],
      city:                 cityMapData?['name'] ?? json['city_name'],
      exclusionReasonName:  exclusionMap?['name_ar'] ?? json['exclusion_reason_name'],
      
      statusId:       json['status_id']?.toString(),
      platformId:     json['platform_id']?.toString(),
      propertyTypeId: json['property_type_id']?.toString(),
      listingTypeId:  json['listing_type_id']?.toString(),
      channelId:      json['channel_id']?.toString(),
      cityId:         json['city_id'] as int?,
      governorateId:  json['governorate_id'] as int?,
      exclusionReasonId: json['exclusion_reason_id']?.toString(),
      
      descLeadNeed: json['desc_lead_need'],
      propertyCode: json['property_code'],
      budgetFrom: json['budget_from'] != null
          ? num.tryParse(json['budget_from'].toString()) : null,
      budgetTo: json['budget_to'] != null
          ? num.tryParse(json['budget_to'].toString()) : null,
          
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      
      notes: notes,
    );
  }
}