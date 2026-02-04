import 'dart:typed_data';
import '../models/property_model.dart';
import '../services/property_service.dart';
import '../services/storage_service.dart';

class PropertyRepository {
  final PropertyService _pService;
  final StorageService _sService;

  PropertyRepository(this._pService, this._sService);

  // 1. إنشاء عقار كامل مع الصور
  Future<PropertyModel> createFullProperty(PropertyModel model, List<Uint8List> images) async {
    String? newId;
    try {
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
      final fresh = await _pService.getMyProperties(userId: model.createdBy!, from: 0, to: 0);
      return PropertyModel.fromJson(fresh.first);
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
  Future<List<PropertyModel>> filterProperties(int f, int t, {String? c, String? ty}) async {
    final data = await _pService.filterProperties(from: f, to: t, city: c, type: ty);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  // 4. البحث النصي
  Future<List<PropertyModel>> searchProperties(String q) async {
    final data = await _pService.searchProperties(q);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  // 5. العدادات
  Future<int> fetchMyCount(String uid) => _pService.getMyCount(uid);
  Future<int> fetchFilterCount({String? c, String? ty}) =>
      _pService.getFilterCount(city: c, type: ty);

  // 6. حذف العقار بالكامل
  Future<void> deleteFullProperty(String id) async {
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

      // جلب البيانات المحدثة (تم تحسين الاستعلام ليجلب الموظف بمدى واسع للبحث عن الـ ID)
      final fresh = await _pService.getMyProperties(userId: p.createdBy!, from: 0, to: 50);
      final rawProp = fresh.firstWhere(
            (element) => element['id'].toString() == p.id,
        orElse: () => throw Exception("العقار غير موجود بعد التحديث"),
      );

      return PropertyModel.fromJson(rawProp);
    } catch (e) {
      throw Exception("فشل تحديث العقار: $e");
    }
  }



}