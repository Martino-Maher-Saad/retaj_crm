/// موديل سجل الأحداث — من جدول lead_logs
/// يُستخدم في صفحة التايملاين لعرض تاريخ العميل
class LeadLogModel {
  final String id;
  final String leadId;
  final String action;
  final String? performedById;
  final String? performedByName;
  final DateTime createdAt;

  // بيانات الحالة
  final String? oldStatusId;
  final String? oldStatusName;
  final String? newStatusId;
  final String? newStatusName;

  // بيانات التحويل
  final String? oldAssignedToId;
  final String? oldAssignedToName;
  final String? newAssignedToId;
  final String? newAssignedToName;

  // بيانات الأكشن
  final String? notes;
  final bool? isAnswered;
  final DateTime? scheduledDeadlineAt;

  // بيانات إضافية حسب نوع الأكشن (JSONB)
  final Map<String, dynamic>? actionData;

  const LeadLogModel({
    required this.id,
    required this.leadId,
    required this.action,
    required this.createdAt,
    this.performedById,
    this.performedByName,
    this.oldStatusId,
    this.oldStatusName,
    this.newStatusId,
    this.newStatusName,
    this.oldAssignedToId,
    this.oldAssignedToName,
    this.newAssignedToId,
    this.newAssignedToName,
    this.notes,
    this.isAnswered,
    this.scheduledDeadlineAt,
    this.actionData,
  });

  factory LeadLogModel.fromJson(Map<String, dynamic> json) {
    // قراءة اسم من قام بالأكشن
    final performedBy = json['performed_by_profile'] as Map<String, dynamic>?;
    final performedByName = performedBy != null
        ? '${performedBy['first_name'] ?? ''} ${performedBy['last_name'] ?? ''}'
            .trim()
        : null;

    // قراءة الحالات القديمة والجديدة
    final oldStatus = json['old_status'] as Map<String, dynamic>?;
    final newStatus = json['new_status'] as Map<String, dynamic>?;

    // قراءة بيانات التحويل
    final oldAssignee = json['old_assignee'] as Map<String, dynamic>?;
    final newAssignee = json['new_assignee'] as Map<String, dynamic>?;

    return LeadLogModel(
      id: json['id'] ?? '',
      leadId: json['lead_id'] ?? '',
      action: json['action'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      performedById: json['performed_by']?.toString(),
      performedByName: performedByName?.isNotEmpty == true
          ? performedByName
          : null,
      oldStatusId: json['old_status_id']?.toString(),
      oldStatusName: oldStatus?['name_ar']?.toString() ??
          json['old_status_name']?.toString(),
      newStatusId: json['new_status_id']?.toString(),
      newStatusName: newStatus?['name_ar']?.toString() ??
          json['new_status_name']?.toString(),
      oldAssignedToId: json['old_assigned_to']?.toString(),
      oldAssignedToName: oldAssignee != null
          ? '${oldAssignee['first_name'] ?? ''} ${oldAssignee['last_name'] ?? ''}'
              .trim()
          : json['old_assigned_to_name']?.toString(),
      newAssignedToId: json['new_assigned_to']?.toString(),
      newAssignedToName: newAssignee != null
          ? '${newAssignee['first_name'] ?? ''} ${newAssignee['last_name'] ?? ''}'
              .trim()
          : json['new_assigned_to_name']?.toString(),
      notes: json['notes']?.toString(),
      isAnswered: json['is_answered'] as bool?,
      scheduledDeadlineAt: json['scheduled_deadline_at'] != null
          ? DateTime.parse(json['scheduled_deadline_at']).toLocal()
          : null,
      actionData: json['action_data'] as Map<String, dynamic>?,
    );
  }

  // ─── helpers ───

  /// الأيقونة حسب نوع الأكشن
  String get actionIcon {
    switch (action) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'action':
        return '📋';
      case 'trash':
        return '🗑️';
      case 'restore':
        return '♻️';
      case 'transfer':
        return '🔁';
      default:
        return '📌';
    }
  }

  /// الوصف النصي للأكشن
  String get actionDescription {
    switch (action) {
      case 'create':
        return 'تم إنشاء العميل';
      case 'update':
        return 'تم تعديل البيانات';
      case 'action':
        final statusChange = (newStatusName != null)
            ? ' → $newStatusName'
            : '';
        return 'أكشن$statusChange';
      case 'trash':
        return 'تم النقل للمهملات';
      case 'restore':
        return 'تمت الاستعادة';
      case 'transfer':
        final to = newAssignedToName ?? 'موظف آخر';
        return 'تم التحويل إلى $to';
      default:
        return action;
    }
  }
}
