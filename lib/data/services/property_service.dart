import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PropertiesService {
  final _client = Supabase.instance.client;

  // دالة ضغط الصور لتحسين أداء الرفع في الـ Web
  Future<Uint8List> _compressImage(Uint8List list) async {
    try {
      return await FlutterImageCompress.compressWithList(
        list,
        minHeight: 1080,
        minWidth: 1920,
        quality: 75, // توازن مثالي للـ CRM
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      return list; // العودة للأصل في حال فشل الضغط
    }
  }

  // 1. إضافة عقار (تم تعديل الـ select ليكون بسيطاً في أول خطوة)
  Future<Map<String, dynamic>> insertProperty(Map<String, dynamic> data) async {
    // إزالة أي حقول صور أو معرفات يدوية قبل الإرسال لجدول properties
    data.remove('id');
    data.remove('property_images');
    data.remove('images');

    return await _client
        .from('properties')
        .insert(data)
        .select() // نجلب بيانات الصف الأساسي فقط
        .single();
  }

  // 2. تحديث عقار
  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> data) async {
    data.remove('created_by');
    data.remove('created_at');
    data.remove('id');
    data.remove('property_images');
    data.remove('images');

    return await _client
        .from('properties')
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }

  // 3. دالة جديدة مطلوبة لجلب العقار مع صوره بعد عملية الربط
  Future<Map<String, dynamic>> getPropertyById(String id) async {
    return await _client
        .from('properties')
        .select('*, property_images(image_url)')
        .eq('id', id)
        .single();
  }

  // 4. رفع الصور
  Future<List<String>> uploadImages(List<Uint8List> bytesList, String propertyId) async {
    List<String> imageUrls = [];
    for (int i = 0; i < bytesList.length; i++) {
      Uint8List compressedData = await _compressImage(bytesList[i]);
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final String path = '$propertyId/$fileName';

      await _client.storage.from('property_images').uploadBinary(
        path,
        compressedData,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      imageUrls.add(_client.storage.from('property_images').getPublicUrl(path));
    }
    return imageUrls;
  }

  // 5. ربط الصور بجدول الصور المنفصل
  Future<void> insertImageUrls(String propertyId, List<String> urls) async {
    if (urls.isEmpty) return;
    final List<Map<String, dynamic>> rows = urls.map((url) => {
      'property_id': propertyId,
      'image_url': url
    }).toList();
    await _client.from('property_images').insert(rows);
  }

  // 6. جلب العقارات بالقائمة
  Future<List<Map<String, dynamic>>> getProperties({
    required int page,
    required int pageSize,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    var query = _client.from('properties').select('*, property_images(image_url)');

    if (role == 'sales') query = query.eq('created_by', userId);
    if (city != null && city.isNotEmpty) query = query.eq('city', city);
    if (type != null && type.isNotEmpty) query = query.eq('type', type);

    final response = await (sortByPrice
        ? query.order('price', ascending: false)
        : query.order('created_at', ascending: false))
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  // 7. حذف العقار
  Future<void> deleteProperty(String propertyId) async {
    try {
      final List<FileObject> files = await _client.storage.from('property_images').list(path: propertyId);
      if (files.isNotEmpty) {
        final List<String> pathsToDelete = files.map((f) => '$propertyId/${f.name}').toList();
        await _client.storage.from('property_images').remove(pathsToDelete);
      }
    } catch (_) {}
    await _client.from('properties').delete().eq('id', propertyId);
  }

  // 8. دالة العد (بنفس الطريقة التي طلبتها مع معالجة النوع)
  Future<int> getPropertiesCount({required String userId, required String role, String? city, String? type}) async {
    var query = _client.from('properties').select('*');
    if (role == 'sales') query = query.eq('created_by', userId);
    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
  }

  // داخل ملف properties_service.dart

  // داخل كلاس PropertiesService في ملف properties_service.dart
// أضف هذه الدالة ولا تحذف أي دالة أخرى

  Future<void> deleteSpecificImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    // 1. تنظيف الروابط لضمان المطابقة في قاعدة البيانات
    // إزالة أي شيء بعد علامة الـ '?' مثل (width=250)
    final cleanedUrls = imageUrls.map((url) => url.split('?').first).toList();

    // 2. حذف السجلات من جدول روابط الصور
    await _client
        .from('property_images')
        .delete()
        .inFilter('image_url', cleanedUrls); // 👈 المسمى الصحيح في أغلب إصدارات Dart/Supabase

    // 3. حذف الملفات الفعلية من الـ Storage (التنظيف الذري)
    for (var url in cleanedUrls) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        // استخراج المسار (folder/filename)
        if (pathSegments.length >= 2) {
          final storagePath = "${pathSegments[pathSegments.length - 2]}/${pathSegments.last}";
          await _client.storage.from('property_images').remove([storagePath]);
        }
      } catch (e) {
        // نكتفي بطباعة الخطأ لضمان استمرار العملية وعدم توقف التطبيق
      }
    }
  }


}