import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // إضافة المكتبة للـ Scaling
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart'; // لاستخدام الثوابت إذا وجدت للمسافات
import '../../auth/cubit/auth_cubit.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // استخدام .h لضمان بقاء المسافة متناسبة مع ارتفاع الشاشة
      padding: EdgeInsets.only(bottom: 30.h),
      child: Tooltip(
        message: 'تسجيل الخروج', // تحسين تجربة المستخدم في الـ Web
        child: InkWell(
          onTap: () => context.read<AuthCubit>().logout(),
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              // إعطاء خلفية بسيطة عند التحويم أو التفاعل إذا أردت،
              // أو تركه شفافاً كما في تصميمك الأصلي
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.primaryRed,
              size: 32.sp, // استخدام .sp ليكون حجم الأيقونة متناسقاً مع الخطوط
            ),
          ),
        ),
      ),
    );
  }
}