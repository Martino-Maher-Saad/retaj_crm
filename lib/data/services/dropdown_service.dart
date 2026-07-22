import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

/// موديل موحد لكل الجداول المرجعية
class LookupOptionModel {
  final String id;
  final String nameAr;
  final bool isActive;
  final Map<String, dynamic>? extra;

  const LookupOptionModel({
    required this.id,
    required this.nameAr,
    this.isActive = true,
    this.extra,
  });

  factory LookupOptionModel.fromJson(Map<String, dynamic> json) {
    return LookupOptionModel(
      id: json['id']?.toString() ?? '',
      // يدعم name_ar (lookup tables) و name (governorates/cities)
      nameAr: json['name_ar']?.toString() ?? json['name']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      extra: json, // Store all columns for advanced use
    );
  }
}

class DropdownService {
  final _client = Supabase.instance.client;

  // ────────────────────────────────────────────────
  //  للـ Dropdowns العادية: Active فقط
  // ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCities() async {
    try {
      final response = await _client
          .from('governorates')
          .select('id, name, is_active, cities(id, name, governorate_id, is_active)')
          .order('id', ascending: true);

      return (response as List).map((gov) {
        final cities = (gov['cities'] as List? ?? []).toList();
        return {...gov as Map<String, dynamic>, 'cities': cities};
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LookupOptionModel>> _fetchFromTable(String tableName, {String? orderBy}) async {
    try {
      final query = _client.from(tableName).select(); // Fetch all columns to avoid missing column errors
      final response = orderBy != null ? await query.order(orderBy, ascending: true) : await query;
      return (response as List).map((e) => LookupOptionModel.fromJson(e)).toList();
    } catch (e) {
      return [LookupOptionModel(id: 'error_$tableName', nameAr: 'Error in $tableName: $e')];
    }
  }

  Future<List<LookupOptionModel>> fetchLeadStatuses() => _fetchFromTable('lead_statuses');
  Future<List<LookupOptionModel>> fetchStageTypes() => _fetchFromTable('stage_types');
  Future<List<LookupOptionModel>> fetchTaskStatuses() => _fetchFromTable('task_statuses');
  Future<List<LookupOptionModel>> fetchMeetingTypes() => _fetchFromTable('meeting_types');
  Future<List<LookupOptionModel>> fetchMeetingPurposes() => _fetchFromTable('meeting_purposes');
  Future<List<LookupOptionModel>> fetchActivityTypes() => _fetchFromTable('activity_types');
  Future<List<LookupOptionModel>> fetchPropertyTypes() => _fetchFromTable('property_types');
  Future<List<LookupOptionModel>> fetchListingTypes() => _fetchFromTable('listing_types');
  Future<List<LookupOptionModel>> fetchLeadPlatforms() => _fetchFromTable('lead_platforms');
  Future<List<LookupOptionModel>> fetchCommunicationChannels() => _fetchFromTable('communication_channels');
  Future<List<LookupOptionModel>> fetchPropertySources() => _fetchFromTable('property_sources');
  Future<List<LookupOptionModel>> fetchAdvertisingPlatforms() => _fetchFromTable('advertising_platforms');
  Future<List<LookupOptionModel>> fetchLeadExclusionReasons() => _fetchFromTable('lead_exclusion_reasons');
  Future<List<LookupOptionModel>> fetchPropertyApprovalStatuses() => _fetchFromTable('property_approval_statuses');
  Future<List<LookupOptionModel>> fetchLeadRates() => _fetchFromTable('lead_rates');

  // ────────────────────────────────────────────────
  //  للـ Admin Screen: كل القيم (Active + Inactive)
  // ────────────────────────────────────────────────

  Future<List<LookupOptionModel>> fetchAllForAdmin(String tableName, {bool isLocation = false}) async {
    final response = isLocation 
      ? await _client.from(tableName).select().order('id', ascending: true)
      : await _client.from(tableName).select(); // Do not order by created_at to avoid missing column errors
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
    Map<String, dynamic>? extraData,
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final data = <String, dynamic>{nameCol: nameAr, 'is_active': true};
    if (governorateId != null) data['governorate_id'] = governorateId;
    if (extraData != null) data.addAll(extraData);

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
    Map<String, dynamic>? extraData,
  }) async {
    final nameCol = isLocation ? 'name' : 'name_ar';
    final data = <String, dynamic>{nameCol: newName};
    if (extraData != null) data.addAll(extraData);

    final response = await _client
        .from(tableName)
        .update(data)
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

  /// مسح حالة العميل مع نقل العملاء
  Future<void> deleteLeadStatus(String id, String? replaceWithId) async {
    // 1. نقل العملاء إلى الحالة الجديدة
    if (replaceWithId != null) {
      await _client.from('leads').update({'status_id': replaceWithId}).eq('status_id', id);
    }
    
    // 2. مسح الحالة القديمة
    await _client.from('lead_statuses').delete().eq('id', id);
  }

  /// حساب عدد العملاء في حالة معينة
  Future<int> countLeadsWithStatus(String statusId) async {
    final response = await _client.from('leads').select('id').eq('status_id', statusId).count(CountOption.exact);
    return response.count ?? 0;
  }
}
