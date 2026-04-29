import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dropdown_option_model.dart';
import '../models/location_model.dart';

/// Service مسؤول عن جلب وإدارة بيانات الـ Dropdowns من قاعدة البيانات
/// يُستدعى مرة واحدة عند تسجيل الدخول ويُخزن في StaticDataManager
class DropdownService {
  final _client = Supabase.instance.client;

  /// جلب كل المحافظات مع مدنها (nested)
  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCities() async {
    final response = await _client
        .from('governorates')
        .select('id, name, cities(id, name, governorate_id)')
        .order('id', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// جلب كل خيارات الـ Dropdown النشطة (listing_type, property_type, platform, lead_status)
  Future<List<DropdownOptionModel>> fetchAllOptions() async {
    final response = await _client
        .from('dropdown_options')
        .select()
        .eq('is_active', true)
        .order('category', ascending: true);
    return (response as List)
        .map((e) => DropdownOptionModel.fromJson(e))
        .toList();
  }

  /// إضافة خيار جديد (للمدير فقط - التحقق في الـ Flutter)
  Future<DropdownOptionModel> addOption(String category, String valueAr) async {
    final response = await _client
        .from('dropdown_options')
        .insert({'category': category, 'value_ar': valueAr})
        .select()
        .single();
    return DropdownOptionModel.fromJson(response);
  }

  /// حذف خيار (للمدير فقط)
  Future<void> deleteOption(String id) async {
    await _client.from('dropdown_options').delete().eq('id', id);
  }

  /// تعديل خيار (للمدير فقط)
  Future<DropdownOptionModel> updateOption(String id, String newValue) async {
    final response = await _client
        .from('dropdown_options')
        .update({'value_ar': newValue})
        .eq('id', id)
        .select()
        .single();
    return DropdownOptionModel.fromJson(response);
  }
}
