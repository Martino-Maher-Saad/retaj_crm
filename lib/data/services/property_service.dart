import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  final _client = Supabase.instance.client;

  // SELECT مع JOIN على profiles لجلب اسم الموظف
  static const _select =
      '*, property_images(*), creator:profiles!properties_created_by_fk(first_name, last_name)';

  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final response = await _client
        .from('properties')
        .select(_select)
        .eq('id', id)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getMyProperties({
    required String userId,
    required int from,
    required int to,
  }) async {
    final response = await _client
        .from('properties')
        .select(_select)
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> filterProperties({
    required int from,
    required int to,
    String? city,
    String? type,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client.from('properties').select(_select);

    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('created_by', assignedTo);
    }
    if (governorate != null && governorate.isNotEmpty) {
      query = query.eq('governorate_ar', governorate);
    }
    if (city != null && city.isNotEmpty) {
      query = query.eq('city_ar', city);
    }
    if (type != null && type.isNotEmpty) {
      query = query.eq('property_type_ar', type);
    }
    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type_ar', listingType);
    }
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchProperties(String term) async {
    final response = await _client
        .from('properties')
        .select(_select)
        .textSearch('search_vector', term)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getMyCount(String userId) async {
    final res = await _client
        .from('properties')
        .select('*')
        .eq('created_by', userId)
        .limit(0)
        .count(CountOption.exact);
    return res.count ?? 0;
  }

  Future<int> getFilterCount({
    String? city,
    String? type,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client.from('properties').select('*');

    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('created_by', assignedTo);
    }
    if (governorate != null && governorate.isNotEmpty) {
      query = query.eq('governorate_ar', governorate);
    }
    if (city != null && city.isNotEmpty) {
      query = query.eq('city_ar', city);
    }
    if (type != null && type.isNotEmpty) {
      query = query.eq('property_type_ar', type);
    }
    if (listingType != null && listingType.isNotEmpty) {
      query = query.eq('listing_type_ar', listingType);
    }
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }
    if (toDate != null) {
      query = query.lte('created_at', toDate.toIso8601String());
    }

    final res = await query.limit(0).count(CountOption.exact);
    return res.count ?? 0;
  }

  Future<Map<String, dynamic>> insertProperty(Map<String, dynamic> data) async {
    return await _client.from('properties').insert(data).select().single();
  }

  Future<void> insertImageRecord(String propId, String url) async =>
      await _client.from('property_images').insert({
        'property_id': propId,
        'image_url': url,
      });

  Future<void> deletePropertyRecord(String id) async =>
      await _client.from('properties').delete().eq('id', id);

  Future<Map<String, dynamic>> updateProperty(
    String id,
    Map<String, dynamic> data,
  ) async =>
      await _client
          .from('properties')
          .update(data)
          .eq('id', id)
          .select()
          .single();

  Future<void> deleteImageRecordsByIds(List<String> ids) async =>
      await _client.from('property_images').delete().inFilter('id', ids);

  Future<List<Map<String, dynamic>>> searchPropertiesByAi(
    List<double> vector,
  ) async {
    final response = await _client.rpc(
      'match_properties',
      params: {
        'query_embedding': vector,
        'match_threshold': 0.75,
        'match_count': 10,
      },
    ).select(_select);
    return List<Map<String, dynamic>>.from(response);
  }
}
