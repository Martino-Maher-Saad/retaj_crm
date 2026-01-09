/*
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> changePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ================= ADMIN ACTIONS =================

  Future<UserResponse> adminCreateUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    return await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        userMetadata: metadata,
        emailConfirm: true,
      ),
    );
  }

  Future<UserResponse> adminUpdateEmail({
    required String userId,
    required String newEmail,
  }) async {
    return await _client.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(email: newEmail),
    );
  }

  Future<UserResponse> adminUpdatePassword({
    required String userId,
    required String newPassword,
  }) async {
    return await _client.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(password: newPassword),
    );
  }
}
*/


import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exceptions.dart';

class AuthService {

  final _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {

    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthCustomException(e.message);
    } on SocketException{
      throw NetworkException();
    } catch (e) {
      throw ServerException();
    }

  }


  Future<Map<String, dynamic>> getUserProfile(String userId) async {

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } on PostgrestException catch(e){
      throw ServerException("Database error: ${e.message}");
    } catch(e){
      throw ServerException("Failed to fetch user profile");
    }

  }


  Future<void> signOut() async => await _supabase.auth.signOut();

}