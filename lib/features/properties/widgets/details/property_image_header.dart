import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/property_cache_manager.dart';
import '../../../../data/models/property_image_model.dart';
import '../../screens/property_full_screen_image.dart';

/// معرض صور أفقي في أعلى صفحة تفاصيل العقار
/// يدعم التمرير الأفقي، والضغط للتكبير، وعرض placeholder عند التحميل
class PropertyImageHeader extends StatelessWidget {
  /// قائمة صور العقار — كل صورة تحتوي على preview و original و thumbnail
  final List<PropertyImageModel> images;

  const PropertyImageHeader({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      // ─── حالة: لا توجد صور ───
      child: images.isEmpty
          ? Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            )
          // ─── حالة: توجد صور — ListView أفقي ───
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) => GestureDetector(
                // الضغط على الصورة يفتح صفحة العرض الكامل (Full Screen)
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyFullScreenImage(imageUrl: images[index].original),
                  ),
                ),
                child: Container(
                  width: 340.w,
                  margin: EdgeInsets.only(right: 8.w),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ─── الصورة مع الـ Cache ───
                      CachedNetworkImage(
                        imageUrl: images[index].preview, // نستخدم preview (صورة مضغوطة) للأداء
                        cacheManager: PropertyCacheManager.instance,
                        fit: BoxFit.cover,
                        memCacheWidth: 800, // تحديد الحجم في الذاكرة لتحسين الأداء
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),

                      // ─── مؤشر التكبير (Zoom Hint) ───
                      Positioned(
                        bottom: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(Icons.zoom_out_map, color: Colors.white, size: 16.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
