import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

bool _parseBool(dynamic val) {
  if (val == null) return true;
  if (val is bool) return val;
  if (val is int) return val != 0;
  return true;
}

/// موديل موحد لكل الجداول المرجعية
class LookupOptionModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final int listOrder;
  final bool isActive;

  const LookupOptionModel({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    this.listOrder = 0,
    this.isActive = true,
  });

  factory LookupOptionModel.fromJson(Map<String, dynamic> json) {
    return LookupOptionModel(
      id: json['id']?.toString() ?? '',
      // يدعم name_ar (lookup tables) و name (governorates/cities)
      nameAr: json['name_ar']?.toString() ?? json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      listOrder: json['list_order'] ?? 0,
      isActive: _parseBool(json['is_active']),
    );
  }
}

class DropdownService {
  final _client = Supabase.instance.client;

  // ────────────────────────────────────────────────
  //  للـ Dropdowns العادية: Active فقط
  // ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCities() async {
    // Fetch ALL for historical data, UI filters them via getActiveOptions
    final response = await _client
        .from('governorates')
        .select('id, name, name_en, list_order, is_active, cities(id, name, name_en, list_order, governorate_id, is_active)')
        .order('list_order', ascending: true)
        .order('id', ascending: true);

    return (response as List).map((gov) {
      final cities = (gov['cities'] as List? ?? []).toList();
      cities.sort((a, b) => ((a['list_order'] ?? 0) as int).compareTo((b['list_order'] ?? 0) as int));
      return {...gov as Map<String, dynamic>, 'cities': cities};
    }).toList();
  }

  Future<List<LookupOptionModel>> fetchCitiesOnly() async {
    final response = await _client
        .from('cities')
        .select('id, name, name_en, list_order, is_active')
        .order('list_order', ascending: true)
        .order('id', ascending: true);
    return (response as List).map((e) => LookupOptionModel.fromJson(e)).toList();
  }

  Future<List<LookupOptionModel>> _fetchFromTable(String tableName) async {
    final response = await _client
        .from(tableName)
        .select('id, name_ar, name_en, list_order, is_active')
        .order('list_order', ascending: true)
        .order('id', ascending: true);
    return (response as List).map((e) => LookupOptionModel.fromJson(e)).toList();
  }

  Future<List<LookupOptionModel>> fetchLeadStatuses() => _fetchFromTable('lead_statuses');
  Future<List<LookupOptionModel>> fetchPropertyTypes() => _fetchFromTable('property_types');
  Future<List<LookupOptionModel>> fetchListingTypes() => _fetchFromTable('listing_types');
  Future<List<LookupOptionModel>> fetchLeadPlatforms() => _fetchFromTable('lead_platforms');
  Future<List<LookupOptionModel>> fetchCommunicationChannels() => _fetchFromTable('communication_channels');
  Future<List<LookupOptionModel>> fetchPropertySources() => _fetchFromTable('property_sources');
  Future<List<LookupOptionModel>> fetchAdvertisingPlatforms() => _fetchFromTable('advertising_platforms');
  Future<List<LookupOptionModel>> fetchLeadExclusionReasons() => _fetchFromTable('lead_exclusion_reasons');
  Future<List<LookupOptionModel>> fetchPropertyApprovalStatuses() => _fetchFromTable('property_approval_statuses');

  // ────────────────────────────────────────────────
  //  للـ Admin Screen: كل القيم (Active + Inactive)
  // ────────────────────────────────────────────────

  Future<List<LookupOptionModel>> fetchAllForAdmin(String tableName, {bool isLocation = false}) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final response = await _client
        .from(tableName)
        .select('id, $nameCol, name_en, list_order, is_active')
        .order('list_order', ascending: true)
        .order('id', ascending: true);
    return (response as List).map((e) => LookupOptionModel.fromJson(e)).toList();
  }

  // ────────────────────────────────────────────────
  //  CRUD موحد
  // ────────────────────────────────────────────────

  Future<LookupOptionModel> addOption(
    String tableName,
    String nameAr, {
    String nameEn = '',
    int listOrder = 0,
    bool isLocation = false,
    int? governorateId, // للمدن فقط
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final data = <String, dynamic>{
      nameCol: nameAr,
      'name_en': nameEn,
      'list_order': listOrder,
      'is_active': true
    };
    if (governorateId != null) data['governorate_id'] = governorateId;

    final response = await _client
        .from(tableName)
        .insert(data)
        .select()
        .single();
    return LookupOptionModel.fromJson(response);
  }

  Future<LookupOptionModel> updateOption(
    String tableName,
    String id,
    String newName, {
    String nameEn = '',
    int listOrder = 0,
    bool isLocation = false,
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final response = await _client
        .from(tableName)
        .update({
          nameCol: newName,
          'name_en': nameEn,
          'list_order': listOrder,
        })
        .eq('id', id)
        .select()
        .single();
    return LookupOptionModel.fromJson(response);
  }

  Future<void> deactivateOption(String tableName, String id) async {
    await _client.from(tableName).update({'is_active': false}).eq('id', id);
  }

  Future<void> activateOption(String tableName, String id) async {
    await _client.from(tableName).update({'is_active': true}).eq('id', id);
  }

  Future<void> hardDeleteOption(String tableName, String oldId, String newId) async {
    await _client.rpc('replace_and_delete_lookup', params: {
      'p_table_name': tableName,
      'p_old_id': oldId,
      'p_new_id': newId,
    });
  }
}
