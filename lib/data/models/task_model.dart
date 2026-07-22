class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final String assignedTo;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String statusId;
  final String? leadId;
  final String? propertyId;

  // الحقول المجلوبة (Joined Fields)
  final String? createdByName;
  final String? assignedToName;
  final String? statusName;
  final String? leadClientName;
  final String? propertyTitle;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.assignedTo,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.statusId,
    this.leadId,
    this.propertyId,
    //
    this.createdByName,
    this.assignedToName,
    this.statusName,
    this.leadClientName,
    this.propertyTitle,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // التعامل مع الحقول المرتبطة (Relations) إذا كانت متضمنة في الاستعلام
    final creator = json['creator'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final statusObj = json['task_statuses'] as Map<String, dynamic>?;
    final leadObj = json['leads'] as Map<String, dynamic>?;
    final propertyObj = json['properties'] as Map<String, dynamic>?;

    String? parseName(Map<String, dynamic>? data) {
      if (data == null) return null;
      final f = data['first_name'] ?? '';
      final l = data['last_name'] ?? '';
      return '$f $l'.trim();
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      createdBy: json['created_by']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString() ?? '',
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']).toLocal() 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']).toLocal() 
          : DateTime.now(),
      statusId: json['status_id']?.toString() ?? '',
      leadId: json['lead_id']?.toString(),
      propertyId: json['property_id']?.toString(),

      createdByName: parseName(creator),
      assignedToName: parseName(assignee),
      statusName: statusObj?['name_ar']?.toString(),
      leadClientName: leadObj?['client_name']?.toString(),
      propertyTitle: propertyObj?['title_ar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'end_date': endDate.toUtc().toIso8601String(),
      'status_id': statusId,
      if (leadId != null) 'lead_id': leadId,
      if (propertyId != null) 'property_id': propertyId,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? statusId,
    String? leadId,
    String? propertyId,
    String? createdByName,
    String? assignedToName,
    String? statusName,
    String? leadClientName,
    String? propertyTitle,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusId: statusId ?? this.statusId,
      leadId: leadId ?? this.leadId,
      propertyId: propertyId ?? this.propertyId,
      createdByName: createdByName ?? this.createdByName,
      assignedToName: assignedToName ?? this.assignedToName,
      statusName: statusName ?? this.statusName,
      leadClientName: leadClientName ?? this.leadClientName,
      propertyTitle: propertyTitle ?? this.propertyTitle,
    );
  }
}
