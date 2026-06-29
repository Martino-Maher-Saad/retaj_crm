import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import 'smart_match_screen.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  final ProfileModel currentUser;

  const LeadDetailsScreen({
    super.key,
    required this.leadId,
    required this.currentUser,
  });

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
          backgroundColor: const Color(0xFFF5F5FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل العميل',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                Text(
                  lead.clientName,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 40.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── بطاقة الحالة ───
                _buildStatusCard(lead),

                SizedBox(height: 4.h),

                // ─── المعلومات الأساسية ───
                RetajSectionCard(
                  title: 'المعلومات الأساسية',
                  icon: Icons.person_outline_rounded,
                  children: [
                    RetajTextField(
                      readOnly: true,
                      label: 'اسم العميل',
                      initialValue: lead.clientName,
                    ),
                    ...lead.phones.asMap().entries.map((e) => RetajTextField(
                      readOnly: true,
                      label: e.value.isPrimary ? 'رقم الهاتف الأساسي' : 'رقم هاتف ${e.key + 1}',
                      initialValue: e.value.phoneNumber,
                      forceLtr: true,
                    )),
                    if (lead.assignedToName != null && lead.assignedToName!.isNotEmpty)
                      RetajTextField(
                        readOnly: true,
                        label: 'المسؤول عن العميل',
                        initialValue: lead.assignedToName,
                      ),
                  ],
                ),

                // ─── تفاصيل الطلب ───
                RetajSectionCard(
                  title: 'تفاصيل الطلب',
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.blue,
                  children: [
                    RetajFieldRow(
                      first: RetajTextField(
                        readOnly: true,
                        label: 'نوع الإعلان',
                        initialValue: lead.listingType ?? '—',
                      ),
                      second: RetajTextField(
                        readOnly: true,
                        label: 'نوع العقار',
                        initialValue: lead.propertyType ?? '—',
                      ),
                    ),
                    RetajFieldRow(
                      first: RetajTextField(
                        readOnly: true,
                        label: 'المحافظة',
                        initialValue: lead.governorate ?? '—',
                      ),
                      second: RetajTextField(
                        readOnly: true,
                        label: 'المدينة',
                        initialValue: lead.city ?? '—',
                      ),
                    ),
                    RetajFieldRow(
                      first: RetajTextField(
                        readOnly: true,
                        label: 'المنصة',
                        initialValue: lead.platform ?? '—',
                      ),
                      second: RetajTextField(
                        readOnly: true,
                        label: 'طريقة التواصل',
                        initialValue: lead.communicationChannel ?? '—',
                      ),
                    ),
                    if (lead.propertyCode != null && lead.propertyCode!.isNotEmpty)
                      RetajTextField(
                        readOnly: true,
                        label: 'كود العقار المهتم به',
                        initialValue: lead.propertyCode,
                      ),
                    if (lead.budgetFrom != null || lead.budgetTo != null)
                      RetajTextField(
                        readOnly: true,
                        label: 'الميزانية',
                        initialValue: 'من ${lead.budgetFrom?.toCurrency() ?? "0"} إلى ${lead.budgetTo?.toCurrency() ?? "غير محدد"} ج.م',
                        forceLtr: false,
                      ),
                  ],
                ),

                // ─── وصف الاحتياج ───
                if (lead.descLeadNeed != null && lead.descLeadNeed!.isNotEmpty)
                  RetajSectionCard(
                    title: 'وصف الاحتياج',
                    icon: Icons.description_outlined,
                    iconColor: Colors.green,
                    children: [
                      RetajTextArea(
                        readOnly: true,
                        label: 'الاحتياج',
                        initialValue: lead.descLeadNeed,
                        minLines: 3,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SmartMatchScreen(
                                lead: lead,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          ),
                          icon: Icon(Icons.auto_awesome, size: 20.sp),
                          label: Text(
                            'بحث ذكي عن عقارات مطابقة',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ─── سجل الملاحظات ───
                RetajSectionCard(
                  title: 'سجل الملاحظات (${lead.notes.length})',
                  icon: Icons.notes_rounded,
                  iconColor: Colors.orange,
                  children: [
                    _buildNotesSection(lead),
                  ],
                ),

                // ─── Footer ───
                Center(
                  child: Opacity(
                    opacity: 0.55,
                    child: Text(
                      'تمت الإضافة: ${lead.createdAt != null ? DateFormat("yyyy/MM/dd – HH:mm").format(lead.createdAt!) : "---"}\nبواسطة: ${lead.createdByName ?? "---"}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.6),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(LeadModel lead) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الحالة', style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
                SizedBox(height: 4.h),
                Text(
                  lead.leadStatus ?? 'غير محدد',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.brandPrimary),
                ),
              ],
            ),
          ),
          if (lead.isPinned)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin_rounded, size: 14.sp, color: Colors.amber.shade700),
                  SizedBox(width: 4.w),
                  Text('مثبت', style: TextStyle(fontSize: 12.sp, color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(LeadModel lead) {
    final notes = [...lead.notes]
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    final displayCount = _showAllNotes ? notes.length : _initialNotesCount.clamp(0, notes.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قائمة الملاحظات
        if (notes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text('لا توجد ملاحظات حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          )
        else ...[
          ...notes.take(displayCount).map((note) => Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.w, height: 8.h,
                      decoration: BoxDecoration(color: AppColors.brandPrimary, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 8.w),
                    if (note.userName != null)
                      Text(note.userName!, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.brandPrimary)),
                    const Spacer(),
                    if (note.createdAt != null)
                      Text(
                        DateFormat('dd/MM/yyyy – HH:mm').format(note.createdAt!),
                        style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(note.noteText, style: TextStyle(fontSize: 14.sp, height: 1.6)),
              ],
            ),
          )),

          if (notes.length > _initialNotesCount)
            TextButton.icon(
              onPressed: () => setState(() => _showAllNotes = !_showAllNotes),
              icon: Icon(_showAllNotes ? Icons.expand_less : Icons.expand_more, color: AppColors.brandPrimary, size: 20.sp),
              label: Text(
                _showAllNotes
                    ? 'إخفاء الملاحظات القديمة'
                    : 'عرض المزيد (${notes.length - _initialNotesCount} ملاحظة)',
                style: TextStyle(color: AppColors.brandPrimary, fontSize: 13.sp),
              ),
            ),
        ],

        // ─── حقل إضافة ملاحظة ───
        SizedBox(height: 48.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة ملاحظة جديدة', style: AppTextStyles.h3.copyWith(fontSize: 14.sp, color: AppColors.textSecondary)),
              SizedBox(height: 48.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'اكتب ملاحظة...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  InkWell(
                    onTap: _isAddingNote ? null : () => _submitNote(lead),
                    child: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: _isAddingNote
                          ? AppColors.brandPrimary.withValues(alpha: 0.5)
                          : AppColors.brandPrimary,
                      child: _isAddingNote
                          ? SizedBox(width: 16.w, height: 16.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
