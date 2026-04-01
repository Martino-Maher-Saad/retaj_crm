import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../services/lead_service.dart';


class LeadRepository {
  final LeadService _leadService;

  LeadRepository(this._leadService);

  // جلب كل العملاء مع ترقيم الصفحات (Pagination)
  Future<List<LeadModel>> getAllLeads({
    required String role,
    required String userId,
    required int from,
    required int to,
    String? filterByEmployeeId,
  }) async {
    try {
      return await _leadService.fetchAllLeads(
          role: role, userId: userId, from: from, to: to, filterByEmployeeId: filterByEmployeeId);
    } on PostgrestException catch (e, stack) {
      print("❌ PostgrestException in getAllLeads: ${e.message}");
      print(stack);
      throw _handlePostgrestError(e);
    } catch (e, stack) {
      print("❌ General Exception in getAllLeads: $e");
      print(stack);
      throw "حدث خطأ غير متوقع أثناء جلب البيانات";
    }
  }

  // جلب إجمالي العدد
  Future<int> getLeadsCount({required String role, required String userId, String? filterByEmployeeId}) async {
    try {
      return await _leadService.getLeadsCount(role: role, userId: userId, filterByEmployeeId: filterByEmployeeId);
    } catch (e) {
      return 0;
    }
  }

  // إضافة عميل جديد
  Future<LeadModel> addNewLead(LeadModel lead) async {
    try {
      return await _leadService.addLead(lead);
    } on PostgrestException catch (e, stack) {
      print("❌ PostgrestException in addNewLead: ${e.message}");
      print(stack);
      throw _handlePostgrestError(e);
    } catch (e, stack) {
      print("❌ General Exception in addNewLead: $e");
      print(stack);
      throw "فشل الاتصال بالسيرفر، تأكد من الإنترنت";
    }
  }

  // تحديث بيانات أو حالة (تأكد أن الـ Service يستقبل Map ويحدث الحقول المطلوبة)
  Future<LeadModel> updateLeadData(String id, Map<String, dynamic> updates) async {
    try {
      // إزالة الـ id من الـ updates لتجنب مشاكل سوبابيز عند تحديث المفتاح الأساسي
      updates.remove('id');
      return await _leadService.updateLead(id, updates);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "فشل تحديث البيانات، حاول مرة أخرى";
    }
  }

  // حذف عميل
  Future<void> deleteLeadById(String id) async {
    try {
      await _leadService.deleteLead(id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "لم يتم الحذف، حدث خطأ تقني";
    }
  }

  // دالة مساعدة لترجمة أخطاء سوبابيز للغة عربية مفهومة للموظف
  String _handlePostgrestError(PostgrestException e) {
    // يمكنك تخصيص الرسائل بناءً على الـ code الخاص بالخطأ
    switch (e.code) {
      case '23505': return "هذا العميل موجود بالفعل (رقم الهاتف مكرر)";
      case '42P01': return "خطأ في الوصول لجدول البيانات";
      default: return "خطأ في السيرفر: ${e.message}";
    }
  }

  // جلب الموظفين للإدارة
  Future<List<ProfileModel>> getAllEmployees() async {
    try {
      return await _leadService.fetchAllEmployees();
    } catch(e) {
      return [];
    }
  }
}