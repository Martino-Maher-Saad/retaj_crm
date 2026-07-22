import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/form_field_model.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import 'smart_match_screen.dart';
import '../widgets/details/lead_action_form_widget.dart';
import '../widgets/details/lead_transfer_dialog.dart';
import 'package:intl/intl.dart';
import 'lead_form_screen.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;
import '../widgets/forms/dynamic_lead_field.dart';

class LeadPreviewSideSheet extends StatefulWidget {
  final String leadId;
  final ProfileModel currentUser;

  const LeadPreviewSideSheet({
    super.key,
    required this.leadId,
    required this.currentUser,
  });

  @override
  State<LeadPreviewSideSheet> createState() => _LeadPreviewSideSheetState();
}

class _LeadPreviewSideSheetState extends State<LeadPreviewSideSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditingMode = false;
  final dataManager = di.sl<StaticDataManager>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<LeadCubit>().fetchLeadDetails(widget.leadId);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  FormFieldModel? _getFieldMeta(String key) {
    try {
      return dataManager.formFields.firstWhere((f) => f.fieldKey == key);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        final lead = _getLatestLead(state);
        if (lead == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final width = MediaQuery.of(context).size.width * 0.5;
        
        return Container(
          width: width.clamp(360.0, 900.0),
          height: double.infinity,
          color: Colors.white,
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lead.clientName, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                          Text(lead.primaryPhone ?? '-', style: TextStyle(fontSize: 14.sp, color: Colors.blue)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (AppRole.fromString(widget.currentUser.role).isAtLeast(AppRole.leader))
                          Tooltip(
                            message: 'إعادة تعيين لموظف آخر',
                            child: IconButton(
                              icon: Icon(Icons.person_add_alt_1, color: Colors.orange.shade700, size: 24.sp),
                              onPressed: () async {
                                final leadCubit = context.read<LeadCubit>();
                                final result = await showDialog(
                                  context: context,
                                  builder: (context) => BlocProvider.value(
                                    value: leadCubit,
                                    child: LeadTransferDialog(
                                      lead: lead,
                                      dataManager: dataManager,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  // تحديث شاشة التفاصيل أو القائمة
                                }
                              },
                            ),
                          ),
                        Tooltip(
                          message: _isEditingMode ? 'إلغاء التعديل' : 'تعديل بيانات العميل',
                          child: IconButton(
                            icon: Icon(_isEditingMode ? Icons.edit_off : Icons.edit, color: Colors.blue.shade700, size: 24.sp),
                            onPressed: () {
                                setState(() {
                                  _isEditingMode = !_isEditingMode;
                                  if (_isEditingMode) {
                                    _tabController.index = 0;
                                  }
                                });
                            },
                          ),
                        ),

                        Tooltip(
                          message: 'إضافة إجراء (Action)',
                          child: IconButton(
                            icon: Icon(Icons.add_task, color: Colors.purple.shade700, size: 24.sp),
                            onPressed: () {
                              setState(() => _isEditingMode = false);
                              _tabController.animateTo(1);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.brandPrimary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.brandPrimary,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'بيانات العميل'),
                  Tab(text: 'الأكشنز'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'المطابقة الذكية'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(lead),
                    _buildCommentsTab(lead),
                    _buildTimelineTab(lead),
                    SmartMatchScreen(lead: lead, currentUser: widget.currentUser),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getDynamicValues(LeadModel lead) {
    return {
      'property_code': lead.propertyCode,
      'desc_lead_need': lead.descLeadNeed,
      'budget_from': lead.budgetFrom,
      'budget_to': lead.budgetTo,
      'listing_type_id': lead.listingTypeId,
      'property_type_id': lead.propertyTypeId,
      'city_id': lead.cityId,
      'platform_id': lead.platformId,
      'channel_id': lead.channelId,
      'rate_id': lead.rateId,
      'last_activity_type_id': lead.lastActivityTypeId,
      'assigned_to_at': lead.assignedToAt?.toIso8601String(),
      'scheduled_deadline_at': lead.scheduledDeadlineAt?.toIso8601String(),
      'last_comment': lead.lastComment,
      'transferred_by': lead.transferredBy,
      'transferred_from': lead.transferredFrom,
      if (lead.customFields != null) ...lead.customFields!,
    };
  }

  Widget _buildInfoTab(LeadModel lead) {
    if (_isEditingMode) {
      return LeadFormScreen(
        lead: lead,
        user: widget.currentUser,
        isEmbedded: true,
        onSaved: () {
          if (mounted) {
            setState(() {
              _isEditingMode = false;
            });
          }
        },
      );
    }

    final visibleFields = dataManager.getFormFieldsForRole(widget.currentUser.role, onlyForm: false);
    final manualKeys = ['client_name', 'phones', 'lead_status', 'assigned_to', 'exclusion_reason_id'];
    
    final dynamicFields = visibleFields.where((f) => !manualKeys.contains(f.fieldKey)).toList();
    dynamicFields.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));
    
    final dynamicValues = _getDynamicValues(lead);

    final nameField = _getFieldMeta('client_name');
    final phonesField = _getFieldMeta('phones');
    final statusField = _getFieldMeta('lead_status');
    final assignedField = _getFieldMeta('assigned_to');

    final showName = nameField?.isVisibleForRole(widget.currentUser.role) ?? true;
    final showPhones = phonesField?.isVisibleForRole(widget.currentUser.role) ?? true;
    final showStatus = statusField?.isVisibleForRole(widget.currentUser.role) ?? true;
    final showAssigned = assignedField?.isVisibleForRole(widget.currentUser.role) ?? true;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showName || showPhones || showStatus)
            RetajSectionCard(
              title: "البيانات الأساسية",
              icon: Icons.person_outline,
              children: [
                Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showName) _infoRow(nameField?.titleAr ?? 'اسم العميل', lead.clientName),
                        if (showPhones) _infoRow(phonesField?.titleAr ?? 'رقم الهاتف', lead.primaryPhone ?? '-'),
                        if (showStatus) _infoRow(statusField?.titleAr ?? 'حالة العميل', lead.leadStatus ?? '-'),
                      ],
                    ),
                  ),
                  SizedBox(width: 24.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('تاريخ الإضافة', lead.createdAt != null ? DateFormat('yyyy-MM-dd').format(lead.createdAt!) : '-'),
                      ],
                    ),
                  ),
                ],
              ),
              ],
            ),

          if (dynamicFields.isNotEmpty)
            RetajSectionCard(
              title: "التفاصيل (ديناميكي)",
              icon: Icons.dynamic_form_outlined,
              children: [
                ...dynamicFields.map((f) => DynamicLeadFieldReadOnly(
                  field: f,
                  value: dynamicValues[f.fieldKey],
                  userRole: widget.currentUser.role,
                )),
              ],
            ),

          RetajSectionCard(
            title: "تفاصيل النظام",
            icon: Icons.admin_panel_settings_outlined,
            children: [
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showAssigned) _infoRow(assignedField?.titleAr ?? 'المسؤول', lead.assignedToName ?? '-'),
                          _infoRow('تم الإنشاء بواسطة', lead.createdByName ?? '-'),
                        ],
                      ),
                    ),
                    SizedBox(width: 24.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lead.transferredFromName != null) ...[
                            _infoRow('تم التحويل من', lead.transferredFromName!),
                            _infoRow('تاريخ التحويل', lead.updatedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(lead.updatedAt!) : '-'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(LeadModel lead) {
    final actionLogs = lead.logs.where((l) => l.actionEn == 'action').toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: LeadActionFormWidget(lead: lead),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        if (actionLogs.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 16.sp, color: AppColors.brandPrimary),
                SizedBox(width: 6.w),
                Text(
                  'سجل الإجراءات (${actionLogs.length})',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                ),
              ],
            ),
          ),
        Expanded(
          child: actionLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt_rounded, size: 48.sp, color: Colors.grey.shade300),
                      SizedBox(height: 12.h),
                      Text('لا توجد إجراءات مسجلة بعد', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                  itemCount: actionLogs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final log = actionLogs[index];
                    return _buildActionCard(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionCard(LeadLogEntryModel log) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14.sp, color: AppColors.brandPrimary),
                  SizedBox(width: 4.w),
                  Text(
                    log.createdByName ?? 'النظام',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.brandPrimary),
                  ),
                ],
              ),
              Text(
                DateFormat('dd/MM/yyyy – HH:mm').format(log.createdAt),
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (log.newStatusName != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward, size: 12.sp, color: AppColors.brandPrimary),
                  SizedBox(width: 4.w),
                  Text(
                    log.newStatusName!,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.brandPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (log.scheduledAt != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 13.sp, color: Colors.orange.shade700),
                  SizedBox(width: 5.w),
                  Text(
                    'موعد المتابعة: ${DateFormat('dd/MM/yyyy – HH:mm').format(log.scheduledAt!)}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (log.notes != null && log.notes!.isNotEmpty)
            Text(log.notes!, style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary, height: 1.5))
          else
            Text('لا يوجد تعليق', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(LeadModel lead) {
    if (lead.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_rounded, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text('لا توجد سجلات في التايم لاين', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      itemCount: lead.logs.length,
      itemBuilder: (context, index) {
        final log = lead.logs[index];
        final isLast = index == lead.logs.length - 1;

        final (icon, color) = switch (log.actionEn) {
          'create'   => (Icons.person_add_alt_1_rounded, const Color(0xFF10B981)),
          'action'   => (Icons.task_alt_rounded,          AppColors.brandPrimary),
          'transfer' => (Icons.swap_horiz_rounded,        Colors.orange),
          'trash'    => (Icons.delete_outline_rounded,    Colors.red),
          'restore'  => (Icons.restore_rounded,           Colors.green),
          'update'   => (Icons.edit_note_rounded,         Colors.blue),
          _          => (Icons.circle_outlined,           Colors.grey),
        };

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(icon, size: 18.sp, color: color),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        color: Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.action.isNotEmpty ? log.action : 'تحديث',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: color),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(log.createdAt),
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        if (log.oldStatusName != null || log.newStatusName != null) ...
                          [
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                if (log.oldStatusName != null) ...[
                                  Text(log.oldStatusName!, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                                    child: Icon(Icons.arrow_forward, size: 12.sp, color: Colors.grey),
                                  ),
                                ],
                                if (log.newStatusName != null)
                                  Text(log.newStatusName!, style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        if (log.notes != null && log.notes!.isNotEmpty) ...
                          [
                            SizedBox(height: 6.h),
                            Text(log.notes!, style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4)),
                          ],
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12.sp, color: Colors.grey.shade400),
                            SizedBox(width: 4.w),
                            Text(DateFormat('HH:mm').format(log.createdAt), style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400)),
                            if (log.createdByName != null) ...[
                              SizedBox(width: 8.w),
                              Icon(Icons.person_outline, size: 12.sp, color: Colors.grey.shade400),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(log.createdByName!, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
