import '../../../data/models/property_model.dart';

sealed class PropertyTasksState {}

class PropertyTasksInitial extends PropertyTasksState {}

class PropertyTasksLoading extends PropertyTasksState {}

class PropertyTasksSuccess extends PropertyTasksState {
  final List<PropertyModel> taskProperties;
  final List<PropertyModel> pendingApprovals;
  final bool isLoadingTasks;
  final bool isLoadingApprovals;
  final bool hasFetchedTasks;
  final bool hasFetchedApprovals;
  final String? lastError;

  PropertyTasksSuccess({
    this.taskProperties = const [],
    this.pendingApprovals = const [],
    this.isLoadingTasks = false,
    this.isLoadingApprovals = false,
    this.hasFetchedTasks = false,
    this.hasFetchedApprovals = false,
    this.lastError,
  });

  PropertyTasksSuccess copyWith({
    List<PropertyModel>? taskProperties,
    List<PropertyModel>? pendingApprovals,
    bool? isLoadingTasks,
    bool? isLoadingApprovals,
    bool? hasFetchedTasks,
    bool? hasFetchedApprovals,
    String? lastError,
    bool clearError = false,
  }) {
    return PropertyTasksSuccess(
      taskProperties: taskProperties ?? this.taskProperties,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isLoadingApprovals: isLoadingApprovals ?? this.isLoadingApprovals,
      hasFetchedTasks: hasFetchedTasks ?? this.hasFetchedTasks,
      hasFetchedApprovals: hasFetchedApprovals ?? this.hasFetchedApprovals,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class PropertyTasksError extends PropertyTasksState {
  final String message;
  PropertyTasksError(this.message);
}
