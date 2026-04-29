class LeadModel {
  final String? id;
  final String clientName;
  final List<String> clientPhone;
  final String createdBy;
  final String? createdByName; // اسم الموظف اللي أضاف العميل - من JOIN على profiles
  final String assignedTo;
  final String? assignedToName; // اسم الموظف المسؤول - من JOIN على profiles
  final DateTime? createdAt;

  // حقول نوع العقار المطلوب
  final String? listingType;     // نوع الإعلان (بيع/إيجار)
  final String? propertyType;   // نوع العقار (شقة/فيلا)
  final String? governorate;    // المحافظة المطلوبة
  final String? city;            // المدينة المطلوبة

  // حقول اختيارية
  final String? platform;        // مصدر العميل (فيسبوك/ترشيح...)
  final String? leadStatus;      // حالة العميل
  final String? descLeadNeed;    // وصف ما يريده العميل
  final String? propertyCode;    // كود عقار مرتبط (اختياري)
  final List<String> history;    // تاريخ التعليقات - array of strings
  // حقول إضافية
  final num? budgetFrom;
  final num? budgetTo;
  final String? communicationChannel;

  LeadModel({
    this.id,
    required this.clientName,
    required this.clientPhone,
    required this.createdBy,
    this.createdByName,
    required this.assignedTo,
    this.assignedToName,
    this.createdAt,
    this.listingType,
    this.propertyType,
    this.governorate,
    this.city,
    this.platform,
    this.leadStatus,
    this.descLeadNeed,
    this.propertyCode,
    this.history = const [],
    this.budgetFrom,
    this.budgetTo,
    this.communicationChannel,
  });

  LeadModel copyWith({
    String? id,
    String? clientName,
    List<String>? clientPhone,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    DateTime? createdAt,
    String? listingType,
    String? propertyType,
    String? governorate,
    String? city,
    String? platform,
    String? leadStatus,
    String? descLeadNeed,
    String? propertyCode,
    List<String>? history,
    num? budgetFrom,
    num? budgetTo,
    String? communicationChannel,
  }) {
    return LeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt ?? this.createdAt,
      listingType: listingType ?? this.listingType,
      propertyType: propertyType ?? this.propertyType,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      platform: platform ?? this.platform,
      leadStatus: leadStatus ?? this.leadStatus,
      descLeadNeed: descLeadNeed ?? this.descLeadNeed,
      propertyCode: propertyCode ?? this.propertyCode,
      history: history ?? this.history,
      budgetFrom: budgetFrom ?? this.budgetFrom,
      budgetTo: budgetTo ?? this.budgetTo,
      communicationChannel: communicationChannel ?? this.communicationChannel,
    );
  }

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    return {
      if (isUpdate) 'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'listing_type': listingType,
      'property_type': propertyType,
      'governorate': governorate,
      'city': city,
      'platform': platform,
      'lead_status': leadStatus,
      'desc_lead_need': descLeadNeed,
      'property_code': propertyCode,
      'budget_from': budgetFrom,
      'budget_to': budgetTo,
      'communication_channel': communicationChannel,
      // history لا يُرسل في الـ toJson العادي - يُحدَّث عبر دالة appendComment منفصلة
    };
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // جلب اسم من أضاف العميل
    final creator = json['creator'] as Map<String, dynamic>?;
    final createdByName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : null;

    // جلب اسم الموظف المسؤول
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final assignedToName = assignee != null
        ? '${assignee['first_name'] ?? ''} ${assignee['last_name'] ?? ''}'.trim()
        : null;

    // قراءة الـ history كـ array of strings
    final rawHistory = json['history'];
    final history = rawHistory != null
        ? List<String>.from(rawHistory as List)
        : <String>[];

    return LeadModel(
      id: json['id']?.toString(),
      clientName: json['client_name'] ?? '',
      clientPhone: json['client_phone'] != null
          ? List<String>.from(json['client_phone'])
          : [],
      createdBy: json['created_by'] ?? '',
      createdByName: createdByName?.isNotEmpty == true ? createdByName : null,
      assignedTo: json['assigned_to'] ?? '',
      assignedToName: assignedToName?.isNotEmpty == true ? assignedToName : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      listingType: json['listing_type'],
      propertyType: json['property_type'],
      governorate: json['governorate'],
      city: json['city'],
      platform: json['platform'],
      leadStatus: json['lead_status'],
      descLeadNeed: json['desc_lead_need'],
      propertyCode: json['property_code'],
      budgetFrom: json['budget_from'] != null ? num.tryParse(json['budget_from'].toString()) : null,
      budgetTo: json['budget_to'] != null ? num.tryParse(json['budget_to'].toString()) : null,
      communicationChannel: json['communication_channel'],
      history: history,
    );
  }
}