
class LeadModel {
  final String? id;
  final String clientName;
  final List<String> clientPhone;
  final String? propertyId;
  final String createdBy;
  final String? comment;
  final String? propertyCode;
  final DateTime? createdAt;
  final String? city;
  final String? source;
  final String? leadStatus;
  final String? descLeadNeed;
  final String assignedTo;

  LeadModel({
    this.id,
    required this.clientName,
    required this.clientPhone,
    this.propertyId,
    required this.createdBy,
    this.comment,
    this.propertyCode,
    this.createdAt,
    this.city,
    this.source,
    this.leadStatus,
    this.descLeadNeed,
    required this.assignedTo,
  });

  // دالة copyWith لإعادة إنشاء الكائن مع تعديل حقول محددة فقط
  LeadModel copyWith({
    String? id,
    String? clientName,
    List<String>? clientPhone,
    String? propertyId,
    String? createdBy,
    String? comment,
    String? propertyCode,
    DateTime? createdAt,
    String? city,
    String? source,
    String? leadStatus,
    String? descLeadNeed,
    String? assignedTo,
  }) {
    return LeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      propertyId: propertyId ?? this.propertyId,
      createdBy: createdBy ?? this.createdBy,
      comment: comment ?? this.comment,
      propertyCode: propertyCode ?? this.propertyCode,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      source: source ?? this.source,
      leadStatus: leadStatus ?? this.leadStatus,
      descLeadNeed: descLeadNeed ?? this.descLeadNeed,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    return {
      if (isUpdate) 'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'property_id': propertyId,
      'created_by': createdBy,
      'comment': comment,
      'property_code': propertyCode,
      'city': city,
      'source': source,
      'lead_status': leadStatus,
      'desc_lead_need': descLeadNeed,
      'assigned_to': assignedTo,
    };
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'] != null
          ? List<String>.from(json['client_phone'])
          : [],
      propertyId: json['property_id'],
      createdBy: json['created_by'],
      comment: json['comment'],
      propertyCode: json['property_code'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      city: json['city'],
      source: json['source'],
      leadStatus: json['lead_status'],
      descLeadNeed: json['desc_lead_need'],
      assignedTo: json['assigned_to'],
    );
  }
}