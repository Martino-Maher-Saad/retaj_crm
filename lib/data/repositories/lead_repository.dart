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
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
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
        platformId: platformId,
        leadStatusId: leadStatusId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        governorateId: governorateId,
        cityId: cityId,
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
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      return await _leadService.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        platformId: platformId,
        leadStatusId: leadStatusId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        governorateId: governorateId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      return 0;
    }
  }

  Future<LeadModel> addNewLead(
    LeadModel lead,
    List<LeadPhoneModel> phones, {
    List<LeadNoteModel> notes = const [],
  }) async {
    try {
      return await _leadService.addLead(lead, phones, notes: notes);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل الاتصال بالسيرفر، تأكد من الإنترنت';
    }
  }

  Future<LeadModel> updateLeadData(
    String id,
    LeadModel lead,
    List<LeadPhoneModel> phones, {
    String? newNote,
  }) async {
    try {
      return await _leadService.updateLead(id, lead, phones, newNote: newNote);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحديث البيانات، حاول مرة أخرى';
    }
  }

  Future<LeadModel> updateLeadStatus(String id, String statusId) async {
    try {
      return await _leadService.updateLeadStatus(id, statusId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحديث الحالة، حاول مرة أخرى';
    }
  }

  Future<LeadModel> addNote(String leadId, String noteText) async {
    try {
      return await _leadService.addNote(leadId, noteText);
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