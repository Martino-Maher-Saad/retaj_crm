import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import 'smart_match_screen.dart';
import '../widgets/details/lead_action_form_widget.dart';

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
  bool _showAllNotes = false;
  final int _initialNotesCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadCubit>().fetchLeadDetails(widget.leadId);
    });
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
    return BlocBuilder<LeadCubit, LeadState>(
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
                        label: 'المدينة',
                        initialValue: lead.city ?? '—',
                      ),
                      second: const SizedBox.shrink(),
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

                // ─── سجل الإجراءات والملاحظات (Timeline) ───
                RetajSectionCard(
                  title: 'سجل الإجراءات والملاحظات',
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
    // دمج الملاحظات والسجلات في قائمة واحدة للـ Timeline
    final List<Map<String, dynamic>> timeline = [];

    for (var note in lead.notes) {
      if (note.createdAt != null) {
        timeline.add({
          'is_log': false,
          'date': note.createdAt!,
          'title': 'ملاحظة جديدة',
          'description': note.noteText,
          'user': note.userName ?? 'غير معروف',
          'icon': Icons.note_alt_outlined,
          'color': Colors.blue,
        });
      }
    }

    for (var log in lead.logs) {
      timeline.add({
        'is_log': true,
        'date': log.createdAt,
        'title': log.action ?? 'تحديث الحالة',
        'description': log.oldStatusName != null 
            ? 'من ${log.oldStatusName} إلى ${log.newStatusName}'
            : 'الحالة: ${log.newStatusName ?? "غير محدد"}',
        'user': log.createdByName ?? 'النظام',
        'icon': Icons.track_changes_outlined,
        'color': Colors.orange,
      });
    }

    timeline.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    final displayCount = _showAllNotes ? timeline.length : _initialNotesCount.clamp(0, timeline.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قائمة الملاحظات
        if (timeline.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text('لا توجد سجلات حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          )
        else ...[
          ...timeline.take(displayCount).map((item) => Container(
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
                    Icon(item['icon'] as IconData, size: 18.sp, color: item['color'] as Color),
                    SizedBox(width: 8.w),
                    Text(item['title'] as String, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: item['color'] as Color)),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy – HH:mm').format(item['date'] as DateTime),
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(item['description'] as String, style: TextStyle(fontSize: 14.sp, height: 1.6, fontWeight: item['is_log'] == true ? FontWeight.bold : FontWeight.normal)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(item['user'] as String, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )),

          if (timeline.length > _initialNotesCount)
            TextButton.icon(
              onPressed: () => setState(() => _showAllNotes = !_showAllNotes),
              icon: Icon(_showAllNotes ? Icons.expand_less : Icons.expand_more, color: AppColors.brandPrimary, size: 20.sp),
              label: Text(
                _showAllNotes
                    ? 'إخفاء السجل القديم'
                    : 'عرض المزيد (${timeline.length - _initialNotesCount} إجراء)',
                style: TextStyle(color: AppColors.brandPrimary, fontSize: 13.sp),
              ),
            ),
        ],

        // ─── إضافة إجراء جديد ───
        SizedBox(height: 48.h),
        LeadActionFormWidget(lead: lead),
      ],
    );
  }
}
