import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

/// Repository الداشبورد — الوسيط بين الـ Cubit والـ Service
class DashboardRepository {
  final DashboardService _service;

  DashboardRepository(this._service);

  Future<EmployeeDashboardModel> getEmployeeDashboard({
    required String userId,
    required int days,
  }) =>
      _service.getEmployeeDashboard(userId: userId, days: days);

  Future<ManagerDashboardModel> getManagerDashboard({required int days}) =>
      _service.getManagerDashboard(days: days);
}
