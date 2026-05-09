import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/property_model.dart';
import '../widgets/details/property_copyable_field.dart';
import '../widgets/details/property_image_header.dart';
import '../widgets/details/property_main_info_card.dart';
import '../widgets/details/property_section_card.dart';

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

  bool get isOwner => property.createdBy == currentUserId;
  bool get isManagerOrAdmin => role == 'manager' || role == 'admin';
  bool get shouldMask => role == 'sales' && !isOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(property.titleAr, style: AppTextStyles.h3),
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
              padding: EdgeInsets.all(20.w), // 30% Scale up
              child: Column(
                children: [
                  // 2. بطاقة المعلومات الأساسية والسعر
                  PropertyMainInfoCard(property: property),
                  SizedBox(height: 20.h), // 30% Scale up

                  // 3. الموقع
                  PropertySectionCard(
                    title: "الموقع",
                    icon: Icons.location_on,
                    content: _buildLocationContent(),
                  ),
                  SizedBox(height: 20.h),

                  // 4. الوصف
                  PropertySectionCard(
                    title: "الوصف",
                    icon: Icons.description,
                    content: PropertyCopyableField(
                      label: "الوصف بالعربي",
                      value: property.descAr,
                      isLong: true,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 5. مصدر العقار ومنصات الإعلان
                  if ((property.source != null && property.source!.isNotEmpty) || property.advertisingPlatforms.isNotEmpty) ...[
                    PropertySectionCard(
                      title: "مصدر العقار والمنصات",
                      icon: Icons.campaign_outlined,
                      content: _buildSourceAndPlatforms(),
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // 6. بيانات المالك والملاحظات
                  PropertySectionCard(
                    title: "بيانات الإدارة والمالك",
                    icon: Icons.admin_panel_settings,
                    content: _buildOwnerContent(),
                  ),
                  SizedBox(height: 50.h),
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
        if (!shouldMask && property.regionAr != null && property.regionAr!.isNotEmpty)
          PropertyCopyableField(label: "المنطقة", value: property.regionAr),
        if (!shouldMask && property.locationInDetails != null && property.locationInDetails!.isNotEmpty)
          PropertyCopyableField(label: "العنوان التفصيلي", value: property.locationInDetails),
      ],
    );
  }

  Widget _buildSourceAndPlatforms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property.source != null && property.source!.isNotEmpty)
          PropertyCopyableField(label: "مصدر العقار", value: property.source),
        if (property.advertisingPlatforms.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            "منصات الإعلان:",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF888899),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: property.advertisingPlatforms.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  entry.nameAr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildOwnerContent() {
    if (shouldMask) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          children: [
            Text(
              "غير مصرح لك برؤية تفاصيل المالك لأن العقار يخص زميل مبيعات آخر.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              "العقار مسجل بواسطة: ${property.createdByName ?? '---'}",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (property.ownerName != null && property.ownerName!.isNotEmpty)
          PropertyCopyableField(label: "اسم المالك", value: property.ownerName),
        if (property.ownerPhone != null && property.ownerPhone!.isNotEmpty)
          PropertyCopyableField(label: "رقم الهاتف", value: property.ownerPhone),
        if (property.internalNotes != null && property.internalNotes!.isNotEmpty) ...[
          const Divider(),
          PropertyCopyableField(label: "ملاحظات الموظفين", value: property.internalNotes, isLong: true),
        ]
      ],
    );
  }
}
