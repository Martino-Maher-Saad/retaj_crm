import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// بطاقة غلاف كل section في فورم العقار
/// تعرض: أيقونة + العنوان في المنتصف + المحتوى
class PropertyFormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final int? stepNumber;
  final Color? accentColor;

  const PropertyFormCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.stepNumber,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = accentColor ?? AppColors.brandPrimary;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── عنوان القسم في المنتصف ───
          Padding(
            padding: EdgeInsets.only(top: 22.h, bottom: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(icon, color: resolvedColor, size: 20.sp),
              ],
            ),
          ),
          Divider(color: const Color(0xFFF0F0F6), thickness: 1, height: 22.h),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
            child: child,
          ),
        ],
      ),
    );
  }
}
