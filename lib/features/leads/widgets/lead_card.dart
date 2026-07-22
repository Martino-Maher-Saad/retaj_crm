import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/lead_model.dart';
import '../cubit/leads_cubit.dart';

class LeadCard extends StatefulWidget {
  final LeadModel lead;
  final String role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;

  const LeadCard({
    super.key,
    required this.lead,
    required this.role,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onRestore,
    required this.onTap,
    this.onPinToggle,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  bool _isHovering = false;
  int _duplicateCount = 0;
  bool _isLoadingDuplicates = false;
  List<LeadModel> _duplicates = [];

  @override
  void initState() {
    super.initState();
    _checkDuplicates();
  }

  void _checkDuplicates() async {
    final bool isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';
    if (!isManagerOrAdmin || widget.lead.phones.isEmpty) return;

    if (mounted) setState(() => _isLoadingDuplicates = true);
    
    try {
      final phones = widget.lead.phones.map((e) => e.phoneNumber).toList();
      final duplicates = await context.read<LeadCubit>().checkDuplicates(phones);
      // count includes the lead itself, so we check if duplicates > 1
      if (mounted) {
        setState(() {
          _duplicateCount = duplicates.length;
          _duplicates = duplicates;
          _isLoadingDuplicates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDuplicates = false);
    }
  }

  void _showDuplicatesModal() {
    if (_duplicates.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('التكرارات لهذا العميل', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  itemCount: _duplicates.length,
                  itemBuilder: (ctx, i) {
                    final l = _duplicates[i];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10.h),
                      child: ListTile(
                        title: Text(l.clientName),
                        subtitle: Text(l.phones.isNotEmpty ? l.phones.first.phoneNumber : 'بدون هاتف'),
                        trailing: Text(l.leadStatus ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LeadPhoneModel? get _primaryPhone {
    if (widget.lead.phones.isEmpty) return null;
    try {
      return widget.lead.phones.firstWhere((p) => p.isPrimary);
    } catch (_) {
      return widget.lead.phones.first;
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رقم الهاتف 📋'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'جديد':
        return const Color(0xFF3B82F6);
      case 'تم التواصل':
        return const Color(0xFF8B5CF6);
      case 'تفاوض':
        return AppColors.brandPrimary;
      case 'تم التعاقد':
        return const Color(0xFF10B981);
      case 'مستبعد':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get _initials {
    final parts = widget.lead.clientName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final bool isManagerOrAdmin =
        widget.role == 'manager' || widget.role == 'admin';
    final Color sColor = _statusColor(widget.lead.leadStatus);
    final bool hasPlatform = widget.lead.platformId != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.005))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: !hasPlatform
                ? Colors.red.withValues(alpha: 0.3)
                : _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
            width: _isHovering || !hasPlatform ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovering
                  ? AppColors.brandPrimary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovering ? 24 : 14,
              spreadRadius: _isHovering ? 2 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.lead.isPinned)
                    Positioned(
                      top: -30.h,
                      right: -30.w,
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          color: AppColors.brandPrimary,
                          size: 20.sp,
                        ),
                      ),
                    ),

                  if (_duplicateCount > 1)
                    Positioned(
                      top: -30.h,
                      left: -20.w,
                      child: GestureDetector(
                        onTap: _showDuplicatesModal,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, color: Colors.white, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text("مكرر $_duplicateCount مرات", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── الصف الأول: Avatar + الاسم + الهاتف + الأزرار ───
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          _buildAvatar(sColor),
                          SizedBox(width: 18.w),

                          // الاسم + الهاتف
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.lead.clientName,
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                if (_primaryPhone != null)
                                  GestureDetector(
                                    onTap: () =>
                                        _copyPhone(_primaryPhone!.phoneNumber),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 17.sp,
                                          color: AppColors.brandPrimary,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          _primaryPhone!.phoneNumber,
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brandPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 14.sp,
                                          color: AppColors.brandPrimary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    'لا يوجد رقم هاتف',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // أزرار التحكم
                          _buildActions(isManagerOrAdmin),
                        ],
                      ),

                      SizedBox(height: 16.h),
                      Divider(height: 1, color: const Color(0xFFF3F4F6)),
                      SizedBox(height: 14.h),

                      // ─── الصف الثاني: الحالة + المنصة + التاريخ ───
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 8.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // حالة العميل
                          _buildBadge(
                            label: widget.lead.leadStatus ?? 'غير محدد',
                            color: sColor,
                            icon: Icons.circle,
                            iconSize: 8,
                          ),

                          // منصة المصدر
                          if (hasPlatform)
                            _buildBadge(
                              label: widget.lead.platform!,
                              color: const Color(0xFF6366F1),
                              icon: Icons.campaign_outlined,
                              iconSize: 15,
                            )
                          else
                            _buildBadge(
                              label: 'منصة غير محددة',
                              color: Colors.red,
                              icon: Icons.warning_amber_rounded,
                              iconSize: 15,
                              isOutlined: true,
                            ),

                          // تاريخ الإنشاء
                          if (widget.lead.createdAt != null)
                            _buildBadge(
                              label:
                                  'إنشاء: ${DateFormat('EEE dd/MM/yyyy – hh:mm a', 'ar').format(widget.lead.createdAt!)}',
                              color: AppColors.info,
                              icon: Icons.calendar_today_outlined,
                              iconSize: 14,
                              isOutlined: false,
                            ),

                          // آخر تعديل للحالة
                          _buildBadge(
                            label: widget.lead.updatedAt != null
                                ? 'آخر تعديل: ${DateFormat('EEE dd/MM/yyyy – hh:mm a', 'ar').format(widget.lead.updatedAt!)}'
                                : 'لم يتم تعديل الحالة',
                            color: widget.lead.updatedAt != null
                                ? AppColors.warning
                                : AppColors.textSecondary,
                            icon: widget.lead.updatedAt != null
                                ? Icons.update_rounded
                                : Icons.history_toggle_off_rounded,
                            iconSize: 14,
                            isOutlined: widget.lead.updatedAt == null,
                          ),

                          // الموظف المسؤول
                          if (isManagerOrAdmin &&
                              widget.lead.assignedToName != null)
                            _buildBadge(
                              label: widget.lead.assignedToName!,
                              color: AppColors.brandPrimary,
                              icon: Icons.person_outline_rounded,
                              iconSize: 15,
                              isOutlined: true,
                            ),
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

  Widget _buildAvatar(Color sColor) {
    return Container(
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sColor.withValues(alpha: 0.1),
        border: Border.all(color: sColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: sColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
    required double iconSize,
    bool isOutlined = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: color.withValues(alpha: isOutlined ? 0.5 : 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isManagerOrAdmin) {
    return Column(
      children: [
        if (widget.onPinToggle != null) ...[
          _actionBtn(
            widget.lead.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            widget.lead.isPinned ? AppColors.brandPrimary : Colors.grey,
            widget.onPinToggle!,
            widget.lead.isPinned ? 'إلغاء التثبيت' : 'تثبيت',
          ),
          SizedBox(height: 8.h),
        ],
        if (widget.onEdit != null)
          _actionBtn(Icons.edit_rounded, AppColors.info, widget.onEdit!, 'تعديل'),

        if (widget.onRestore != null) ...[
          SizedBox(height: 8.h),
          _actionBtn(Icons.restore_page_outlined, Colors.green, widget.onRestore!, 'استعادة'),
        ],
        if (widget.onDelete != null) ...[
          SizedBox(height: 8.h),
          _actionBtn(
            Icons.delete_outline_rounded,
            AppColors.brandAccent,
            widget.onDelete!,
            'حذف',
          ),
        ],
      ],
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(9.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
      ),
    );
  }
}
