import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyService {
  final _client = Supabase.instance.client;

  // SELECT مع JOINs على جداول الـ lookup لجلب الأسماء العربية
  static const _select =
      '*, '
      'property_images(*), '
      'creator:profiles!properties_created_by_fk(first_name, last_name), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'property_sources!source_id(name_ar), '
      'cities!city_id(name), '
      'governorates!governorate_id(name), '
      'property_platforms(id, platform_id, advertising_platforms!pp_platform_fk(id, name_ar))';

  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final response = await _client.from('properties').select(_select).eq('id', id).single();
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
    int? cityId,
    String? propertyTypeId,
    int? governorateId,
    String? listingTypeId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client.from('properties').select(_select);

    if (assignedTo != null && assignedTo.isNotEmpty) query = query.eq('created_by', assignedTo);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    final response = await query.order('created_at', ascending: false).range(from, to);
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
    int? cityId,
    String? propertyTypeId,
    int? governorateId,
    String? listingTypeId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var query = _client.from('properties').select('*');

    if (assignedTo != null && assignedTo.isNotEmpty) query = query.eq('created_by', assignedTo);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());

    final res = await query.limit(0).count(CountOption.exact);
    return res.count ?? 0;
  }

  Future<Map<String, dynamic>> insertProperty(Map<String, dynamic> data) async {
    return await _client.from('properties').insert(data).select().single();
  }

  Future<void> insertImageRecord(String propId, String url) async =>
      await _client.from('property_images').insert({'property_id': propId, 'image_url': url});

  Future<void> deletePropertyRecord(String id) async =>
      await _client.from('properties').delete().eq('id', id);

  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> data) async =>
      await _client.from('properties').update(data).eq('id', id).select().single();

  Future<void> deleteImageRecordsByIds(List<String> ids) async =>
      await _client.from('property_images').delete().inFilter('id', ids);

  Future<List<Map<String, dynamic>>> searchPropertiesByAi(List<double> vector) async {
    final response = await _client.rpc('match_properties', params: {
      'query_embedding': vector,
      'match_threshold': 0.85,
      'match_count': 10,
    }).select(_select);
    return List<Map<String, dynamic>>.from(response);
  }

  /// إضافة منصات إعلانية لعقار (INSERT في property_platforms)
  Future<void> insertPlatforms(String propId, List<String> platformIds) async {
    if (platformIds.isEmpty) return;
    final rows = platformIds
        .map((pid) => {'property_id': propId, 'platform_id': pid})
        .toList();
    await _client.from('property_platforms').insert(rows);
  }

  /// حذف كل المنصات المرتبطة بعقار (لإعادة الإضافة بعدين)
  Future<void> deletePlatforms(String propId) async {
    await _client.from('property_platforms').delete().eq('property_id', propId);
  }
}
