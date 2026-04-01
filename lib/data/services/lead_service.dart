import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';


class LeadService {
  final _supabase = Supabase.instance.client;

  // 1. جلب كل العملاء (مرتبين من الأحدث للأقدم)
  /*Future<List<LeadModel>> fetchAllLeads() async {
    // الـ RLS في سوبابيز سيتكفل بجلب بيانات الموظف نفسه فقط
    final response = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }*/
  Future<List<LeadModel>> fetchAllLeads({
    required String role,
    required String userId,
    required int from,
    required int to,
    String? filterByEmployeeId,
  }) async {
    var query = _supabase.from('leads').select('*, assignee:profiles!leads_assigned_to_fkey(first_name, last_name)');

    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    final response = await query.order('created_at', ascending: false).range(from, to);
    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  // جلب إجمالي عدد العملاء
  Future<int> getLeadsCount({required String role, required String userId, String? filterByEmployeeId}) async {
    var query = _supabase.from('leads').select('*');
    if (role != 'manager' && role != 'admin') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }
    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
  }

  // 2. إضافة عميل جديد
  // نستخدم .select().single() لضمان استلام الكائن الجديد بالـ ID و الـ CreatedAt
  Future<LeadModel> addLead(LeadModel lead) async {
    final response = await _supabase
        .from('leads')
        .insert(lead.toJson())
        .select('*, assignee:profiles!leads_assigned_to_fkey(first_name, last_name)')
        .single();

    return LeadModel.fromJson(response);
  }

  // 3. تحديث بيانات العميل أو حالته
  Future<LeadModel> updateLead(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('leads')
        .update(updates)
        .eq('id', id)
        .select('*, assignee:profiles!leads_assigned_to_fkey(first_name, last_name)')
        .single();

    return LeadModel.fromJson(response);
  }

  // 4. حذف عميل
  Future<void> deleteLead(String id) async {
    await _supabase
        .from('leads')
        .delete()
        .eq('id', id);
  }

  // 5. جلب كافة الموظفين للإدارة
  Future<List<ProfileModel>> fetchAllEmployees() async {
    final response = await _supabase.from('profiles').select();
    return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
  }
}