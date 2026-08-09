import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/design_model.dart';

class DesignService {
  final _client = Supabase.instance.client;

  static const _select = 
    '*, '
    'design_images(*), '
    'design_room_types:room_type_id(name_ar), '
    'design_styles:style_id(name_ar), '
    'profiles:added_by(first_name, last_name)';

  /// جلب التشطيبات مع Pagination
  Future<List<DesignModel>> getDesigns({
    int limit = 20,
    int offset = 0,
    String? roomTypeId,
    String? styleId,
    String? addedByProfileId,
  }) async {
    var query = _client.from('designs').select(_select);
    
    if (roomTypeId != null) {
      query = query.eq('room_type_id', roomTypeId);
    }
    if (styleId != null) {
      query = query.eq('style_id', styleId);
    }
    if (addedByProfileId != null) {
      query = query.eq('added_by', addedByProfileId);
    }
    
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
        
    return (response as List).map((e) => DesignModel.fromJson(e)).toList();
  }

  /// جلب تصميم واحد عن طريق ID
  Future<DesignModel> getDesignById(String id) async {
    final response = await _client.from('designs').select(_select).eq('id', id).single();
    return DesignModel.fromJson(response);
  }

  /// إضافة تشطيب جديد (بدون Embedding والصور تضاف لاحقاً أو معاً)
  Future<Map<String, dynamic>> insertDesign(Map<String, dynamic> data) async {
    return await _client.from('designs').insert(data).select().single();
  }

  /// تحديث تشطيب
  Future<Map<String, dynamic>> updateDesign(String id, Map<String, dynamic> data) async {
    return await _client.from('designs').update(data).eq('id', id).select().single();
  }

  /// حذف تشطيب (الصور تُحذف تلقائياً بفضل On Delete Cascade)
  Future<void> deleteDesign(String id) async {
    await _client.from('designs').delete().eq('id', id);
  }

  /// إضافة صورة لتشطيب
  Future<void> insertImage(String designId, String url, bool isThumbnail) async {
    await _client.from('design_images').insert({
      'design_id': designId,
      'image_url': url,
      'is_thumbnail': isThumbnail,
    });
  }

  /// حذف صورة معينة من التشطيب
  Future<void> deleteImage(String imageId) async {
    await _client.from('design_images').delete().eq('id', imageId);
  }

  /// البحث الذكي عن التشطيبات
  Future<List<DesignModel>> searchDesignsByAi({required List<double> vector, String? roomTypeId, String? styleId, String? addedByProfileId}) async {
    Map<String, dynamic> params = {
      'query_embedding': vector,
      'match_threshold': 0.7,
      'match_count': 20,
    };

    if (roomTypeId != null) params['filter_room_type_id'] = roomTypeId;
    if (styleId != null) params['filter_style_id'] = styleId;
    if (addedByProfileId != null) params['filter_profile_id'] = addedByProfileId; // This assumes the RPC supports it. If it crashes, we'll need to filter locally.

    final response = await _client.rpc('match_designs', params: params);

    final List<dynamic> rpcResults = response;
    if (rpcResults.isEmpty) return [];

    final List<String> ids = rpcResults.map((r) => r['id'].toString()).toList();
    
    final fullDesigns = await _client.from('designs').select(_select).inFilter('id', ids);
    final List<DesignModel> designs = (fullDesigns as List).map((e) => DesignModel.fromJson(e)).toList();
    
    // ترتيب التشطيبات حسب نتيجة البحث الذكاء الاصطناعي
    designs.sort((a, b) {
      final indexA = ids.indexOf(a.id.toString());
      final indexB = ids.indexOf(b.id.toString());
      return indexA.compareTo(indexB);
    });

    return designs;
  }
}
