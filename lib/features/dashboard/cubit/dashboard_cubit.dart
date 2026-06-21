import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';
import 'dart:core';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  @override
  void emit(DashboardState state) {
    if (!isClosed) super.emit(state);
  }

  static DateTime get defaultStartDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime get defaultEndDate {
    final now = DateTime.now();
    return now.month == 12
        ? DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1))
        : DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
  }

  // ─── داشبورد الموظف ───
  Future<void> loadEmployeeDashboard({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? defaultStartDate;
    final end = endDate ?? defaultEndDate;
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _repository.getFilteredDashboardStats(role: 'sales', userId: userId, startDate: start, endDate: end),
        _repository.getPropertyAddedStats(startDate: start, endDate: end, employeeId: userId),
      ]);
      final data = results[0] as DashboardStatsModel;
      final propStats = results[1] as PropertyAddedStats;
      emit(EmployeeDashboardLoaded(data: data, startDate: start, endDate: end, propertyAddedStats: propStats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── تغيير الفترة الزمنية (موظف) ───
  Future<void> changeEmployeePeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final currentState = state;
    if (currentState is EmployeeDashboardLoaded) {
      emit(currentState.copyWith(startDate: startDate, endDate: endDate));
    } else {
      emit(DashboardLoading());
    }
    try {
      final results = await Future.wait([
        _repository.getFilteredDashboardStats(role: 'sales', userId: userId, startDate: startDate, endDate: endDate),
        _repository.getPropertyAddedStats(startDate: startDate, endDate: endDate, employeeId: userId),
      ]);
      final data = results[0] as DashboardStatsModel;
      final propStats = results[1] as PropertyAddedStats;
      emit(EmployeeDashboardLoaded(data: data, startDate: startDate, endDate: endDate, propertyAddedStats: propStats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── داشبورد المدير ───
  Future<void> loadManagerDashboard({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? employeeName,
  }) async {
    final start = startDate ?? defaultStartDate;
    final end = endDate ?? defaultEndDate;
    emit(DashboardLoading());
    try {
      final results = await Future.wait([
        _repository.getFilteredDashboardStats(role: 'manager', userId: employeeId ?? '', startDate: start, endDate: end, employeeId: employeeId),
        _repository.getPropertyAddedStats(startDate: start, endDate: end, employeeId: employeeId),
      ]);
      final data = results[0] as DashboardStatsModel;
      final propStats = results[1] as PropertyAddedStats;
      emit(ManagerDashboardLoaded(
        data: data,
        startDate: start,
        endDate: end,
        selectedEmployeeId: employeeId,
        selectedEmployeeName: employeeName,
        propertyAddedStats: propStats,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── تغيير الفلاتر (مدير) ───
  Future<void> changeManagerFilters({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
    String? employeeName,
  }) async {
    final currentState = state;
    if (currentState is ManagerDashboardLoaded) {
      emit(currentState.copyWith(
        startDate: startDate,
        endDate: endDate,
        selectedEmployeeId: employeeId,
        selectedEmployeeName: employeeName,
        clearEmployee: employeeId == null,
      ));
    } else {
      emit(DashboardLoading());
    }
    try {
      final results = await Future.wait([
        _repository.getFilteredDashboardStats(role: 'manager', userId: employeeId ?? '', startDate: startDate, endDate: endDate, employeeId: employeeId),
        _repository.getPropertyAddedStats(startDate: startDate, endDate: endDate, employeeId: employeeId),
      ]);
      final data = results[0] as DashboardStatsModel;
      final propStats = results[1] as PropertyAddedStats;
      emit(ManagerDashboardLoaded(
        data: data,
        startDate: startDate,
        endDate: endDate,
        selectedEmployeeId: employeeId,
        selectedEmployeeName: employeeName,
        propertyAddedStats: propStats,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
