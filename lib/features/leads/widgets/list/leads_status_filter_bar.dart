import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';

/// شريط فلاتر حالة العملاء — ChoiceChips أفقية قابلة للتمرير
/// الفلاتر: الكل، جديد، تم التواصل، تفاوض، تم التعاقد، مستبعد
class LeadsStatusFilterBar extends StatelessWidget {
  /// قائمة كل الفلاتر المتاحة
  final List<String> filters;

  /// الفلتر المختار حالياً
  final String currentFilter;

  /// يُستدعى عند اختيار فلتر جديد
  final ValueChanged<String> onFilterSelected;

  const LeadsStatusFilterBar({
    super.key,
    required this.filters,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      // ListView أفقي لاستيعاب عدد الفلاتر بدون overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final bool isSelected = currentFilter == filters[index];

          return Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filters[index]),

              // ─── تصميم: مختار = أزرق / غير مختار = رمادي ───
              selectedColor: AppColors.brandPrimary,
              backgroundColor: AppColors.bgMain,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              labelStyle: AppTextStyles.chipLabel.copyWith(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.r8),
                side: BorderSide(
                  color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
