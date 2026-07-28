class CrmEvent {
  final String entity; // 'lead', 'property', 'property_share', 'duplicate'
  final String action; // 'insert', 'update', 'delete', 'transfer'
  final String id;
  final String? assignedTo;
  final String? createdBy;
  final Map<String, dynamic>? data;

  CrmEvent({
    required this.entity,
    required this.action,
    required this.id,
    this.assignedTo,
    this.createdBy,
    this.data,
  });

  factory CrmEvent.fromJson(Map<String, dynamic> json) {
    return CrmEvent(
      entity: json['entity'] as String,
      action: json['action'] as String,
      id: json['id'] as String,
      assignedTo: json['assignedTo'] as String?,
      createdBy: json['createdBy'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity': entity,
      'action': action,
      'id': id,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'data': data,
    };
  }
}
