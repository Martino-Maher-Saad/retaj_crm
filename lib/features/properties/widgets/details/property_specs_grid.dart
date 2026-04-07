import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/property_model.dart';
import 'property_spec_item.dart';

/// شبكة المواصفات الفنية للعقار — تستخدم Wrap للتوزيع التلقائي
class PropertySpecsGrid extends StatelessWidget {
  final PropertyModel property;

  const PropertySpecsGrid({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        PropertySpecItem(
          icon: Icons.king_bed_outlined,
          label: "الغرف",
          value: "${property.bedrooms ?? 0}",
          iconColor: AppColors.brandPrimary,
        ),
        PropertySpecItem(
          icon: Icons.bathtub_outlined,
          label: "الحمامات",
          value: "${property.bathrooms ?? 0}",
          iconColor: AppColors.info,
        ),
        PropertySpecItem(
          icon: Icons.square_foot_outlined,
          label: "المساحة",
          value: "${property.builtArea ?? 0} م²",
          iconColor: AppColors.success,
        ),
        PropertySpecItem(
          icon: Icons.layers_outlined,
          label: "الدور",
          value: "${property.floor ?? '---'}",
          iconColor: AppColors.warning,
        ),
        PropertySpecItem(
          icon: Icons.format_paint_outlined,
          label: "التشطيب",
          value: property.completionStatus ?? "غير محدد",
          iconColor: const Color(0xFF7C3AED),
        ),
        PropertySpecItem(
          icon: Icons.chair_outlined,
          label: "مفروش",
          value: property.furnished == "yes" ? "نعم" : "لا",
          iconColor: const Color(0xFFDB2777),
        ),
      ],
    );
  }
}
