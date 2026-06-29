import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../services/ai_service.dart';
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
    bool? isArchived = false,
    bool? isStagnant,
    bool? isForTasks,
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
        isArchived: isArchived,
        isStagnant: isStagnant,
        isForTasks: isForTasks,
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع أثناء جلب البيانات';
    }
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
    try {
      return await _leadService.fetchDashboardExcelLeads(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        listingTypeId: listingTypeId,
        propertyTypeId: propertyTypeId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e, s) {
      print("============== DATABASE FETCH EXCEL LEADS ERROR ==============");
      print("Error: $e");
      print("Stack trace: $s");
      print("=============================================================");
      throw 'حدث خطأ أثناء تحميل بيانات تقرير العملاء: $e';
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
    bool? isArchived = false,
    bool? isStagnant,
    bool? isForTasks,
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
        isArchived: isArchived,
        isStagnant: isStagnant,
        isForTasks: isForTasks,
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
      print('🚀 Supabase Error in updateLeadData: ${e.message} \n Details: ${e.details} \n Hint: ${e.hint}');
      throw _handlePostgrestError(e);
    } catch (e) {
      print('🚀 Unknown Error in updateLeadData: $e');
      throw 'فشل تحديث البيانات، حاول مرة أخرى';
    }
  }

  Future<LeadModel> updateLeadStatus(String id, String statusId) async {
    try {
      return await _leadService.updateLeadStatus(id, statusId);
    } on PostgrestException catch (e) {
      print('🚀 Supabase Error in updateLeadStatus: ${e.message} \n Details: ${e.details} \n Hint: ${e.hint}');
      throw _handlePostgrestError(e);
    } catch (e) {
      print('🚀 Unknown Error in updateLeadStatus: $e');
      throw 'فشل تحديث الحالة، حاول مرة أخرى';
    }
  }

  Future<LeadModel> updateLeadStatusAndEmployee(String id, String statusId, String employeeId) async {
    try {
      return await _leadService.updateLeadStatusAndEmployee(id, statusId, employeeId);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحديث الحالة والموظف';
    }
  }

  Future<LeadModel> togglePin(String id, bool isPinned) async {
    try {
      return await _leadService.togglePin(id, isPinned);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحديث حالة التثبيت';
    }
  }

  Future<void> archiveLead(String id, bool isArchived) async {
    try {
      await _leadService.archiveLead(id, isArchived);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل أرشفة العميل';
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

  Future<List<LeadModel>> searchLeadsWithAi({
    required String query,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
  }) async {
    try {
      final aiService = di.sl<AiService>();
      final vector = await aiService.generateEmbedding(query);
      if (vector == null) throw 'فشل في حساب دلالات البحث من سيرفر الذكاء الاصطناعي';
      
      return await _leadService.searchLeadsByAi(
        vector: vector,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        governorateId: governorateId,
        cityId: cityId,
      );
    } catch (e) {
      throw 'حدث خطأ أثناء البحث الذكي';
    }
  }

  Future<List<LeadModel>> searchLeads(String query, {String type = 'phone', required String role, required String userId}) async {
    return await _leadService.searchLeads(query, type: type, role: role, userId: userId);
  }

  Future<List<LeadModel>> checkDuplicateLeadPhones(List<String> phones) async {
    return await _leadService.checkDuplicateLeadPhones(phones);
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