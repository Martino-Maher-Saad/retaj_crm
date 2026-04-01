import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/error/app_exceptions.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // تحديث بيانات المستخدم
  Future<ProfileModel> updateProfile(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
          
      return ProfileModel.fromJson(response);
    } catch (e, stackTrace) {
      print('=== ERROR UPDATING PROFILE ===');
      print(e.toString());
      print(stackTrace.toString());
      print('==============================');
      throw ServerException('فشل تحديث البيانات: $e');
    }
  }

  // رفع الصورة الشخصية (متوافق مع الويب والموبايل)
  Future<String> uploadProfileImageBytes(String userId, Uint8List imageBytes, String fileExt) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      // وضع الصور داخل فولدر avatars أو رفعها مباشرة في الباكيت
      final filePath = 'avatars/$fileName';

      await _supabase.storage.from('profile_images').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
          );

      return _supabase.storage.from('profile_images').getPublicUrl(filePath);
    } catch (e, stackTrace) {
      print('=== ERROR UPLOADING IMAGE ===');
      print(e.toString());
      print(stackTrace.toString());
      print('=============================');
      throw ServerException('فشل رفع الصورة: $e');
    }
  }
}
