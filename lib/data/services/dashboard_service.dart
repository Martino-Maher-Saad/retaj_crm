import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_model.dart';

/// Service مسؤول عن استدعاء RPC Functions الخاصة بالداشبورد
class DashboardService {
  final _client = Supabase.instance.client;

  /// جلب بيانات داشبورد المفلترة لجميع الصلاحيات
  /// [year] - السنة (مثلاً 2026)
  /// [month] - الشهر (1 إلى 12)
  /// [employeeId] - معرّف الموظف للتصفية (اختياري)
  Future<DashboardStatsModel> getFilteredDashboardStats({
    required int year,
    required int month,
    String? employeeId,
  }) async {
    final response = await _client.rpc(
      'get_filtered_dashboard_stats',
      params: {
        'p_year': year,
        'p_month': month,
        'p_employee_id': employeeId,
      },
    );
    return DashboardStatsModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// جلب العقارات المضافة في فترة زمنية معينة لعمل إحصائيات التجميع
  Future<List<Map<String, dynamic>>> getRawPropertiesForPeriod({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _client
        .from('properties')
        .select('created_by, property_type_id, listing_type_id, city_id')
        .gte('created_at', startDate)
        .lt('created_at', endDate);
    return List<Map<String, dynamic>>.from(response);
  }
}
