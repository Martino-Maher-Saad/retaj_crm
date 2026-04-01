import 'package:equatable/equatable.dart';
import '../../../data/models/profile_model.dart';

abstract class AdminUsersState extends Equatable {
  const AdminUsersState();
  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {}
class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<ProfileModel> users;
  const AdminUsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class AdminUsersError extends AdminUsersState {
  final String message;
  const AdminUsersError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminActionSuccess extends AdminUsersState {
  final String message;
  const AdminActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
