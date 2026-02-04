import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';


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
        padding: EdgeInsets.all(AppConstants.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. كارت الهوية والحالة
            _buildHeaderCard(),

            SizedBox(height: AppConstants.p16),

            // 2. كارت أرقام التواصل
            _buildSectionTitle("أرقام التواصل"),
            _buildContactCard(),

            SizedBox(height: AppConstants.p16),

            // 3. كارت تفاصيل الطلب
            _buildSectionTitle("تفاصيل الطلب"),
            _buildInfoGrid(),

            SizedBox(height: AppConstants.p16),

            // 4. الاحتياج والملاحظات
            if (lead.descLeadNeed != null && lead.descLeadNeed!.isNotEmpty) ...[
              _buildSectionTitle("وصف الاحتياج"),
              _buildLongTextCard(lead.descLeadNeed!),
              SizedBox(height: AppConstants.p16),
            ],

            if (lead.comment != null && lead.comment!.isNotEmpty) ...[
              _buildSectionTitle("ملاحظات إضافية"),
              _buildLongTextCard(lead.comment!, isComment: true),
            ],

            SizedBox(height: AppConstants.p32),

            // تاريخ الإنشاء في الأسفل
            Center(
              child: Text(
                "تمت الإضافة بتاريخ: ${lead.createdAt != null ? DateFormat('yyyy/MM/dd - hh:mm a').format(lead.createdAt!) : '---'}",
                style: AppTextStyles.tableCellSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- [ UI Helper Components ] ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.p8, right: AppConstants.p4),
      child: Text(title, style: AppTextStyles.h3),
    );
  }

  Widget _buildHeaderCard() {
    Color statusColor = _getStatusColor(lead.leadStatus ?? 'جديد');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.p24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(lead.clientName, style: AppTextStyles.h1, textAlign: TextAlign.center),
          SizedBox(height: AppConstants.p8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.p16, vertical: AppConstants.p4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.r20),
              border: Border.all(color: statusColor),
            ),
            child: Text(lead.leadStatus ?? 'جديد', style: AppTextStyles.chipLabel.copyWith(color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: lead.clientPhone.map((phone) => ListTile(
          leading: const Icon(Icons.phone_android, color: AppColors.brandPrimary),
          title: Text(phone, style: AppTextStyles.tableCellMain),
          trailing: const Icon(Icons.call, color: AppColors.success),
          onTap: () { /* أضف منطق الاتصال هنا */ },
        )).toList(),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: EdgeInsets.all(AppConstants.p16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_outlined, "المدينة", lead.city ?? "---"),
          const Divider(color: AppColors.borderSubtle),
          _buildInfoRow(Icons.home_work_outlined, "كود العقار", lead.propertyCode ?? "---"),
          const Divider(color: AppColors.borderSubtle),
          _buildInfoRow(Icons.campaign_outlined, "المصدر", lead.source ?? "---"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.p8),
      child: Row(
        children: [
          Icon(icon, size: AppConstants.iconMd, color: AppColors.brandPrimaryLight),
          SizedBox(width: AppConstants.p16),
          Text("$label:", style: AppTextStyles.tableCellSub),
          const Spacer(),
          Text(value, style: AppTextStyles.tableCellMain),
        ],
      ),
    );
  }

  Widget _buildLongTextCard(String text, {bool isComment = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.p16),
      decoration: BoxDecoration(
        color: isComment ? AppColors.brandPrimarySurface.withOpacity(0.3) : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.r12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(text, style: AppTextStyles.inputText),
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