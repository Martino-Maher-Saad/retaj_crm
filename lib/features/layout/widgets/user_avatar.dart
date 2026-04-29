import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/property_cache_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../../core/di/injection_container.dart' as di;

/// الأفاتار الدائري يُستخدم في الـ TopHeader — حجم ثابت بدون Expanded
/// لأنه داخل Row غير محدود العرض.
class UserAvatar extends StatelessWidget {
  final ProfileModel user;
  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (_) => di.sl<ProfileCubit>(),
              child: UserProfileScreen(currentUser: user),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(6.r),
        child: CircleAvatar(
          radius: 18.r,
          backgroundColor: AppColors.brandPrimary,
          child: ClipOval(
            child: user.imageUrl == null || user.imageUrl!.isEmpty
                ? Text(
                    user.firstName?[0].toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: user.imageUrl!,
                    width: 36.r,
                    height: 36.r,
                    fit: BoxFit.cover,
                    cacheManager: PropertyCacheManager.instance,
                    placeholder: (context, url) => SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}