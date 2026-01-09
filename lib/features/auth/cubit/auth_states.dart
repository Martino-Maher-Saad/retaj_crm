import 'package:retaj_crm/data/models/profile_model.dart';


sealed class AuthStates {}


class AuthInitial extends AuthStates {}


class AuthLoading extends AuthStates {}


class AuthSuccess extends AuthStates {
  final ProfileModel user;
  AuthSuccess(this.user);
}


class AuthFailure extends AuthStates {
  final String message;
  AuthFailure(this.message);
}


class AuthLoggedOut extends AuthStates {}