import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// رأس قائمة العقارات — يعرض عنوان الشاشة وعدد الوحدات وزر الإضافة
class PropertyListHeader extends StatelessWidget {
  /// إجمالي عدد الوحدات المسجلة (يُعرض في العنوان الفرعي)
  final int totalCount;

  /// يُستدعى عند الضغط على زر "إضافة وحدة"
  final VoidCallback onAdd;

  const PropertyListHeader({
    super.key,
    required this.totalCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 45.h, 20.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ─── العنوان الرئيسي والفرعي ───
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "مخزون العقارات",
                style: AppTextStyles.blue16Bold.copyWith(fontSize: 22.sp, color: Colors.black),
              ),
              SizedBox(height: 4.h),
              Text(
                "إدارة الوحدات ($totalCount وحدة)",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          // ─── زر الإضافة ───
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("إضافة وحدة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }
}
