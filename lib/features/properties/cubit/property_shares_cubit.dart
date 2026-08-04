import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/property_share_model.dart';
import '../../../../data/repositories/property_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../data/services/realtime_service.dart';
import '../../../../data/models/crm_event.dart';

abstract class PropertySharesState {}

class PropertySharesInitial extends PropertySharesState {}

class PropertySharesLoading extends PropertySharesState {}

class PropertySharesLoaded extends PropertySharesState {
  final List<PropertyShareModel> inbox;
  final List<PropertyShareModel> sent;
  final String fetchedForUserId;
  final bool hasNewUpdates;

  PropertySharesLoaded(this.inbox, this.sent, this.fetchedForUserId, {this.hasNewUpdates = false});

  PropertySharesLoaded copyWith({
    List<PropertyShareModel>? inbox,
    List<PropertyShareModel>? sent,
    String? fetchedForUserId,
    bool? hasNewUpdates,
  }) {
    return PropertySharesLoaded(
      inbox ?? this.inbox,
      sent ?? this.sent,
      fetchedForUserId ?? this.fetchedForUserId,
      hasNewUpdates: hasNewUpdates ?? this.hasNewUpdates,
    );
  }
}

class PropertySharesError extends PropertySharesState {
  final String message;
  PropertySharesError(this.message);
}

class PropertySharesCubit extends Cubit<PropertySharesState> {
  final PropertyRepository _repo;
  final String userId;
  final RealtimeService _realtimeService;
  late final StreamSubscription _realtimeSubscription;

  PropertySharesCubit(this.userId, {PropertyRepository? repo, RealtimeService? realtimeService})
      : _repo = repo ?? di.sl<PropertyRepository>(),
        _realtimeService = realtimeService ?? di.sl<RealtimeService>(),
        super(PropertySharesInitial()) {
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
    fetchShares();
  }

  void _handleRealtimeEvent(CrmEvent event) {
    if (event.entity != 'property_share') return;

    final currentState = state;
    if (currentState is PropertySharesLoaded) {
      final isSoftDelete = event.action == 'update' && 
          (event.data?['sender_deleted'] == true || event.data?['receiver_deleted'] == true);

      if (event.action == 'delete' || isSoftDelete) {
        final shareId = event.id;
        final newInbox = currentState.inbox.where((s) => s.id != shareId).toList();
        final newSent = currentState.sent.where((s) => s.id != shareId).toList();
        emit(currentState.copyWith(inbox: newInbox, sent: newSent));
      } else if (event.action == 'insert' || event.action == 'update') {
        emit(currentState.copyWith(hasNewUpdates: true));
      }
    }
  }

  @override
  Future<void> close() {
    _realtimeSubscription.cancel();
    return super.close();
  }

  Future<void> fetchShares({String? filterByUserId}) async {
    final targetId = filterByUserId ?? userId;
    try {
      if (state is! PropertySharesLoaded) {
        emit(PropertySharesLoading());
      }
      
      final inboxData = await _repo.fetchReceivedShares(targetId);
      final sentData = await _repo.fetchSentShares(targetId);

      emit(PropertySharesLoaded(inboxData, sentData, targetId));
    } catch (e) {
      emit(PropertySharesError(e.toString()));
    }
  }

  Future<void> deleteShare(String shareId, bool isSender) async {
    final prevState = state;
    // Optimistic: remove immediately from local list
    if (state is PropertySharesLoaded) {
      final current = state as PropertySharesLoaded;
      emit(PropertySharesLoaded(
        current.inbox.where((s) => s.id != shareId).toList(),
        current.sent.where((s) => s.id != shareId).toList(),
        current.fetchedForUserId,
      ));
    }
    try {
      await _repo.deleteShare(shareId, isSender);
    } catch (e) {
      // Rollback on failure
      emit(prevState);
      emit(PropertySharesError("فشل حذف المشاركة: $e"));
    }
  }
}
