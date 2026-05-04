import 'package:equatable/equatable.dart';
import '../../../data/models/dashboard_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class EmployeeDashboardLoaded extends DashboardState {
  final EmployeeDashboardModel data;
  final int selectedDays;

  const EmployeeDashboardLoaded({
    required this.data,
    required this.selectedDays,
  });

  @override
  List<Object?> get props => [data, selectedDays];

  EmployeeDashboardLoaded copyWith({
    EmployeeDashboardModel? data,
    int? selectedDays,
  }) =>
      EmployeeDashboardLoaded(
        data:         data ?? this.data,
        selectedDays: selectedDays ?? this.selectedDays,
      );
}

class ManagerDashboardLoaded extends DashboardState {
  final ManagerDashboardModel data;
  final int selectedDays;
  // لما المدير يختار موظف معين
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;
  final EmployeeDashboardModel? selectedEmployeeData;

  const ManagerDashboardLoaded({
    required this.data,
    required this.selectedDays,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
    this.selectedEmployeeData,
  });

  bool get isViewingEmployee => selectedEmployeeId != null;

  @override
  List<Object?> get props => [data, selectedDays, selectedEmployeeId, selectedEmployeeData];

  ManagerDashboardLoaded copyWith({
    ManagerDashboardModel? data,
    int? selectedDays,
    String? selectedEmployeeId,
    String? selectedEmployeeName,
    EmployeeDashboardModel? selectedEmployeeData,
    bool clearEmployee = false,
  }) =>
      ManagerDashboardLoaded(
        data:                 data ?? this.data,
        selectedDays:         selectedDays ?? this.selectedDays,
        selectedEmployeeId:   clearEmployee ? null : (selectedEmployeeId ?? this.selectedEmployeeId),
        selectedEmployeeName: clearEmployee ? null : (selectedEmployeeName ?? this.selectedEmployeeName),
        selectedEmployeeData: clearEmployee ? null : (selectedEmployeeData ?? this.selectedEmployeeData),
      );
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
