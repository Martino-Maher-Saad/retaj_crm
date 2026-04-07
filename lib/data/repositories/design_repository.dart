import 'dart:typed_data';
import '../models/design_image_model.dart';
import '../models/design_model.dart';
import '../services/ai_service.dart';
import '../services/design_service.dart';
import '../services/storage_service.dart';

class DesignRepository {
  final DesignService _service;
  final StorageService _storageService;
  final AiService _aiService;

  DesignRepository(this._service, this._storageService, this._aiService);

  Future<List<DesignModel>> getDesigns({required int from, required int to}) async {
    final data = await _service.getDesigns(from: from, to: to);
    return data.map((e) => DesignModel.fromJson(e)).toList();
  }

  Future<DesignModel> createFullDesign({
    required DesignModel baseDesign,
    required List<Uint8List> rawImages,
  }) async {
    // 1. Generate Semantic Embedding
    final textForAi = "${baseDesign.descAr ?? ''} ${baseDesign.roomType ?? ''} ${baseDesign.style ?? ''}";
    List<double>? embedding;
    if (textForAi.trim().isNotEmpty) {
      try {
        embedding = await _aiService.generateEmbedding(textForAi, isSearch: false);
      } catch (e) {
        // Continue even if AI fails, or handle it as required
      }
    }

    final dataToInsert = baseDesign.toJson();
    if (embedding != null) {
      dataToInsert['embedding'] = embedding;
    }

    // 2. Insert into Database
    final insertedData = await _service.insertDesign(dataToInsert);
    final String newId = insertedData['id'].toString();
    final List<DesignImageModel> createdImages = [];

    // 3. Upload Images
    if (rawImages.isNotEmpty) {
      final String folderName = newId;
      for (int i = 0; i < rawImages.length; i++) {
        final imageBytes = rawImages[i];
        final fileName = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        try {
          final url = await _storageService.uploadImage(
            imageBytes,
            folderName,
            fileName,
            bucket: 'design_images',
          );
          await _service.insertImageRecord(newId, url);
          createdImages.add(DesignImageModel(
            id: '',
            designId: newId,
            imageUrl: url,
            createdAt: DateTime.now(),
          ));
        } catch (e) {
          // If a major error occurs, we might want to rollback
          await deleteFullDesign(newId);
          throw Exception("Failed to upload images, design creation rolled back. Error: $e");
        }
      }
    }

    return DesignModel(
      id: newId,
      descAr: insertedData['desc_ar'],
      roomType: insertedData['room_type'],
      style: insertedData['style'],
      createdAt: DateTime.parse(insertedData['created_at']),
      addedBy: insertedData['added_by'],
      embedding: embedding,
      images: createdImages,
    );
  }

  Future<void> deleteFullDesign(String designId) async {
    // Delete images from Storage first
    await _storageService.deleteFolder(designId, bucket: 'design_images');
    // Delete from DB logic (cascade usually handles image records, but record is deleted here)
    await _service.deleteDesignRecord(designId);
  }

  Future<DesignModel> updateFullDesign({
    required String designId,
    required Map<String, dynamic> updatedFields,
    required List<Uint8List> newImagesBytes,
    required List<String> imagesToDeleteIds,
  }) async {
    // Re-generate embeddings if relevant fields changed
    if (updatedFields.containsKey('desc_ar') || updatedFields.containsKey('room_type') || updatedFields.containsKey('style')) {
      final textForAi = "${updatedFields['desc_ar'] ?? ''} ${updatedFields['room_type'] ?? ''} ${updatedFields['style'] ?? ''}";
      try {
        final embedding = await _aiService.generateEmbedding(textForAi, isSearch: false);
        updatedFields['embedding'] = embedding;
      } catch (_) {}
    }

    // 1. Delete requested images
    if (imagesToDeleteIds.isNotEmpty) {
      await _service.deleteImageRecordsByIds(imagesToDeleteIds);
    }

    // 2. Upload new images
    if (newImagesBytes.isNotEmpty) {
      final String folderName = designId;
      for (int i = 0; i < newImagesBytes.length; i++) {
        final imageBytes = newImagesBytes[i];
        final fileName = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
        final url = await _storageService.uploadImage(
          imageBytes,
          folderName,
          fileName,
          bucket: 'design_images',
        );
        await _service.insertImageRecord(designId, url);
      }
    }

    // 3. Update core details
    final updatedData = await _service.updateDesign(designId, updatedFields);
    
    // Fetch full design to return
    final fullDesign = await _service.getDesignById(designId);
    return DesignModel.fromJson(fullDesign);
  }

  Future<List<DesignModel>> searchDesignsSemantic(String query) async {
    if (query.trim().isEmpty) return [];
    final vector = await _aiService.generateEmbedding(query, isSearch: true);
    final data = await _service.searchDesignsByAi(vector);
    return data.map((e) => DesignModel.fromJson(e)).toList();
  }
}
