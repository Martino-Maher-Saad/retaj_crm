import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/whatsapp_share_helper.dart';
import '../../../data/models/property_model.dart';
import 'package:flutter/services.dart';

class PropertyShareSheet extends StatelessWidget {
  final BuildContext originalContext;
  final PropertyModel property;
  final bool canShareInternal;

  const PropertyShareSheet({
    super.key,
    required this.originalContext,
    required this.property,
    required this.canShareInternal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مشاركة العقار',
                style: AppTextStyles.h2.copyWith(fontSize: 22.sp),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 24.sp, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          _buildShareOption(
            context: context,
            icon: Icons.share_rounded,
            title: 'مشاركة للعميل',
            subtitle: 'الصور + السعر + الموقع + الوصف',
            color: AppColors.brandPrimary,
            onTap: () {
              Navigator.of(context).pop();
              WhatsappShareHelper.sharePublic(originalContext, property);
            },
          ),
          
          SizedBox(height: 16.h),
          _buildShareOption(
            context: context,
            icon: Icons.download_rounded,
            title: 'تحميل الصور',
            subtitle: 'حفظ جميع صور العقار',
            color: AppColors.success,
            onTap: () {
              Navigator.of(context).pop();
              WhatsappShareHelper.downloadImages(originalContext, property);
            },
          ),
          
          SizedBox(height: 16.h),
          _buildShareOption(
            context: context,
            icon: Icons.copy_rounded,
            title: 'نسخ التفاصيل',
            subtitle: 'نسخ نص الإعلان للحافظة',
            color: AppColors.textPrimary,
            onTap: () async {
              Navigator.of(context).pop();
              final text = WhatsappShareHelper.buildPublicMessage(property);
              await Clipboard.setData(ClipboardData(text: text));
              if (originalContext.mounted) {
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  const SnackBar(content: Text('تم نسخ التفاصيل للحافظة')),
                );
              }
            },
          ),
          
          if (canShareInternal) ...[
            SizedBox(height: 16.h),
            _buildShareOption(
              context: context,
              icon: Icons.lock_outline_rounded,
              title: 'مشاركة داخلية (للزملاء)',
              subtitle: 'كود + مالك + ملاحظات (واتساب)',
              color: AppColors.info, 
              onTap: () {
                Navigator.of(context).pop();
                WhatsappShareHelper.shareInternal(originalContext, property);
              },
            ),
          ],
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18.sp,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.tableCellSub.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showPropertyShareSheet(BuildContext context, PropertyModel property, {required bool canShareInternal}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PropertyShareSheet(
      originalContext: context,
      property: property,
      canShareInternal: canShareInternal,
    ),
  );
}
