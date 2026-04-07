import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

/// عنصر مواصفة فنية — بطاقة صغيرة تحتوي على أيقونة + تسمية + قيمة
/// مثال: غرف، حمامات، مساحة، دور، تشطيب
class PropertySpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const PropertySpecItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // القيمة الرقمية → LTR، الكلامية → RTL
    final bool isNumeric =
        value.isNotEmpty && (value.codeUnitAt(0) >= 0x0030 && value.codeUnitAt(0) <= 0x0039);

    return Container(
      width: 110.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.r8),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── أيقونة ───
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.brandPrimary).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.brandPrimary,
              size: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          // ─── قيمة المواصفة ───
          Text(
            value,
            style: AppTextStyles.tableCellMain.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            textDirection: isNumeric ? TextDirection.ltr : TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          // ─── تسمية المواصفة ───
          Text(
            label,
            style: AppTextStyles.tableCellSub.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
