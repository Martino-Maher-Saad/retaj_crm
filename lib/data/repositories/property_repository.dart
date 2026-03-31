import 'dart:typed_data';

import '../models/property_model.dart';
import '../services/ai_service.dart';
import '../services/property_service.dart';
import '../services/storage_service.dart';

class PropertyRepository {
  final PropertyService _pService;
  final StorageService _sService;
  final AiService _aiService;

  PropertyRepository(this._pService, this._sService, this._aiService);

  // 1. إنشاء عقار كامل مع الصور
  Future<PropertyModel> createFullProperty(
    PropertyModel model,
    List<Uint8List> images,
  ) async {
    String? newId;
    try {
      // توليد الـ Embedding قبل الحفظ في الداتابيز
      final text =
          '${model.titleAr} ${model.propertyTypeAr} في ${model.cityAr} بمحافظة ${model.governorateAr}. ${model.descAr}';
      final vector = await _aiService.generateEmbedding(text, isSearch: false);
      model = model.copyWith(embedding: vector);

      // إرسال البيانات (الموديل سيولد JSON بالمسميات الجديدة تلقائياً)
      final data = await _pService.insertProperty(model.toJson());
      newId = data['id'].toString();

      // رفع الصور وربطها بالعقار
      for (int i = 0; i < images.length; i++) {
        final name = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final url = await _sService.uploadImage(images[i], newId, name);
        await _pService.insertImageRecord(newId, url);
      }

      // جلب العقار بعد الإضافة لضمان الحصول على الـ search_vector والبيانات المحسوبة
      // استخدمنا range(0,0) لجلب آخر واحد تمت إضافته لهذا المستخدم
      final fresh = await _pService.getPropertyById(newId);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      // تراجع (Rollback) في حالة الفشل
      if (newId != null) {
        await _pService.deletePropertyRecord(newId);
        await _sService.deleteFolder(newId);
      }
      throw Exception("فشل الإضافة الآمنة: $e");
    }
  }

  // 2. جلب عقارات الموظف
  Future<List<PropertyModel>> getMyProperties(String uid, int f, int t) async {
    final data = await _pService.getMyProperties(userId: uid, from: f, to: t);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  // 3. الفلترة (توجيه البارامترات للأسماء الجديدة في الـ Service)
  Future<List<PropertyModel>> filterProperties(
    int f,
    int t, {
    String? c,
    String? ty,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
  }) async {
    final data = await _pService.filterProperties(
      from: f,
      to: t,
      city: c,
      type: ty,
      governorate: governorate,
      listingType: listingType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      assignedTo: assignedTo,
    );
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  // 4. البحث النصي
  Future<List<PropertyModel>> searchProperties(String q) async {
    final data = await _pService.searchProperties(q);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  // 5. العدادات
  Future<int> fetchMyCount(String uid) => _pService.getMyCount(uid);
  Future<int> fetchFilterCount({
    String? c, 
    String? ty,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
  }) =>
      _pService.getFilterCount(
        city: c, 
        type: ty,
        governorate: governorate,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: assignedTo,
      );

  // 6. حذف العقار بالكامل
  Future<void> deleteFullProperty(String id) async {
    // نمسح الصور من الـ Storage أولاً لضمان عدم بقاء صور بدون عقار (orphan)
    // لو فشل الـ Storage delete، الـ DB record يفضل موجود والعقار يظهر بدون مشكلة
    await _sService.deleteFolder(id);
    await _pService.deletePropertyRecord(id);
  }

  // 7. تحديث العقار والصور
  Future<PropertyModel> updateFullProperty({
    required PropertyModel p,
    required List<Uint8List> newImgs,
    List<String>? delImgsIds, // قائمة الـ IDs للمسح من DB
    List<String>? delImgsUrls, // قائمة الـ URLs للمسح من Storage
  }) async {
    try {
      // تحديث الـ Embedding عند التعديل
      final text =
          '${p.titleAr} ${p.propertyTypeAr} في ${p.cityAr} بمحافظة ${p.governorateAr}. ${p.descAr}';
      final vector = await _aiService.generateEmbedding(text, isSearch: false);
      p = p.copyWith(embedding: vector);

      // تحديث البيانات النصية
      await _pService.updateProperty(p.id, p.toJson());

      // 2. حذف الصور (داتا بيز + ستوريدج)
      if (delImgsIds != null && delImgsIds.isNotEmpty) {
        // حذف من الداتا بيز بطلقة واحدة
        await _pService.deleteImageRecordsByIds(delImgsIds);

        // حذف من الـ Storage (بنلف على الـ URLs)
        for (var url in delImgsUrls!) {
          final fileName = url.split('/').last;
          await _sService.deleteFile(p.id, fileName);
        }
      }

      // رفع الصور الجديدة
      for (int i = 0; i < newImgs.length; i++) {
        final name = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final url = await _sService.uploadImage(newImgs[i], p.id, name);
        await _pService.insertImageRecord(p.id, url);
      }

      // جلب البيانات المحدثة مباشرة بالـ ID لضمان الدقة والسرعة
      final fresh = await _pService.getPropertyById(p.id);
      return PropertyModel.fromJson(fresh);
    } catch (e) {
      throw Exception("فشل تحديث العقار: $e");
    }
  }

  // البحث الذكي بالذكاء الاصطناعي
  Future<List<PropertyModel>> searchWithAi(String query) async {
    try {
      final vector = await _aiService.generateEmbedding(query, isSearch: true);
      final data = await _pService.searchPropertiesByAi(vector);
      return data.map((e) => PropertyModel.fromJson(e)).toList();
    } catch (e) {
      throw 'فشل الاتصال بخدمات الذكاء الاصطناعي، تأكد من الإنترنت';
    }
  }
}
