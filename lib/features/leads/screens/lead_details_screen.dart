import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/details/lead_copyable_field.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId; // نمرر ID فقط ونجلب أحدث نسخة من الـ State

  const LeadDetailsScreen({super.key, required this.leadId});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;  // loading state للتعليق

  // كام كومنت بيتظهروا افتراضياً
  static const int _initialCommentsCount = 3;
  bool _showAllComments = false;

  void _submitComment(LeadModel lead) {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isAddingComment) return;
    setState(() => _isAddingComment = true);
    _commentController.clear();
    context.read<LeadCubit>().addComment(lead.id!, text);
    // الرسالة بتظهر في الـ BlocConsumer listener بعد التأكيد الفعلي من السيرفر
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// نجيب أحدث نسخة من الـ lead من الـ State مباشرةً
  LeadModel? _getLatestLead(LeadState state) {
    if (state is LeadLoaded) {
      try {
        return state.allLeads.firstWhere((l) => l.id == widget.leadId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadCubit, LeadState>(
      listener: (context, state) {
        // هنا بس نعرض رسائل النجاح/الفشل بعد التأكيد الفعلي
        if (_isAddingComment) {
          if (state is LeadLoaded) {
            setState(() => _isAddingComment = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إضافة التعليق بنجاح'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is LeadError) {
            setState(() => _isAddingComment = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ فشل إضافة التعليق: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final lead = _getLatestLead(state);

        if (lead == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. المعلومات الأساسية ───
                _buildSectionTitle("المعلومات الأساسية"),
                LeadCopyableField(label: "الاسم بالكامل", value: lead.clientName),
                ...lead.clientPhone.asMap().entries.map(
                  (e) => LeadCopyableField(label: "تيلفون ${e.key + 1}", value: e.value),
                ),
                SizedBox(height: 24.h),

                // ─── 2. تفاصيل الطلب ───
                _buildSectionTitle("تفاصيل الطلب"),
                LeadCopyableField(label: "المنصة", value: lead.platform),
                LeadCopyableField(label: "طريقة التواصل", value: lead.communicationChannel),
                LeadCopyableField(label: "نوع الإعلان", value: lead.listingType),
                LeadCopyableField(label: "نوع العقار", value: lead.propertyType),
                LeadCopyableField(label: "المحافظة", value: lead.governorate),
                LeadCopyableField(label: "المدينة", value: lead.city),
                LeadCopyableField(label: "كود العقار المهتم به", value: lead.propertyCode),
                LeadCopyableField(label: "تخصيص لموظف", value: lead.assignedToName),
                SizedBox(height: 24.h),

                // ─── 3. وصف الاحتياج ───
                if (lead.descLeadNeed != null && lead.descLeadNeed!.isNotEmpty) ...[
                  _buildSectionTitle("وصف الاحتياج"),
                  LeadCopyableField(label: "الوصف", value: lead.descLeadNeed, isLong: true),
                  SizedBox(height: 12.h),
                ],

                // ─── 4. التعليقات / السجل (History) ───
                _buildSectionTitle("سجل التعليقات"),
                _buildHistorySection(lead),

                SizedBox(height: 40.h),

                // ─── Footer: تاريخ الإنشاء ───
                Center(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                      "تمت الإضافة بتاريخ: ${lead.createdAt != null ? DateFormat('yyyy/MM/dd - HH:mm').format(lead.createdAt!) : '---'}\nبواسطة: ${lead.createdByName ?? '---'}",
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
      },
    );
  }

  Widget _buildHistorySection(LeadModel lead) {
    final comments = lead.history;
    // نعرض التعليقات من الأحدث للأقدم
    final reversed = comments.reversed.toList();
    final displayCount = _showAllComments ? reversed.length : _initialCommentsCount.clamp(0, reversed.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── قائمة التعليقات ───
        if (reversed.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              "لا توجد تعليقات حتى الآن",
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 10.w, top: 2.h),
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reversed[index],
                        style: TextStyle(fontSize: 14.sp, height: 1.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // زر "عرض المزيد" أو "إخفاء"
          if (reversed.length > _initialCommentsCount)
            TextButton.icon(
              onPressed: () => setState(() => _showAllComments = !_showAllComments),
              icon: Icon(
                _showAllComments ? Icons.expand_less : Icons.expand_more,
                color: AppColors.brandPrimary,
                size: 20.sp,
              ),
              label: Text(
                _showAllComments
                    ? "إخفاء التعليقات القديمة"
                    : "عرض المزيد (${reversed.length - _initialCommentsCount} تعليق إضافي)",
                style: TextStyle(color: AppColors.brandPrimary, fontSize: 13.sp),
              ),
            ),
        ],

        // ─── حقل إضافة تعليق جديد ───
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "إضافة تعليق جديد",
                style: AppTextStyles.h3.copyWith(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "اكتب تعليقاً...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  InkWell(
                    onTap: _isAddingComment ? null : () => _submitComment(lead),
                    child: CircleAvatar(
                      radius: 26.r,
                      backgroundColor: _isAddingComment
                          ? AppColors.brandPrimary.withValues(alpha: 0.5)
                          : AppColors.brandPrimary,
                      child: _isAddingComment
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h, right: 4.w),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.brandPrimary,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
