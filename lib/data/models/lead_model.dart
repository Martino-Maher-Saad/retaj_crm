import 'package:retaj_crm/core/constants/delay_config.dart';
import 'package:retaj_crm/data/models/lead_status_model.dart';
import 'package:retaj_crm/core/di/injection_container.dart' as di;
import 'package:retaj_crm/core/utils/static_data_manager.dart';

// ─────────────────────────────────────────────────────────
/// موديل رقم هاتف العميل — من جدول lead_phones
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
/// موديل ملاحظة العميل — من جدول lead_notes
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
/// موديل سجل التغييرات البسيط (للعرض داخل LeadModel)
/// للسجل التفصيلي استخدم LeadLogModel
// ─────────────────────────────────────────────────────────
class LeadLogEntryModel {
  final String id;
  final String action;
  final String? actionEn;
  final DateTime createdAt;
  final String? oldStatusName;
  final String? newStatusName;
  final String? createdByName;
  final String? notes;
  final DateTime? scheduledAt;

  const LeadLogEntryModel({
    required this.id,
    required this.action,
    this.actionEn,
    required this.createdAt,
    this.oldStatusName,
    this.newStatusName,
    this.createdByName,
    this.notes,
    this.scheduledAt,
  });

  factory LeadLogEntryModel.fromJson(Map<String, dynamic> json) {
    final dataManager = di.sl<StaticDataManager>();

    // Backend join fallback
    final oldStatusMap = json['old_status'] as Map<String, dynamic>?;
    final newStatusMap = json['new_status'] as Map<String, dynamic>?;
    final creatorMap = json['creator'] as Map<String, dynamic>?;
    final activityTypeMap = json['activity_types'] as Map<String, dynamic>?;

    // Client-side joins
    final activityTypeId = json['activity_type_id']?.toString();
    final activityTypeOption = activityTypeId != null ? dataManager.getOptionById('activity_types', activityTypeId) : null;
    
    final oldStatusId = json['old_status_id']?.toString();
    final oldStatusOption = oldStatusId != null ? dataManager.getOptionById('lead_status', oldStatusId) : null;
    
    final newStatusId = json['new_status_id']?.toString();
    final newStatusOption = newStatusId != null ? dataManager.getOptionById('lead_status', newStatusId) : null;

    final changedById = json['changed_by']?.toString();
    final employee = changedById != null ? dataManager.employees.where((e) => e.id == changedById).firstOrNull : null;

    final creatorName = creatorMap != null
        ? '${creatorMap['first_name'] ?? ''} ${creatorMap['last_name'] ?? ''}'.trim()
        : (employee != null ? '${employee.firstName ?? ''} ${employee.lastName ?? ''}'.trim() : null);

    final activityTypeName = activityTypeMap?['name_ar']?.toString() ?? activityTypeOption?.nameAr;
    final activityTypeNameEn = activityTypeMap?['name_en']?.toString() ?? activityTypeOption?.extra?['name_en']?.toString();

    final oldStatusName = oldStatusMap?['name_ar']?.toString() ?? oldStatusOption?.nameAr;
    final newStatusName = newStatusMap?['name_ar']?.toString() ?? newStatusOption?.nameAr;

    return LeadLogEntryModel(
      id: json['id']?.toString() ?? '',
      action: activityTypeName ?? json['action']?.toString() ?? '',
      actionEn: activityTypeNameEn,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      oldStatusName: oldStatusName,
      newStatusName: newStatusName,
      createdByName: creatorName?.isNotEmpty == true ? creatorName : null,
      notes: json['notes']?.toString(),
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']).toLocal() : null,
    );
  }
}

// ─────────────────────────────────────────────────────────
/// الموديل الرئيسي للعميل — من جدول leads
// ─────────────────────────────────────────────────────────
class LeadModel {
  final String? id;
  final String clientName;
  final List<LeadPhoneModel> phones;
  final String createdBy;
  final String? createdByName;
  final String assignedTo;
  final String? assignedToName;
  final DateTime? assignedToAt;
  final String? transferredFrom;
  final String? transferredFromName;
  final String? transferredBy;
  final String? transferredByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  // ─── حقول العرض النصية ───
  final String? listingType;
  final String? propertyType;
  final String? city;
  final String? platform;
  final String? leadStatus;
  final String? communicationChannel;
  final String? exclusionReasonName;

  // ─── حقول بيانات ───
  final String? descLeadNeed;
  final String? propertyCode;
  final List<LeadNoteModel> notes;
  final List<LeadLogEntryModel> logs;
  final num? budgetFrom;
  final num? budgetTo;

  // ─── IDs للربط ───
  final String? statusId;
  final String? platformId;
  final String? propertyTypeId;
  final String? listingTypeId;
  final String? channelId;
  final String? cityId;
  final String? exclusionReasonId;

  // ─── حقول الحالة ───
  final bool isPinned;
  final bool isArchived; // نحتفظ به لعدم كسر الكود القديم
  final bool isActive;

  // ─── حقول جديدة ───
  final DateTime? lastActionAt;
  final String? lastActivityTypeId;
  final String? lastActivityTypeName;
  final DateTime? scheduledDeadlineAt;
  final String? lastComment;
  final String? rateId;
  final String? rateName;
  final String? rateColorHex;
  final Map<String, dynamic>? customFields;
  final String? statusColorHex;          // لون الحالة الحالية
  final LeadStatusModel? currentStatus;  // كائن الحالة كاملاً (إن وُجد)

  // ─── كود الدولة للهاتف (legacy) ───
  final String? propertyCode2; // كان موجوداً كـ propertyCode في الكود القديم

  const LeadModel({
    this.id,
    required this.clientName,
    this.phones = const [],
    required this.createdBy,
    this.createdByName,
    required this.assignedTo,
    this.assignedToName,
    this.assignedToAt,
    this.transferredFrom,
    this.transferredFromName,
    this.transferredBy,
    this.transferredByName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.listingType,
    this.propertyType,
    this.city,
    this.platform,
    this.leadStatus,
    this.communicationChannel,
    this.exclusionReasonName,
    this.descLeadNeed,
    this.propertyCode,
    this.propertyCode2,
    this.notes = const [],
    this.logs = const [],
    this.budgetFrom,
    this.budgetTo,
    this.statusId,
    this.platformId,
    this.propertyTypeId,
    this.listingTypeId,
    this.channelId,
    this.cityId,
    this.exclusionReasonId,
    this.isPinned = false,
    this.isArchived = false,
    this.isActive = true,
    this.lastActionAt,
    this.lastActivityTypeId,
    this.lastActivityTypeName,
    this.scheduledDeadlineAt,
    this.lastComment,
    this.rateId,
    this.rateName,
    this.rateColorHex,
    this.customFields,
    this.statusColorHex,
    this.currentStatus,
  });

  // ─────────────────────────────────────────────────────────
  // fromJson
  // ─────────────────────────────────────────────────────────
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    // Client-side joins via StaticDataManager
    final dataManager = di.sl<StaticDataManager>();

    final creator = json['creator'] as Map<String, dynamic>?;
    final createdByName = creator != null
        ? '${creator['first_name'] ?? ''} ${creator['last_name'] ?? ''}'.trim()
        : json['created_by_name']?.toString();

    final assignee = json['assignee'] as Map<String, dynamic>?;
    final assignedToName = assignee != null
        ? '${assignee['first_name'] ?? ''} ${assignee['last_name'] ?? ''}'
            .trim()
        : json['assigned_to_name']?.toString();

    final transferrer = json['transferrer'] as Map<String, dynamic>?;
    final transferredFromName = transferrer != null
        ? '${transferrer['first_name'] ?? ''} ${transferrer['last_name'] ?? ''}'
            .trim()
        : json['transferred_from_name']?.toString();
    
    // local join for transferred_from and transferred_by if names are missing in json
    String? localTransferredFromName = transferredFromName;
    if (localTransferredFromName == null && json['transferred_from'] != null) {
      final emp = dataManager.employees.where((e) => e.id == json['transferred_from']).firstOrNull;
      if (emp != null) localTransferredFromName = emp.fullName;
    }

    String? localTransferredByName;
    if (json['transferred_by'] != null) {
      final emp = dataManager.employees.where((e) => e.id == json['transferred_by']).firstOrNull;
      if (emp != null) localTransferredByName = emp.fullName;
    }

    // Lookup tables
    final leadStatusMap = json['lead_statuses'] as Map<String, dynamic>?;
    final platformMap = json['advertising_platforms'] as Map<String, dynamic>?
        ?? json['lead_platforms'] as Map<String, dynamic>?;
    final propTypeMap = json['property_types'] as Map<String, dynamic>?;
    final listTypeMap = json['listing_types'] as Map<String, dynamic>?;
    final channelMap = json['communication_channels'] as Map<String, dynamic>?;
    final cityMapData = json['cities'] as Map<String, dynamic>?;
    final exclusionMap =
        json['lead_exclusion_reasons'] as Map<String, dynamic>?;

    // أرقام الهاتف
    final rawPhones = json['lead_phones'] as List?;
    final phones = rawPhones != null
        ? rawPhones
            .map((p) => LeadPhoneModel.fromJson(p as Map<String, dynamic>))
            .toList()
        : <LeadPhoneModel>[];

    // الملاحظات
    final rawNotes = json['lead_notes'] as List?;
    final notes = rawNotes != null
        ? rawNotes
            .map((n) => LeadNoteModel.fromJson(n as Map<String, dynamic>))
            .toList()
        : <LeadNoteModel>[];

    // السجلات
    final rawLogs = json['lead_logs'] as List?;
    final logs = rawLogs != null
        ? rawLogs
            .map((l) => LeadLogEntryModel.fromJson(l as Map<String, dynamic>))
            .toList()
        : <LeadLogEntryModel>[];

    // الحالة الكاملة إن وجدت
    final currentStatus = leadStatusMap != null
        ? LeadStatusModel.fromJson(leadStatusMap)
        : null;

    // Client-side lookup for new fields
    final lastActivityTypeId = json['last_activity_type_id']?.toString();
    final lastActivityTypeName = lastActivityTypeId != null
        ? dataManager.getOptionById('activity_types', lastActivityTypeId)?.nameAr
        : null;

    final rateId = json['rate_id']?.toString();
    final rateOption = rateId != null
        ? dataManager.getOptionById('lead_rates', rateId)
        : null;
    final rateName = rateOption?.nameAr;
    final rateColorHex = rateOption?.extra?['color_hex']?.toString();

    return LeadModel(
      id: json['id']?.toString(),
      clientName: json['client_name'] ?? json['name'] ?? '',
      phones: phones,
      createdBy: json['created_by'] ?? '',
      createdByName:
          createdByName?.isNotEmpty == true ? createdByName : null,
      assignedTo: json['assigned_to'] ?? '',
      assignedToName:
          assignedToName?.isNotEmpty == true ? assignedToName : null,
      assignedToAt: json['assigned_to_at'] != null
          ? DateTime.parse(json['assigned_to_at']).toLocal()
          : null,
      transferredFrom: json['transferred_from']?.toString(),
      transferredFromName:
          localTransferredFromName?.isNotEmpty == true ? localTransferredFromName : null,
      transferredBy: json['transferred_by']?.toString(),
      transferredByName:
          localTransferredByName?.isNotEmpty == true ? localTransferredByName : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toLocal()
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at']).toLocal()
          : null,
      leadStatus: leadStatusMap?['name_ar'] ?? json['status_name'] ?? dataManager.getOptionById('lead_statuses', json['status_id']?.toString() ?? '')?.nameAr,
      platform: platformMap?['name_ar'] ?? json['platform_name'] ?? dataManager.getOptionById('lead_platforms', json['platform_id']?.toString() ?? '')?.nameAr,
      propertyType: propTypeMap?['name_ar'] ?? json['property_type_name'] ?? dataManager.getOptionById('property_types', json['property_type_id']?.toString() ?? '')?.nameAr,
      listingType: listTypeMap?['name_ar'] ?? json['listing_type_name'] ?? dataManager.getOptionById('listing_types', json['listing_type_id']?.toString() ?? '')?.nameAr,
      communicationChannel:
          channelMap?['name_ar'] ?? json['channel_name'] ?? dataManager.getOptionById('communication_channels', json['channel_id']?.toString() ?? '')?.nameAr,
      city: cityMapData?['name'] ?? json['city_name'] ?? dataManager.getOptionById('cities', json['city_id']?.toString() ?? '')?.nameAr,
      exclusionReasonName:
          exclusionMap?['name_ar'] ?? json['exclusion_reason_name'] ?? dataManager.getOptionById('lead_exclusion_reasons', json['exclusion_reason_id']?.toString() ?? '')?.nameAr,
      statusId: json['status_id']?.toString(),
      platformId: json['platform_id']?.toString(),
      propertyTypeId: json['property_type_id']?.toString(),
      listingTypeId: json['listing_type_id']?.toString(),
      channelId: json['channel_id']?.toString(),
      cityId: json['city_id']?.toString(),
      exclusionReasonId: json['exclusion_reason_id']?.toString(),
      descLeadNeed: json['desc_lead_need'],
      propertyCode: json['property_code'],
      budgetFrom: json['budget_from'] != null
          ? num.tryParse(json['budget_from'].toString())
          : null,
      budgetTo: json['budget_to'] != null
          ? num.tryParse(json['budget_to'].toString())
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 'true' || json['is_active'] == 1 || json['is_active'] == null,
      isArchived: json['is_active'] == false || json['is_active'] == 'false' || json['is_active'] == 0,
      isPinned: json['is_pinned'] ?? false,
      lastActionAt: json['last_action_at'] != null
          ? DateTime.parse(json['last_action_at']).toLocal()
          : null,
      lastActivityTypeId: lastActivityTypeId,
      lastActivityTypeName: lastActivityTypeName,
      scheduledDeadlineAt: json['scheduled_deadline_at'] != null
          ? DateTime.parse(json['scheduled_deadline_at']).toLocal()
          : null,
      lastComment: json['last_comment']?.toString(),
      rateId: rateId,
      rateName: rateName,
      rateColorHex: rateColorHex,
      customFields: json['custom_fields'] as Map<String, dynamic>?,
      statusColorHex: leadStatusMap?['color_hex']?.toString(),
      currentStatus: currentStatus,
      notes: notes,
      logs: logs,
    );
  }

  // ─────────────────────────────────────────────────────────
  // copyWith
  // ─────────────────────────────────────────────────────────
  LeadModel copyWith({
    String? id,
    String? clientName,
    List<LeadPhoneModel>? phones,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedToAt,
    String? transferredFrom,
    String? transferredFromName,
    String? transferredBy,
    String? transferredByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? listingType,
    String? propertyType,
    String? city,
    String? platform,
    String? leadStatus,
    String? communicationChannel,
    String? exclusionReasonName,
    String? descLeadNeed,
    String? propertyCode,
    List<LeadNoteModel>? notes,
    List<LeadLogEntryModel>? logs,
    num? budgetFrom,
    num? budgetTo,
    String? statusId,
    String? platformId,
    String? propertyTypeId,
    String? listingTypeId,
    String? channelId,
    String? cityId,
    String? exclusionReasonId,
    bool? isPinned,
    bool? isArchived,
    bool? isActive,
    DateTime? lastActionAt,
    String? lastActivityTypeId,
    String? lastActivityTypeName,
    DateTime? scheduledDeadlineAt,
    String? lastComment,
    String? rateId,
    String? rateName,
    String? rateColorHex,
    Map<String, dynamic>? customFields,
    String? statusColorHex,
    LeadStatusModel? currentStatus,
  }) {
    return LeadModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      phones: phones ?? this.phones,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToAt: assignedToAt ?? this.assignedToAt,
      transferredFrom: transferredFrom ?? this.transferredFrom,
      transferredFromName: transferredFromName ?? this.transferredFromName,
      transferredBy: transferredBy ?? this.transferredBy,
      transferredByName: transferredByName ?? this.transferredByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      listingType: listingType ?? this.listingType,
      propertyType: propertyType ?? this.propertyType,
      city: city ?? this.city,
      platform: platform ?? this.platform,
      leadStatus: leadStatus ?? this.leadStatus,
      communicationChannel: communicationChannel ?? this.communicationChannel,
      exclusionReasonName: exclusionReasonName ?? this.exclusionReasonName,
      descLeadNeed: descLeadNeed ?? this.descLeadNeed,
      propertyCode: propertyCode ?? this.propertyCode,
      notes: notes ?? this.notes,
      logs: logs ?? this.logs,
      budgetFrom: budgetFrom ?? this.budgetFrom,
      budgetTo: budgetTo ?? this.budgetTo,
      statusId: statusId ?? this.statusId,
      platformId: platformId ?? this.platformId,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      channelId: channelId ?? this.channelId,
      cityId: cityId ?? this.cityId,
      exclusionReasonId: exclusionReasonId ?? this.exclusionReasonId,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isActive: isActive ?? this.isActive,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      lastActivityTypeId: lastActivityTypeId ?? this.lastActivityTypeId,
      lastActivityTypeName: lastActivityTypeName ?? this.lastActivityTypeName,
      scheduledDeadlineAt: scheduledDeadlineAt ?? this.scheduledDeadlineAt,
      lastComment: lastComment ?? this.lastComment,
      rateId: rateId ?? this.rateId,
      rateName: rateName ?? this.rateName,
      rateColorHex: rateColorHex ?? this.rateColorHex,
      customFields: customFields ?? this.customFields,
      statusColorHex: statusColorHex ?? this.statusColorHex,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  /// الهاتف الأساسي
  String? get primaryPhone {
    if (phones.isEmpty) return null;
    try {
      return phones.firstWhere((p) => p.isPrimary).phoneNumber;
    } catch (_) {
      return phones.first.phoneNumber;
    }
  }

  /// هل العميل في المهملات
  bool get isTrashed => deletedAt != null;

  /// هل العميل متأخر في المتابعة
  bool get isDelayed => DelayConfig.isLeadDelayed(
        lastActionAt: lastActionAt,
        delayValue: currentStatus?.delayValue,
        delayUnit: currentStatus?.delayUnit,
      );

  /// هل العميل في مرحلة Fresh
  bool get isFresh => currentStatus?.isFresh ?? false;
}