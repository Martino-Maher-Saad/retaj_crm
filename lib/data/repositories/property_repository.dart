import 'dart:typed_data';
import '../../core/constants/app_constants.dart';
import '../models/property_model.dart';
import '../services/property_service.dart';

class PropertiesRepository {
  final PropertiesService _service;
  PropertiesRepository(this._service);

  Future<PropertyModel> createProperty({required PropertyModel property, required List<Uint8List> imageFiles}) async {
    final initialData = await _service.insertProperty(property.toJson());
    final String serverId = initialData['id'];

    try {
      if (imageFiles.isNotEmpty) {
        final List<String> urls = await _service.uploadImages(imageFiles, serverId);
        await _service.insertImageUrls(serverId, urls);
      }
      final finalData = await _service.getPropertyById(serverId);
      return PropertyModel.fromJson(finalData);
    } catch (e) {
      await _service.deleteProperty(serverId);
      throw Exception("فشل في استكمال إضافة العقار: $e");
    }
  }

  // داخل ملف properties_repository.dart

  // داخل كلاس PropertiesRepository في ملف property_repository.dart

  Future<PropertyModel> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<String>? imagesToDelete, // 👈 الباراميتر الجديد
  }) async {
    try {
      // 1. تنفيذ حذف الصور التي اختارها المستخدم (قبل أي شيء آخر)
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        await _service.deleteSpecificImages(imagesToDelete);
      }

      // 2. رفع الصور الجديدة (الزيادة)
      if (newImages.isNotEmpty) {
        final List<String> uploadedUrls = await _service.uploadImages(newImages, property.id);
        await _service.insertImageUrls(property.id, uploadedUrls);
      }

      // 3. تحديث البيانات النصية (السعر، الوصف، إلخ)
      await _service.updateProperty(property.id, property.toJson());

      // 4. جلب أحدث نسخة للعقار من السيرفر (للـ State Management)
      final finalData = await _service.getPropertyById(property.id);
      return PropertyModel.fromJson(finalData);
    } catch (e) {
      // فشل العملية هنا لا يحذف العقار الأصلي لأنه موجود بالفعل
      throw Exception("فشل في تحديث العقار: $e");
    }
  }

  Future<Map<String, dynamic>> fetchPropertiesWithPagination({
    required int page,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false
  }) async {
    final results = await Future.wait([
      _service.getProperties(page: page, pageSize: AppConstants.pageSize, userId: userId, role: role, city: city, type: type, sortByPrice: sortByPrice),
      _service.getPropertiesCount(userId: userId, role: role, city: city, type: type),
    ]);

    return {
      'properties': (results[0] as List).map((json) => PropertyModel.fromJson(json)).toList(),
      'totalCount': results[1] as int,
    };
  }

  Future<void> deleteProperty(String id) async => await _service.deleteProperty(id);
}