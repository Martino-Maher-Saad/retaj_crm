import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/property_model.dart';
import '../widgets/details/property_copyable_field.dart';
import '../widgets/details/property_image_header.dart';
import '../widgets/details/property_main_info_card.dart';
import '../widgets/details/property_section_card.dart';
import '../widgets/details/property_specs_grid.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;

  const PropertyDetailsScreen({
    super.key, 
    required this.property,
    required this.currentUserId,
    required this.role,
  });

  bool get shouldMask => role == 'sales' && property.createdBy != currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(property.titleAr ?? "تفاصيل العقار", style: AppTextStyles.blue16Bold),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. معرض الصور
            PropertyImageHeader(images: property.images),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // 2. بطاقة المعلومات الأساسية والسعر
                  PropertyMainInfoCard(property: property),
                  SizedBox(height: 16.h),

                  // 3. المواصفات الفنية
                  PropertySectionCard(
                    title: "المواصفات الفنية",
                    icon: Icons.straighten,
                    content: PropertySpecsGrid(property: property),
                  ),
                  SizedBox(height: 16.h),

                  // 4. الموقع
                  PropertySectionCard(
                    title: "الموقع",
                    icon: Icons.location_on,
                    content: _buildLocationContent(),
                  ),
                  SizedBox(height: 16.h),

                  // 5. الوصف
                  PropertySectionCard(
                    title: "الوصف",
                    icon: Icons.description,
                    content: PropertyCopyableField(
                      label: "الوصف بالعربي",
                      value: property.descAr,
                      isLong: true,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 6. بيانات المالك والملاحظات
                  PropertySectionCard(
                    title: "بيانات الإدارة والمالك",
                    icon: Icons.admin_panel_settings,
                    content: _buildOwnerContent(),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent() {
    return Column(
      children: [
        PropertyCopyableField(label: "المحافظة", value: property.governorateAr),
        PropertyCopyableField(label: "المدينة", value: property.cityAr),
        PropertyCopyableField(label: "المنطقة", value: property.regionAr),
        if (!shouldMask)
          PropertyCopyableField(label: "العنوان التفصيلي", value: property.locationInDetails),
      ],
    );
  }

  Widget _buildOwnerContent() {
    if (shouldMask) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Text(
          "غير مصرح لك برؤية تفاصيل المالك لأن العقار يخص زميل مبيعات آخر.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        PropertyCopyableField(label: "اسم المالك", value: property.ownerName),
        PropertyCopyableField(label: "رقم الهاتف", value: property.ownerPhone),
        const Divider(),
        PropertyCopyableField(label: "ملاحظات الموظفين", value: property.internalNotes),
      ],
    );
  }
}
