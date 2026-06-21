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
  final DashboardStatsModel data;
  final DateTime startDate;
  final DateTime endDate;
  final PropertyAddedStats propertyAddedStats;

  const EmployeeDashboardLoaded({
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.propertyAddedStats,
  });

  @override
  List<Object?> get props => [data, startDate, endDate, propertyAddedStats];

  EmployeeDashboardLoaded copyWith({
    DashboardStatsModel? data,
    DateTime? startDate,
    DateTime? endDate,
    PropertyAddedStats? propertyAddedStats,
  }) =>
      EmployeeDashboardLoaded(
        data: data ?? this.data,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        propertyAddedStats: propertyAddedStats ?? this.propertyAddedStats,
      );
}

class ManagerDashboardLoaded extends DashboardState {
  final DashboardStatsModel data;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedEmployeeId;
  final String? selectedEmployeeName;
  final PropertyAddedStats propertyAddedStats;

  const ManagerDashboardLoaded({
    required this.data,
    required this.startDate,
    required this.endDate,
    this.selectedEmployeeId,
    this.selectedEmployeeName,
    required this.propertyAddedStats,
  });

  bool get isViewingEmployee => selectedEmployeeId != null;

  @override
  List<Object?> get props => [data, startDate, endDate, selectedEmployeeId, selectedEmployeeName, propertyAddedStats];

  ManagerDashboardLoaded copyWith({
    DashboardStatsModel? data,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedEmployeeId,
    String? selectedEmployeeName,
    bool clearEmployee = false,
    PropertyAddedStats? propertyAddedStats,
  }) =>
      ManagerDashboardLoaded(
        data: data ?? this.data,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        selectedEmployeeId: clearEmployee ? null : (selectedEmployeeId ?? this.selectedEmployeeId),
        selectedEmployeeName: clearEmployee ? null : (selectedEmployeeName ?? this.selectedEmployeeName),
        propertyAddedStats: propertyAddedStats ?? this.propertyAddedStats,
      );
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
