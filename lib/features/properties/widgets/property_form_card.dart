import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// بطاقة غلاف كل section في فورم العقار أو العميل
/// تعرض: رقم الخطوة (اختياري) + أيقونة + العنوان + المحتوى
/// يمكن استخدامها بدون stepNumber للـ leads أو أي form آخر
class PropertyFormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  /// رقم الخطوة — لو موجود يظهر badge رقمي ملون على يسار العنوان
  final int? stepNumber;

  /// لون مخصص لأيقونة الـ header — الافتراضي primaryBlue
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
    final Color resolvedColor = accentColor ?? AppColors.primaryBlue;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        // حد خفيف جداً مع ظل صغير يعطي عمقاً من غير مبالغة
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: resolvedColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── رأس الـ section ───
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
            decoration: BoxDecoration(
              // خلفية فاتحة جداً تميز الـ header عن المحتوى
              color: resolvedColor.withOpacity(0.04),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
              border: Border(
                bottom: BorderSide(color: resolvedColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                // ─── badge رقم الخطوة (اختياري) ───
                if (stepNumber != null) ...[
                  Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: resolvedColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],

                // ─── أيقونة الـ section ───
                Icon(icon, size: 20.sp, color: resolvedColor),
                SizedBox(width: 8.w),

                // ─── عنوان الـ section ───
                Text(
                  title,
                  style: AppTextStyles.blue16Bold.copyWith(color: resolvedColor),
                ),
              ],
            ),
          ),

          // ─── محتوى الـ section ───
          Padding(
            padding: EdgeInsets.all(16.w),
            child: child,
          ),
        ],
      ),
    );
  }
}
