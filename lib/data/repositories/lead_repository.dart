import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../services/ai_service.dart';
import '../services/lead_service.dart';

class LeadRepository {
  final LeadService _leadService;

  LeadRepository(this._leadService);

  Future<LeadModel> getLeadById(String id) async {
    try {
      // السجلات (logs) يتم جلبها مدمجة مع بيانات العميل الآن
      return await _leadService.getLeadById(id);
    } catch (e) {
      throw 'فشل في جلب تفاصيل العميل: $e';
    }
  }

  Future<LeadModel> getLeadByIdBasic(String id) async {
    try {
      return await _leadService.getLeadByIdBasic(id);
    } catch (e) {
      throw 'فشل في جلب تفاصيل العميل: $e';
    }
  }

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
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isTrash,
    List<String>? statusIds,
    bool? isTransferred,
    bool? delayFilter,
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
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        isTrash: isTrash,
        statusIds: statusIds,
        isTransferred: isTransferred,
        delayFilter: delayFilter,
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e, stacktrace) {
      print('=== ACTUAL REPO ERROR ===');
      print(e);
      print(stacktrace);
      throw 'حدث خطأ غير متوقع أثناء جلب البيانات: $e';
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
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isTrash,
    List<String>? statusIds,
    bool? isTransferred,
    bool? delayFilter,
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
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        isTrash: isTrash,
        statusIds: statusIds,
        isTransferred: isTransferred,
        delayFilter: delayFilter,
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
      List<double>? vector;
      if (lead.descLeadNeed != null && lead.descLeadNeed!.trim().isNotEmpty) {
        final aiService = di.sl<AiService>();
        vector = await aiService.generateEmbedding(lead.descLeadNeed!.trim(), useGemini: true);
        if (vector == null || vector.isEmpty) {
          throw 'فشل في حساب دلالات البحث من سيرفر الذكاء الاصطناعي لوصف طلب العميل';
        }
      }

      final newLead = await _leadService.addLead(lead, phones, notes: notes);

      if (vector != null && newLead.id != null) {
        await _leadService.updateLeadEmbedding(newLead.id!, vector);
      }

      return newLead;
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'فشل إضافة العميل، حدث خطأ أثناء المعالجة أو توليد المتجه الدلالي لطلب العميل';
    }
  }

  Future<LeadModel> updateLeadData(
    String id,
    LeadModel lead,
    List<LeadPhoneModel> phones, {
    String? newNote,
  }) async {
    try {
      List<double>? vector;
      final bool hasNewNeed = lead.descLeadNeed != null && lead.descLeadNeed!.trim().isNotEmpty;
      if (hasNewNeed) {
        final aiService = di.sl<AiService>();
        vector = await aiService.generateEmbedding(lead.descLeadNeed!.trim(), useGemini: true);
        if (vector == null || vector.isEmpty) {
          throw 'فشل في حساب دلالات البحث من سيرفر الذكاء الاصطناعي لوصف طلب العميل';
        }
      }

      final updatedLead = await _leadService.updateLead(id, lead, phones, newNote: newNote);

      // تحديث المتجه دائمًا في السيرفر (حتى لو كان فارغًا نقوم بتصفيره)
      await _leadService.updateLeadEmbedding(id, vector);

      return updatedLead;
    } on PostgrestException catch (e) {
      print('🚀 Supabase Error in updateLeadData: ${e.message} \n Details: ${e.details} \n Hint: ${e.hint}');
      throw _handlePostgrestError(e);
    } catch (e) {
      if (e is String) rethrow;
      print('🚀 Unknown Error in updateLeadData: $e');
      throw 'فشل تحديث البيانات، حاول مرة أخرى أو توليد المتجه الدلالي لطلب العميل';
    }
  }

  Future<LeadModel> updateLeadStatus(String id, String statusId, {bool isExcluded = false}) async {
    try {
      return await _leadService.updateLeadStatus(id, statusId, isExcluded: isExcluded);
    } on PostgrestException catch (e) {
      print('🚀 Supabase Error in updateLeadStatus: ${e.message} \n Details: ${e.details} \n Hint: ${e.hint}');
      throw _handlePostgrestError(e);
    } catch (e) {
      print('🚀 Unknown Error in updateLeadStatus: $e');
      throw 'فشل تحديث الحالة، حاول مرة أخرى';
    }
  }

  Future<LeadModel> updateLeadStatusAndEmployee(String id, String statusId, String employeeId, {bool isExcluded = false}) async {
    try {
      return await _leadService.updateLeadStatusAndEmployee(id, statusId, employeeId, isExcluded: isExcluded);
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

  Future<LeadModel> transferLead({
    required String leadId,
    required String fromEmployeeId,
    required String toEmployeeId,
    required String changedBy,
    String? notes,
  }) async {
    try {
      return await _leadService.transferLead(
        leadId: leadId,
        fromEmployeeId: fromEmployeeId,
        toEmployeeId: toEmployeeId,
        changedBy: changedBy,
        notes: notes,
      );
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw 'فشل تحويل العميل: $e';
    }
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
    try {
      await _leadService.addLeadAction(
        leadId: leadId,
        comment: comment,
        nextStatusId: nextStatusId,
        scheduledAt: scheduledAt,
        meetingTypeId: meetingTypeId,
        meetingPurposeId: meetingPurposeId,
        meetingLocation: meetingLocation,
        exclusionReasonId: exclusionReasonId,
        propertyCode: propertyCode,
        companyProfit: companyProfit,
      );
    } catch (e) {
      throw 'فشل إضافة الأكشن: $e';
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
    int? cityId,
    required String role,
    required String userId,
  }) async {
    try {
      final aiService = di.sl<AiService>();
      final vector = await aiService.generateEmbedding(query, useGemini: true);
      if (vector == null || vector.isEmpty) throw 'فشل في حساب دلالات البحث من سيرفر الذكاء الاصطناعي';
      
      return await _leadService.searchLeadsByAi(
        vector: vector,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        cityId: cityId,
        role: role,
        userId: userId,
      );
    } catch (e, s) {
      print("========== SMART SEARCH LEADS ERROR ==========");
      print("Error: $e");
      print("Stack trace: $s");
      print("=============================================");
      if (e is String) rethrow;
      throw 'حدث خطأ أثناء البحث الذكي: $e';
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

  Future<List<List<LeadModel>>> findDuplicateLeads({required String role, required String userId}) async {
    try {
      return await _leadService.findDuplicateLeads(role: role, userId: userId);
    } catch (e) {
      throw 'حدث خطأ أثناء جلب العملاء المكررين: $e';
    }
  }

  Future<void> mergeLeads(String primaryLeadId, List<String> secondaryIds, {String? assignedToId}) async {
    try {
      await _leadService.mergeLeads(primaryLeadId, secondaryIds, assignedToId: assignedToId);
    } on PostgrestException catch (e) {
      throw 'حدث خطأ أثناء دمج العملاء: $e';
    }
  }
}