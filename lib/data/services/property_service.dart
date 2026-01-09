import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertiesService {

  final _client = Supabase.instance.client;


  Future<List<Map<String, dynamic>>> getProperties({
    required int page,
    required int pageSize,
    required String userId,
    required String role,
    double? minPrice, double? maxPrice,
    String? city, int? rooms, String? type,
  }) async {
    try {

      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = _client
          .from('properties')
          .select('*, property_images(image_url)');

      if (role == 'sales') {
        query = query.eq('created_by', userId);
      }

      if (city != null && city.isNotEmpty) query = query.eq('city', city);
      if (type != null && type.isNotEmpty) query = query.eq('type', type);
      if (rooms != null) query = query.gte('rooms', rooms);
      if (minPrice != null) query = query.gte('price', minPrice);
      if (maxPrice != null) query = query.lte('price', maxPrice);

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return response;
    } catch (e) {
      throw Exception("Error in Fetching data : $e");
    }
  }



  Future<List<String>> uploadImages(List<Uint8List> bytesList, String propertyId) async {
    List<String> imageUrls = [];

    for (int i = 0; i < bytesList.length; i++) {
      final String path = '$propertyId/img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      await _client.storage.from('property_images').uploadBinary(
        path,
        bytesList[i],
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final String url = _client.storage.from('property_images').getPublicUrl(path);
      imageUrls.add(url);
    }
    return imageUrls;
  }


  Future<Map<String, dynamic>> insertProperty(Map<String, dynamic> data) async {
    return await _client.from('properties').insert(data).select().single();
  }


  Future<void> insertImageUrls(String propertyId, List<String> urls) async {
    final List<Map<String, dynamic>> rows = urls
        .map((url) => {'property_id': propertyId, 'image_url': url})
        .toList();
    await _client.from('property_images').insert(rows);
  }



  Future<void> deleteProperty(String propertyId) async {
    try {
      final List<FileObject> files = await _client.storage.from('property_images').list(path: propertyId);
      if (files.isNotEmpty) {
        final List<String> pathsToDelete = files.map((f) => '$propertyId/${f.name}').toList();
        await _client.storage.from('property_images').remove(pathsToDelete);
      }
      await _client.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      throw Exception("Error in deleting property : $e");
    }
  }


  Future<void> deleteSpecificImages(List<String> urls) async {
    if (urls.isEmpty) return;

    try {
      List<String> pathsToDelete = [];
      for (var url in urls) {
        final Uri uri = Uri.parse(url);
        final String path = "${uri.pathSegments[uri.pathSegments.length - 2]}/${uri.pathSegments.last}";
        pathsToDelete.add(path);
      }
      if (pathsToDelete.isNotEmpty) {
        await _client.storage.from('property_images').remove(pathsToDelete);
      }
      await _client.from('property_images').delete().inFilter('image_url', urls);
    } catch (e) {
      throw Exception("Error in deleting image : $e");
    }
  }

}