import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/admin_user_service.dart';
import 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminUserService _adminUserService;

  AdminUsersCubit(this._adminUserService) : super(AdminUsersInitial());

  @override
  void emit(AdminUsersState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> fetchAllUsers() async {
    emit(AdminUsersLoading());
    try {
      final users = await _adminUserService.getAllUsers();
      emit(AdminUsersLoaded(users));
    } catch (e) {
      emit(AdminUsersError(e.toString()));
    }
  }

  Future<void> createNewUser({
    required String email, 
    required String password, 
    required String role, 
    required String firstName, 
    required String lastName,
  }) async {
    final currentState = state;
    emit(AdminUsersLoading());
    try {
      // Create user via edge function
      await _adminUserService.createUser(
        email: email, 
        password: password, 
        role: role, 
        firstName: firstName, 
        lastName: lastName
      );
      emit(const AdminActionSuccess("تم إنشاء الحساب بنجاح وتمت إضافته للقاعدة البيانات!"));
      // Refresh list
      await fetchAllUsers();
    } catch (e, stackTrace) {
      print('=== ERROR IN CUBIT (CREATE USER) ===');
      print(e.toString());
      print(stackTrace.toString());
      print('====================================');
      emit(AdminUsersError(e.toString()));
      if (currentState is AdminUsersLoaded) emit(currentState);
    }
  }

  Future<void> updateUserAdmin(String targetUserId, {String? email, String? password, String? role}) async {
    final currentState = state;
    emit(AdminUsersLoading());
    try {
      // Update user details via edge function
      await _adminUserService.updateUserAdmin(
        targetUserId, 
        email: email, 
        password: password, 
        role: role
      );
      emit(const AdminActionSuccess("تم تحديث الحساب للإدارة بنجاح!"));
      // Refresh list
      await fetchAllUsers();
    } catch (e) {
      emit(AdminUsersError(e.toString()));
      if (currentState is AdminUsersLoaded) emit(currentState);
    }
  }

  Future<void> deactivateUser(String targetUserId, {required String replaceWithId, required String adminId}) async {
    final currentState = state;
    emit(AdminUsersLoading());
    try {
      await _adminUserService.deactivateUser(targetUserId, replaceWithId: replaceWithId, adminId: adminId);
      emit(const AdminActionSuccess("تم إيقاف حساب الموظف ونقل عهدته بنجاح!"));
      await fetchAllUsers();
    } catch (e) {
      emit(AdminUsersError(e.toString()));
      if (currentState is AdminUsersLoaded) emit(currentState);
    }
  }

  Future<Map<String, int>> getEmployeeCustodyCount(String targetUserId) async {
    try {
      return await _adminUserService.getEmployeeCustodyCount(targetUserId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> reactivateUser(String targetUserId) async {
    final currentState = state;
    emit(AdminUsersLoading());
    try {
      await _adminUserService.reactivateUser(targetUserId);
      emit(const AdminActionSuccess("تم إعادة تفعيل حساب الموظف بنجاح!"));
      await fetchAllUsers();
    } catch (e) {
      emit(AdminUsersError(e.toString()));
      if (currentState is AdminUsersLoaded) emit(currentState);
    }
  }
}
