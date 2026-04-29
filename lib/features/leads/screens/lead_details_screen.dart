import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../cubit/leads_cubit.dart';
import '../widgets/details/lead_copyable_field.dart';

class LeadDetailsScreen extends StatefulWidget {
  final LeadModel lead;

  const LeadDetailsScreen({super.key, required this.lead});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;
    context.read<LeadCubit>().addComment(widget.lead.id!, _commentController.text.trim());
    _commentController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إضافة التعليق بنجاح"), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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
        padding: EdgeInsets.all(24.w), // Scaled up
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. المعلومات الأساسية ───
            _buildSectionTitle("المعلومات الأساسية"),
            LeadCopyableField(label: "الاسم بالكامل", value: widget.lead.clientName),
            ...widget.lead.clientPhone.asMap().entries.map(
              (e) => LeadCopyableField(label: "تيلفون ${e.key + 1}", value: e.value),
            ),
            SizedBox(height: 24.h), // Scaled up

            // ─── 2. تفاصيل الطلب ───
            _buildSectionTitle("تفاصيل الطلب"),
            LeadCopyableField(label: "المنصة", value: widget.lead.platform),
            LeadCopyableField(label: "طريقة التواصل", value: widget.lead.communicationChannel),
            LeadCopyableField(label: "نوع الإعلان", value: widget.lead.listingType),
            LeadCopyableField(label: "نوع العقار", value: widget.lead.propertyType),
            LeadCopyableField(label: "المحافظة", value: widget.lead.governorate),
            LeadCopyableField(label: "المدينة", value: widget.lead.city),
            LeadCopyableField(label: "كود العقار المهتم به", value: widget.lead.propertyCode),
            LeadCopyableField(label: "تخصيص لموظف", value: widget.lead.assignedToName),
            SizedBox(height: 24.h), // Scaled up

            // ─── 3. الوصف والميزانية ───
            if (widget.lead.descLeadNeed != null && widget.lead.descLeadNeed!.isNotEmpty) ...[
              _buildSectionTitle("وصف الاحتياج"),
              LeadCopyableField(label: "الوصف", value: widget.lead.descLeadNeed, isLong: true),
              SizedBox(height: 12.h),
            ],
            if (widget.lead.budgetFrom != null || widget.lead.budgetTo != null) ...[
              _buildSectionTitle("الميزانية"),
              LeadCopyableField(label: "من", value: widget.lead.budgetFrom?.toString()),
              LeadCopyableField(label: "إلى", value: widget.lead.budgetTo?.toString()),
              SizedBox(height: 12.h),
            ],

            // ─── 4. التعليقات / السجل (History) ───
            _buildSectionTitle("سجل التعليقات"),
            if (widget.lead.history.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.lead.history.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w), // Scaled up
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      widget.lead.history[index],
                      style: TextStyle(fontSize: 15.sp, height: 1.5),
                    ),
                  );
                },
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text("لا توجد تعليقات حتى الآن", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
              ),

            // إضافة تعليق جديد
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "أضف تعليقاً جديداً...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                SizedBox(width: 12.w),
                InkWell(
                  onTap: _submitComment,
                  child: CircleAvatar(
                    radius: 26.r,
                    backgroundColor: AppColors.brandPrimary,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40.h),

            // ─── تاريخ الإنشاء (في الأسفل كـ footer) ───
            Center(
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  "تمت الإضافة بتاريخ: ${widget.lead.createdAt != null ? DateFormat('yyyy/MM/dd - HH:mm').format(widget.lead.createdAt!) : '---'}\nبواسطة: ${widget.lead.createdByName ?? '---'}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  /// عنوان قسم — يُستخدم لتقسيم الحقول بصرياً إلى مجموعات
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h, right: 4.w),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.brandPrimary,
          fontSize: 20.sp, // Scaled up
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
