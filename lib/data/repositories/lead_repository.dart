import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../services/lead_service.dart';

class LeadRepository {
  final LeadService _leadService;

  LeadRepository(this._leadService);

  Future<List<LeadModel>> getAllLeads({
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
    try {
      return await _leadService.fetchAllLeads(
        role: role,
        userId: userId,
        from: from,
        to: to,
        filterByEmployeeId: filterByEmployeeId,
        platform: platform,
        leadStatus: leadStatus,
        propertyType: propertyType,
        listingType: listingType,
        governorate: governorate,
        city: city,
        fromDate: fromDate,
        toDate: toDate,
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع أثناء جلب البيانات';
    }
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
    try {
      return await _leadService.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        platform: platform,
        leadStatus: leadStatus,
        propertyType: propertyType,
        listingType: listingType,
        governorate: governorate,
        city: city,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      return 0;
    }
  }

  Future<LeadModel> addNewLead(LeadModel lead) async {
    try {
      return await _leadService.addLead(lead);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل الاتصال بالسيرفر، تأكد من الإنترنت';
    }
  }

  Future<LeadModel> updateLeadData(String id, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      return await _leadService.updateLead(id, updates);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحديث البيانات، حاول مرة أخرى';
    }
  }

  /// إضافة كومنت جديد لقائمة الـ history
  Future<LeadModel> appendComment(String leadId, String comment) async {
    try {
      return await _leadService.appendComment(leadId, comment);
    } catch (e) {
      throw 'فشل إضافة التعليق، حاول مرة أخرى';
    }
  }

  Future<void> deleteLeadById(String id) async {
    try {
      await _leadService.deleteLead(id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'لم يتم الحذف، حدث خطأ تقني';
    }
  }

  Future<List<ProfileModel>> getAllEmployees() async {
    try {
      return await _leadService.fetchAllEmployees();
    } catch (e) {
      return [];
    }
  }

  String _handlePostgrestError(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'هذا العميل موجود بالفعل (رقم الهاتف مكرر)';
      case '42P01':
        return 'خطأ في الوصول لجدول البيانات';
      default:
        return 'خطأ في السيرفر: ${e.message}';
    }
  }
}