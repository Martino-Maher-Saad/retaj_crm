import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/property_share_model.dart';
import '../../../../data/repositories/property_repository.dart';
import '../../../../core/di/injection_container.dart' as di;

abstract class PropertySharesState {}

class PropertySharesInitial extends PropertySharesState {}

class PropertySharesLoading extends PropertySharesState {}

class PropertySharesLoaded extends PropertySharesState {
  final List<PropertyShareModel> inbox;
  final List<PropertyShareModel> sent;
  final String fetchedForUserId;

  PropertySharesLoaded(this.inbox, this.sent, this.fetchedForUserId);
}

class PropertySharesError extends PropertySharesState {
  final String message;
  PropertySharesError(this.message);
}

class PropertySharesCubit extends Cubit<PropertySharesState> {
  final PropertyRepository _repo;
  final String userId;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  PropertySharesCubit(this.userId, {PropertyRepository? repo})
      : _repo = repo ?? di.sl<PropertyRepository>(),
        super(PropertySharesInitial()) {
    // تم إيقاف الـ Realtime مؤقتاً لتجنب خطأ Hot Restart على الويب
    // _initRealtime();
    fetchShares();
  }

  void _initRealtime() {
    // Listen for any changes in property_shares table where user is sender or receiver
    _subscription = Supabase.instance.client
        .from('property_shares')
        .stream(primaryKey: ['id'])
        .listen((data) {
          // Whenever the stream pushes data, we re-fetch to get the joined properties/profiles
          // This ensures instant updates when a colleague shares a property or when someone deletes one.
          fetchShares();
        }, onError: (e) {
          print('Realtime error: $e');
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
    _subscription?.cancel();
    return super.close();
  }
}
