import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;
  static const String _bucket = 'property_images';

  StorageService(this._client);

  Future<String> uploadImage(Uint8List bytes, String folder, String fileName) async {
    final String path = '$folder/$fileName';
    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> deleteFolder(String folder) async {
    final List<FileObject> files = await _client.storage.from(_bucket).list(path: folder);
    if (files.isNotEmpty) {
      final paths = files.map((f) => '$folder/${f.name}').toList();
      await _client.storage.from(_bucket).remove(paths);
    }
  }


  Future<void> deleteFile(String folder, String fileName) async {
    final String path = '$folder/$fileName';
    await _client.storage.from(_bucket).remove([path]);
  }

}