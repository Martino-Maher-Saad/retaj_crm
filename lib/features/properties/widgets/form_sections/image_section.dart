import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/property_image_model.dart';

class ImageSection extends StatelessWidget {
  final List<PropertyImageModel> existingImages;
  final List<Uint8List> newImagesBytes;
  final Function(PropertyImageModel) onRemoveExisting;
  final Function(int) onRemoveNew;
  final VoidCallback onAddPressed;

  const ImageSection({
    super.key,
    required this.existingImages,
    required this.newImagesBytes,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAddPressed,
  });

  int get _totalImages => existingImages.length + newImagesBytes.length;

  @override
  Widget build(BuildContext context) {
    // لو مفيش صور — اعرض منطقة الرفع الكبيرة
    if (_totalImages == 0) {
      return _buildUploadArea();
    }

    // لو في صور — اعرض الصور + زر إضافة صغير
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...existingImages.map((img) => _imgBox(
                    CachedNetworkImage(imageUrl: img.imageUrl, fit: BoxFit.cover),
                    onDel: () => onRemoveExisting(img),
                  )),
              ...newImagesBytes.asMap().entries.map((e) => _imgBox(
                    Image.memory(e.value, fit: BoxFit.cover),
                    onDel: () => onRemoveNew(e.key),
                  )),
              if (_totalImages < 10) _addMoreBtn(),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '$_totalImages / 10 صور',
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  /// منطقة الرفع الكبيرة مع خط متقطع (Dashed border)
  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: const Color(0xFFF8F8FF),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 32.sp,
                  color: AppColors.brandPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'قم بسحب وإفلات الصور هنا',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'أو انقر لتصفح ملفاتك. (الحد الأقصى 10 صور، صيغة JPG/PNG)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgBox(Widget img, {required VoidCallback onDel}) => Container(
        width: 110.w,
        margin: EdgeInsets.only(left: 8.w),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox.expand(child: img),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDel,
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 14.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _addMoreBtn() => GestureDetector(
        onTap: onAddPressed,
        child: Container(
          width: 110.w,
          margin: EdgeInsets.only(left: 8.w),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.brandPrimary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.brandPrimary, size: 28.sp),
              SizedBox(height: 4.h),
              Text(
                'إضافة',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

/// رسام الحدود المتقطعة
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBBBDD)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6;
    const double dashSpace = 4;
    const double radius = 14;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(radius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
