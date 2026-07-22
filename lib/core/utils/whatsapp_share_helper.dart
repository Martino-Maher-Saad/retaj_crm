import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import '../../../data/models/property_model.dart';
import 'property_cache_manager.dart';
import 'number_formatter.dart';

class WhatsappShareHelper {
  static String buildPublicMessage(PropertyModel property) {
    final buffer = StringBuffer();
    buffer.writeln('🏠 *عقار مميز للبيع/الإيجار*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 *نوع العقار والإعلان:* ${property.propertyTypeAr} - ${property.listingTypeAr}');
    buffer.writeln('💰 *السعر:* ${property.price.toCurrency()} ج.م');
    buffer.writeln('📍 *المحافظة / المدينة:* ${property.governorateAr} - ${property.cityAr}');
    if (property.regionAr != null && property.regionAr!.isNotEmpty) {
      buffer.writeln('🏘️ *المنطقة:* ${property.regionAr}');
    }
    buffer.writeln('📝 *الوصف:* ${property.descAr}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('✨ من ريتاج للعقارات');
    return buffer.toString();
  }

  static String buildInternalMessage(PropertyModel property) {
    final buffer = StringBuffer();
    buffer.writeln('🏠 *مشاركة داخلية (زميل)*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 *نوع العقار والإعلان:* ${property.propertyTypeAr} - ${property.listingTypeAr}');
    buffer.writeln('💰 *السعر:* ${property.price.toCurrency()} ج.م');
    buffer.writeln('📍 *المحافظة / المدينة:* ${property.governorateAr} - ${property.cityAr}');
    if (property.regionAr != null && property.regionAr!.isNotEmpty) {
      buffer.writeln('🏘️ *المنطقة:* ${property.regionAr}');
    }
    if (property.locationInDetails != null && property.locationInDetails!.isNotEmpty) {
      buffer.writeln('📌 *تفاصيل الموقع:* ${property.locationInDetails}');
    }
    buffer.writeln('📝 *الوصف:* ${property.descAr}');
    buffer.writeln('🔑 *الحالة:* ${property.status ? "نشط" : "مغلق"}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🆔 *كود العقار:* #${property.propertyCode ?? "---"}');
    buffer.writeln('👤 *اسم المالك:* ${property.ownerName ?? "غير محدد"}');
    buffer.writeln('📱 *تليفون المالك:* ${property.ownerPhone ?? "غير محدد"}');
    if (property.internalNotes != null && property.internalNotes!.isNotEmpty) {
      buffer.writeln('🔒 *ملاحظات داخلية:* ${property.internalNotes}');
    }
    if (property.source != null && property.source!.isNotEmpty) {
      buffer.writeln('🌐 *المصدر:* ${property.source}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚠️ هذه المعلومات للاستخدام الداخلي فقط');
    return buffer.toString();
  }

  static Future<void> copyToClipboard(BuildContext context, PropertyModel property) async {
    final text = buildPublicMessage(property);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ تفاصيل العقار بنجاح')),
      );
    }
  }

  static Future<void> sharePublic(BuildContext context, PropertyModel property) async {
    bool isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    ).then((_) => isDialogShowing = false);

    try {
      final message = buildPublicMessage(property);
      final List<XFile> imageFiles = [];

      if (property.images.isNotEmpty) {
        final imagesToShare = property.images.toList();
        
        for (int i = 0; i < imagesToShare.length; i++) {
          final imageUrl = imagesToShare[i].original; 
          if (imageUrl.isNotEmpty) {
            try {
              final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
              if (kIsWeb) {
                final bytes = await file.readAsBytes();
                imageFiles.add(XFile.fromData(
                  bytes,
                  name: 'property_img_$i.jpg',
                  mimeType: 'image/jpeg',
                ));
              } else {
                imageFiles.add(XFile(file.path));
              }
            } catch (e) {
              debugPrint('Error loading image from cache: $e');
            }
          }
        }
      }

      if (context.mounted && isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }

      if (kIsWeb) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('تم تحضير الصور بنجاح'),
              content: const Text('الصور جاهزة الآن. اضغط على الزر بالأسفل لفتح المشاركة (الواتساب).'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (imageFiles.isNotEmpty) {
                      Share.shareXFiles(imageFiles, text: message, subject: 'تفاصيل العقار');
                    } else {
                      Share.share(message, subject: 'تفاصيل العقار');
                    }
                  },
                  child: const Text('مشاركة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        if (imageFiles.isNotEmpty) {
          await Share.shareXFiles(
            imageFiles,
            text: message,
            subject: 'تفاصيل العقار',
          );
        } else {
          await Share.share(message, subject: 'تفاصيل العقار');
        }
      }
    } catch (e, stack) {
      print('======================================================');
      print('=================== SHARE ERROR ======================');
      print('Error: $e');
      print('Stack: $stack');
      print('======================================================');
      print('======================================================');
      if (context.mounted) {
        if (isDialogShowing) {
          Navigator.of(context).pop();
          isDialogShowing = false;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('خطأ في المشاركة'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  static Future<void> downloadImages(BuildContext context, PropertyModel property) async {
    if (property.images.isEmpty) {
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
        // In web, directly download using universal_html
        int downloadedCount = 0;
        for (int i = 0; i < property.images.length; i++) {
          final imageUrl = property.images[i].original; 
          if (imageUrl.isNotEmpty) {
            try {
              final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
              final bytes = await file.readAsBytes();
              
              final blob = html.Blob([bytes]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final anchor = html.AnchorElement(href: url)
                ..setAttribute("download", "${property.propertyCode ?? 'property'}_img_$i.jpg")
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
            SnackBar(
              content: Text('تم تحميل $downloadedCount صورة بنجاح ✅'),
              backgroundColor: Colors.green,
            )
          );
        }
        return;
      }

      // Android/iOS direct download
      int savedCount = 0;
      Directory? downloadsDirectory;
      
      try {
        if (Platform.isAndroid) {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
          if (!await downloadsDirectory.exists()) {
            downloadsDirectory = await getDownloadsDirectory();
          }
        } else {
          downloadsDirectory = await getDownloadsDirectory();
        }
      } catch (e) {
        downloadsDirectory = await getDownloadsDirectory();
      }

      if (downloadsDirectory == null) {
        throw Exception('لا يمكن الوصول لمجلد التنزيلات');
      }

      final propertyFolderName = property.propertyCode ?? 'property_${DateTime.now().millisecondsSinceEpoch}';
      final propertyFolder = Directory('${downloadsDirectory.path}/$propertyFolderName');
      
      if (!await propertyFolder.exists()) {
        await propertyFolder.create(recursive: true);
      }

      for (int i = 0; i < property.images.length; i++) {
        final imageUrl = property.images[i].original; 
        if (imageUrl.isNotEmpty) {
          final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
          final ext = file.path.split('.').last;
          final safeExt = ext.length > 4 ? 'jpg' : ext;
          final newFile = File('${propertyFolder.path}/img_$i.$safeExt');
          await file.copy(newFile.path);
          savedCount++;
        }
      }

      if (context.mounted && isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ $savedCount صورة في مجلد التنزيلات ($propertyFolderName) بنجاح ✅'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (context.mounted && isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }
      debugPrint('Error downloading images: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
      }
    }
  }

  static Future<void> shareInternal(BuildContext context, PropertyModel property) async {
    bool isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    ).then((_) => isDialogShowing = false);

    try {
      final message = buildInternalMessage(property);
      final List<XFile> imageFiles = [];

      if (property.images.isNotEmpty) {
        final imagesToShare = property.images.toList();
        
        for (int i = 0; i < imagesToShare.length; i++) {
          final imageUrl = imagesToShare[i].original; 
          if (imageUrl.isNotEmpty) {
            try {
              final file = await PropertyCacheManager.instance.getSingleFile(imageUrl);
              if (kIsWeb) {
                final bytes = await file.readAsBytes();
                imageFiles.add(XFile.fromData(
                  bytes,
                  name: 'property_img_$i.jpg',
                  mimeType: 'image/jpeg',
                ));
              } else {
                imageFiles.add(XFile(file.path));
              }
            } catch (e) {
              debugPrint('Error loading image from cache: $e');
            }
          }
        }
      }

      if (context.mounted && isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }

      if (kIsWeb) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('تم تحضير الصور بنجاح'),
              content: const Text('الصور جاهزة الآن. اضغط على الزر بالأسفل لفتح المشاركة (الواتساب).'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (imageFiles.isNotEmpty) {
                      Share.shareXFiles(imageFiles, text: message, subject: 'مشاركة داخلية');
                    } else {
                      Share.share(message, subject: 'مشاركة داخلية');
                    }
                  },
                  child: const Text('مشاركة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        if (imageFiles.isNotEmpty) {
          await Share.shareXFiles(
            imageFiles,
            text: message,
            subject: 'مشاركة داخلية',
          );
        } else {
          await Share.share(message, subject: 'مشاركة داخلية');
        }
      }
    } catch (e, stack) {
      print('======================================================');
      print('=================== SHARE ERROR ======================');
      print('Error: $e');
      print('Stack: $stack');
      print('======================================================');
      print('======================================================');
      if (context.mounted) {
        if (isDialogShowing) {
          Navigator.of(context).pop();
          isDialogShowing = false;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('خطأ في المشاركة'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }
}
