import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../widgets/details/lead_header_card.dart';
import '../widgets/details/lead_copyable_field.dart';
import '../widgets/details/lead_pipeline_indicator.dart';

/// شاشة تفاصيل العميل — تعرض كل بياناته في تنسيق قابل للنسخ
/// تنقسم إلى: بطاقة الهوية، المعلومات الأساسية، تفاصيل الطلب، الوصف، الملاحظات
class LeadDetailsScreen extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailsScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text('تفاصيل العميل', style: AppTextStyles.h2),
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.brandPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. بطاقة الهوية والحالة ───
            LeadHeaderCard(lead: lead),
            SizedBox(height: 24.h),

            // ─── 2. المعلومات الأساسية ───
            _buildSectionTitle("المعلومات الأساسية"),
            LeadCopyableField(label: "الاسم بالكامل", value: lead.clientName),
            // نعرض كل أرقام الهاتف بشكل منفصل مع ترقيم
            ...lead.clientPhone.asMap().entries.map(
              (e) => LeadCopyableField(label: "تيلفون ${e.key + 1}", value: e.value),
            ),
            SizedBox(height: 16.h),

            // ─── 3. تفاصيل الطلب ───
            _buildSectionTitle("تفاصيل الطلب"),
            LeadCopyableField(label: "المدينة", value: lead.city),
            LeadCopyableField(label: "طريقة التواصل", value: lead.communicationChannel),
            LeadCopyableField(label: "كود العقار المهتم به", value: lead.propertyCode),
            LeadCopyableField(label: "المصدر", value: lead.source),
            SizedBox(height: 16.h),

            // ─── 4. وصف الاحتياج (يظهر فقط لو موجود) ───
            if (lead.descLeadNeed != null && lead.descLeadNeed!.isNotEmpty) ...[
              _buildSectionTitle("وصف الاحتياج"),
              LeadCopyableField(label: "الوصف", value: lead.descLeadNeed),
            ],

            // ─── 5. ملاحظات الموظف (تظهر فقط لو موجودة) ───
            if (lead.comment != null && lead.comment!.isNotEmpty) ...[
              _buildSectionTitle("ملاحظات الموظف"),
              LeadCopyableField(label: "الملاحظات", value: lead.comment),
            ],

            SizedBox(height: 32.h),

            // ─── تاريخ الإنشاء (في الأسفل كـ footer) ───
            Center(
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  "تمت الإضافة بتاريخ: ${lead.createdAt != null ? DateFormat('yyyy/MM/dd - hh:mm a').format(lead.createdAt!) : '---'}",
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// عنوان قسم — يُستخدم لتقسيم الحقول بصرياً إلى مجموعات
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, right: 4.w),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.brandPrimary,
          fontSize: 16.sp,
        ),
      ),
    );
  }
}
