import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';

class LeadService {
  final _supabase = Supabase.instance.client;

  // SELECT مع JOIN على profiles لجلب اسم الموظف المسؤول ومن أضاف العميل
  static const _select =
      '*, assignee:profiles!leads_assigned_to_fkey(first_name, last_name), creator:profiles!leads_created_by_fk(first_name, last_name)';

  Future<List<LeadModel>> fetchAllLeads({
    required String role,
    required String userId,
    required int from,
    required int to,
    String? filterByEmployeeId,
    String? platform,
    String? leadStatus,
    String? propertyType,
    String? listingType,
    String? governorate,
    String? city,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _supabase.from('leads').select(_select);

    // فلتر الدور
    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    // الفلاتر الإضافية
    if (platform != null && platform.isNotEmpty) {
      query = query.eq('platform', platform);
    }
    if (leadStatus != null && leadStatus.isNotEmpty) {
      query = query.eq('lead_status', leadStatus);
    }
    if (propertyType != null && propertyType.isNotEmpty) {
      query = query.eq('property_type', propertyType);
    }
    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type', listingType);
    }
    if (governorate != null && governorate.isNotEmpty) {
      query = query.eq('governorate', governorate);
    }
    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response =
        await query.order('created_at', ascending: false).range(from, to);
    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  Future<int> getLeadsCount({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    String? platform,
    String? leadStatus,
    String? propertyType,
    String? listingType,
    String? governorate,
    String? city,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _supabase.from('leads').select('*');

    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (platform != null && platform.isNotEmpty) {
      query = query.eq('platform', platform);
    }
    if (leadStatus != null && leadStatus.isNotEmpty) {
      query = query.eq('lead_status', leadStatus);
    }
    if (propertyType != null && propertyType.isNotEmpty) {
      query = query.eq('property_type', propertyType);
    }
    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type', listingType);
    }
    if (governorate != null && governorate.isNotEmpty) {
      query = query.eq('governorate', governorate);
    }
    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
  }

  Future<LeadModel> addLead(LeadModel lead) async {
    final response = await _supabase
        .from('leads')
        .insert(lead.toJson())
        .select(_select)
        .single();
    return LeadModel.fromJson(response);
  }

  Future<LeadModel> updateLead(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('leads')
        .update(updates)
        .eq('id', id)
        .select(_select)
        .single();
    return LeadModel.fromJson(response);
  }

  /// إضافة كومنت جديد لقائمة الـ history (read-modify-write)
  Future<LeadModel> appendComment(String leadId, String comment) async {
    // 1. اقرأ الـ lead الحالي عشان نجيب الـ history الموجودة
    final currentLead = await getLeadById(leadId);

    // 2. أضف الكومنت الجديد على آخر الـ list
    final updatedHistory = [...currentLead.history, comment];

    // 3. اعمل update للـ history فقط
    await _supabase
        .from('leads')
        .update({'history': updatedHistory})
        .eq('id', leadId);

    // 4. رجع الـ lead المحدث من السيرفر للتأكيد
    return await getLeadById(leadId);
  }

  Future<LeadModel> getLeadById(String id) async {
    final response = await _supabase
        .from('leads')
        .select(_select)
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