import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';

class LeadCard extends StatefulWidget {
  final LeadModel lead;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.role,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  bool _isHovering = false;

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم نسخ رقم الهاتف"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _resolveStatusColor(widget.lead.leadStatus ?? 'جديد');
    final String initials = widget.lead.clientName.isNotEmpty
        ? widget.lead.clientName.trim().substring(0, 1).toUpperCase()
        : '?';

    final String formattedDate = widget.lead.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(widget.lead.createdAt!)
        : 'غير محدد';

    final bool isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.01))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r), // Scaled up
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
          border: Border.all(
            color: _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.35)
                : AppColors.borderSubtle,
            width: _isHovering ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h), // Scaled up
              child: Row(
                children: [
                  // ─── 1. Avatar ───
                  CircleAvatar(
                    radius: 28.r, // Scaled up
                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.sp, // Scaled up
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),

                  // ─── 2. العميل والهاتف ───
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.lead.clientName,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 18.sp, // Scaled up
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        if (widget.lead.clientPhone.isNotEmpty)
                          InkWell(
                            onTap: () => _copyPhone(widget.lead.clientPhone.first),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_outlined, size: 16.sp, color: AppColors.brandPrimary),
                                SizedBox(width: 4.w),
                                Text(
                                  widget.lead.clientPhone.first,
                                  style: AppTextStyles.tableCellMain.copyWith(
                                    color: AppColors.brandPrimary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.copy, size: 14.sp, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ─── 3. الطلب (نوع العقار والموقع) ───
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home_work_outlined, size: 18.sp, color: AppColors.textSecondary),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "${widget.lead.listingType ?? 'غير محدد'} — ${widget.lead.propertyType ?? 'غير محدد'}",
                                style: AppTextStyles.tableCellSub.copyWith(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18.sp, color: AppColors.textSecondary),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                "${widget.lead.governorate ?? 'غير محدد'} — ${widget.lead.city ?? 'غير محدد'}",
                                style: AppTextStyles.tableCellSub.copyWith(fontSize: 14.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── 4. المنصة واسم الموظف والتاريخ ───
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.campaign_outlined, size: 16.sp, color: AppColors.info),
                            SizedBox(width: 6.w),
                            Text(widget.lead.platform ?? 'غير محدد', style: AppTextStyles.tableCellSub.copyWith(fontSize: 13.sp)),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.person_add_alt_1_outlined, size: 16.sp, color: AppColors.brandAccent),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                widget.lead.createdByName ?? 'غير محدد',
                                style: AppTextStyles.tableCellSub.copyWith(fontSize: 13.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16.sp, color: AppColors.textDisabled),
                            SizedBox(width: 6.w),
                            Text(formattedDate, style: AppTextStyles.tableCellSub.copyWith(fontSize: 12.sp)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── 5. الحالة والأزرار ───
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Text(
                          widget.lead.leadStatus ?? 'جديد',
                          style: AppTextStyles.tableCellSub.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: Icons.edit_rounded,
                            color: AppColors.info,
                            onPressed: widget.onEdit,
                          ),
                          if (isManagerOrAdmin) ...[
                            SizedBox(width: 10.w),
                            _buildActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.brandAccent,
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Icon(icon, size: 22.sp, color: color), // Scaled up
      ),
    );
  }

  Color _resolveStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return AppColors.info;
      case 'تم التواصل':
        return AppColors.warning;
      case 'تفاوض':
        return AppColors.brandPrimary;
      case 'تم التعاقد':
        return AppColors.success;
      case 'مستبعد':
        return AppColors.brandAccent;
      default:
        return AppColors.textDisabled;
    }
  }
}
