import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../../core/constants/app_roles.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/utils/static_data_manager.dart';

class LeadService {
  final _supabase = Supabase.instance.client;

  static bool _isManagerOrAdmin(String role) =>
      AppRole.fromString(role).isAtLeast(AppRole.manager);

  // ─── SELECT للقائمة (بدون notes لتسريع التحميل) ───
  static const _selectList =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar, delay_value, delay_unit), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'lead_exclusion_reasons!exclusion_reason_id(name_ar), '
      'lead_phones(id, phone_number, is_primary), '
      'lead_logs(id, activity_type_id, created_at, notes, scheduled_at, changed_by, old_status_id, new_status_id, is_answered)';

  static const _selectDetail =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar, delay_value, delay_unit), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'lead_exclusion_reasons!exclusion_reason_id(name_ar), '
      'lead_phones(id, phone_number, is_primary), '
      'lead_logs(id, activity_type_id, created_at, notes, scheduled_at, changed_by, old_status_id, new_status_id, is_answered), '
      'lead_notes(id, note_text, created_at, user_id, user:profiles!lead_notes_user_id_fkey(first_name, last_name))';

  // نفس الـ _selectDetail بدون lead_logs — تُجلب بـ fetchLeadLogs() منفصلة
  static const _selectExcelTable =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar, delay_value, delay_unit), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'lead_exclusion_reasons!exclusion_reason_id(name_ar), '
      'lead_phones(id, phone_number, is_primary), '
      'lead_logs(id, activity_type_id, created_at, notes, scheduled_at, changed_by, old_status_id, new_status_id, is_answered), '
      'lead_notes(id, note_text, created_at, user_id, user:profiles!lead_notes_user_id_fkey(first_name, last_name))';

  // لعدم جلب الـ logs لتوفير الكاش
  static const _selectBasic =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar, delay_value, delay_unit), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'lead_exclusion_reasons!exclusion_reason_id(name_ar), '
      'lead_phones(id, phone_number, is_primary), '
      'lead_notes(id, note_text, created_at, user_id, user:profiles!lead_notes_user_id_fkey(first_name, last_name))';

  Future<List<LeadModel>> fetchAllLeads({
    required String role,
    required String userId,
    required int from,
    required int to,
    String? filterByEmployeeId,
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isTrash,
    List<String>? statusIds,
    bool? isTransferred, // للعملاء المحولين
    bool? delayFilter, // للعملاء المتأخرين
  }) async {
    dynamic query = _supabase.from('leads').select(_selectList);

    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (isTrash == true) {
      query = query.eq('is_active', false);
    } else {
      query = query.or('is_active.eq.true,is_active.is.null');
    }

    if (statusIds != null && statusIds.isNotEmpty) {
      query = query.filter('status_id', 'in', statusIds);
    }

    if (isTransferred == true) {
      query = query.not('transferred_from', 'is', null);
    }

    if (platformId != null && platformId.isNotEmpty) query = query.eq('platform_id', platformId);
    if (leadStatusId != null && leadStatusId.isNotEmpty) query = query.eq('status_id', leadStatusId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    // ترتيب بحيث يظهر المثبت (is_pinned = true) أولاً
    query = query.order('is_pinned', ascending: false).order('created_at', ascending: false);

    if (delayFilter == true) {
      final response = await _supabase.rpc('get_delayed_leads', params: {
        'p_user_id': userId,
        'p_role': role,
        'p_from': from,
        'p_to': to,
      });
      return (response as List).map((e) => LeadModel.fromJson(e)).toList();
    }

    final response = await query.range(from, to - 1);
    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  Future<int> getLeadsCount({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isTrash,
    List<String>? statusIds,
    bool? isTransferred,
    bool? delayFilter,
  }) async {
    var query = _supabase.from('leads').select(delayFilter == true ? _selectList : 'id');

    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (isTrash == true) {
      query = query.eq('is_active', false);
    } else {
      query = query.or('is_active.eq.true,is_active.is.null');
    }

    if (statusIds != null && statusIds.isNotEmpty) {
      query = query.filter('status_id', 'in', statusIds);
    }

    if (isTransferred == true) {
      query = query.not('transferred_from', 'is', null);
    }

    if (platformId != null && platformId.isNotEmpty) query = query.eq('platform_id', platformId);
    if (leadStatusId != null && leadStatusId.isNotEmpty) query = query.eq('status_id', leadStatusId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    if (delayFilter == true) {
      final response = await _supabase.rpc('get_delayed_leads_count', params: {
        'p_user_id': userId,
        'p_role': role,
      });
      return (response as int?) ?? 0;
    }

    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
  }

  Future<List<LeadModel>> fetchDashboardExcelLeads({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    String? listingTypeId,
    String? propertyTypeId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    dynamic query = _supabase.from('leads').select(_selectExcelTable);

    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    query = query.order('created_at', ascending: false);

    final response = await query;
    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  /// إضافة عميل جديد — يستخدم RPC لضمان atomicity
  Future<LeadModel> addLead(
    LeadModel lead,
    List<LeadPhoneModel> phones, {
    List<LeadNoteModel> notes = const [],
  }) async {
    final phonesJson = phones.map((p) => p.toJson()).toList();
    final notesJson = notes
        .where((n) => n.noteText.trim().isNotEmpty)
        .map((n) => {'note_text': n.noteText.trim()})
        .toList();

    final leadId = await _supabase.rpc('create_lead_with_details', params: {
      'p_client_name':      lead.clientName,
      'p_assigned_to':      lead.assignedTo,
      'p_status_id':        lead.statusId,
      'p_platform_id':      lead.platformId,
      'p_property_type_id': lead.propertyTypeId,
      'p_listing_type_id':  lead.listingTypeId,
      'p_channel_id':       lead.channelId,
      'p_city_id':          lead.cityId,
      'p_governorate_id':   null,
      'p_property_code':    lead.propertyCode,
      'p_desc_lead_need':   lead.descLeadNeed,
      'p_budget_from':      lead.budgetFrom,
      'p_budget_to':        lead.budgetTo,
      'p_exclusion_reason_id': lead.exclusionReasonId,
      'p_is_pinned':        lead.isPinned,
      'p_is_archived':      lead.isArchived,
      'p_is_active':        lead.isActive,
      'p_phones':           phonesJson,
      'p_notes':            notesJson,
    });

    if ((lead.customFields != null && lead.customFields!.isNotEmpty) || lead.rateId != null || lead.lastActivityTypeId != null || lead.transferredFrom != null || lead.transferredBy != null || lead.lastComment != null || lead.assignedToAt != null || lead.scheduledDeadlineAt != null) {
      await _supabase.from('leads').update({
        if (lead.customFields != null && lead.customFields!.isNotEmpty) 'custom_fields': lead.customFields,
        if (lead.rateId != null) 'rate_id': lead.rateId,
        if (lead.lastActivityTypeId != null) 'last_activity_type_id': lead.lastActivityTypeId,
        if (lead.transferredFrom != null) 'transferred_from': lead.transferredFrom,
        if (lead.transferredBy != null) 'transferred_by': lead.transferredBy,
        if (lead.lastComment != null) 'last_comment': lead.lastComment,
        if (lead.assignedToAt != null) 'assigned_to_at': lead.assignedToAt!.toIso8601String(),
        if (lead.scheduledDeadlineAt != null) 'scheduled_deadline_at': lead.scheduledDeadlineAt!.toIso8601String(),
      }).eq('id', leadId);
    }

    return await getLeadById(leadId.toString());
  }

  /// تحديث عميل — يستخدم RPC للـ Smart Sync
  Future<LeadModel> updateLead(
    String id,
    LeadModel lead,
    List<LeadPhoneModel> phones, {
    String? newNote,
  }) async {
    final phonesJson = phones.map((p) => p.toJson()).toList();

    await _supabase.rpc('update_lead_with_details', params: {
      'p_lead_id':          id,
      'p_client_name':      lead.clientName,
      'p_assigned_to':      lead.assignedTo,
      'p_status_id':        lead.statusId,
      'p_platform_id':      lead.platformId,
      'p_property_type_id': lead.propertyTypeId,
      'p_listing_type_id':  lead.listingTypeId,
      'p_channel_id':       lead.channelId,
      'p_city_id':          lead.cityId,
      'p_governorate_id':   null,
      'p_property_code':    lead.propertyCode,
      'p_desc_lead_need':   lead.descLeadNeed,
      'p_budget_from':      lead.budgetFrom,
      'p_budget_to':        lead.budgetTo,
      'p_exclusion_reason_id': lead.exclusionReasonId,
      'p_is_pinned':        lead.isPinned,
      'p_is_archived':      lead.isArchived,
      'p_is_active':        lead.isActive,
      'p_phones':           phonesJson,
      'p_new_note':         newNote ?? '',
    });

    // تحديث الحقول التي لا يدعمها الـ RPC بشكل منفصل
    await _supabase.from('leads').update({
      if (lead.transferredFrom != null) 'transferred_from': lead.transferredFrom,
      if (lead.transferredBy != null) 'transferred_by': lead.transferredBy,
      if (lead.customFields != null) 'custom_fields': lead.customFields,
      if (lead.rateId != null) 'rate_id': lead.rateId,
      if (lead.lastActivityTypeId != null) 'last_activity_type_id': lead.lastActivityTypeId,
      if (lead.lastComment != null) 'last_comment': lead.lastComment,
      if (lead.assignedToAt != null) 'assigned_to_at': lead.assignedToAt!.toIso8601String(),
      if (lead.scheduledDeadlineAt != null) 'scheduled_deadline_at': lead.scheduledDeadlineAt!.toIso8601String(),
    }).eq('id', id);

    return await getLeadById(id);
  }

  /// تحديث متجه البحث لطلب العميل (Embedding) في قاعدة البيانات
  Future<void> updateLeadEmbedding(String id, List<double>? vector) async {
    await _supabase.from('leads').update({
      'embedding': vector,
    }).eq('id', id);
  }

  Future<void> archiveLead(String id, bool isArchived) async {
    final expectedIsActive = !isArchived;
    final response = await _supabase.from('leads').update({
      'is_active': expectedIsActive,
      'deleted_at': isArchived ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).select();

    if (response.isEmpty) {
      throw 'حدث خطأ: لا تملك صلاحية التعديل على هذا العميل، أو أن العميل غير موجود.';
    }
    
    if (response.first['is_active'] != expectedIsActive) {
      throw 'حدث خطأ: قاعدة البيانات ترفض تغيير حالة العميل (Trigger Error).';
    }
  }

  Future<LeadModel> transferLead({
    required String leadId,
    required String fromEmployeeId,
    required String toEmployeeId,
    required String changedBy,
    String? notes,
  }) async {
    final dataManager = di.sl<StaticDataManager>();
    final options = dataManager.getRefTableOptions('activity_types');
    String? transferActivityId;
    try {
      transferActivityId = options.firstWhere((o) => o.nameAr.contains('تحويل') || (o.extra?['name_en']?.toString().toLowerCase().contains('transfer') ?? false)).id;
    } catch (_) {}

    await _supabase.from('lead_logs').insert({
      'lead_id': leadId,
      if (transferActivityId != null) 'activity_type_id': transferActivityId,
      'transferred_from_id': fromEmployeeId,
      'transferred_to_id': toEmployeeId,
      'changed_by': changedBy,
      'notes': notes,
    });

    return await getLeadById(leadId);
  }

  Future<void> addLeadAction({
    required String leadId,
    required String comment,
    required String nextStatusId,
    DateTime? scheduledAt,
    String? meetingTypeId,
    String? meetingPurposeId,
    String? meetingLocation,
    String? exclusionReasonId,
    String? propertyCode,
    double? companyProfit,
  }) async {
    await _supabase.rpc('add_lead_action_v3', params: {
      'p_lead_id': leadId,
      'p_comment': comment,
      'p_next_status_id': nextStatusId,
      'p_scheduled_at': scheduledAt?.toIso8601String(),
      'p_meeting_type_id': meetingTypeId,
      'p_meeting_purpose_id': meetingPurposeId,
      'p_meeting_location': meetingLocation,
      'p_exclusion_reason_id': exclusionReasonId,
      'p_property_code': propertyCode,
      'p_company_profit': companyProfit,
    });
  }

  Future<LeadModel> updateLeadStatus(String leadId, String statusId, {bool isExcluded = false}) async {
    await _supabase
        .from('leads')
        .update({
          'status_id': statusId,
          'transferred_from': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          if (isExcluded) 'is_archived': true,
        })
        .eq('id', leadId);
    return await getLeadById(leadId);
  }

  Future<LeadModel> updateLeadStatusAndEmployee(String leadId, String statusId, String employeeId, {bool isExcluded = false}) async {
    await _supabase
        .from('leads')
        .update({
          'status_id': statusId,
          'assigned_to': employeeId,
          'transferred_from': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          if (isExcluded) 'is_archived': true,
        })
        .eq('id', leadId);
    return await getLeadById(leadId);
  }

  Future<LeadModel> togglePin(String leadId, bool isPinned) async {
    await _supabase
        .from('leads')
        .update({'is_pinned': isPinned})
        .eq('id', leadId);
    return await getLeadById(leadId);
  }


  /// إضافة ملاحظة من شاشة التفاصيل — عملية واحدة لا تحتاج RPC
  Future<LeadModel> addNote(String leadId, String noteText) async {
    await _supabase.from('lead_notes').insert({
      'lead_id': leadId,
      'user_id': _supabase.auth.currentUser?.id,
      'note_text': noteText.trim(),
    });
    return await getLeadById(leadId);
  }

  Future<LeadModel> getLeadById(String id) async {
    final response = await _supabase
        .from('leads')
        .select(_selectDetail)
        .eq('id', id)
        .single();
    return LeadModel.fromJson(response);
  }

  Future<LeadModel> getLeadByIdBasic(String id) async {
    final response = await _supabase
        .from('leads')
        .select(_selectBasic)
        .eq('id', id)
        .single();
    return LeadModel.fromJson(response);
  }

  /// جلب سجلات العميل بشكل منفصل مع عمل الـ joins عند الموظف (client-side)
  /// باستخدام البيانات المحفوظة في StaticDataManager وقائمة الموظفين
  Future<List<LeadLogEntryModel>> fetchLeadLogs(String leadId) async {
    final response = await _supabase
        .from('lead_logs')
        .select('id, activity_type_id, created_at, notes, scheduled_at, changed_by, old_status_id, new_status_id, is_answered')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    final dataManager = di.sl<StaticDataManager>();

    return (response as List).map((json) {
      // Client-side join: activity_type
      final activityTypeId = json['activity_type_id']?.toString();
      final activityType = activityTypeId != null
          ? dataManager.getOptionById('activity_types', activityTypeId)
          : null;

      // Client-side join: statuses
      final oldStatusId = json['old_status_id']?.toString();
      final newStatusId = json['new_status_id']?.toString();
      final oldStatus = oldStatusId != null
          ? dataManager.getOptionById('lead_status', oldStatusId)
          : null;
      final newStatus = newStatusId != null
          ? dataManager.getOptionById('lead_status', newStatusId)
          : null;

      // Client-side join: employee name
      final changedById = json['changed_by']?.toString();
      final employee = changedById != null
          ? dataManager.employees.where((e) => e.id == changedById).firstOrNull
          : null;
      final changedByName = employee != null
          ? '${employee.firstName ?? ''} ${employee.lastName ?? ''}'.trim()
          : null;

      // nameEn من الـ extra map
      final activityNameEn = activityType?.extra?['name_en']?.toString();

      return LeadLogEntryModel(
        id: json['id']?.toString() ?? '',
        action: activityType?.nameAr ?? '',
        actionEn: activityNameEn,
        createdAt: DateTime.parse(json['created_at']).toLocal(),
        oldStatusName: oldStatus?.nameAr,
        newStatusName: newStatus?.nameAr,
        createdByName: changedByName?.isNotEmpty == true ? changedByName : null,
        notes: json['notes']?.toString(),
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.parse(json['scheduled_at']).toLocal()
            : null,
      );
    }).toList();
  }

  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }

  Future<List<LeadModel>> searchLeadsByAi({
    required List<double> vector,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    required String role,
    required String userId,
  }) async {
    final response = await _supabase.rpc('match_leads', params: {
      'query_embedding': vector,
      'match_threshold': 0.15, // تقليل الحد الأدنى للمطابقة لضمان الحصول على نتائج للبحث المخصص
      'match_count': 50,       // جلب عدد كافٍ من النتائج للتصفية اللاحقة حسب الموظف
      'filter_property_type_id': propertyTypeId,
      'filter_listing_type_id': listingTypeId,
      'filter_governorate_id': governorateId,
      'filter_city_id': cityId,
    });
    
    final List<dynamic> rpcResults = response;
    if (rpcResults.isEmpty) return [];

    final List<String> ids = rpcResults.map((r) => r['id'].toString()).toList();
    
    var query = _supabase.from('leads').select(_selectList).inFilter('id', ids);
    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    }
    
    final fullLeads = await query;
    final List<LeadModel> leads = (fullLeads as List).map((e) => LeadModel.fromJson(e)).toList();
    
    // إعادة الترتيب حسب ترتيب درجات التشابه الـ Cosine Similarity
    leads.sort((a, b) {
      final indexA = ids.indexOf(a.id.toString());
      final indexB = ids.indexOf(b.id.toString());
      return indexA.compareTo(indexB);
    });

    return leads;
  }

  Future<List<LeadModel>> searchLeads(String term, {String type = 'phone', required String role, required String userId}) async {
    if (type == 'phone') {
      final phoneRes = await _supabase.from('lead_phones').select('lead_id').like('phone_number', '%$term%');
      final ids = (phoneRes as List).map((e) => e['lead_id'].toString()).toSet().toList();
      if (ids.isEmpty) return [];
      
      var query = _supabase.from('leads').select(_selectList).inFilter('id', ids);
      if (!_isManagerOrAdmin(role)) {
        query = query.eq('assigned_to', userId);
      }
      final fullLeads = await query;
      return (fullLeads as List).map((e) => LeadModel.fromJson(e)).toList();
    }
    return [];
  }

  /// يتحقق من التكرارات بناءً على آخر 7 أرقام
  Future<List<LeadModel>> checkDuplicateLeadPhones(List<String> phones) async {
    final suffixes = phones.map((p) => p.length >= 7 ? p.substring(p.length - 7) : p).where((s) => s.isNotEmpty).toList();
    if (suffixes.isEmpty) return [];

    final orConditions = suffixes.map((s) => 'phone_number.like.%$s').join(',');
    final phoneRes = await _supabase.from('lead_phones').select('lead_id').or(orConditions);
    final ids = (phoneRes as List).map((e) => e['lead_id'].toString()).toSet().toList();
    if (ids.isEmpty) return [];

    final fullLeads = await _supabase.from('leads').select(_selectList).inFilter('id', ids);
    return (fullLeads as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  Future<List<ProfileModel>> fetchAllEmployees() async {
    final response = await _supabase.from('profiles').select();
    return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  // ─── المهملات (Trash) ───
  Future<List<LeadModel>> fetchDeletedLeads() async {
    // TODO: implement if we have soft delete, otherwise handled by is_deleted flag.
    // Assuming there's no is_deleted flag in schema yet based on previous tasks.
    return [];
  }

  // ─── سجل التكرارات (Duplicates) ───
  Future<List<List<LeadModel>>> findDuplicateLeads({
    required String role,
    required String userId,
  }) async {
    // جيب مجموعات التكرار من الداتابيز
    final groups = await _supabase.rpc('get_duplicate_lead_groups', params: {
      'p_user_id': userId,
      'p_role': role,
    });

    if ((groups as List).isEmpty) return [];

    final List<List<LeadModel>> result = [];
    for (final group in groups) {
      final List<String> ids = List<String>.from(group['lead_ids']);
      final leads = await _supabase
          .from('leads')
          .select(_selectList)
          .inFilter('id', ids)
          .order('created_at', ascending: false);
      if ((leads as List).isNotEmpty) {
        result.add((leads as List).map((e) => LeadModel.fromJson(e)).toList());
      }
    }
    return result;
  }

  Future<void> mergeLeads(String primaryLeadId, List<String> secondaryIds, {String? assignedToId}) async {
    if (secondaryIds.isEmpty) return;
    await _supabase.rpc('merge_leads_atomic', params: {
      'p_primary_id': primaryLeadId,
      'p_secondary_ids': secondaryIds,
      'p_assigned_to': assignedToId,
    });
  }
}