import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/layout_cubit.dart';
import '../cubit/layout_state.dart';
import 'user_avatar.dart';

class TopHeader extends StatelessWidget {
  final ProfileModel user;

  const TopHeader({super.key, required this.user});

  final List<String> _titles = const [
    "لوحة التحكم",
    "العقارات",
    "العملاء",
    "التصاميم",
    "الحسابات",
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 72.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ─── عنوان الصفحة الحالية ───
              BlocBuilder<LayoutCubit, LayoutState>(
                builder: (context, state) {
                  int idx = 0;
                  if (state is LayoutNavigationChanged) idx = state.selectedIndex;
                  return Text(
                    idx < _titles.length ? _titles[idx] : _titles[0],
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.brandPrimaryDark,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),

              // ─── اسم المستخدم + أفاتار ───
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${user.firstName ?? ''} ${user.lastName ?? ''}".trim(),
                        style: AppTextStyles.tableCellMain.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _resolveRoleLabel(user.role),
                        style: AppTextStyles.tableCellSub.copyWith(
                          color: AppColors.brandPrimary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  UserAvatar(user: user),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مسؤول النظام';
      case 'manager':
        return 'مدير';
      case 'sales':
        return 'موظف مبيعات';
      default:
        return role;
    }
  }
}