import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// رأس صفحة موحد لجميع شاشات القوائم في التطبيق
/// يعرض: عنوان + subtitle + badge العدد + أزرار الإجراءات
class RetajPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? totalCount;
  final String addLabel;
  final VoidCallback onAdd;
  final VoidCallback? onFilter;
  final String? filterLabel;
  final Widget? searchBar;

  const RetajPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.onAdd,
    this.totalCount,
    this.onFilter,
    this.filterLabel,
    this.searchBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5FB),
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── الصف الرئيسي: عنوان + أزرار ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // العنوان والـ subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        if (totalCount != null && totalCount! > 0) ...[
                          SizedBox(width: 10.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '$totalCount',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFFAAAABB),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── أزرار الإجراءات ───
              if (onFilter != null) ...[
                OutlinedButton.icon(
                  onPressed: onFilter,
                  icon: Icon(Icons.filter_list_rounded,
                      size: 20.sp, color: AppColors.brandPrimary),
                  label: Text(filterLabel ?? 'فلاتر',
                      style: TextStyle(
                          fontSize: 14.sp, color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 18.w, vertical: 12.h),
                    side: BorderSide(
                        color: AppColors.brandPrimary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // زر الإضافة (gradient)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandPrimary,
                      AppColors.brandPrimary.withValues(alpha: 0.8)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            addLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ─── شريط البحث (اختياري) ───
          if (searchBar != null) ...[
            SizedBox(height: 14.h),
            searchBar!,
          ],
        ],
      ),
    );
  }
}
