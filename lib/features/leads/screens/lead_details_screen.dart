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
  final String leadId;

  const LeadDetailsScreen({super.key, required this.leadId});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;

  static const int _initialNotesCount = 3;
  bool _showAllNotes = false;

  void _submitNote(LeadModel lead) {
    final text = _noteController.text.trim();
    if (text.isEmpty || _isAddingNote) return;
    setState(() => _isAddingNote = true);
    _noteController.clear();
    context.read<LeadCubit>().addNote(lead.id!, text);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
        if (_isAddingNote) {
          if (state is LeadLoaded) {
            setState(() => _isAddingNote = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إضافة الملاحظة بنجاح'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is LeadError) {
            setState(() => _isAddingNote = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ فشل إضافة الملاحظة: ${state.message}'),
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
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.brandPrimary),
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
                LeadCopyableField(
                    label: "الاسم بالكامل", value: lead.clientName),
                // أرقام الهاتف من lead_phones
                ...lead.phones.asMap().entries.map(
                      (e) => LeadCopyableField(
                        label: e.value.isPrimary
                            ? "تيلفون أساسي"
                            : "تيلفون ${e.key + 1}",
                        value: e.value.phoneNumber,
                      ),
                    ),
                SizedBox(height: 24.h),

                // ─── 2. تفاصيل الطلب ───
                _buildSectionTitle("تفاصيل الطلب"),
                LeadCopyableField(label: "المنصة", value: lead.platform),
                LeadCopyableField(
                    label: "طريقة التواصل",
                    value: lead.communicationChannel),
                LeadCopyableField(
                    label: "نوع الإعلان", value: lead.listingType),
                LeadCopyableField(
                    label: "نوع العقار", value: lead.propertyType),
                LeadCopyableField(
                    label: "المحافظة", value: lead.governorate),
                LeadCopyableField(label: "المدينة", value: lead.city),
                LeadCopyableField(
                    label: "كود العقار المهتم به", value: lead.propertyCode),
                LeadCopyableField(
                    label: "تخصيص لموظف", value: lead.assignedToName),
                SizedBox(height: 24.h),

                // ─── 3. وصف الاحتياج ───
                if (lead.descLeadNeed != null &&
                    lead.descLeadNeed!.isNotEmpty) ...[
                  _buildSectionTitle("وصف الاحتياج"),
                  LeadCopyableField(
                      label: "الوصف",
                      value: lead.descLeadNeed,
                      isLong: true),
                  SizedBox(height: 12.h),
                ],

                // ─── 4. سجل الملاحظات ───
                _buildSectionTitle("سجل الملاحظات"),
                _buildNotesSection(lead),

                SizedBox(height: 40.h),

                // ─── Footer ───
                Center(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                      "تمت الإضافة بتاريخ: ${lead.createdAt != null ? DateFormat('yyyy/MM/dd - HH:mm').format(lead.createdAt!) : '---'}\nبواسطة: ${lead.createdByName ?? '---'}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                          height: 1.5),
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

  Widget _buildNotesSection(LeadModel lead) {
    // ترتيب الملاحظات من الأحدث للأقدم
    final notes = [...lead.notes]
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    final displayCount =
        _showAllNotes ? notes.length : _initialNotesCount.clamp(0, notes.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── قائمة الملاحظات ───
        if (notes.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              "لا توجد ملاحظات حتى الآن",
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final note = notes[index];
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: اسم الكاتب + التاريخ
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (note.userName != null)
                          Text(
                            note.userName!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        const Spacer(),
                        if (note.createdAt != null)
                          Text(
                            DateFormat('dd/MM/yyyy - HH:mm').format(note.createdAt!),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // نص الملاحظة
                    Text(
                      note.noteText,
                      style: TextStyle(fontSize: 14.sp, height: 1.6),
                    ),
                  ],
                ),
              );
            },
          ),

          // زر "عرض المزيد"
          if (notes.length > _initialNotesCount)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showAllNotes = !_showAllNotes),
              icon: Icon(
                _showAllNotes ? Icons.expand_less : Icons.expand_more,
                color: AppColors.brandPrimary,
                size: 20.sp,
              ),
              label: Text(
                _showAllNotes
                    ? "إخفاء الملاحظات القديمة"
                    : "عرض المزيد (${notes.length - _initialNotesCount} ملاحظة إضافية)",
                style: TextStyle(
                    color: AppColors.brandPrimary, fontSize: 13.sp),
              ),
            ),
        ],

        // ─── حقل إضافة ملاحظة ───
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
                "إضافة ملاحظة جديدة",
                style: AppTextStyles.h3
                    .copyWith(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: "اكتب ملاحظة...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide:
                              const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 14.h),
                      ),
                      maxLines: 2,
                      minLines: 1,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  InkWell(
                    onTap: _isAddingNote ? null : () => _submitNote(lead),
                    child: CircleAvatar(
                      radius: 26.r,
                      backgroundColor: _isAddingNote
                          ? AppColors.brandPrimary.withValues(alpha: 0.5)
                          : AppColors.brandPrimary,
                      child: _isAddingNote
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
