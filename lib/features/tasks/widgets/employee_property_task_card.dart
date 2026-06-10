import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/property_tasks_cubit.dart';
import '../../properties/screens/property_details_screen.dart';
import '../../properties/cubit/properties_cubit.dart';

class EmployeePropertyTaskCard extends StatefulWidget {
  final PropertyModel property;
  final String role;
  final String currentUserId;

  const EmployeePropertyTaskCard({super.key, required this.property, required this.role, required this.currentUserId});

  @override
  State<EmployeePropertyTaskCard> createState() =>
      _EmployeePropertyTaskCardState();
}

class _EmployeePropertyTaskCardState extends State<EmployeePropertyTaskCard> {
  final dataManager = di.sl<StaticDataManager>();
  final Set<String> _selectedPlatformsToPublish = {};
  bool _isSubmitting = false;
  bool _isDescExpanded = false;

  void _submitPublishAction() async {
    setState(() => _isSubmitting = true);

    final platformIds = _selectedPlatformsToPublish
        .map((name) => dataManager.getIdByName('advertising_platform', name))
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (platformIds.isEmpty) {
      setState(() => _isSubmitting = false);
      return;
    }

    final publishedId = '70bb0089-736b-4607-951d-916fbcc1cc07';

    try {
      await context.read<PropertyTasksCubit>().markAsPublished(
            propertyId: widget.property.id,
            approvalStatusId: publishedId,
            publishedPlatformIds: platformIds,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _submitResubmitAction() async {
    setState(() => _isSubmitting = true);
    final approvedId = '74076467-124a-4142-b821-6096d9fa3f4c';
    try {
      await context.read<PropertyTasksCubit>().resubmitRejectedProperty(
            propertyId: widget.property.id,
            approvedStatusId: approvedId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _submitDeleteAction() async {
    setState(() => _isSubmitting = true);
    try {
      await context
          .read<PropertyTasksCubit>()
          .deleteFullProperty(widget.property.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.property.createdAt != null
        ? DateFormat('yyyy/MM/dd – hh:mm a').format(widget.property.createdAt!)
        : 'غير محدد';

    final approvedId  = '74076467-124a-4142-b821-6096d9fa3f4c';
    final rejectedId  = '7345796d-1fd8-462d-b240-7eec15c87e6f';
    final pendingId   = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
    final currentStatus = widget.property.approvalStatusId;

    final unpublishedPlatforms = widget.property.advertisingPlatforms
        .where((p) => !p.isPublished)
        .toList();

    // ─── Status Badge ───
    final (statusLabel, statusColor, statusBg, statusIcon) = switch (currentStatus) {
      _ when currentStatus == pendingId   => ('قيد المراجعة',   const Color(0xFFF59E0B), const Color(0xFFFFF8E6), Icons.hourglass_top_rounded),
      _ when currentStatus == approvedId  => ('تمت الموافقة',  const Color(0xFF10B981), const Color(0xFFE6FFF5), Icons.check_circle_outline_rounded),
      _ when currentStatus == rejectedId  => ('تم الرفض',      const Color(0xFFEF4444), const Color(0xFFFFEEEE), Icons.cancel_outlined),
      _                                   => ('غير محدد',       Colors.grey,             Colors.grey.shade100,    Icons.help_outline),
    };

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      elevation: 3,
      shadowColor: statusColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Status + Code ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(18.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 24.sp, color: statusColor),
                      SizedBox(width: 6.w),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.property.propertyCode != null)
                  Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 24.sp, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(
                        widget.property.propertyCode!,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ─── Body ───
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نوع العقار + نوع الإعلان
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${widget.property.listingTypeAr} — ${widget.property.propertyTypeAr}",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Grid of info
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Wrap(
                    spacing: 12.w,
                    runSpacing: 16.h,
                    children: [
                      // السعر
                      _infoCol(
                        Icons.payments_outlined,
                        'السعر',
                        "${widget.property.price.toCurrency()} ج",
                        valueColor: const Color(0xFF10B981),
                      ),
                      // الموقع
                      _infoCol(
                        Icons.location_on_outlined,
                        'الموقع',
                        "${widget.property.governorateAr}",
                      ),
                      if (widget.property.createdByName != null)
                        _infoCol(
                          Icons.person_outline_rounded,
                          'المُضيف',
                          widget.property.createdByName!,
                        ),
                      _infoCol(
                        Icons.calendar_today_outlined,
                        'تاريخ الإضافة',
                        dateStr.split(' – ').first,
                      ),
                    ],
                  ),
                ),

                // وصف العقار
                if (widget.property.descAr.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, size: 24.sp, color: Colors.grey[600]),
                          SizedBox(width: 6.w),
                          Text(
                            "وصف العقار",
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.property.descAr,
                              style: TextStyle(fontSize: 24.sp, height: 1.6, color: Colors.black87),
                              maxLines: _isDescExpanded ? null : 3,
                              overflow: _isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                            if (widget.property.descAr.length > 120 || widget.property.descAr.split('\n').length > 3)
                              GestureDetector(
                                onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 6.h),
                                  child: Text(
                                    _isDescExpanded ? 'إخفاء ▲' : 'اقرأ المزيد ▼',
                                    style: TextStyle(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24.sp,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // ملاحظات المدير (تحذير)
                if (widget.property.managerNotes != null &&
                    widget.property.managerNotes!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.orange.shade300, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ملاحظة الإدارة / سبب الرفض",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24.sp,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                widget.property.managerNotes!,
                                style: TextStyle(fontSize: 24.sp, color: Colors.black87, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => di.sl<PropertiesCubit>(),
                            child: PropertyDetailsScreen(property: widget.property, role: widget.role, currentUserId: widget.currentUserId),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    icon: Icon(Icons.info_outline, color: Colors.white, size: 24.sp),
                    label: Text(
                      'عرض التفاصيل',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // ─── Actions ───
                if (currentStatus == approvedId) ...[
                  if (unpublishedPlatforms.isNotEmpty) ...[
                    Text(
                      "تأكيد النشر على المنصات المطلوبة:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: unpublishedPlatforms.map((p) {
                        final isSelected = _selectedPlatformsToPublish.contains(p.nameAr);
                        return FilterChip(
                          label: Text(p.nameAr, style: TextStyle(fontSize: 24.sp)),
                          selected: isSelected,
                          selectedColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.brandPrimary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.brandPrimary : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedPlatformsToPublish.add(p.nameAr);
                              } else {
                                _selectedPlatformsToPublish.remove(p.nameAr);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isSubmitting || _selectedPlatformsToPublish.length != unpublishedPlatforms.length)
                            ? null
                            : _submitPublishAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        icon: _isSubmitting
                            ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Icon(Icons.check_circle_outline, color: Colors.white, size: 24.sp),
                        label: Text(
                          _isSubmitting ? 'جارٍ الحفظ...' : 'تأكيد النشر',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.white),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFF5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, color: Colors.green, size: 24.sp),
                          SizedBox(width: 8.w),
                          Text(
                            "تم النشر على جميع المنصات",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (currentStatus == rejectedId) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _submitDeleteAction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          icon: Icon(Icons.delete_outline_rounded, size: 24.sp),
                          label: Text("مسح نهائي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitResubmitAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          icon: _isSubmitting
                              ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Icon(Icons.refresh_rounded, color: Colors.white, size: 24.sp),
                          label: Text("إعادة النشر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(IconData icon, String label, String value, {
    Color? valueColor,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 100.w) / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.brandPrimary.withValues(alpha: 0.7)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[700], fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


