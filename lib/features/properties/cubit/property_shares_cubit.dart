import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/property_share_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/realtime_sync_service.dart';
import '../../../core/di/injection_container.dart' as di;

abstract class PropertySharesState {}

class PropertySharesInitial extends PropertySharesState {}

class PropertySharesLoading extends PropertySharesState {}

class PropertySharesLoaded extends PropertySharesState {
  final List<PropertyShareModel> inbox;
  final List<PropertyShareModel> sent;
  final String fetchedForUserId;
  /// IDs المشاركات اللي اتحدثت للتو — للوميض اللحظي
  final Set<String> flashingIds;

  PropertySharesLoaded(this.inbox, this.sent, this.fetchedForUserId,
      {this.flashingIds = const {}});

  PropertySharesLoaded copyWithFlash(Set<String> ids) =>
      PropertySharesLoaded(inbox, sent, fetchedForUserId, flashingIds: ids);
}

class PropertySharesError extends PropertySharesState {
  final String message;
  PropertySharesError(this.message);
}

class PropertySharesCubit extends Cubit<PropertySharesState> {
  final PropertyRepository _repo;
  final RealtimeSyncService _realtime;
  final String userId;
  StreamSubscription? _sub;

  PropertySharesCubit(this.userId, {PropertyRepository? repo, RealtimeSyncService? realtime})
      : _repo = repo ?? di.sl<PropertyRepository>(),
        _realtime = realtime ?? di.sl<RealtimeSyncService>(),
        super(PropertySharesInitial()) {
    _sub = _realtime.events.listen(_handleRealtimeEvent);
    fetchShares();
  }

  @override
  void emit(PropertySharesState state) {
    if (!isClosed) super.emit(state);
  }

  void _handleRealtimeEvent(RealtimePayload payload) {
    if (payload.table != 'property_shares') return;

    if (payload.type == RealtimeOpType.delete) {
      // حذف محلي فوري — لا نحتاج طلب DB
      final deletedId = payload.oldRecord['id']?.toString();
      if (deletedId != null && state is PropertySharesLoaded) {
        final current = state as PropertySharesLoaded;
        emit(PropertySharesLoaded(
          current.inbox.where((s) => s.id != deletedId).toList(),
          current.sent.where((s) => s.id != deletedId).toList(),
          current.fetchedForUserId,
        ));
      }
    } else if (payload.type == RealtimeOpType.insert) {
      // insert جديد — نعمل refetch كامل عشان نجيب الـ joins (اسم المُرسِل، اسم العقار، ...)
      // لكن بدون loading indicator
      _refetchSilently();
    }
  }

  /// Refetch بدون emit(Loading) عشان يتحدث بصمت
  Future<void> _refetchSilently() async {
    try {
      final inboxData = await _repo.fetchReceivedShares(userId);
      final sentData = await _repo.fetchSentShares(userId);
      final newShare = inboxData.isNotEmpty ? inboxData.first.id : null;
      emit(PropertySharesLoaded(inboxData, sentData, userId));
      // وميض على آخر عنصر مضاف
      if (newShare != null) _flashItem(newShare);
    } catch (_) {}
  }

  void _flashItem(String id) {
    if (state is! PropertySharesLoaded || isClosed) return;
    final st = state as PropertySharesLoaded;
    emit(st.copyWithFlash({id}));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (state is PropertySharesLoaded && !isClosed) {
        emit((state as PropertySharesLoaded).copyWithFlash({}));
      }
    });
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

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
