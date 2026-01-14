import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  final ProfileModel user;
  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // استخدام .w و .h للمسافات الخارجية
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Row(
        children: [
          // الدائرة التعريفية للمستخدم
          CircleAvatar(
            radius: 28.r, // استخدام .r للـ Radius لضمان التناسق
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              user.firstName?[0].toUpperCase() ?? 'U',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 26.sp, // حجم الخط داخل الدائرة
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // بيانات المستخدم (الاسم والدور)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${user.firstName} ${user.lastName ?? ''}",
                  overflow: TextOverflow.ellipsis, // حماية النص من الخروج عن الحدود
                  style: AppTextStyles.blue20Medium.copyWith(
                    color: AppColors.white,
                    fontSize: 16.sp, // تصغير بسيط ليناسب الـ Sidebar
                  ),
                ),

                SizedBox(height: 4.h),

                // بطاقة "الدور" (Role Badge)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 8.w),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2), // شفافية أخف لراحة العين
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    user.role?.toUpperCase() ?? '',
                    style: AppTextStyles.blue18Medium.copyWith(
                      color: AppColors.success, // استخدام اللون المباشر للنص
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}