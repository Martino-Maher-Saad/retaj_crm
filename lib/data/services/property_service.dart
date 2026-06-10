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
      'property_approval_statuses!approval_status_id(name_ar), '
      'property_platforms(id, platform_id, is_published, advertising_platforms!pp_platform_fk(id, name_ar))';

  Future<List<Map<String, dynamic>>> fetchAllEmployees() async {
    final response = await _client.from('profiles').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final response = await _client.from('properties').select(_select).eq('id', id).single();
    return response;
  }

  Future<void> sharePropertyInternal({
    required String propertyId,
    required String senderId,
    required String receiverId,
    String? note,
  }) async {
    await _client.from('property_shares').insert({
      'property_id': propertyId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'notes': note,
    });
  }

  // سيلكت كامل للعقار داخل المشاركات — نفس جداول الوزن كالـ inventory
  static const _sharePropertySelect =
      '*, property_images(*), '
      'creator:profiles!properties_created_by_fk(first_name, last_name), '
      'property_types!property_type_id(name_ar), '
      'listing_types!listing_type_id(name_ar), '
      'property_sources!source_id(name_ar), '
      'cities!city_id(name), '
      'governorates!governorate_id(name), '
      'property_approval_statuses!approval_status_id(name_ar), '
      'property_platforms(id, platform_id, is_published, advertising_platforms!pp_platform_fk(id, name_ar))';

  Future<List<Map<String, dynamic>>> fetchReceivedShares(String userId) async {
    final response = await _client
        .from('property_shares')
        .select('*, sender:sender_id(*), receiver:receiver_id(*)')
        .eq('receiver_id', userId)
        .eq('receiver_deleted', false)
        .order('created_at', ascending: false);

    final shares = List<Map<String, dynamic>>.from(response);
    for (var share in shares) {
      if (share['property_id'] != null) {
        try {
          final prop = await getPropertyById(share['property_id']);
          share['properties'] = prop;
        } catch (e) {
          share['properties'] = null; // العقار محذوف أو مش موجود
        }
      }
    }
    return shares;
  }

  Future<List<Map<String, dynamic>>> fetchSentShares(String userId) async {
    final response = await _client
        .from('property_shares')
        .select('*, sender:sender_id(*), receiver:receiver_id(*)')
        .eq('sender_id', userId)
        .eq('sender_deleted', false)
        .order('created_at', ascending: false);

    final shares = List<Map<String, dynamic>>.from(response);
    for (var share in shares) {
      if (share['property_id'] != null) {
        try {
          final prop = await getPropertyById(share['property_id']);
          share['properties'] = prop;
        } catch (e) {
          share['properties'] = null;
        }
      }
    }
    return shares;
  }

  Future<void> deleteShare(String shareId, bool isSender) async {
    final updateData = isSender ? {'sender_deleted': true} : {'receiver_deleted': true};
    await _client.from('property_shares').update(updateData).eq('id', shareId);
  }

  /// يجيب عقارات صفحة المهمات فقط (مش published)
  Future<List<Map<String, dynamic>>> fetchTaskProperties({
    required int from,
    required int to,
    String? assignedTo,         // null = كل الشركة، UUID = موظف معين
    required String excludeApprovalStatusId, // نستثني "تم النشر"
  }) async {
    dynamic query = _client
        .from('properties')
        .select(_select)
        .eq('is_active', true)
        .neq('approval_status_id', excludeApprovalStatusId);

    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('created_by', assignedTo);
    }

    query = query
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    final response = await query.range(from, to);
    return List<Map<String, dynamic>>.from(response);
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
    String? approvalStatusId,
    bool? isArchived,
  }) async {
    dynamic query = _client.from('properties').select(_select);

    if (assignedTo != null && assignedTo.isNotEmpty) query = query.eq('created_by', assignedTo);
    if (governorateId != null) query = query.eq('governorate_id', governorateId);
    if (cityId != null) query = query.eq('city_id', cityId);
    if (propertyTypeId != null && propertyTypeId.isNotEmpty) query = query.eq('property_type_id', propertyTypeId);
    if (listingTypeId != null && listingTypeId.isNotEmpty) query = query.eq('listing_type_id', listingTypeId);
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);
    if (fromDate != null) query = query.gte('created_at', fromDate.toIso8601String());
    if (toDate != null) query = query.lte('created_at', toDate.toIso8601String());
    if (approvalStatusId != null) query = query.eq('approval_status_id', approvalStatusId);
    if (isArchived != null) query = query.eq('is_active', !isArchived);
    else query = query.eq('is_active', true);

    // ترتيب بحيث يظهر المثبت (is_pinned = true) أولاً
    query = query.order('is_pinned', ascending: false).order('created_at', ascending: false);

    final response = await query.range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> searchProperties(String term, {String type = 'general', String? assignedTo}) async {
    var query = _client.from('properties').select(_select);
    
    // Always restrict if assignedTo is provided (e.g. Sales searching their own properties)
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('created_by', assignedTo);
    }
    
    if (type == 'code') {
      query = query.ilike('property_code', '%$term%');
    } else if (type == 'phone') {
      query = query.like('owner_phone', '%$term%');
    } else {
      query = query.textSearch('search_vector', term);
    }
    final response = await query.limit(10);
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
    String? approvalStatusId,
    bool? isArchived,
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
    if (approvalStatusId != null) query = query.eq('approval_status_id', approvalStatusId);
    if (isArchived != null) query = query.eq('is_active', !isArchived);
    else query = query.eq('is_active', true);

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

  Future<List<Map<String, dynamic>>> searchPropertiesByAi({
    required List<double> vector,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
  }) async {
    final response = await _client.rpc('match_properties_with_filters', params: {
      'query_embedding': vector,
      'match_threshold': 0.70,
      'match_count': 50,
      'filter_property_type_id': propertyTypeId,
      'filter_listing_type_id': listingTypeId,
      'filter_governorate_id': governorateId,
      'filter_city_id': cityId,
      'filter_min_price': minPrice,
      'filter_max_price': maxPrice,
    });
    
    final List<dynamic> rpcResults = response;
    if (rpcResults.isEmpty) return [];

    final List<String> ids = rpcResults.map((r) => r['id'].toString()).toList();
    var query = _client.from('properties').select(_select).inFilter('id', ids);
    
    if (assignedTo != null && assignedTo.isNotEmpty) {
      query = query.eq('created_by', assignedTo);
    }
    
    final fullProperties = await query;
    final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(fullProperties);
    
    results.sort((a, b) {
      final indexA = ids.indexOf(a['id'].toString());
      final indexB = ids.indexOf(b['id'].toString());
      return indexA.compareTo(indexB);
    });
    
    return results.take(10).toList();
  }

  /// إضافة منصات إعلانية لعقار (INSERT في property_platforms)
  Future<void> insertPlatforms(String propId, List<String> platformIds) async {
    if (platformIds.isEmpty) return;
    final rows = platformIds
        .map((pid) => {'property_id': propId, 'platform_id': pid})
        .toList();
    await _client.from('property_platforms').insert(rows);
  }

  Future<void> publishPlatforms(String propId, List<String> platformIds) async {
    if (platformIds.isEmpty) return;
    await _client.from('property_platforms')
        .update({'is_published': true})
        .eq('property_id', propId)
        .inFilter('platform_id', platformIds);
  }

  Future<void> resetPlatformsPublished(String propId) async {
    await _client
        .from('property_platforms')
        .update({'is_published': false})
        .eq('property_id', propId);
  }

  /// حذف كل المنصات المرتبطة بعقار (لإعادة الإضافة بعدين)
  Future<void> deletePlatforms(String propId) async {
    await _client.from('property_platforms').delete().eq('property_id', propId);
  }

  Future<Map<String, dynamic>> togglePin(String propertyId, bool isPinned) async {
    final response = await _client
        .from('properties')
        .update({'is_pinned': isPinned})
        .eq('id', propertyId)
        .select(_select)
        .single();
    return response;
  }

  Future<void> archiveProperty(String propertyId, bool isArchived) async {
    await _client
        .from('properties')
        .update({'is_active': !isArchived})
        .eq('id', propertyId);
  }

  /// يتحقق من التكرارات للعقار بناءً على آخر 6 أرقام من رقم المالك
  Future<List<Map<String, dynamic>>> checkDuplicatePropertyPhone(String ownerPhone) async {
    final suffix = ownerPhone.length >= 6 ? ownerPhone.substring(ownerPhone.length - 6) : ownerPhone;
    if (suffix.isEmpty) return [];

    final response = await _client
        .from('properties')
        .select('*')
        .like('owner_phone', '%$suffix%');
    return List<Map<String, dynamic>>.from(response);
  }
}
