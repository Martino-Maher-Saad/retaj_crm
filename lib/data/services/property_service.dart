import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertiesService {

  final _client = Supabase.instance.client;


  Future<int> getPropertiesCount({
    required String userId,
    required String role,
    String? city,
    String? type,
  }) async {
    var query = _client.from('properties').select('*');

    if (role == 'sales') query = query.eq('created_by', userId);
    if (city != null && city.isNotEmpty) query = query.eq('city', city);
    if (type != null && type.isNotEmpty) query = query.eq('type', type);

    // limit(0) عشان نطلب العدد فقط بدون جلب أي صفوف، لتوفير الباقة والوقت
    final response = await query.limit(0).count(CountOption.exact);
    return response.count ?? 0;
  }


  Future<List<Map<String, dynamic>>> getProperties({
    required int page,         // رقم الصفحة لعمل الـ Pagination
    required int pageSize,     // عدد العقارات في الصفحة (15)
    required String userId,    // معرف الموظف
    required String role,      // دور المستخدم (sales أو admin)
    String? city,              // فلتر المدينة
    String? type,              // فلتر النوع (بيع/إيجار)
    bool sortByPrice = false,  // متغير يحدد هل يريد الترتيب حسب السعر أم لا
  }) async {
    try {
      // 1. حساب حدود الصفحة: من (from) إلى (to)
      // السطر ده بيضمن إننا بنطلب 15 سجل فقط في كل طلب
      final from = page * pageSize;
      final to = from + pageSize - 1;

      // 2. إنشاء الاستعلام (Select Query):
      // بنقول لـ Supabase هات كل أعمدة العقار (*) وهات معاهم روابط الصور من الجدول المرتبط
      var query = _client
          .from('properties')
          .select('*, property_images(image_url)');

      // 3. فلتر الموظف (Privacy):
      // لو المستخدم مش Admin، بنجبر الاستعلام يجيب فقط العقارات اللي الـ created_by بتاعها هو الـ ID بتاعه
      if (role == 'sales') {
        query = query.eq('created_by', userId);
      }

      // 4. تطبيق فلاتر التصنيف (المدينة والنوع):
      // لو المستخدم اختار مدينة، بنضيف شرط "يساوي" (eq) على عمود الـ city
      if (city != null && city.isNotEmpty) query = query.eq('city', city);
      // لو المستخدم اختار نوع (بيع/إيجار)، بنضيف شرط "يساوي" (eq) على عمود الـ type
      if (type != null && type.isNotEmpty) query = query.eq('type', type);

      final PostgrestTransformBuilder finalQuery;

      // 5. منطق الترتيب (Ordering):
      if (sortByPrice) {
        // لو المستخدم اختار فلتر السعر: بنرتب من الأغلى للأرخص (ascending: false تعني تنازلي)
        finalQuery = query.order('price', ascending: false);
      } else {
        // الوضع الافتراضي أو لو لم يختار السعر: بنرتب من الجديد للقديم حسب تاريخ الإضافة
        finalQuery = query.order('created_at', ascending: false);
      }

      // 6. التنفيذ وجلب البيانات:
      // بنبعت الاستعلام للسيرفر مع تحديد نطاق الصفحة (Range)
      final response = await finalQuery.range(from, to);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      // في حالة حدوث أي خطأ في السيرفر أو الشبكة
      throw Exception("Error in Fetching data : $e");
    }
  }



  Future<List<String>> uploadImages(List<Uint8List> bytesList, String propertyId) async {
    List<String> imageUrls = [];

    try {
      // نمر على كل صورة في القائمة المرسلة
      for (int i = 0; i < bytesList.length; i++) {
        // 1. تحديد اسم فريد للملف يتكون من: وقت الرفع + رقم الصورة
        final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        // 2. تحديد المسار: نضع الصور داخل مجلد يحمل ID العقار لتسهيل الحذف لاحقاً
        final String path = '$propertyId/$fileName';

        // 3. عملية الرفع الفعلي لـ Supabase Storage
        await _client.storage.from('property_images').uploadBinary(
          path,
          bytesList[i],
          // تحديد نوع الملف لضمان عرضه بشكل صحيح في المتصفح أو التطبيق
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

        // 4. الحصول على الرابط العام (Public URL) للصورة المرفوعة
        final String url = _client.storage.from('property_images').getPublicUrl(path);

        imageUrls.add(url);
      }
      return imageUrls;
    } catch (e) {
      // استخدام الـ Error Handler الذي ناقشناه (سواء كان مخصصاً أو عاماً حالياً)
      throw Exception("فشل رفع الصور: $e");
    }
  }


  Future<Map<String, dynamic>> insertProperty(Map<String, dynamic> data) async {
    try {
      // إدخال البيانات في جدول properties
      // .select().single() تعني: "بعد الإضافة، هات لي السجل اللي ضفته كـ Map واحدة"
      final response = await _client.from('properties').insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception("فشل حفظ بيانات العقار: $e");
    }
  }

  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      // هنا بنستخدم .update() وبنحدد السجل بـ .eq('id', id)
      return await _client
          .from('properties')
          .update(data)   // تحديث البيانات فقط
          .eq('id', id)   // فين؟ في السجل اللي الـ id بتاعه مطابق
          .select()
          .single();
    } catch (e) {
      throw Exception("فشل تحديث بيانات العقار: $e");
    }
  }


  Future<void> insertImageUrls(String propertyId, List<String> urls) async {
    try {
      // تحويل قائمة الروابط إلى قائمة من الـ Maps لتناسب صيغة الإدخال الجماعي (Bulk Insert)
      final List<Map<String, dynamic>> rows = urls
          .map((url) => {
        'property_id': propertyId, // ربط الصورة بالعقار
        'image_url': url           // الرابط الفعلي
      })
          .toList();

      // إدخال كل الصفوف مرة واحدة (عملية واحدة للسيرفر)
      await _client.from('property_images').insert(rows);
    } catch (e) {
      throw Exception("فشل ربط الصور بالعقار: $e");
    }
  }



  Future<void> deleteProperty(String propertyId) async {
    try {
      // 1. جلب قائمة الملفات الموجودة داخل مجلد العقار في الـ Storage
      // list(path: propertyId) تعيد لنا كل الصور الموجودة في هذا المجلد
      final List<FileObject> files = await _client.storage.from('property_images').list(path: propertyId);

      if (files.isNotEmpty) {
        // 2. تحويل قائمة الملفات إلى قائمة مسارات كاملة (Paths)
        // المسار الكامل هو: اسم المجلد (propertyId) / اسم الملف
        final List<String> pathsToDelete = files.map((f) => '$propertyId/${f.name}').toList();

        // 3. حذف الملفات من الـ Storage
        await _client.storage.from('property_images').remove(pathsToDelete);
      }

      // 4. حذف السجل من جدول العقارات (Database)
      // ملاحظة: إذا كنت قد فعلت الـ (Cascade Delete) في قاعدة البيانات،
      // سيتم حذف روابط الصور من جدول property_images تلقائياً بمجرد حذف العقار.
      await _client.from('properties').delete().eq('id', propertyId);

    } catch (e) {
      throw Exception("حدث خطأ أثناء حذف العقار وملفاته: $e");
    }
  }


  Future<void> deleteSpecificImages(List<String> urls) async {
    if (urls.isEmpty) return;

    try {
      List<String> pathsToDelete = [];

      for (var url in urls) {
        // استخراج المسار النسبي من الرابط الكامل (Public URL)
        // الرابط يكون بصيغة: .../storage/v1/object/public/bucket/propertyId/fileName.jpg
        final Uri uri = Uri.parse(url);
        final segments = uri.pathSegments;

        // المسار الذي يحتاجه Supabase للحذف هو (propertyId/fileName.jpg)
        // وعادة ما يكون هما آخر عنصرين في الـ URL
        final String path = "${segments[segments.length - 2]}/${segments.last}";
        pathsToDelete.add(path);
      }

      // 1. حذف الملفات من الـ Storage الفعلي
      if (pathsToDelete.isNotEmpty) {
        await _client.storage.from('property_images').remove(pathsToDelete);
      }

      // 2. حذف الروابط من جدول الصور (Database) باستخدام فلتر (inFilter)
      // هذا الفلتر يحذف أي سجل يكون الرابط فيه موجود ضمن القائمة المرسلة
      await _client.from('property_images').delete().inFilter('image_url', urls);

    } catch (e) {
      throw Exception("حدث خطأ أثناء حذف الصور المحددة: $e");
    }
  }


}