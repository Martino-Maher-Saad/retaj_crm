import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'property_cache_manager.dart';

class ImageDownloadHelper {
  static Future<void> downloadImages(BuildContext context, List<String> imageUrls, String prefix) async {
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد صور للتحميل')));
      return;
    }

    bool isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    ).then((_) => isDialogShowing = false);

    try {
      if (kIsWeb) {
        int downloadedCount = 0;
        for (int i = 0; i < imageUrls.length; i++) {
          final imageUrl = imageUrls[i];
          if (imageUrl.isNotEmpty) {
            try {
              final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
              final bytes = await file.readAsBytes();
              
              final blob = html.Blob([bytes]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final anchor = html.AnchorElement(href: url)
                ..setAttribute("download", "${prefix}_img_$i.jpg")
                ..click();
              html.Url.revokeObjectUrl(url);
              downloadedCount++;
            } catch (e) {
              debugPrint('Error downloading image on web: $e');
            }
          }
        }
        if (context.mounted && isDialogShowing) {
          Navigator.of(context).pop();
          isDialogShowing = false;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحميل $downloadedCount صورة')),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final saveDir = Directory('${dir.path}/Retaj_Downloads');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        int downloadedCount = 0;
        for (int i = 0; i < imageUrls.length; i++) {
          final imageUrl = imageUrls[i];
          if (imageUrl.isNotEmpty) {
            try {
              final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
              final savedFile = await file.copy('${saveDir.path}/${prefix}_img_$i.jpg');
              debugPrint('Saved to: ${savedFile.path}');
              downloadedCount++;
            } catch (e) {
              debugPrint('Error saving image natively: $e');
            }
          }
        }
        if (context.mounted && isDialogShowing) {
          Navigator.of(context).pop();
          isDialogShowing = false;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحميل $downloadedCount صورة إلى الجهاز')),
          );
        }
      }
    } catch (e) {
      if (context.mounted && isDialogShowing) {
        Navigator.of(context).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحميل')));
      }
    }
  }
}
