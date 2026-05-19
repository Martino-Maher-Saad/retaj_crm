import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';

class LeadService {
  final _supabase = Supabase.instance.client;

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
  }) async {
    var query = _supabase.from('leads_view').select(_selectList);

    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (platformId != null && platformId.isNotEmpty) query = query.eq('platform_id', platformId);
    if (leadStatusId != null && leadStatusId.isNotEmpty) query = query.eq('status_id', leadStatusId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    final response = await query.order('created_at', ascending: false).range(from, to);
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
  }) async {
    var query = _supabase.from('leads').select('*');

    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
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
      'p_phones':           phonesJson,
      'p_new_note':         newNote ?? '',
    });

    return await getLeadById(id);
  }

  /// تحديث حالة العميل فقط (يشغّل الـ Trigger تلقائياً لتسجيل التغيير)
  Future<LeadModel> updateLeadStatus(String leadId, String statusId) async {
    await _supabase
        .from('leads')
        .update({'status_id': statusId})
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
        .from('leads_view')
        .select(_selectDetail)
        .eq('id', id)
        .single();
    return LeadModel.fromJson(response);
  }

  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }

  Future<List<ProfileModel>> fetchAllEmployees() async {
    final response = await _supabase.from('profiles').select();
    return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
  }
}