import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';

/// كارت العميل — يظهر في قائمة العملاء ويعرض ملخص سريع للعميل
/// يحتوي على: أزرار التحكم (تعديل/حذف)، المعلومات الأساسية، badge الحالة والتاريخ
class LeadCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // نحدد لون الحالة مرة واحدة ونستخدمه في أكتر من مكان
    final Color statusColor = _resolveStatusColor(lead.leadStatus ?? 'جديد');

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.p16,
        vertical: AppConstants.p8,
      ),
      elevation: 0, // Flat design مع حدود بدلاً من ظل
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.r12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      color: AppColors.bgSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.p16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── 1. أزرار التحكم على اليمين ───
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    color: AppColors.info,
                    onPressed: onEdit,
                  ),
                  SizedBox(height: AppConstants.p8),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.brandAccent,
                    onPressed: onDelete,
                  ),
                ],
              ),
              SizedBox(width: AppConstants.p16),

              // ─── 2. المعلومات الأساسية في المنتصف ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم العميل
                    Text(
                      lead.clientName,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppConstants.p4),
                    // كود العقار
                    Row(
                      children: [
                        Icon(Icons.home_work_outlined, size: AppConstants.iconSm, color: AppColors.textSecondary),
                        SizedBox(width: AppConstants.p4),
                        Text('كود: ${lead.propertyCode ?? "---"}', style: AppTextStyles.tableCellSub),
                      ],
                    ),
                    SizedBox(height: AppConstants.p4),
                    // المدينة
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: AppConstants.iconSm, color: AppColors.info),
                        SizedBox(width: AppConstants.p4),
                        Text(lead.city ?? "غير محدد", style: AppTextStyles.cardLocation),
                      ],
                    ),
                    if (lead.assignedToName != null) ...[
                      SizedBox(height: AppConstants.p4),
                      Row(
                        children: [
                          Icon(Icons.person, size: AppConstants.iconSm, color: AppColors.textSecondary),
                          SizedBox(width: AppConstants.p4),
                          Text('المسؤول: ${lead.assignedToName}', style: AppTextStyles.tableCellSub),
                        ],
                      ),
                    ],
                    if (lead.createdByName != null && lead.assignedTo != lead.createdBy) ...[
                      SizedBox(height: AppConstants.p4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: AppConstants.iconSm, color: AppColors.textSecondary),
                          SizedBox(width: AppConstants.p4),
                          Text('المُضيف: ${lead.createdByName}', style: AppTextStyles.tableCellSub),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ─── 3. الحالة والتاريخ على اليسار ───
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Badge الحالة
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.p8, vertical: AppConstants.p4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.r8),
                    ),
                    child: Text(
                      lead.leadStatus ?? 'جديد',
                      style: AppTextStyles.chipLabel.copyWith(color: statusColor),
                    ),
                  ),
                  SizedBox(height: AppConstants.p16),
                  // تاريخ الإضافة
                  Text(
                    lead.createdAt != null
                        ? DateFormat('yyyy/MM/dd').format(lead.createdAt!)
                        : '',
                    style: AppTextStyles.tableCellSub.copyWith(fontSize: 10.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر تحكم صغير موحد الشكل (تعديل / حذف)
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppConstants.r8),
      child: Container(
        padding: EdgeInsets.all(AppConstants.p8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.r8),
        ),
        child: Icon(icon, size: AppConstants.iconMd, color: color),
      ),
    );
  }

  /// يحول نص الحالة إلى لون مناسب يعكس مرحلة العميل في pipeline
  Color _resolveStatusColor(String status) {
    switch (status) {
      case 'جديد':         return AppColors.info;
      case 'تم التواصل':  return AppColors.warning;
      case 'تفاوض':       return AppColors.brandPrimary;
      case 'تم التعاقد':  return AppColors.success;
      case 'مستبعد':      return AppColors.brandAccent;
      default:            return AppColors.textDisabled;
    }
  }
}
