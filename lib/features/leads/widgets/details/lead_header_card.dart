import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/lead_model.dart';

/// بطاقة رأس صفحة تفاصيل العميل — تعرض الاسم والحالة بشكل بارز
/// تحتوي على: اسم العميل كبير في المنتصف + badge الحالة مع لون ديناميكي
class LeadHeaderCard extends StatelessWidget {
  final LeadModel lead;

  const LeadHeaderCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    // نحدد لون الحالة ديناميكياً بناءً على قيمة leadStatus
    final Color statusColor = _resolveStatusColor(lead.leadStatus ?? 'جديد');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── اسم العميل ───
          Text(
            lead.clientName,
            style: AppTextStyles.h1.copyWith(fontSize: 22.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),

          // ─── Badge الحالة — لون الخلفية والحد يعكسان الحالة ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.r20),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              lead.leadStatus ?? 'جديد',
              style: AppTextStyles.chipLabel.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// يحول نص الحالة إلى لون مناسب يعكس مرحلة العميل في pipeline المبيعات
  Color _resolveStatusColor(String status) {
    switch (status) {
      case 'جديد':          return AppColors.info;
      case 'تم التواصل':   return AppColors.warning;
      case 'تفاوض':        return AppColors.brandPrimary;
      case 'تم التعاقد':   return AppColors.success;
      case 'مستبعد':       return AppColors.brandAccent;
      default:             return AppColors.textDisabled;
    }
  }
}
