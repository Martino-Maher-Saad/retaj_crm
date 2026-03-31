import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// بطاقة-غلاف مشتركة تُستخدم لتغليف أي محتوى داخل section بعنوان وأيقونة
/// مثال الاستخدام: المواصفات، الموقع، الوصف، بيانات المالك
class PropertySectionCard extends StatelessWidget {
  /// عنوان الـ section (مثال: "الموقع"، "المواصفات الفنية")
  final String title;

  /// أيقونة تظهر يسار العنوان
  final IconData icon;

  /// المحتوى الداخلي — أي Widget (Column, Grid, List...)
  final Widget content;

  const PropertySectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        // حد خفيف جداً يعطي إحساساً بالعمق
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── رأس الـ section: أيقونة + عنوان ───
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
              SizedBox(width: 8.w),
              Text(title, style: AppTextStyles.blue16Bold),
            ],
          ),

          // خط فاصل بين الرأس والمحتوى
          const Divider(height: 24),

          // ─── المحتوى الفعلي ───
          content,
        ],
      ),
    );
  }
}
