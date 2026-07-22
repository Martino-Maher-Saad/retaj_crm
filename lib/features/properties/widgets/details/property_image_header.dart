import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/property_cache_manager.dart';
import '../../../../data/models/property_image_model.dart';
import '../../screens/property_full_screen_image.dart';

/// معرض صور أفقي في أعلى صفحة تفاصيل العقار
/// يدعم التمرير الأفقي، والضغط للتكبير، وعرض placeholder عند التحميل
class PropertyImageHeader extends StatefulWidget {
  /// قائمة صور العقار — كل صورة تحتوي على preview و original و thumbnail
  final List<PropertyImageModel> images;

  const PropertyImageHeader({super.key, required this.images});

  @override
  State<PropertyImageHeader> createState() => _PropertyImageHeaderState();
}

class _PropertyImageHeaderState extends State<PropertyImageHeader> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      // ─── حالة: لا توجد صور ───
      child: widget.images.isEmpty
          ? Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            )
          // ─── حالة: توجد صور — PageView ───
          : Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) => GestureDetector(
                    // الضغط على الصورة يفتح صفحة العرض الكامل (Full Screen)
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyFullScreenImage(imageUrl: widget.images[index].original),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ─── الصورة مع الـ Cache ───
                        CachedNetworkImage(
                          imageUrl: widget.images[index].preview, // نستخدم preview (صورة مضغوطة) للأداء
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
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(Icons.zoom_out_map, color: Colors.white, size: 16.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ─── الأسهم للتقليب ───
                if (widget.images.length > 1) ...[
                  Positioned(
                    left: 10.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onPressed: () {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
