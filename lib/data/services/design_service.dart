import 'package:supabase_flutter/supabase_flutter.dart';

class DesignService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>> getDesignById(String id) async {
    final response = await _client
        .from("designs")
        .select('*, design_images(*), profiles(*)')
        .eq("id", id)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getDesigns({
    required int from,
    required int to,
  }) async {
    final response = await _client
        .from('designs')
        .select('*, design_images(*), profiles(*)')
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getDesignsCount() async {
    final res = await _client
        .from('designs')
        .select('*')
        .limit(0)
        .count(CountOption.exact);
    return res.count ?? 0;
  }

  Future<Map<String, dynamic>> insertDesign(Map<String, dynamic> data) async {
    return await _client.from('designs').insert(data).select().single();
  }

  Future<void> insertImageRecord(String designId, String url) async =>
      await _client.from('design_images').insert({
        'design_id': designId,
        'image_url': url,
      });

  Future<void> deleteDesignRecord(String id) async =>
      await _client.from('designs').delete().eq('id', id);

  Future<Map<String, dynamic>> updateDesign(
    String id,
    Map<String, dynamic> data,
  ) async => await _client
      .from('designs')
      .update(data)
      .eq('id', id)
      .select()
      .single();

  Future<void> deleteImageRecordsByIds(List<String> ids) async =>
      await _client.from('design_images').delete().inFilter('id', ids);

  Future<List<Map<String, dynamic>>> searchDesignsByAi(
    List<double> vector,
  ) async {
    final response = await _client.rpc(
      'match_designs',
      params: {
        'query_embedding': vector,
        'match_threshold': 0.70,
        'match_count': 15,
      },
    ).select('*, design_images(*), profiles(*)'); 
    return List<Map<String, dynamic>>.from(response);
  }
}
