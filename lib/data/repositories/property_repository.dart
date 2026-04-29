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

  Future<PropertyModel> createFullProperty(
    PropertyModel model,
    List<Uint8List> images,
  ) async {
    String? newId;
    try {
      // توليد الـ Embedding باستخدام الأعمدة المحددة فقط (بدون price/search_vector fields)
      // المطلوب: desc_ar + governorate_ar + city_ar + region_ar + location_in_details
      final text =
          '${model.descAr ?? ''} ${model.governorateAr} ${model.cityAr} ${model.regionAr ?? ''} ${model.locationInDetails ?? ''}';
      final vector = await _aiService.generateEmbedding(text, isSearch: false);
      model = model.copyWith(embedding: vector);

      final data = await _pService.insertProperty(model.toJson());
      newId = data['id'].toString();

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
    DateTime? fromDate,
    DateTime? toDate,
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
      fromDate: fromDate,
      toDate: toDate,
    );
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<List<PropertyModel>> searchProperties(String q) async {
    final data = await _pService.searchProperties(q);
    return data.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<int> fetchMyCount(String uid) => _pService.getMyCount(uid);

  Future<int> fetchFilterCount({
    String? c,
    String? ty,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      _pService.getFilterCount(
        city: c,
        type: ty,
        governorate: governorate,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: assignedTo,
        fromDate: fromDate,
        toDate: toDate,
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
  }) async {
    try {
      final text =
          '${p.descAr ?? ''} ${p.governorateAr} ${p.cityAr} ${p.regionAr ?? ''} ${p.locationInDetails ?? ''}';
      final vector = await _aiService.generateEmbedding(text, isSearch: false);
      p = p.copyWith(embedding: vector);

      await _pService.updateProperty(p.id, p.toJson());

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
