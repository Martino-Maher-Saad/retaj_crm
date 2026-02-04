import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/property_cache_manager.dart';

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
            radius: 28.r,
            backgroundColor: AppColors.primaryBlue,
            // نستخدم الـ child لعرض المحتوى
            child: ClipOval( // لضمان أن الصورة تظل دائرية تماماً حتى لو كانت أبعادها غير متساوية
              child: user.imageUrl == null || user.imageUrl!.isEmpty
                  ? Text(
                user.firstName?[0].toUpperCase() ?? 'U',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : CachedNetworkImage(
                imageUrl: user.imageUrl!,
                width: 56.r * 2, // القطر كامل (radius * 2)
                height: 56.r * 2,
                fit: BoxFit.cover,
                // نستخدم الـ CacheManager المخصص للويب الذي أنشأناه سابقاً
                cacheManager: PropertyCacheManager.instance,
                placeholder: (context, url) => CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 30.sp,
                ),
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