import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/services/realtime_sync_service.dart' as di;
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthStates> {

  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(email, password);
      listenToProfileUpdates(user.id, di.sl<di.RealtimeSyncService>());
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }


  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        listenToProfileUpdates(user.id, di.sl<di.RealtimeSyncService>());
        emit(AuthSuccess(user));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }



  StreamSubscription? _profileSub;

  Future<void> logout() async {
    _profileSub?.cancel();
    _profileSub = null;
    await _authRepository.signOut();
    emit(AuthLoggedOut());
  }

  void listenToProfileUpdates(String userId, di.RealtimeSyncService realtime) {
    _profileSub?.cancel(); // Cancel any existing subscription first
    _profileSub = realtime.events.listen((payload) {
      if (payload.table == 'profiles' && payload.type == di.RealtimeOpType.update) {
        if (payload.newRecord['id'] == userId) {
          final bool isActive = payload.newRecord['is_active'] ?? true;
          if (!isActive) {
            logout();
          }
        }
      }
    });
  }
  
  @override
  Future<void> close() {
    _profileSub?.cancel();
    return super.close();
  }
}