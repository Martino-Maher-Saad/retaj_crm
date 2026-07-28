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
  final String? blinkItemId;
  final bool hasNewUpdates;

  const LeadTasksLoaded({
    required this.leads,
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasFetched = false,
    this.blinkItemId,
    this.hasNewUpdates = false,
  });

  LeadTasksLoaded copyWith({
    List<LeadModel>? leads,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasFetched,
    String? blinkItemId,
    bool? hasNewUpdates,
  }) {
    return LeadTasksLoaded(
      leads: leads ?? this.leads,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasFetched: hasFetched ?? this.hasFetched,
      blinkItemId: blinkItemId, // Allow null to clear blink
      hasNewUpdates: hasNewUpdates ?? this.hasNewUpdates,
    );
  }

  @override
  List<Object?> get props => [leads, totalCount, isLoadingMore, hasFetched, blinkItemId, hasNewUpdates];
}

class LeadTasksError extends LeadTasksState {
  final String message;
  const LeadTasksError(this.message);

  @override
  List<Object?> get props => [message];
}
