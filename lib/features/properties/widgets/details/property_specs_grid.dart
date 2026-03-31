import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/property_model.dart';
import 'property_spec_item.dart';

/// شبكة المواصفات الفنية للعقار (غرف، حمامات، مساحة، دور، تشطيب، فرش)
/// تستخدم Wrap لضمان التوزيع التلقائي على عدة أسطر حسب المساحة المتاحة
class PropertySpecsGrid extends StatelessWidget {
  final PropertyModel property;

  const PropertySpecsGrid({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20.w,  // المسافة الأفقية بين العناصر
      runSpacing: 20.h, // المسافة العمودية بين الأسطر
      children: [
        PropertySpecItem(icon: Icons.king_bed, label: "الغرف", value: "${property.bedrooms}"),
        PropertySpecItem(icon: Icons.bathtub, label: "الحمامات", value: "${property.bathrooms}"),
        PropertySpecItem(icon: Icons.square_foot, label: "المساحة", value: "${property.builtArea} م²"),
        PropertySpecItem(icon: Icons.layers, label: "الدور", value: "${property.floor}"),
        PropertySpecItem(icon: Icons.format_paint, label: "التشطيب", value: property.completionStatus ?? "غير محدد"),
        PropertySpecItem(icon: Icons.chair, label: "مفروش", value: property.furnished == "yes" ? "نعم" : "لا"),
      ],
    );
  }
}
