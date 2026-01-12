import 'dart:typed_data';
import '../models/property_model.dart';
import '../services/property_service.dart';


class PropertiesRepository {
  final PropertiesService _service;

  PropertiesRepository(this._service);


  Future<Map<String, dynamic>> fetchPropertiesWithPagination({
    required int page,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false,
  }) async {
    // تنفيذ الطلبين بالتوازي لضمان السرعة
    final results = await Future.wait([
      _service.getProperties( // الدالة الأساسية اللي عندك
        page: page, pageSize: 15, userId: userId, role: role,
        city: city, type: type, sortByPrice: sortByPrice,
      ),
      _service.getPropertiesCount(
        userId: userId, role: role, city: city, type: type,
      ),
    ]);

    final List<PropertyModel> properties = (results[0] as List)
        .map((json) => PropertyModel.fromJson(json))
        .toList();

    return {
      'properties': properties,
      'totalCount': results[1] as int,
    };
  }


  Future<List<PropertyModel>> fetchProperties({
    required int page,
    required int pageSize,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false,
  }) async {
    // 1. طلب البيانات من الـ Service
    final List<Map<String, dynamic>> data = await _service.getProperties(
      page: page,
      pageSize: pageSize,
      userId: userId,
      role: role,
      city: city,
      type: type,
      sortByPrice: sortByPrice,
    );

    // 2. تحويل الـ List<Map> إلى List<PropertyModel>
    // استخدمنا .map لتحويل كل Json إلى Model بناءً على المصنع (fromJson) الموجود في موديلك
    return data.map((json) => PropertyModel.fromJson(json)).toList();
  }


  Future<PropertyModel> createProperty({
    required PropertyModel property,
    required List<Uint8List> imageFiles,
  }) async {
    // أ. توليد ID مؤقت أو عشوائي لاستخدامه كاسم للمجلد في الـ Storage
    // أو يمكننا إدخال العقار أولاً للحصول على الـ ID الحقيقي

    // 1. إدخال بيانات العقار الأساسية (بدون صور) للحصول على الـ ID من السيرفر
    final propertyData = await _service.insertProperty(property.toJson());
    final String propertyId = propertyData['id'];

    try {
      List<String> finalUrls = [];

      // 2. إذا وجد صور، قم برفعها باستخدام الـ ID الذي حصلنا عليه
      if (imageFiles.isNotEmpty) {
        finalUrls = await _service.uploadImages(imageFiles, propertyId);

        // 3. ربط الروابط بالعقار في جدول الصور
        await _service.insertImageUrls(propertyId, finalUrls);
      } else {
        // إذا كان منطق عملك يمنع إضافة عقار بدون صور، يمكننا رمي Exception هنا
        throw Exception("يجب إضافة صورة واحدة على الأقل");
      }

      // 4. إعادة الموديل كاملاً بعد تحديث الـ ID والروابط
      return property.copyWith(id: propertyId, images: finalUrls);

    } catch (e) {
      // "Cleanup" في حالة الفشل: إذا تم حفظ العقار وفشل رفع الصور، نحذف العقار لضمان الذرية
      await _service.deleteProperty(propertyId);
      throw Exception("فشل إنشاء العقار بسبب خطأ في رفع الصور: $e");
    }
  }


  Future<void> updatePropertyData(PropertyModel updatedProperty) async {
    // بنبعت الـ ID لوحده، وباقي البيانات (الـ Json) لوحدها
    await _service.updateProperty(
      updatedProperty.id!,
      updatedProperty.toJson(),
    );
  }



  // الدالة الشاملة للتعديل (رفع صور + تحديث بيانات)
  Future<PropertyModel> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
  }) async {
    try {
      List<String> updatedUrls = List.from(property.images);

      // 1. إذا كان هناك صور جديدة، قم برفعها أولاً
      if (newImages.isNotEmpty) {
        // نرفع الصور ونحصل على الروابط
        final List<String> uploadedUrls = await _service.uploadImages(newImages, property.id!);

        // نربط الروابط الجديدة في قاعدة البيانات (جدول الصور)
        await _service.insertImageUrls(property.id!, uploadedUrls);

        // نضيف الروابط الجديدة للقائمة التي سنعيدها للموديل
        updatedUrls.addAll(uploadedUrls);
      }

      // 2. تحديث بيانات العقار الأساسية (الاسم، السعر، إلخ)
      // نستخدم الدالة التي طلبتها أنت تحديداً
      final propertyWithNewUrls = property.copyWith(images: updatedUrls);
      await updatePropertyData(propertyWithNewUrls);

      // 3. نعيد الموديل المحدث كاملاً لتحديث الواجهة محلياً
      return propertyWithNewUrls;

    } catch (e) {
      throw Exception("فشل تحديث العقار: $e");
    }
  }


  Future<List<String>> uploadAdditionalImages({
    required String propertyId,
    required int currentImagesCount,
    required List<Uint8List> newImageFiles,
  }) async {
    // التأكد من عدم تجاوز الحد الأقصى (10 صور)
    if (currentImagesCount + newImageFiles.length > 10) {
      throw Exception("عفواً، لقد وصلت للحد الأقصى (10 صور). لا يمكنك إضافة المزيد.");
    }

    if (newImageFiles.isNotEmpty) {
      // 1. رفع الصور الجديدة
      final List<String> newUrls = await _service.uploadImages(newImageFiles, propertyId);

      // 2. حفظ الروابط الجديدة في قاعدة البيانات
      await _service.insertImageUrls(propertyId, newUrls);

      return newUrls;
    }
    return [];
  }


  Future<void> deleteSingleImage(String imageUrl) async {
    await _service.deleteSpecificImages([imageUrl]);
  }


  // حذف العقار بالكامل
  Future<void> deleteProperty(String id) async {
    await _service.deleteProperty(id);
  }

}