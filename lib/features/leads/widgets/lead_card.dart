import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';

/// كارت العميل الشريطي الأفقي — Neon-Minimalist
/// يدعم Hover Scale (1.01) + Neon Border لتجربة ويب احترافية
class LeadCard extends StatefulWidget {
  final LeadModel lead;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _resolveStatusColor(widget.lead.leadStatus ?? 'جديد');
    final String initials = widget.lead.clientName.isNotEmpty
        ? widget.lead.clientName.trim().substring(0, 1).toUpperCase()
        : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: AppConstants.p16, vertical: 5.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.007))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
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
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // ─── 1. Avatar (Initials) ───
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: AppTextStyles.blue20Medium.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // ─── 2. الأساسيات (الاسم والكود) ───
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.lead.clientName,
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 15.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'كود: ${widget.lead.propertyCode ?? "---"}',
                          style: AppTextStyles.tableCellSub.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── 3. تفاصيل فرعية ───
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14.sp, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(widget.lead.city ?? 'غير محدد',
                                style: AppTextStyles.tableCellSub),
                          ],
                        ),
                        if (widget.lead.assignedToName != null) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14.sp, color: AppColors.textSecondary),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  widget.lead.assignedToName!,
                                  style: AppTextStyles.tableCellSub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ─── 4. التاريخ ───
                  Expanded(
                    flex: 1,
                    child: Text(
                      widget.lead.createdAt != null
                          ? DateFormat('yyyy/MM/dd').format(widget.lead.createdAt!)
                          : '',
                      style: AppTextStyles.tableCellSub,
                    ),
                  ),

                  // ─── 5. Status Capsule ───
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.lead.leadStatus ?? 'جديد',
                      style: AppTextStyles.tableCellSub.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // ─── 6. الأزرار (تعديل وحذف) ───
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        color: AppColors.info,
                        onPressed: widget.onEdit,
                      ),
                      SizedBox(width: 8.w),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.brandAccent,
                        onPressed: widget.onDelete,
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
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Icon(icon, size: 18.sp, color: color),
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
