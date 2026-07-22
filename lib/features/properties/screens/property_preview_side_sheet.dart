import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/property_model.dart';
import '../widgets/details/property_image_header.dart';
import '../widgets/property_share_sheet.dart';
import 'property_form_screen.dart';
import '../cubit/properties_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Side sheet لتفاصيل العقار — يفتح من اليمين بعرض 50% من الشاشة
class PropertyPreviewSideSheet extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;
  final PropertiesCubit cubit;

  const PropertyPreviewSideSheet({
    super.key,
    required this.property,
    required this.currentUserId,
    required this.role,
    required this.cubit,
  });

  @override
  State<PropertyPreviewSideSheet> createState() =>
      _PropertyPreviewSideSheetState();
}

class _PropertyPreviewSideSheetState extends State<PropertyPreviewSideSheet> {
  late PropertyModel _property;

  bool get isOwner => _property.createdBy == widget.currentUserId;
  bool get isManagerOrAdmin =>
      AppRole.fromString(widget.role).isAtLeast(AppRole.manager);
  bool get shouldMask => widget.role == 'sales' && !isOwner;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.5;
    final priceFormatted = _property.price.toCurrency();

    return Container(
      width: width.clamp(360.0, 900.0),
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: DefaultTabController(
        length: 2,
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───
              _buildHeader(context),

              // ─── Tabs ───
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppColors.brandPrimary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.brandPrimary,
                  tabs: [
                    Tab(text: 'التفاصيل', icon: Icon(Icons.info_outline)),
                    Tab(text: 'الصور', icon: Icon(Icons.photo_library_outlined)),
                  ],
                ),
              ),

              // ─── Body ───
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Details
                    SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // بطاقة السعر والحالة
                  _buildStatusPriceCard(priceFormatted),

                  SizedBox(height: 4.h),

                  // البيانات الأساسية
                  RetajSectionCard(
                    title: 'البيانات الأساسية',
                    icon: Icons.info_outline_rounded,
                    children: [
                      RetajTextField(
                        readOnly: true,
                        label: 'عنوان الإعلان',
                        initialValue: _property.titleAr.isNotEmpty
                            ? _property.titleAr
                            : '—',
                      ),
                      RetajFieldRow(
                        first: RetajTextField(
                          readOnly: true,
                          label: 'نوع الإعلان',
                          initialValue: _property.listingTypeAr,
                        ),
                        second: RetajTextField(
                          readOnly: true,
                          label: 'نوع العقار',
                          initialValue: _property.propertyTypeAr,
                        ),
                      ),
                      RetajTextField(
                        readOnly: true,
                        label: 'السعر',
                        initialValue: '$priceFormatted ج.م',
                        forceLtr: true,
                      ),
                      if (_property.propertyCode != null)
                        RetajTextField(
                          readOnly: true,
                          label: 'كود العقار',
                          initialValue: _property.propertyCode,
                        ),
                      if (_property.descAr.isNotEmpty)
                        RetajTextArea(
                          readOnly: true,
                          label: 'الوصف التفصيلي',
                          initialValue: _property.descAr,
                          minLines: 2,
                        ),
                    ],
                  ),

                  // الموقع
                  RetajSectionCard(
                    title: 'الموقع',
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.green,
                    children: [
                      RetajFieldRow(
                        first: RetajTextField(
                          readOnly: true,
                          label: 'المدينة',
                          initialValue: _property.cityAr.isNotEmpty
                              ? _property.cityAr
                              : '—',
                        ),
                        second: const SizedBox.shrink(),
                      ),
                      if (_property.regionAr != null &&
                          _property.regionAr!.isNotEmpty)
                        RetajTextField(
                          readOnly: true,
                          label: 'المنطقة',
                          initialValue: _property.regionAr,
                        ),
                      if (!shouldMask &&
                          _property.locationInDetails != null &&
                          _property.locationInDetails!.isNotEmpty)
                        RetajTextField(
                          readOnly: true,
                          label: 'العنوان التفصيلي',
                          initialValue: _property.locationInDetails,
                        ),
                      if (!shouldMask &&
                          _property.locationMap != null &&
                          _property.locationMap!.isNotEmpty)
                        RetajTextField(
                          readOnly: true,
                          label: 'رابط خريطة جوجل',
                          initialValue: _property.locationMap,
                          forceLtr: true,
                        ),
                    ],
                  ),

                  // مصدر العقار والمنصات
                  if ((_property.source != null && _property.source!.isNotEmpty) ||
                      _property.advertisingPlatforms.isNotEmpty)
                    RetajSectionCard(
                      title: 'مصدر العقار والمنصات',
                      icon: Icons.campaign_outlined,
                      iconColor: Colors.orange,
                      children: [
                        if (_property.source != null &&
                            _property.source!.isNotEmpty)
                          RetajTextField(
                            readOnly: true,
                            label: 'مصدر العقار',
                            initialValue: _property.source,
                          ),
                        if (_property.advertisingPlatforms.isNotEmpty)
                          _buildPlatformChips(
                            _property.advertisingPlatforms
                                .map((p) => p.nameAr)
                                .toList(),
                          ),
                      ],
                    ),

                  // بيانات المالك
                  if (!shouldMask)
                    RetajSectionCard(
                      title: 'بيانات المالك',
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.purple,
                      children: [
                        if (_property.ownerName != null &&
                            _property.ownerName!.isNotEmpty)
                          RetajTextField(
                            readOnly: true,
                            label: 'اسم المالك',
                            initialValue: _property.ownerName,
                          ),
                        if (_property.ownerPhone != null &&
                            _property.ownerPhone!.isNotEmpty)
                          RetajTextField(
                            readOnly: true,
                            label: 'رقم الهاتف',
                            initialValue: _property.ownerPhone,
                            forceLtr: true,
                          ),
                        if (_property.internalNotes != null &&
                            _property.internalNotes!.isNotEmpty)
                          RetajTextArea(
                            readOnly: true,
                            label: 'ملاحظات الموظفين',
                            initialValue: _property.internalNotes,
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
                              Icon(Icons.lock_person_rounded,
                                  size: 36.sp, color: Colors.red),
                              SizedBox(height: 10.h),
                              Text(
                                'غير مصرح لك برؤية تفاصيل المالك',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'العقار مسجل بواسطة: ${_property.createdByName ?? "---"}',
                                style: TextStyle(
                                    fontSize: 13.sp, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // ملاحظات الإدارة
                  if (isManagerOrAdmin &&
                      _property.managerNotes != null &&
                      _property.managerNotes!.isNotEmpty)
                    RetajSectionCard(
                      title: 'ملاحظات الإدارة',
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.blue,
                      children: [
                        RetajTextArea(
                          readOnly: true,
                          label: 'ملاحظة الإدارة',
                          initialValue: _property.managerNotes,
                          minLines: 2,
                        ),
                      ],
                    ),

                  SizedBox(height: 8.h),

                  // Footer
                  Center(
                    child: Opacity(
                      opacity: 0.55,
                      child: Text(
                        'تمت الإضافة: ${_property.createdAt != null ? DateFormat("yyyy/MM/dd – HH:mm").format(_property.createdAt!) : "---"}\nبواسطة: ${_property.createdByName ?? "---"}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Images
            _property.images.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: PropertyImageHeader(images: _property.images),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 64.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text('لا توجد صور لهذا العقار', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    ],
  ),
),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.home_work_outlined,
                color: AppColors.brandPrimary, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _property.titleAr.isNotEmpty
                      ? _property.titleAr
                      : 'عقار #${_property.propertyCode ?? "---"}',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_property.cityAr} • ${_property.propertyTypeAr}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner || isManagerOrAdmin)
                Tooltip(
                  message: 'مشاركة العقار',
                  child: IconButton(
                    icon: Icon(Icons.ios_share_rounded,
                        color: AppColors.brandPrimary, size: 22.sp),
                    onPressed: () => showPropertyShareSheet(
                      context,
                      _property,
                      canShareInternal: isOwner || isManagerOrAdmin,
                    ),
                  ),
                ),
              if (isOwner || isManagerOrAdmin)
                Tooltip(
                  message: 'تعديل بيانات العقار',
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: Colors.blue.shade700, size: 22.sp),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: widget.cubit,
                            child: PropertyFormScreen(
                              property: _property,
                              userId: widget.currentUserId,
                              userRole: widget.role,
                            ),
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPriceCard(String priceFormatted) {
    final approvedId = '74076467-124a-4142-b821-6096d9fa3f4c';
    final rejectedId = '7345796d-1fd8-462d-b240-7eec15c87e6f';
    final pendingId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
    final statusId = _property.approvalStatusId;

    final (label, color, bg) = switch (statusId) {
      _ when statusId == approvedId => ('تمت الموافقة', const Color(0xFF10B981), const Color(0xFFE6FFF5)),
      _ when statusId == rejectedId => ('تم الرفض', const Color(0xFFEF4444), const Color(0xFFFFEEEE)),
      _ when statusId == pendingId => ('قيد المراجعة', const Color(0xFFF59E0B), const Color(0xFFFFF8E6)),
      _ => ('غير محدد', Colors.grey, Colors.grey.shade100),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12.h, top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السعر',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
                Text(
                  '$priceFormatted ج.م',
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChips(List<String> platforms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('منصات الإعلان:',
            style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children: platforms
              .map((name) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
