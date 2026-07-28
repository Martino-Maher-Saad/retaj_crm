import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/lead_model.dart';

import '../../../data/repositories/lead_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../../data/models/crm_event.dart';
import 'dart:async';
import 'lead_tasks_state.dart';

class LeadTasksCubit extends Cubit<LeadTasksState> {
  final LeadRepository _repository;
  final RealtimeService _realtimeService;
  late final StreamSubscription _realtimeSubscription;

  String? _filterByEmployeeId;
  String _role = '';
  String _userId = '';

  LeadTasksCubit(this._repository, this._realtimeService) : super(LeadTasksInitial()) {
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(CrmEvent event) async {
    if (event.entity != 'lead') return;

    final currentState = state is LeadTasksLoaded ? state as LeadTasksLoaded : null;
    if (currentState == null) return;

    // For tasks, we just trigger the banner for any relevant change
    // because tasks might be reassigned, deadlines changed, etc.
    // If it's a delete, we can remove it immediately.
    if (event.action == 'delete') {
      emit(currentState.copyWith(blinkItemId: event.id));
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!isClosed) {
          final st = state is LeadTasksLoaded ? state as LeadTasksLoaded : null;
          if (st != null) {
            final newLeads = st.leads.where((l) => l.id != event.id).toList();
            emit(st.copyWith(leads: newLeads, blinkItemId: null));
          }
        }
      });
    } else {
      // For insert, update, transfer:
      // We could fetch and update in place, but since tasks have complex filters (like deadlines),
      // we'll just show the refresh banner for them to click.
      emit(currentState.copyWith(hasNewUpdates: true));
    }
  }

  @override
  Future<void> close() {
    _realtimeSubscription.cancel();
    return super.close();
  }

  @override
  void emit(LeadTasksState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> fetchTasks({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    bool isRefresh = false,
  }) async {
    final current = state is LeadTasksLoaded ? state as LeadTasksLoaded : null;

    if (_userId != userId || _role != role) {
      isRefresh = true;
    }

    if (!isRefresh && current != null && current.hasFetched) return;

    if (isRefresh || current == null) emit(LeadTasksLoading());

    _role = role;
    _userId = userId;
    _filterByEmployeeId = filterByEmployeeId;

    try {
      final totalCount = await _repository.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        isArchived: false,
        isForTasks: true,
      );
      final leads = await _repository.getAllLeads(
        role: role,
        userId: userId,
        from: 0,
        to: 200,
        filterByEmployeeId: filterByEmployeeId,
        isArchived: false,
        isForTasks: true,
      );

      emit(LeadTasksLoaded(
        leads: leads,
        totalCount: totalCount,
        hasFetched: true,
      ));
    } catch (e) {
      emit(LeadTasksError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is! LeadTasksLoaded) return;
    final current = state as LeadTasksLoaded;

    if (current.isLoadingMore || current.leads.length >= current.totalCount) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    try {
      final more = await _repository.getAllLeads(
        role: _role,
        userId: _userId,
        from: current.leads.length,
        to: current.leads.length + 100,
        filterByEmployeeId: _filterByEmployeeId,
        isArchived: false,
      );

      emit(current.copyWith(
        leads: [...current.leads, ...more],
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  void removeLead(String leadId) {
    if (state is LeadTasksLoaded) {
      final current = state as LeadTasksLoaded;
      emit(current.copyWith(
        leads: current.leads.where((l) => l.id != leadId).toList(),
        totalCount: current.totalCount > 0 ? current.totalCount - 1 : 0,
      ));
    }
  }

  void patchLead(LeadModel updated) {
    if (state is LeadTasksLoaded) {
      final current = state as LeadTasksLoaded;
      emit(current.copyWith(
        leads: current.leads
            .map((l) => l.id == updated.id ? updated : l)
            .toList(),
      ));
    }
  }
}
