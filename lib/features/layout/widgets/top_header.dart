import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // للـ Scaling
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/layout_cubit.dart';
import '../cubit/layout_state.dart';

class TopHeader extends StatelessWidget {
  final ProfileModel user;

  TopHeader({super.key, required this.user});

  final List<String> titles = [
    "Dashboard",
    "Properties",
    "Leads",
    "Designs",
    "Accounts",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // استخدام .h ليكون الارتفاع متناسباً مع الشاشة (حوالي 90 بكسل في التصميم الأصلي)
      height: 90.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyLight.withOpacity(0.5), // خط سفلي بسيط للفصل بين الهيدر والمحتوى
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w), // بادينج مرن من الجوانب
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // جزء العنوان (يتغير حسب الصفحة المختارة)
          BlocBuilder<LayoutCubit, LayoutState>(
            builder: (context, state) {
              String title = titles[0];
              if (state is LayoutNavigationChanged) title = titles[state.selectedIndex];
              return Text(
                title,
                style: AppTextStyles.blue32Bold.copyWith(
                  fontSize: 28.sp, // تحجيم الخط ليكون متناسقاً مع مساحة الهيدر
                ),
              );
            },
          ),

          // الجزء الأيمن (أيقونات البحث والإشعارات ليعطي شكل الـ CRM الاحترافي)
          Row(
            children: [
              // أيقونة بحث وهمية مؤقتاً (كما في صور الـ UI التي أرسلتها)
              _headerIconButton(Icons.search_rounded),
              SizedBox(width: 15.w),
              _headerIconButton(Icons.notifications_none_rounded),
              SizedBox(width: 15.w),
              _headerIconButton(Icons.settings_outlined),

              // فاصل بسيط قبل صورة المستخدم إذا أردت إضافتها هنا لاحقاً
              VerticalDivider(
                indent: 30.h,
                endIndent: 30.h,
                color: AppColors.greyLight,
                thickness: 1,
              ),
              SizedBox(width: 15.w),

              // اسم المستخدم المصغر في الهيدر (اختياري لزيادة الاحترافية)
              Text(
                "${user.firstName}",
                style: AppTextStyles.blue18Medium.copyWith(fontSize: 14.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget فرعي للأيقونات للحفاظ على نظافة الكود
  Widget _headerIconButton(IconData icon) {
    return InkWell(
      onTap: () {}, // سيتم ربط الأكشن لاحقاً
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: Icon(
          icon,
          color: AppColors.sidebarBackground.withOpacity(0.7), // استخدام لون داكن متناسق
          size: 24.sp,
        ),
      ),
    );
  }
}