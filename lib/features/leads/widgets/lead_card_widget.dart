import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
// استيراد الملفات الخاصة بك (تأكد من تعديل المسارات حسب مشروعك)


class LeadCardWidget extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const LeadCardWidget({
    super.key,
    required this.lead,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد لون الحالة بناءً على المسميات العربية
    Color statusColor = _getStatusColor(lead.leadStatus ?? 'جديد');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.p16, vertical: AppConstants.p8),
      elevation: 0, // اعتماد تصميم Flat مع حدود خفيفة كما في ملف الـ Colors
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
            crossAxisAlignment: CrossAxisAlignment.center, // توسيط عمودي للأزرار مع النصوص
            children: [
              // 1. أزرار التحكم على اليمين (Action Buttons)
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

              // 2. المعلومات الأساسية (Main Content)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.clientName,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppConstants.p4),
                    Row(
                      children: [
                        Icon(Icons.home_work_outlined, size: AppConstants.iconSm, color: AppColors.textSecondary),
                        SizedBox(width: AppConstants.p4),
                        Text(
                          'كود: ${lead.propertyCode ?? "---"}',
                          style: AppTextStyles.tableCellSub,
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.p4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: AppConstants.iconSm, color: AppColors.info),
                        SizedBox(width: AppConstants.p4),
                        Text(
                          lead.city ?? "غير محدد",
                          style: AppTextStyles.cardLocation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. التاج والتاريخ (Status & Date)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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

  // مكوّن صغير للأزرار لضمان توحيد الشكل والـ Padding
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'جديد': return AppColors.info;
      case 'تم التواصل': return AppColors.warning;
      case 'تفاوض': return AppColors.brandPrimary;
      case 'تم التعاقد': return AppColors.success;
      case 'مستبعد': return AppColors.brandAccent;
      default: return AppColors.textDisabled;
    }
  }
}