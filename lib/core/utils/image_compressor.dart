import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  /// Compresses an image if its size exceeds [maxSizeInBytes].
  /// Default max size is 200KB (204,800 bytes).
  static Future<Uint8List> compressImage(Uint8List list, {int maxSizeInBytes = 204800}) async {
    if (list.lengthInBytes <= maxSizeInBytes) {
      return list;
    }

    Uint8List result = list;
    int quality = 85;
    int minWidth = 1080;
    int minHeight = 1080;

    while (result.lengthInBytes > maxSizeInBytes && quality > 10) {
      try {
        final compressed = await FlutterImageCompress.compressWithList(
          list, // Always compress from the original to avoid artifact accumulation
          minHeight: minHeight,
          minWidth: minWidth,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        result = compressed;
        quality -= 15;
        minWidth = (minWidth * 0.8).toInt();
        minHeight = (minHeight * 0.8).toInt();
      } catch (e) {
        // In case of error, stop compressing and return what we have
        break;
      }
    }
    return result;
  }
}
