import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  

  
  /// رفع الصورة إلى Cloudinary بصيغة Bytes
  Future<String?> uploadImage(Uint8List imageBytes, String fileName, {String? folder}) async {
    try {
      String? cloudName;
      String? apiKey;
      String? apiSecret;

      final response = await Supabase.instance.client
          .from('system_settings')
          .select('key, value')
          .inFilter('key', ['cloudinary_cloud_name', 'cloudinary_api_key', 'cloudinary_api_secret']);

      for (var row in response) {
        if (row['key'] == 'cloudinary_cloud_name') cloudName = row['value'];
        if (row['key'] == 'cloudinary_api_key') apiKey = row['value'];
        if (row['key'] == 'cloudinary_api_secret') apiSecret = row['value'];
      }

      if (cloudName == null || apiKey == null || apiSecret == null) {
        print('Cloudinary keys are missing in system_settings');
        return null;
      }

      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      
      final folderStr = folder != null ? 'folder=$folder&' : '';
      final signature = sha1.convert(utf8.encode('${folderStr}timestamp=$timestamp$apiSecret')).toString();

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature;
        
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName,
          ),
        );

      var res = await request.send();
      final resBody = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final data = json.decode(resBody);
        return data['secure_url'];
      } else {
        print('Cloudinary Upload Error: $resBody');
        return null;
      }
    } catch (e) {
      print('Cloudinary Exception: $e');
      return null;
    }
  }

  /// حذف صورة من Cloudinary باستخدام الرابط الخاص بها
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) return false;
      
      final publicIdWithExt = pathSegments.sublist(uploadIndex + 2).join('/');
      final lastDotIndex = publicIdWithExt.lastIndexOf('.');
      final publicId = lastDotIndex != -1 ? publicIdWithExt.substring(0, lastDotIndex) : publicIdWithExt;

      String? cloudName;
      String? apiKey;
      String? apiSecret;

      final response = await Supabase.instance.client
          .from('system_settings')
          .select('key, value')
          .inFilter('key', ['cloudinary_cloud_name', 'cloudinary_api_key', 'cloudinary_api_secret']);

      for (var row in response) {
        if (row['key'] == 'cloudinary_cloud_name') cloudName = row['value'];
        if (row['key'] == 'cloudinary_api_key') apiKey = row['value'];
        if (row['key'] == 'cloudinary_api_secret') apiSecret = row['value'];
      }

      if (cloudName == null || apiKey == null || apiSecret == null) return false;

      final deleteUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/destroy';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      
      final signature = sha1.convert(utf8.encode('public_id=$publicId&timestamp=$timestamp$apiSecret')).toString();

      final res = await http.post(
        Uri.parse(deleteUrl),
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp,
          'signature': signature,
        }
      );

      return res.statusCode == 200;
    } catch (e) {
      print('Cloudinary Delete Exception: $e');
      return false;
    }
  }

  /// جلب رابط مصغرلإنشاء رابط الـ Thumbnail مصغر (10% جودة وعرض أصغر)
  static String getThumbnailUrl(String originalUrl) {
    if (originalUrl.contains('/upload/')) {
      return originalUrl.replaceFirst('/upload/', '/upload/q_auto:low,w_400/');
    }
    return originalUrl; // Fallback
  }
}
