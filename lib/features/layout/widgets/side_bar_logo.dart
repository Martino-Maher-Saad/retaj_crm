import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SideBarLogo extends StatelessWidget {
  const SideBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            color: AppColors.white,
            size: 50.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            "RETAJ CRM",
            style: AppTextStyles.blue20Medium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 20.sp, // تحجيم النص بـ sp
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 40.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}