import 'dart:typed_data';

import '../models/property_model.dart';
import '../models/property_share_model.dart';
import '../services/ai_service.dart';
import '../services/property_service.dart';
import '../services/storage_service.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/utils/static_data_manager.dart';

class PropertyRepository {
  final PropertyService _pService;
  final StorageService _sService;
  final AiService _aiService;

  PropertyRepository(this._pService, this._sService, this._aiService);

  Future<PropertyModel> createFullProperty(
    PropertyModel model,
    List<Uint8List> images, {
    List<String> platformIds = const [],
  }) async {
    String? newId;
    try {
      final text = model.descAr;
      
      // توليد الـ Vector الجديد من Gemini (768 بعداً) - تم إيقاف Hugging Face بالكامل لتسريع الإضافة
      final vectorV2 = await _aiService.generateEmbedding(text, isSearch: false, useGemini: true);
      
      // تعيين حالة "قيد المراجعة" كحالة افتراضية
      String? pendingStatusId = model.approvalStatusId;
      if (pendingStatusId == null) {
        pendingStatusId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
      }
      
      model = model.copyWith(
        embedding: null, // إيقاف الحقل القديم
        embeddingV2: vectorV2,
        approvalStatusId: pendingStatusId,
      );

      final data = await _pService.insertProperty(model.toJson());
      newId = data['id'].toString();

      // إضافة المنصات الإعلانية في جدول property_platforms
      if (platformIds.isNotEmpty) {
        await _pService.insertPlatforms(newId, platformIds);
      }

      for (int i = 0; i < images.length; i++) {
        final name = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final url = await _sService.uploadImage(images[i], newId, name);
        await _pService.insertImageRecord(newId, url);
      }

      final fresh = await _pService.getPropertyById(newId);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      if (newId != null) {
        await _pService.deletePropertyRecord(newId);
        await _sService.deleteFolder(newId);
      }
      throw Exception("فشل الإضافة الآمنة: $e");
    }
  }

  Future<List<PropertyModel>> getMyProperties(String uid, int f, int t) async {
    final data = await _pService.getMyProperties(userId: uid, from: f, to: t);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  /// يجيب عقارات صفحة المهمات فقط (مش published)
  Future<List<PropertyModel>> fetchTaskProperties({
    String? assignedTo,
    required String excludeApprovalStatusId,
    int from = 0,
    int to = 200,
  }) async {
    final data = await _pService.fetchTaskProperties(
      from: from,
      to: to,
      assignedTo: assignedTo,
      excludeApprovalStatusId: excludeApprovalStatusId,
    );
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  /// الفلترة — تستخدم IDs بدلاً من نصوص
  Future<List<PropertyModel>> filterProperties(
    int f,
    int t, {
    int? cityId,
    String? propertyTypeId,
    int? governorateId,
    String? listingTypeId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
    String? approvalStatusId,
    bool? isArchived,
  }) async {
    final data = await _pService.filterProperties(
      from: f,
      to: t,
      cityId: cityId,
      propertyTypeId: propertyTypeId,
      governorateId: governorateId,
      listingTypeId: listingTypeId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      assignedTo: assignedTo,
      fromDate: fromDate,
      toDate: toDate,
      approvalStatusId: approvalStatusId,
      isArchived: isArchived,
    );
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> searchProperties(String q, {String type = 'general', String? assignedTo}) async {
    final data = await _pService.searchProperties(q, type: type, assignedTo: assignedTo);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> checkDuplicatePropertyPhone(String ownerPhone) async {
    final data = await _pService.checkDuplicatePropertyPhone(ownerPhone);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<int> fetchMyCount(String uid) => _pService.getMyCount(uid);

  Future<int> fetchFilterCount({
    int? cityId,
    String? propertyTypeId,
    int? governorateId,
    String? listingTypeId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
    String? approvalStatusId,
    bool? isArchived,
  }) =>
      _pService.getFilterCount(
        cityId: cityId,
        propertyTypeId: propertyTypeId,
        governorateId: governorateId,
        listingTypeId: listingTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: assignedTo,
        fromDate: fromDate,
        toDate: toDate,
        approvalStatusId: approvalStatusId,
        isArchived: isArchived,
      );

  Future<void> deleteFullProperty(String id) async {
    await _sService.deleteFolder(id);
    await _pService.deletePropertyRecord(id);
  }

  Future<PropertyModel> updateFullProperty({
    required PropertyModel p,
    required List<Uint8List> newImgs,
    List<String>? delImgsIds,
    List<String>? delImgsUrls,
    List<String> platformIds = const [],
  }) async {
    try {
      final text = p.descAr;

      // توليد الـ Vector الجديد من Gemini (768 بعداً) - تم إيقاف Hugging Face بالكامل لتسريع التعديل
      final vectorV2 = await _aiService.generateEmbedding(text, isSearch: false, useGemini: true);

      p = p.copyWith(
        embedding: null, // إيقاف الحقل القديم
        embeddingV2: vectorV2,
      );

      await _pService.updateProperty(p.id, p.toJson());

      // تحديث المنصات: حذف القديمة ثم إضافة الجديدة
      await _pService.deletePlatforms(p.id);
      if (platformIds.isNotEmpty) {
        await _pService.insertPlatforms(p.id, platformIds);
      }

      if (delImgsIds != null && delImgsIds.isNotEmpty) {
        await _pService.deleteImageRecordsByIds(delImgsIds);
        for (var url in delImgsUrls!) {
          final fileName = url.split('/').last;
          await _sService.deleteFile(p.id, fileName);
        }
      }

      for (int i = 0; i < newImgs.length; i++) {
        final name = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final url = await _sService.uploadImage(newImgs[i], p.id, name);
        await _pService.insertImageRecord(p.id, url);
      }

      final fresh = await _pService.getPropertyById(p.id);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      throw Exception("فشل تحديث العقار: $e");
    }
  }

  Future<PropertyModel> updateProperty({
    required String id,
    required Map<String, dynamic> data,
    List<String> platformIds = const [],
  }) async {
    try {
      await _pService.updateProperty(id, data);
      
      if (platformIds.isNotEmpty) {
        await _pService.deletePlatforms(id);
        await _pService.insertPlatforms(id, platformIds);
      }

      final fresh = await _pService.getPropertyById(id);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      throw Exception("فشل تحديث العقار: $e");
    }
  }

  Future<void> sharePropertyInternal({
    required String propertyId,
    required String senderId,
    required String receiverId,
    String? note,
  }) async {
    await _pService.sharePropertyInternal(
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      note: note,
    );
  }

  Future<List<PropertyShareModel>> fetchReceivedShares(String userId) async {
    final data = await _pService.fetchReceivedShares(userId);
    return data.map((e) => PropertyShareModel.fromJson(e)).toList();
  }

  Future<List<PropertyShareModel>> fetchSentShares(String userId) async {
    final data = await _pService.fetchSentShares(userId);
    return data.map((e) => PropertyShareModel.fromJson(e)).toList();
  }

  Future<void> deleteShare(String shareId, bool isSender) async {
    await _pService.deleteShare(shareId, isSender);
  }

  Future<List<Map<String, dynamic>>> fetchAllEmployees() async {
    return await _pService.fetchAllEmployees();
  }

  Future<List<double>> generateQueryEmbedding(String query) =>
      _aiService.generateEmbedding(query, isSearch: true, useGemini: true);

  Future<List<PropertyModel>> searchWithAi({
    required List<double> vector,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final data = await _pService.searchPropertiesByAi(
        vector: vector,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        governorateId: governorateId,
        cityId: cityId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: assignedTo,
        limit: limit,
        offset: offset,
      );
      return data.map((e) => PropertyModel.fromJson(e)).toList();
    } catch (e) {
      throw 'فشل الذكاء الاصطناعي: $e';
    }
  }

  Future<PropertyModel> togglePin(String propertyId, bool isPinned) async {
    try {
      final fresh = await _pService.togglePin(propertyId, isPinned);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      throw 'فشل التثبيت، حاول مرة أخرى';
    }
  }

  Future<void> archiveProperty(String propertyId, bool isArchived) async {
    try {
      await _pService.archiveProperty(propertyId, isArchived);
    } catch (e) {
      throw Exception("فشل تحديث الأرشيف: $e");
    }
  }

  Future<void> publishPropertyPlatforms(String propertyId, List<String> platformIds) async {
    await _pService.publishPlatforms(propertyId, platformIds);
  }

  Future<void> insertPropertyPlatforms(String propertyId, List<String> platformIds) async {
    await _pService.insertPlatforms(propertyId, platformIds);
  }

  Future<void> resetPlatformsPublished(String propertyId) async {
    await _pService.resetPlatformsPublished(propertyId);
  }

  Future<PropertyModel> getPropertyById(String id) async {
    final data = await _pService.getPropertyById(id);
    return PropertyModel.fromJson(data);
  }
}
