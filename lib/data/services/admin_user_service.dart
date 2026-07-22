import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/error/app_exceptions.dart';
import '../../core/di/injection_container.dart' as di;
import 'realtime_sync_service.dart';

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

  // إيقاف حساب موظف (Soft Delete) ونقل العهدة عبر RPC
  Future<void> deactivateUser(String targetUserId, {required String replaceWithId, required String adminId}) async {
    try {
      await _supabase.rpc(
        'deactivate_employee_bulk_transfer',
        params: {
          'p_employee_id': targetUserId,
          'p_new_owner_id': replaceWithId,
          'p_admin_id': adminId,
        },
      );
      
      // Notify the receiver instantly
      try {
        final realtime = di.sl<RealtimeSyncService>();
        await realtime.sendBulkTransferEvent(replaceWithId);
      } catch (_) {}
    } catch (e) {
      throw ServerException('فشل إيقاف حساب الموظف ونقل العهدة: $e');
    }
  }

  // معرفة حجم عهدة الموظف قبل النقل
  Future<Map<String, int>> getEmployeeCustodyCount(String targetUserId) async {
    try {
      final leadsRes = await _supabase.from('leads').select('id').eq('assigned_to', targetUserId).count(CountOption.exact);
      final propsRes = await _supabase.from('properties').select('id').eq('created_by', targetUserId).eq('is_active', true).count(CountOption.exact);
      return {
        'leads': leadsRes.count ?? 0,
        'properties': propsRes.count ?? 0,
      };
    } catch (e) {
      throw ServerException('فشل إحضار حجم عهدة الموظف: $e');
    }
  }

  // إعادة تفعيل حساب الموظف
  Future<void> reactivateUser(String targetUserId) async {
    try {
      await _supabase.from('profiles').update({'is_active': true}).eq('id', targetUserId);
    } catch (e) {
      throw ServerException('فشل إعادة تفعيل حساب الموظف: $e');
    }
  }
}
