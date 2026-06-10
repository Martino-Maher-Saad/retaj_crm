import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/utils/static_data_manager.dart';

class LeadService {
  final _supabase = Supabase.instance.client;

  static bool _isManagerOrAdmin(String role) {
    final lowerRole = role.toLowerCase().trim();
    return lowerRole == 'manager' || lowerRole == 'admin' || lowerRole == 'ceo';
  }

  // ─── SELECT للقائمة (بدون notes لتسريع التحميل) ───
  static const _selectList =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'governorates!governorate_id(name), '
      'lead_exclusion_reasons!exclusion_reason_id(name_ar), '
      'lead_phones(id, phone_number, is_primary)';

  // ─── SELECT لشاشة التفاصيل (مع notes والكاتب) ───
  static const _selectDetail =
      '*, '
      'assignee:profiles!leads_assigned_to_fkey(first_name, last_name), '
      'creator:profiles!leads_created_by_fk(first_name, last_name), '
      'lead_statuses!status_id(name_ar), '
      'lead_platforms!platform_id(name_ar), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'communication_channels!channel_id(name_ar), '
      'cities!city_id(name), '
      'governorates!governorate_id(name), '
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
    int? governorateId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isArchived = false, // القيمة الافتراضية هنا لا تجلب الأرشيف
    bool? isStagnant, // إذا كان true يجلب اللي مر عليهم يومين بدون تحديث
    bool? isForTasks, // يجلب العملاء المتأخرين والمحولين معاً
  }) async {
    dynamic query = _supabase.from('leads').select(_selectList);

    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    final archiveStatuses = ['34f6f48c-3179-4b83-b34e-edc3fdc2e3d4', '6d5c7b17-9ef7-48ee-a9f6-0575cc390278']; // مستبعد و تم التعاقد

    if (isArchived == true) {
      query = query.filter('status_id', 'in', archiveStatuses);
    } else if (isArchived == false) {
      query = query.not('status_id', 'in', archiveStatuses);
    }

    if (isStagnant == true) {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      query = query.lte('updated_at', oneMonthAgo);
    }

    if (isForTasks == true) {
      final twoDaysAgo = DateTime.now().subtract(const Duration(hours: 48)).toIso8601String();
      if (!_isManagerOrAdmin(role)) {
        query = query.or('and(status_updated_at.lte.$twoDaysAgo,assigned_to.eq.$userId),and(transferred_from.not.is.null,assigned_to.eq.$userId)');
      } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
        query = query.or('and(status_updated_at.lte.$twoDaysAgo,assigned_to.eq.$filterByEmployeeId),and(transferred_from.not.is.null,assigned_to.eq.$filterByEmployeeId)');
      } else {
        query = query.or('status_updated_at.lte.$twoDaysAgo,transferred_from.not.is.null');
      }
    } else {
      if (!_isManagerOrAdmin(role)) {
        query = query.eq('assigned_to', userId);
      } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
        query = query.eq('assigned_to', filterByEmployeeId);
      }
    }

    if (platformId != null && platformId.isNotEmpty) query = query.eq('platform_id', platformId);
    if (leadStatusId != null && leadStatusId.isNotEmpty) query = query.eq('status_id', leadStatusId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    // ترتيب بحيث يظهر المثبت (is_pinned = true) أولاً
    query = query.order('is_pinned', ascending: false).order('created_at', ascending: false);

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
    int? governorateId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isArchived = false,
    bool? isStagnant,
    bool? isForTasks,
  }) async {
    var query = _supabase.from('leads').select('*');

    if (!_isManagerOrAdmin(role)) {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    final archiveStatuses = ['34f6f48c-3179-4b83-b34e-edc3fdc2e3d4', '6d5c7b17-9ef7-48ee-a9f6-0575cc390278']; // مستبعد و تم التعاقد

    if (isArchived == true) {
      query = query.filter('status_id', 'in', archiveStatuses);
    } else if (isArchived == false) {
      query = query.not('status_id', 'in', archiveStatuses);
    }

    if (isStagnant == true) {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      query = query.lte('updated_at', oneMonthAgo);
    }
    
    if (isForTasks == true) {
      final twoDaysAgo = DateTime.now().subtract(const Duration(hours: 48)).toIso8601String();
      if (!_isManagerOrAdmin(role)) {
        query = query.or('and(status_updated_at.lte.$twoDaysAgo,assigned_to.eq.$userId),and(transferred_from.not.is.null,assigned_to.eq.$userId)');
      } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
        query = query.or('and(status_updated_at.lte.$twoDaysAgo,assigned_to.eq.$filterByEmployeeId),and(transferred_from.not.is.null,assigned_to.eq.$filterByEmployeeId)');
      } else {
        query = query.or('status_updated_at.lte.$twoDaysAgo,transferred_from.not.is.null');
      }
    } else {
      if (!_isManagerOrAdmin(role)) {
        query = query.eq('assigned_to', userId);
      } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
        query = query.eq('assigned_to', filterByEmployeeId);
      }
    }

    if (platformId != null && platformId.isNotEmpty) query = query.eq('platform_id', platformId);
    if (leadStatusId != null && leadStatusId.isNotEmpty) query = query.eq('status_id', leadStatusId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
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
      'p_governorate_id':   lead.governorateId,
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
      'p_governorate_id':   lead.governorateId,
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

    // تحديث المحول منه بشكل منفصل لعدم دعمه في الـ RPC
    await _supabase.from('leads').update({
      'transferred_from': lead.transferredFrom
    }).eq('id', id);

    return await getLeadById(id);
  }

  /// تحديث حالة العميل فقط وتفريغ المحول منه لإنهاء المهمة
  Future<LeadModel> updateLeadStatus(String leadId, String statusId) async {
    final isExcluded = statusId == '34f6f48c-3179-4b83-b34e-edc3fdc2e3d4';
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

  Future<LeadModel> updateLeadStatusAndEmployee(String leadId, String statusId, String employeeId) async {
    final isExcluded = statusId == '34f6f48c-3179-4b83-b34e-edc3fdc2e3d4';
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

  Future<void> archiveLead(String leadId, bool isArchived) async {
    await _supabase.from('leads').update({'is_archived': isArchived}).eq('id', leadId);
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

  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }

  Future<List<LeadModel>> searchLeadsByAi({
    required List<double> vector,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
  }) async {
    final response = await _supabase.rpc('match_leads', params: {
      'query_embedding': vector,
      'match_threshold': 0.70,
      'match_count': 10,
      'filter_property_type_id': propertyTypeId,
      'filter_listing_type_id': listingTypeId,
      'filter_governorate_id': governorateId,
      'filter_city_id': cityId,
    });
    
    final List<dynamic> rpcResults = response;
    if (rpcResults.isEmpty) return [];

    final List<String> ids = rpcResults.map((r) => r['id'].toString()).toList();
    final fullLeads = await _supabase.from('leads').select(_selectList).inFilter('id', ids);
    return (fullLeads as List).map((e) => LeadModel.fromJson(e)).toList();
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

  /// يتحقق من التكرارات بناءً على آخر 6 أرقام
  Future<List<LeadModel>> checkDuplicateLeadPhones(List<String> phones) async {
    final suffixes = phones.map((p) => p.length >= 6 ? p.substring(p.length - 6) : p).where((s) => s.isNotEmpty).toList();
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
}