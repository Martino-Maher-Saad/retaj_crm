import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/property_share_model.dart';
import '../screens/property_details_screen.dart';
import '../cubit/properties_cubit.dart';
import '../../../core/di/injection_container.dart' as di;

class PropertyShareCard extends StatefulWidget {
  final PropertyShareModel share;
  final bool isInbox;
  final VoidCallback onDelete;
  final String currentUserId;

  const PropertyShareCard({
    super.key,
    required this.share,
    required this.isInbox,
    required this.onDelete,
    required this.currentUserId,
  });

  @override
  State<PropertyShareCard> createState() => _PropertyShareCardState();
}

class _PropertyShareCardState extends State<PropertyShareCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final otherPerson = widget.isInbox ? widget.share.sender : widget.share.receiver;
    final otherName = otherPerson != null
        ? "${otherPerson.firstName} ${otherPerson.lastName}".trim()
        : "غير محدد";

    final dateStr = DateFormat('yyyy/MM/dd – hh:mm a').format(widget.share.createdAt);
    final property = widget.share.property;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.01))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
            width: _isHovering ? 2.0 : 1.5,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (property != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<PropertiesCubit>(),
                      child: PropertyDetailsScreen(
                        property: property,
                        currentUserId: widget.currentUserId,
                        role: 'sales', // Share viewing usually implies limited or normal access
                      ),
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(22.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: من/إلى + التاريخ ───
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: widget.isInbox
                        ? AppColors.info.withValues(alpha: 0.08)
                        : AppColors.brandPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22.r),
                      topRight: Radius.circular(22.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isInbox ? Icons.call_received_rounded : Icons.call_made_rounded,
                        color: widget.isInbox ? AppColors.info : AppColors.brandPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          widget.isInbox ? "مُرسلة من: $otherName" : "مُرسلة إلى: $otherName",
                          style: AppTextStyles.tableCellSub.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: widget.isInbox ? AppColors.info : AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),

                // ─── بيانات العقار ───
                if (property != null)
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // نوع العقار + نوع الإعلان
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                "${property.listingTypeAr} — ${property.propertyTypeAr}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "#${property.propertyCode ?? '---'}",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // السعر
                        Text(
                          "${property.price.toCurrency()} ج.م",
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // الموقع
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18.sp, color: Colors.grey),
                            SizedBox(width: 6.w),
                            Text(
                              "${property.governorateAr} — ${property.cityAr}",
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey[800]),
                            ),
                          ],
                        ),

                        // اسم المضيف
                        if (property.createdByName != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 18.sp, color: Colors.grey),
                              SizedBox(width: 6.w),
                              Text(
                                "أضافه: ${property.createdByName}",
                                style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: 16.h),

                        // وصف العقار (مختصر)
                        if (property.descAr.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              property.descAr,
                              style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.6),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(24.h),
                    child: Center(
                      child: Text(
                        "تم حذف هذا العقار من النظام",
                        style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                      ),
                    ),
                  ),

                // ─── ملاحظات المُرسِل ───
                if (widget.share.notes != null && widget.share.notes!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded, size: 18.sp, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            widget.share.notes!,
                            style: TextStyle(fontSize: 15.sp, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── زرار الإزالة ───
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20.sp),
                        label: Text(
                          "إزالة من القائمة",
                          style: TextStyle(color: Colors.red, fontSize: 15.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
