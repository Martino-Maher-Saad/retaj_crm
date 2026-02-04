import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';


class LeadService {
  final _supabase = Supabase.instance.client;

  // 1. جلب كل العملاء (مرتبين من الأحدث للأقدم)
  Future<List<LeadModel>> fetchAllLeads() async {
    // الـ RLS في سوبابيز سيتكفل بجلب بيانات الموظف نفسه فقط
    final response = await _supabase
        .from('leads')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => LeadModel.fromJson(e)).toList();
  }

  // 2. إضافة عميل جديد
  // نستخدم .select().single() لضمان استلام الكائن الجديد بالـ ID و الـ CreatedAt
  Future<LeadModel> addLead(LeadModel lead) async {
    final response = await _supabase
        .from('leads')
        .insert(lead.toJson())
        .select()
        .single();

    return LeadModel.fromJson(response);
  }

  // 3. تحديث بيانات العميل أو حالته
  Future<LeadModel> updateLead(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('leads')
        .update(updates)
        .eq('id', id)
        .select()
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
}