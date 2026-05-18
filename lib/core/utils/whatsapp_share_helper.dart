import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/property_model.dart';
import 'property_cache_manager.dart';

class WhatsappShareHelper {
  static String buildPublicMessage(PropertyModel property) {
    final buffer = StringBuffer();
    buffer.writeln('🏠 *عقار للـ بيع — ${property.propertyTypeAr}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *السعر:* ${property.price.toStringAsFixed(0)} ج.م');
    buffer.writeln('📍 *المحافظة / المدينة:* ${property.governorateAr} — ${property.cityAr}');
    if (property.regionAr != null && property.regionAr!.isNotEmpty) {
      buffer.writeln('🏘️ *المنطقة:* ${property.regionAr}');
    }
    if (property.locationInDetails != null && property.locationInDetails!.isNotEmpty) {
      buffer.writeln('📍 *تفاصيل الموقع:* ${property.locationInDetails}');
    }
    buffer.writeln('📝 *الوصف:* ${property.descAr}');
    buffer.writeln('🔑 *الحالة:* ${property.status ? "نشط" : "مغلق"}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📲 من نظام رتاج للعقارات');
    return buffer.toString();
  }

  static String buildInternalMessage(PropertyModel property) {
    final buffer = StringBuffer();
    buffer.writeln('🔒 *بيانات داخلية — رتاج*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 *كود العقار:* #${property.propertyCode ?? "---"}');
    buffer.writeln('👤 *اسم المالك:* ${property.ownerName ?? "غير محدد"}');
    buffer.writeln('📞 *تليفون المالك:* ${property.ownerPhone ?? "غير محدد"}');
    if (property.internalNotes != null && property.internalNotes!.isNotEmpty) {
      buffer.writeln('📝 *ملاحظات داخلية:* ${property.internalNotes}');
    }
    if (property.source != null && property.source!.isNotEmpty) {
      buffer.writeln('📡 *المصدر:* ${property.source}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚠️ هذه المعلومات للاستخدام الداخلي فقط');
    return buffer.toString();
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

  static Future<void> shareInternal(BuildContext context, PropertyModel property) async {
    final message = buildInternalMessage(property);
    
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        final webUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          await Share.share(message);
        }
      }
    } catch (e) {
      await Share.share(message);
    }
  }
}
