import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/error/app_exceptions.dart';
import '../../core/di/injection_container.dart' as di;
import 'realtime_service.dart';
import '../models/crm_event.dart';

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

  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      await _supabase.from('profiles').update({'is_active': isActive}).eq('id', userId);
    } catch (e) {
      throw ServerException('فشل تحديث حالة الحساب: $e');
    }
  }

  // إنشاء مستخدم جديد عبر Edge Function
  Future<void> createUser({
    required String email, 
    required String password, 
    required String role, 
    required String firstName, 
    required String lastName,
    bool canMakeAds = false,
    String? propertyPrefix,
    String? phone,
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
      
      // Update custom fields in profiles table directly
      await _supabase.from('profiles').update({
        'can_make_ads': canMakeAds,
        'property_prefix': propertyPrefix,
        if (phone != null) 'phone': phone,
      }).eq('email', email);
    } catch (e, stackTrace) {
      print('=== ERROR CREATING USER (SERVICE) ===');
      print(e.toString());
      print(stackTrace.toString());
      print('=====================================');
      throw ServerException('فشل إنشاء الحساب: $e');
    }
  }
  
  // تغيير إيميل أو باسورد حساب موجود
  Future<void> updateUserAdmin(String targetUserId, {String? email, String? password, String? role, bool? canMakeAds, String? propertyPrefix, String? phone}) async {
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

      // Update custom fields if provided
      final Map<String, dynamic> profileUpdates = {};
      if (email != null) profileUpdates['email'] = email;
      if (role != null) profileUpdates['role'] = role;
      if (canMakeAds != null) profileUpdates['can_make_ads'] = canMakeAds;
      if (propertyPrefix != null) profileUpdates['property_prefix'] = propertyPrefix;
      if (phone != null) profileUpdates['phone'] = phone;
      
      if (profileUpdates.isNotEmpty) {
        await _supabase.from('profiles').update(profileUpdates).eq('id', targetUserId);
      }
    } catch (e) {
      throw ServerException('فشل تحديث الحساب للإدارة: $e');
    }
  }

  /// تحديث قائمة الموظفين المخصصين لموظف ماركيتينج
  Future<void> updateAssignedEmployees(String marketingUserId, List<String> employeeIds) async {
    try {
      await _supabase
          .from('profiles')
          .update({'assigned_employees': employeeIds})
          .eq('id', marketingUserId);
    } catch (e) {
      throw ServerException('فشل تحديث الموظفين المخصصين: $e');
    }
  }

  // جلب إحصائيات المستخدم من عقارات وعملاء
  Future<Map<String, int>> getUserStats(String targetUserId) async {
    try {
      final props = await _supabase.from('properties').select('id').eq('created_by', targetUserId);
      final leads = await _supabase.from('leads').select('id').eq('assigned_to', targetUserId);
      return {
        'properties': (props as List).length,
        'leads': (leads as List).length,
      };
    } catch (e, stackTrace) {
      print('=== ERROR IN GET USER STATS ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      throw ServerException('فشل جلب إحصائيات المستخدم: $e');
    }
  }

  // نقل البيانات من مستخدم لآخر
  Future<void> transferData(String oldUserId, String newUserId) async {
    try {
      // نقل التنبيهات
      await _supabase.from('notifications').update({'user_id': newUserId}).eq('user_id', oldUserId);
      
      // نقل العقارات
      await _supabase.from('properties').update({'created_by': newUserId}).eq('created_by', oldUserId);
      
      // نقل العملاء وكل ما يتعلق بهم
      await _supabase.from('leads').update({'assigned_to': newUserId}).eq('assigned_to', oldUserId);
      await _supabase.from('leads').update({'created_by': newUserId}).eq('created_by', oldUserId);
      await _supabase.from('leads').update({'transferred_from': newUserId}).eq('transferred_from', oldUserId);
      
      // نقل ملاحظات وسجلات العملاء
      await _supabase.from('lead_notes').update({'user_id': newUserId}).eq('user_id', oldUserId);

      // نقل مشاركات العقارات
      await _supabase.from('property_shares').update({'sender_id': newUserId}).eq('sender_id', oldUserId);
      await _supabase.from('property_shares').update({'receiver_id': newUserId}).eq('receiver_id', oldUserId);

      // Send Realtime Broadcasts for bulk updates
      final realtime = di.sl<RealtimeService>();
    } catch (e, stackTrace) {
      print('=== ERROR IN TRANSFER DATA ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      throw ServerException('فشل نقل البيانات: $e');
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
