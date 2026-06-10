import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

/// موديل موحد لكل الجداول المرجعية
class LookupOptionModel {
  final String id;
  final String nameAr;
  final bool isActive;

  const LookupOptionModel({
    required this.id,
    required this.nameAr,
    this.isActive = true,
  });

  factory LookupOptionModel.fromJson(Map<String, dynamic> json) {
    return LookupOptionModel(
      id: json['id']?.toString() ?? '',
      // يدعم name_ar (lookup tables) و name (governorates/cities)
      nameAr: json['name_ar']?.toString() ?? json['name']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class DropdownService {
  final _client = Supabase.instance.client;

  // ────────────────────────────────────────────────
  //  للـ Dropdowns العادية: Active فقط
  // ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCities() async {
    final response = await _client
        .from('governorates')
        .select('id, name, is_active, cities(id, name, governorate_id, is_active)')
        .order('id', ascending: true);

    return (response as List).map((gov) {
      final cities = (gov['cities'] as List? ?? []).toList();
      return {...gov as Map<String, dynamic>, 'cities': cities};
    }).toList();
  }

  Future<List<LookupOptionModel>> _fetchFromTable(String tableName) async {
    final response = await _client
        .from(tableName)
        .select('id, name_ar, is_active')
        .order('created_at', ascending: true);
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
        .select('id, $nameCol, is_active')
        .order(isLocation ? 'id' : 'created_at', ascending: true);
    return (response as List).map((e) => LookupOptionModel.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCitiesForAdmin() async {
    final response = await _client
        .from('governorates')
        .select('id, name, is_active, cities(id, name, governorate_id, is_active)')
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ────────────────────────────────────────────────
  //  CRUD موحد
  // ────────────────────────────────────────────────

  Future<LookupOptionModel> addOption(
    String tableName,
    String nameAr, {
    bool isLocation = false,
    int? governorateId, // للمدن فقط
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final data = <String, dynamic>{nameCol: nameAr, 'is_active': true};
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
    bool isLocation = false,
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final response = await _client
        .from(tableName)
        .update({nameCol: newName})
        .eq('id', id)
        .select()
        .single();
    return LookupOptionModel.fromJson(response);
  }

  /// Soft Delete — يخفي من القوائم بدون مسح البيانات المرتبطة
  Future<void> deactivateOption(String tableName, String id) async {
    await _client.from(tableName).update({'is_active': false}).eq('id', id);
  }

  /// إعادة تفعيل
  Future<void> activateOption(String tableName, String id) async {
    await _client.from(tableName).update({'is_active': true}).eq('id', id);
  }
}
