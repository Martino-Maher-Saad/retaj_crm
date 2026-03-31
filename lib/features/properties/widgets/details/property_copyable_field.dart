import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// حقل قراءة فقط (Read-Only) مع زر نسخ في نهايته
/// يُستخدم في صفحة التفاصيل لعرض أي بيانات قابلة للنسخ
/// مثال: المحافظة، المدينة، اسم المالك، الوصف
class PropertyCopyableField extends StatelessWidget {
  /// تسمية الحقل (تظهر كـ label فوق القيمة)
  final String label;

  /// القيمة المعروضة — لو null يعرض "---" ومش بيظهر زر النسخ
  final String? value;

  /// لو true يتمدد الحقل عمودياً لاستيعاب النصوص الطويلة (مثل الوصف)
  final bool isLong;

  const PropertyCopyableField({
    super.key,
    required this.label,
    this.value,
    this.isLong = false,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText = value ?? '---';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        initialValue: displayText,
        readOnly: true,
        // isLong = true → نصوص طويلة (وصف، ملاحظات)
        maxLines: isLong ? null : 1,
        style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),

          // ─── زر النسخ — يظهر فقط لو القيمة مش null ───
          suffixIcon: value != null
              ? IconButton(
                  tooltip: 'نسخ',
                  icon: Icon(
                    Icons.copy_all_rounded,
                    size: 20.sp,
                    color: AppColors.primaryBlue.withOpacity(0.6),
                  ),
                  onPressed: () {
                    // نسخ النص للـ clipboard
                    Clipboard.setData(ClipboardData(text: value!));

                    // إشعار المستخدم بنجاح النسخ
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ "$label"',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primaryBlue,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            // إزالة الحد الأفقي لمظهر أنظف
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        ),
      ),
    );
  }
}
