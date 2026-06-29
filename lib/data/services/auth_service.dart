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
    } on SocketException {
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
    } on PostgrestException catch (e) {
      throw ServerException("Database error: ${e.message}");
    } catch (e) {
      throw ServerException("Failed to fetch user profile");
    }
  }

  Future<void> signOut() async => await _supabase.auth.signOut();
}
