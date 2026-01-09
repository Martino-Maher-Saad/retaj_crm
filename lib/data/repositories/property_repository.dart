import 'dart:typed_data';
import '../models/property_model.dart';
import '../services/property_service.dart';


class PropertiesRepository {
  final PropertiesService _service;

  PropertiesRepository(this._service);


  Future<List<PropertyModel>> fetchProperties({
    required int page,
    required int pageSize,
    required String userId,
    required String role,
    double? minPrice, double? maxPrice,
    String? city, int? rooms, String? type,
  }) async {

    final List<Map<String, dynamic>> data = await _service.getProperties(
      page: page, pageSize: pageSize, userId: userId, role: role,
      city: city, minPrice: minPrice, maxPrice: maxPrice, rooms: rooms, type: type,
    );
    return data.map((json) => PropertyModel.fromJson(json)).toList();
  }


  Future<PropertyModel> createProperty({
    required PropertyModel property,
    required List<Uint8List> imageFiles,
  }) async {

    final propertyData = await _service.insertProperty(property.toJson());
    final String propertyId = propertyData['id'];

    List<String> finalUrls = [];

    if (imageFiles.isNotEmpty) {
      finalUrls = await _service.uploadImages(imageFiles, propertyId);
      await _service.insertImageUrls(propertyId, finalUrls);
    }

    return property.copyWith(id: propertyId, images: finalUrls);
  }


  Future<void> updatePropertyData(PropertyModel updatedProperty) async {
    await _service.insertProperty({
      ...updatedProperty.toJson(),
      'id': updatedProperty.id,
    });
  }


  Future<void> uploadAdditionalImages({
    required String propertyId,
    required int currentImagesCount,
    required List<Uint8List> newImageFiles,
  }) async {

    if (currentImagesCount + newImageFiles.length > 10) {
      throw Exception("Sorry you reached ${currentImagesCount + newImageFiles.length} and your limit is 10 images");
    }

    if (newImageFiles.isNotEmpty) {

      final List<String> newUrls = await _service.uploadImages(newImageFiles, propertyId);
      await _service.insertImageUrls(propertyId, newUrls);
    }
  }


  Future<void> deleteSingleImage(String imageUrl) async {
    await _service.deleteSpecificImages([imageUrl]);
  }


  Future<void> deleteProperty(String id) async {
    await _service.deleteProperty(id);
  }

}