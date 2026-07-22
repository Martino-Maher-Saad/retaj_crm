import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/error/app_exceptions.dart';

class AdminUserService {
  final _supabase = Supabase.instance.client;

  // جلب كل المستخدمين
  Future<List<ProfileModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب المستخدمين: $e');
    }
  }

  // إنشاء مستخدم جديد عبر Edge Function
  Future<void> createUser({
    required String email, 
    required String password, 
    required String role, 
    required String firstName, 
    required String lastName,
  }) async {
    try {
      await _supabase.functions.invoke(
        'admin_actions',
        body: {
          'action': 'create_user',
          'email': email,
          'password': password,
          'role': role,
          'first_name': firstName,
          'last_name': lastName,
        },
      );
    } catch (e, stackTrace) {
      print('=== ERROR CREATING USER (SERVICE) ===');
      print(e.toString());
      print(stackTrace.toString());
      print('=====================================');
      throw ServerException('فشل إنشاء الحساب: $e');
    }
  }
  
  // تغيير إيميل أو باسورد حساب موجود
  Future<void> updateUserAdmin(String targetUserId, {String? email, String? password, String? role}) async {
    try {
      await _supabase.functions.invoke(
        'admin_actions',
        body: {
          'action': 'update_user',
          'target_user_id': targetUserId,
          'email': email,
          'password': password,
          'role': role,
        },
      );
    } catch (e) {
      throw ServerException('فشل تحديث الحساب للإدارة: $e');
    }
  }

  // حذف موظف نهائياً عبر Edge Function
  Future<void> deleteUser(String targetUserId) async {
    try {
      await _supabase.functions.invoke(
        'admin_actions',
        body: {
          'action': 'delete_user',
          'target_user_id': targetUserId,
        },
      );
    } catch (e) {
      throw ServerException('فشل حذف حساب الموظف: $e');
    }
  }
}
