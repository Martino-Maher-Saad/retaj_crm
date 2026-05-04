import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_model.dart';

/// Service مسؤول عن استدعاء RPC Functions الخاصة بالداشبورد
class DashboardService {
  final _client = Supabase.instance.client;

  /// جلب بيانات داشبورد الموظف
  /// [userId] - الـ UUID بتاع الموظف
  /// [days] - عدد الأيام (7 / 30 / 90 / 365)
  Future<EmployeeDashboardModel> getEmployeeDashboard({
    required String userId,
    required int days,
  }) async {
    final response = await _client.rpc(
      'get_employee_dashboard',
      params: {
        'p_user_id': userId,
        'p_days': days,
      },
    );
    return EmployeeDashboardModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// جلب بيانات داشبورد المدير
  /// [days] - عدد الأيام (7 / 30 / 90 / 365)
  Future<ManagerDashboardModel> getManagerDashboard({
    required int days,
  }) async {
    final response = await _client.rpc(
      'get_manager_dashboard',
      params: {'p_days': days},
    );
    return ManagerDashboardModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }
}
