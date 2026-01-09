import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exceptions.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';


class AuthRepository {

  final _supabase = Supabase.instance.client;
  final AuthService _authService;
  AuthRepository(this._authService);


  Future<ProfileModel> login(String email, String password) async {

    try {
      final response = await _authService.signIn(email, password);

      if (response.user == null) {
        throw AuthCustomException("User not found");
      }

      final profileData = await _authService.getUserProfile(response.user!.id);
      return ProfileModel.fromJson(profileData);

    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException("Something went wrong");
    }

  }


  Future<ProfileModel?> getCurrentUser() async {

    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final profileData = await _authService.getUserProfile(session.user.id);
      return ProfileModel.fromJson(profileData);
    } catch (e) {
      return null;
    }

  }


  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw ServerException("failed to sign out try again");
    }
  }

}