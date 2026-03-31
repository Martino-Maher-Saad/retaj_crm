import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// حقل معلومات قابل للنسخ بتصميم ListTile
/// يختلف عن PropertyCopyableField بالشكل — هنا Card بيضاء مع ListTile بدلاً من TextFormField
/// يدعم أيقونة اتصال إضافية لأرقام الهاتف
class LeadCopyableField extends StatelessWidget {
  /// تسمية الحقل (تظهر كـ subtitle فوق القيمة)
  final String label;

  /// القيمة المعروضة — لو null أو فارغة لا يظهر زر النسخ
  final String? value;

  const LeadCopyableField({
    super.key,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText = value ?? '---';

    // نكتشف لو الحقل هو رقم هاتف عشان نظهر أيقونة الاتصال
    final bool isPhoneField = label.contains("تيلفون");

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppConstants.r8),
          border: Border.all(color: AppColors.borderSubtle.withOpacity(0.5)),
        ),
        child: ListTile(
          dense: true,
          // ─── تسمية الحقل ───
          title: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.brandPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          // ─── قيمة الحقل ───
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // ─── أزرار اليمين: اتصال (للهاتف فقط) + نسخ ───
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الاتصال — تظهر فقط لحقول الهاتف
              if (isPhoneField && value != null && value!.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.phone_enabled_rounded,
                    color: AppColors.success,
                    size: 20.sp,
                  ),
                  onPressed: () {
                    // نسخ الرقم للـ clipboard (يمكن لاحقاً ربطه بـ url_launcher)
                    Clipboard.setData(ClipboardData(text: value!));
                  },
                ),
              // أيقونة النسخ — تظهر دائماً لو القيمة موجودة
              if (value != null && value!.isNotEmpty)
                IconButton(
                  tooltip: 'نسخ',
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 20.sp,
                    color: AppColors.brandPrimary.withOpacity(0.6),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ "$label"',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.brandPrimary,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        margin: EdgeInsets.all(20.w),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
