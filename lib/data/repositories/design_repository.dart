import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/design_model.dart';
import '../services/design_service.dart';
import '../services/cloudinary_service.dart';
import '../services/ai_service.dart';

class DesignRepository {
  final DesignService _dService;
  final CloudinaryService _cService;
  final AiService _aiService;

  DesignRepository(this._dService, this._cService, this._aiService);

  /// إضافة تشطيب جديد بالكامل (البيانات + التضمين AI + الصور في Cloudinary)
  Future<DesignModel> createFullDesign(
    DesignModel model,
    List<Uint8List> images,
  ) async {
    String? newId;
    try {
      final text = model.descAr;
      
      // 1. توليد الـ Vector من وصف التشطيب (768 بعداً باستخدام Gemini)
      final vector = await _aiService.generateEmbedding(text, isSearch: false, useGemini: true);
      
      // 2. تعيين المُدخل (User ID)
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final dataToInsert = model.toJson(embedding: vector);
      dataToInsert['added_by'] = userId;

      // 3. إضافة التشطيب في Supabase
      final data = await _dService.insertDesign(dataToInsert);
      newId = data['id'].toString();

      // 4. رفع الصور إلى Cloudinary وإضافة روابطها في Supabase
      for (int i = 0; i < images.length; i++) {
        final name = 'design_${newId}_img_$i.jpg';
        final url = await _cService.uploadImage(images[i], name, folder: 'designs/$newId');
        
        if (url != null) {
          final isThumbnail = (i == 0); // نعتبر أول صورة هي المصغرة (الغلاف)
          await _dService.insertImage(newId, url, isThumbnail);
        }
      }

      // 5. جلب التشطيب بالكامل مرة أخرى لإرجاعه للمستخدم
      return await _dService.getDesignById(newId);
    } catch (e) {
      if (newId != null) {
        // في حالة فشل رفع الصور بعد إضافة التشطيب، نحذفه لتجنب البيانات المعلقة
        await _dService.deleteDesign(newId);
      }
      rethrow;
    }
  }

  /// تعديل تشطيب (تعديل الوصف أو الروابط) مع إعادة توليد الـ Vector إذا لزم الأمر
  Future<DesignModel> updateFullDesign(
    DesignModel model, {
    List<Uint8List>? newImages,
    List<String>? deletedImageIds,
  }) async {
    final oldModel = await _dService.getDesignById(model.id);
    
    List<double>? vector;
    // إعادة التوليد لو اختلف الوصف
    if (oldModel.descAr != model.descAr) {
      vector = await _aiService.generateEmbedding(model.descAr, isSearch: false, useGemini: true);
    }

    final dataToUpdate = model.toJson(embedding: vector);
    dataToUpdate.remove('added_by'); // لا نحدث من أضافه أبداً

    await _dService.updateDesign(model.id, dataToUpdate);

    // حذف الصور القديمة
    if (deletedImageIds != null && deletedImageIds.isNotEmpty) {
      for (var imgId in deletedImageIds) {
        await _dService.deleteImage(imgId);
      }
    }

    // إضافة الصور الجديدة
    if (newImages != null && newImages.isNotEmpty) {
      for (int i = 0; i < newImages.length; i++) {
        final name = 'design_${model.id}_new_img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _cService.uploadImage(newImages[i], name);
        if (url != null) {
          // نعطي أول صورة مضافة حديثاً كـ Thumbnail لو لم يكن هناك صور من قبل
          bool isThumb = false;
          if (i == 0 && (oldModel.images == null || oldModel.images!.isEmpty) && (deletedImageIds?.length ?? 0) >= (oldModel.images?.length ?? 0)) {
            isThumb = true;
          }
          await _dService.insertImage(model.id, url, isThumb);
        }
      }
    }

    // جلب التشطيب المحدث
    return await _dService.getDesignById(model.id);
  }

  /// حذف التشطيب بالكامل
  Future<void> deleteDesign(String id) async {
    // 1. Fetch design to get image URLs
    final design = await _dService.getDesignById(id);
    
    // 2. Delete images from Cloudinary first (so we don't leave orphaned images)
    if (design.images != null) {
      for (var img in design.images!) {
        if (img.imageUrl != null) {
          await _cService.deleteImageByUrl(img.imageUrl!);
        }
      }
    }
    
    // 3. Delete from database
    await _dService.deleteDesign(id);
  }

  /// البحث الذكي عبر AI
  Future<List<DesignModel>> searchDesignsByAi(String query, {String? roomTypeId, String? styleId, String? addedByProfileId}) async {
    final vector = await _aiService.generateEmbedding(query, isSearch: true, useGemini: true);
    return await _dService.searchDesignsByAi(vector: vector, roomTypeId: roomTypeId, styleId: styleId, addedByProfileId: addedByProfileId);
  }

  /// جلب القائمة
  Future<List<DesignModel>> getDesigns({int limit = 20, int offset = 0, String? roomTypeId, String? styleId, String? addedByProfileId}) async {
    return await _dService.getDesigns(limit: limit, offset: offset, roomTypeId: roomTypeId, styleId: styleId, addedByProfileId: addedByProfileId);
  }
}
