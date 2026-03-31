import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'leads_status_filter_bar.dart';

/// الشريط العلوي في شاشة إدارة العملاء
/// يحتوي على: زر "إضافة عميل" + شريط فلاتر الحالة جنبه
class LeadTopActionsBar extends StatelessWidget {
  /// قائمة حالات الفلترة (الكل، جديد، تم التواصل...)
  final List<String> filters;

  /// الفلتر المحدد حالياً
  final String currentFilter;

  /// يُستدعى عند الضغط على زر "إضافة عميل"
  final VoidCallback onAddPressed;

  /// يُستدعى عند الضغط على أي فلتر — يمرر قيمة الفلتر الجديد
  final ValueChanged<String> onFilterSelected;

  const LeadTopActionsBar({
    super.key,
    required this.filters,
    required this.currentFilter,
    required this.onAddPressed,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      // خلفية بيضاء تفصل الـ bar عن باقي الجسم
      color: AppColors.bgSurface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppConstants.p16),
        child: Row(
          children: [
            // ─── زر إضافة عميل جديد ───
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(
                "إضافة عميل",
                style: AppTextStyles.buttonLarge.copyWith(fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.r8),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // ─── شريط فلاتر الحالة بجانب الزر ───
            Expanded(
              child: LeadsStatusFilterBar(
                filters: filters,
                currentFilter: currentFilter,
                onFilterSelected: onFilterSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
