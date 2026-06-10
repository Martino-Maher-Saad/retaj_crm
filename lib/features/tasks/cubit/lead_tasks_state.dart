import 'package:equatable/equatable.dart';
import '../../../data/models/lead_model.dart';

abstract class LeadTasksState extends Equatable {
  const LeadTasksState();

  @override
  List<Object?> get props => [];
}

class LeadTasksInitial extends LeadTasksState {}

class LeadTasksLoading extends LeadTasksState {}

class LeadTasksLoaded extends LeadTasksState {
  final List<LeadModel> leads;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasFetched;

  const LeadTasksLoaded({
    required this.leads,
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasFetched = false,
  });

  LeadTasksLoaded copyWith({
    List<LeadModel>? leads,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasFetched,
  }) {
    return LeadTasksLoaded(
      leads: leads ?? this.leads,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasFetched: hasFetched ?? this.hasFetched,
    );
  }

  @override
  List<Object?> get props => [leads, totalCount, isLoadingMore, hasFetched];
}

class LeadTasksError extends LeadTasksState {
  final String message;
  const LeadTasksError(this.message);

  @override
  List<Object?> get props => [message];
}
