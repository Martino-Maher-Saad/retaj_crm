import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/property_model.dart';
import '../widgets/details/property_image_header.dart';
import '../widgets/property_share_sheet.dart';

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
  bool get isManagerOrAdmin => role == 'manager' || role == 'admin' || role == 'ceo';
  bool get shouldMask => role == 'sales' && !isOwner;

  @override
  Widget build(BuildContext context) {
    final priceFormatted = property.price.toCurrency();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل العقار',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            if (property.propertyCode != null)
              Text(
                '#${property.propertyCode}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.black87),
            onPressed: () => showPropertyShareSheet(
              context,
              property,
              canShareInternal: isOwner || isManagerOrAdmin,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 40.h),
        child: Column(
          children: [
            // ─── معرض الصور ───
            if (property.images.isNotEmpty) ...[
              SizedBox(height: 32.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: PropertyImageHeader(images: property.images),
              ),
            ],

            SizedBox(height: 32.h),

            // ─── بطاقة الحالة والسعر ───
            _StatusPriceCard(property: property),

            SizedBox(height: 4.h),

            // ─── البيانات الأساسية ───
            RetajSectionCard(
              title: 'البيانات الأساسية',
              icon: Icons.info_outline_rounded,
              children: [
                RetajTextField(
                  readOnly: true,
                  label: 'عنوان الإعلان',
                  initialValue: property.titleAr.isNotEmpty ? property.titleAr : '—',
                ),
                RetajFieldRow(
                  first: RetajTextField(
                    readOnly: true,
                    label: 'نوع الإعلان',
                    initialValue: property.listingTypeAr,
                  ),
                  second: RetajTextField(
                    readOnly: true,
                    label: 'نوع العقار',
                    initialValue: property.propertyTypeAr,
                  ),
                ),
                RetajTextField(
                  readOnly: true,
                  label: 'السعر',
                  initialValue: '$priceFormatted ج.م',
                  forceLtr: true,
                ),
                if (property.propertyCode != null)
                  RetajTextField(
                    readOnly: true,
                    label: 'كود العقار',
                    initialValue: property.propertyCode,
                  ),
                if (property.descAr.isNotEmpty)
                  RetajTextArea(
                    readOnly: true,
                    label: 'الوصف التفصيلي',
                    initialValue: property.descAr,
                    minLines: 3,
                  ),
              ],
            ),

            // ─── الموقع ───
            RetajSectionCard(
              title: 'الموقع',
              icon: Icons.location_on_outlined,
              iconColor: Colors.green,
              children: [
                RetajFieldRow(
                  first: RetajTextField(
                    readOnly: true,
                    label: 'المحافظة',
                    initialValue: property.governorateAr,
                  ),
                  second: RetajTextField(
                    readOnly: true,
                    label: 'المدينة',
                    initialValue: property.cityAr,
                  ),
                ),
                if (property.regionAr != null && property.regionAr!.isNotEmpty)
                  RetajTextField(
                    readOnly: true,
                    label: 'المنطقة',
                    initialValue: property.regionAr,
                  ),
                if (!shouldMask && property.locationInDetails != null && property.locationInDetails!.isNotEmpty)
                  RetajTextField(
                    readOnly: true,
                    label: 'العنوان التفصيلي',
                    initialValue: property.locationInDetails,
                  ),
                if (!shouldMask && property.locationMap != null && property.locationMap!.isNotEmpty)
                  RetajTextField(
                    readOnly: true,
                    label: 'رابط خريطة جوجل',
                    initialValue: property.locationMap,
                    forceLtr: true,
                  ),
              ],
            ),

            // ─── مصدر العقار والمنصات ───
            if ((property.source != null && property.source!.isNotEmpty) ||
                property.advertisingPlatforms.isNotEmpty)
              RetajSectionCard(
                title: 'مصدر العقار والمنصات',
                icon: Icons.campaign_outlined,
                iconColor: Colors.orange,
                children: [
                  if (property.source != null && property.source!.isNotEmpty)
                    RetajTextField(
                      readOnly: true,
                      label: 'مصدر العقار',
                      initialValue: property.source,
                    ),
                  if (property.advertisingPlatforms.isNotEmpty)
                    _PlatformChips(platforms: property.advertisingPlatforms.map((p) => p.nameAr).toList()),
                ],
              ),

            // ─── بيانات المالك ───
            if (!shouldMask)
              RetajSectionCard(
                title: 'بيانات المالك',
                icon: Icons.person_outline_rounded,
                iconColor: Colors.purple,
                children: [
                  if (property.ownerName != null && property.ownerName!.isNotEmpty)
                    RetajTextField(
                      readOnly: true,
                      label: 'اسم المالك',
                      initialValue: property.ownerName,
                    ),
                  if (property.ownerPhone != null && property.ownerPhone!.isNotEmpty)
                    RetajTextField(
                      readOnly: true,
                      label: 'رقم الهاتف',
                      initialValue: property.ownerPhone,
                      forceLtr: true,
                    ),
                  if (property.internalNotes != null && property.internalNotes!.isNotEmpty)
                    RetajTextArea(
                      readOnly: true,
                      label: 'ملاحظات الموظفين',
                      initialValue: property.internalNotes,
                      minLines: 2,
                    ),
                ],
              )
            else
              RetajSectionCard(
                title: 'بيانات المالك',
                icon: Icons.lock_outline_rounded,
                iconColor: Colors.red,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_person_rounded, size: 36.sp, color: Colors.red),
                        SizedBox(height: 10.h),
                        Text(
                          'غير مصرح لك برؤية تفاصيل المالك',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15.sp),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'العقار مسجل بواسطة: ${property.createdByName ?? "---"}',
                          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // ─── ملاحظات الإدارة ───
            if (isManagerOrAdmin && property.managerNotes != null && property.managerNotes!.isNotEmpty)
              RetajSectionCard(
                title: 'ملاحظات الإدارة',
                icon: Icons.admin_panel_settings_outlined,
                iconColor: Colors.blue,
                children: [
                  RetajTextArea(
                    readOnly: true,
                    label: 'ملاحظة الإدارة',
                    initialValue: property.managerNotes,
                    minLines: 2,
                  ),
                ],
              ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

// ─── Status + Price Card ───
class _StatusPriceCard extends StatelessWidget {
  final PropertyModel property;
  const _StatusPriceCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final approvedId = '74076467-124a-4142-b821-6096d9fa3f4c';
    final rejectedId = '7345796d-1fd8-462d-b240-7eec15c87e6f';
    final pendingId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
    final statusId = property.approvalStatusId;

    final (label, color, bg) = switch (statusId) {
      _ when statusId == approvedId => ('تمت الموافقة', const Color(0xFF10B981), const Color(0xFFE6FFF5)),
      _ when statusId == rejectedId => ('تم الرفض',    const Color(0xFFEF4444), const Color(0xFFFFEEEE)),
      _ when statusId == pendingId  => ('قيد المراجعة', const Color(0xFFF59E0B), const Color(0xFFFFF8E6)),
      _                             => ('غير محدد',     Colors.grey,             Colors.grey.shade100),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // السعر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                ),
                Text(
                  '${property.price.toCurrency()} ج.م',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          // حالة الموافقة
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Platform Chips ───
class _PlatformChips extends StatelessWidget {
  final List<String> platforms;
  const _PlatformChips({required this.platforms});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'منصات الإعلان:',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children: platforms
              .map((name) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
