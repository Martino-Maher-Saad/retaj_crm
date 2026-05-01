import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
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
    final Color statusColor =
        _resolveStatusColor(widget.lead.leadStatus ?? 'جديد');
    final bool isManagerOrAdmin =
        widget.role == 'manager' || widget.role == 'admin';

    final String name = widget.lead.clientName.trim();
    final List<String> parts =
        name.split(' ').where((p) => p.isNotEmpty).toList();
    final String initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts.isNotEmpty && parts[0].isNotEmpty
            ? parts[0][0].toUpperCase()
            : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.005))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : const Color(0xFFEAEAF0),
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
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── أزرار تعديل / حذف ───
                  _buildActionButtons(isManagerOrAdmin),
                  SizedBox(width: 20.w),

                  // ─── Status + الاهتمام ───
                  SizedBox(
                    width: 200.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(statusColor),
                        SizedBox(height: 14.h),
                        Text(
                          'الاهتمام',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          '${widget.lead.propertyType ?? 'غير محدد'} — ${widget.lead.city ?? widget.lead.governorate ?? 'غير محدد'}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: const Color(0xFF333344),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.lead.listingType != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            widget.lead.listingType!,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: const Color(0xFF888899),
                            ),
                          ),
                        ],
                        if (widget.lead.budgetFrom != null || widget.lead.budgetTo != null) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(Icons.attach_money_rounded,
                                  size: 16.sp,
                                  color: AppColors.success),
                              SizedBox(width: 3.w),
                              Text(
                                widget.lead.budgetFrom != null && widget.lead.budgetTo != null
                                    ? '${widget.lead.budgetFrom} - ${widget.lead.budgetTo}'
                                    : '${widget.lead.budgetFrom ?? widget.lead.budgetTo}',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ─── Divider عمودي ───
                  Container(
                    width: 1.2,
                    height: 70.h,
                    color: const Color(0xFFEEEEF5),
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                  ),

                  // ─── اسم العميل + رقمه + المنصة ───
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.lead.clientName,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 10.h),
                        if (widget.lead.clientPhone.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _copyPhone(widget.lead.clientPhone.first),
                                child: Text(
                                  widget.lead.clientPhone.first,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: AppColors.brandPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.brandPrimary
                                        .withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.phone_outlined,
                                size: 18.sp,
                                color: const Color(0xFFAAAAAA),
                              ),
                            ],
                          ),
                        if (widget.lead.platform != null) ...[
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.lead.platform!,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: const Color(0xFFAAAAAA),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.campaign_outlined,
                                size: 17.sp,
                                color: const Color(0xFFCCCCDD),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 20.w),

                  // ─── Avatar ───
                  _buildAvatar(initials),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Container(
      width: 70.r,
      height: 70.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.brandPrimary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color statusColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.r,
            height: 9.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            widget.lead.leadStatus ?? 'جديد',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isManagerOrAdmin) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: 'تعديل',
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.edit_rounded,
                  size: 22.sp, color: AppColors.info),
            ),
          ),
        ),
        if (isManagerOrAdmin) ...[
          SizedBox(height: 10.h),
          Tooltip(
            message: 'حذف',
            child: InkWell(
              onTap: widget.onDelete,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 22.sp, color: AppColors.brandAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _resolveStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return AppColors.info;
      case 'تم التواصل':
        return const Color(0xFF8B5CF6);
      case 'تفاوض':
        return AppColors.brandPrimary;
      case 'تم التعاقد':
        return AppColors.success;
      case 'مستبعد':
        return AppColors.brandAccent;
      default:
        return const Color(0xFFAAAAAA);
    }
  }
}
