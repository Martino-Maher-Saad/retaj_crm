import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  @override
  void emit(DashboardState state) {
    if (!isClosed) super.emit(state);
  }

  // ─── داشبورد الموظف ───
  Future<void> loadEmployeeDashboard({
    required String userId,
    int days = 30,
  }) async {
    emit(DashboardLoading());
    try {
      final data = await _repository.getEmployeeDashboard(
        userId: userId,
        days: days,
      );
      emit(EmployeeDashboardLoaded(data: data, selectedDays: days));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── تغيير الفترة الزمنية (موظف) ───
  Future<void> changeEmployeePeriod({
    required String userId,
    required int days,
  }) async {
    final currentState = state;
    // نحتفظ بالبيانات القديمة ونحدّث الـ selectedDays أولاً
    if (currentState is EmployeeDashboardLoaded) {
      emit(currentState.copyWith(selectedDays: days));
    } else {
      emit(DashboardLoading());
    }
    try {
      final data = await _repository.getEmployeeDashboard(
        userId: userId,
        days: days,
      );
      emit(EmployeeDashboardLoaded(data: data, selectedDays: days));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── داشبورد المدير ───
  Future<void> loadManagerDashboard({int days = 30}) async {
    emit(DashboardLoading());
    try {
      final data = await _repository.getManagerDashboard(days: days);
      emit(ManagerDashboardLoaded(data: data, selectedDays: days));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── تغيير الفترة الزمنية (مدير) ───
  Future<void> changeManagerPeriod({required int days}) async {
    final currentState = state;
    if (currentState is ManagerDashboardLoaded) {
      emit(currentState.copyWith(selectedDays: days));
    } else {
      emit(DashboardLoading());
    }
    try {
      final data = await _repository.getManagerDashboard(days: days);
      emit(ManagerDashboardLoaded(data: data, selectedDays: days));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── المدير يختار موظف معين ───
  Future<void> viewEmployee({
    required String employeeId,
    required String employeeName,
  }) async {
    final currentState = state;
    if (currentState is! ManagerDashboardLoaded) return;
    final days = currentState.selectedDays;
    // نعرّض loading بينما نجيب بيانات الموظف
    emit(currentState.copyWith(
      selectedEmployeeId:   employeeId,
      selectedEmployeeName: employeeName,
    ));
    try {
      final empData = await _repository.getEmployeeDashboard(
        userId: employeeId,
        days:   days,
      );
      emit(currentState.copyWith(
        selectedEmployeeId:   employeeId,
        selectedEmployeeName: employeeName,
        selectedEmployeeData: empData,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ─── المدير يرجع لنظرة الشركة ───
  void backToCompanyView() {
    final currentState = state;
    if (currentState is ManagerDashboardLoaded) {
      emit(currentState.copyWith(clearEmployee: true));
    }
  }
}
