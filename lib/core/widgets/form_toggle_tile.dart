import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Toggle tile موحد يستبدل SwitchListTile و CheckboxListTile الـ default
/// يُستخدم في: property form sections و lead form sections
/// يعطي مظهراً احترافياً ومتسقاً مع باقي عناصر الـ form
class FormToggleTile extends StatelessWidget {
  /// النص الرئيسي للـ toggle
  final String title;

  /// نص توضيحي اختياري يظهر أسفل العنوان
  final String? subtitle;

  /// أيقونة اختيارية على اليمين
  final IconData? icon;

  /// الحالة الحالية (true = مفعل)
  final bool value;

  /// يُستدعى عند الضغط على الـ toggle
  final ValueChanged<bool> onChanged;

  /// لون مخصص للـ switch عند التفعيل — الافتراضي brandPrimary
  final Color? activeColor;

  const FormToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedActiveColor = activeColor ?? AppColors.brandPrimary;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          // الخلفية تتغير لتعكس الحالة — خفيف عند التفعيل
          color: value
              ? resolvedActiveColor.withOpacity(0.06)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppConstants.r12),
          border: Border.all(
            // الحد يتغير لوناً عند التفعيل
            color: value
                ? resolvedActiveColor.withOpacity(0.4)
                : AppColors.borderSubtle,
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // ─── أيقونة اختيارية ───
            if (icon != null) ...[
              Icon(
                icon,
                size: 20.sp,
                color: value ? resolvedActiveColor : AppColors.textSecondary,
              ),
              SizedBox(width: 12.w),
            ],

            // ─── النص الرئيسي والفرعي ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                      color: value ? resolvedActiveColor : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ─── Switch مخصص ───
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: resolvedActiveColor,
              // track color يتناسق مع نظام الألوان
              activeTrackColor: resolvedActiveColor.withOpacity(0.3),
              inactiveThumbColor: AppColors.textDisabled,
              inactiveTrackColor: AppColors.borderSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
