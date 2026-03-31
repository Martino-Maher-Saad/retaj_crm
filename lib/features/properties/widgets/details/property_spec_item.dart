import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عنصر مواصفة واحدة — أيقونة + تسمية + قيمة
/// يُستخدم داخل PropertySpecsGrid لعرض كل مواصفة منفردة
/// مثال: غرف نوم، حمامات، مساحة، دور
class PropertySpecItem extends StatelessWidget {
  final IconData icon;

  /// اسم المواصفة (مثال: "الغرف"، "المساحة")
  final String label;

  /// القيمة (مثال: "3"، "120 م²")
  final String value;

  const PropertySpecItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // عرض ثابت يضمن التوزيع المنتظم داخل الـ Wrap
      width: 80.w,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22.sp),
          SizedBox(height: 4.h),
          // ─── تسمية المواصفة ───
          Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          // ─── القيمة بخط أعرض ───
          Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
