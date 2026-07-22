import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/models/form_field_model.dart';
import '../../../../data/models/lead_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/leads_cubit.dart';
import '../details/lead_restore_dialog.dart';

class LeadsTableView extends StatefulWidget {
  final List<LeadModel> leads;
  final String role;
  final Function(LeadModel) onTap;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  /// IDs العملاء اللي اتحدثت للتو عبر realtime — يطلب وميض لحظي
  final Set<String> flashingIds;

  const LeadsTableView({
    super.key,
    required this.leads,
    required this.role,
    required this.onTap,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.flashingIds = const {},
  });

  @override
  State<LeadsTableView> createState() => _LeadsTableViewState();
}

class _LeadsTableViewState extends State<LeadsTableView> {
  bool get _isManager => AppRole.fromString(widget.role).isAtLeast(AppRole.manager);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        widget.onLoadMore?.call();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = di.sl<StaticDataManager>();
    final visibleFields = dataManager.getFormFieldsForRole(widget.role, onlyForm: false);
    bool isVisibleInCard(String key) => visibleFields.any((f) => f.fieldKey == key && f.showInCard);

    final showName = isVisibleInCard('client_name');
    final showPhone = isVisibleInCard('phone_primary') || isVisibleInCard('phones');
    final showCity = true;
    final showListing = true;
    final showProperty = true;
    final showStatus = true;
    final showAssigned = _isManager && isVisibleInCard('assigned_to');
    final showAction = true;
    final canSoftDelete = dataManager.canPerformAction('action_soft_delete', widget.role);
    final canHardDelete = dataManager.canPerformAction('action_hard_delete', widget.role);
    final canRestore = canHardDelete; 
    final showDelete = canSoftDelete || canHardDelete || canRestore;

    final manualKeys = ['client_name', 'phone_primary', 'phones', 'lead_status', 'platform_id', 'assigned_to', 'city_id', 'listing_type_id', 'property_type_id', 'last_action_at'];
    final dynamicColumns = visibleFields.where((f) => f.showInCard && !manualKeys.contains(f.fieldKey)).toList();
    dynamicColumns.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

    double totalWidth = 0;
    if (showName) totalWidth += 220.w;
    if (showPhone) totalWidth += 150.w;
    if (showCity) totalWidth += 120.w;
    if (showListing) totalWidth += 130.w;
    if (showProperty) totalWidth += 130.w;
    if (showStatus) totalWidth += 140.w;
    if (showAssigned) totalWidth += 150.w;
    if (showAction) totalWidth += 120.w;
    totalWidth += dynamicColumns.length * 140.w;
    if (showDelete) totalWidth += 120.w;

    double tableWidth = totalWidth > (MediaQuery.of(context).size.width - 32.w)
        ? totalWidth
        : (MediaQuery.of(context).size.width - 32.w);

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Container(
                      color: AppColors.bgMain,
                      height: 56.h,
                      child: Row(
                        children: [
                          if (showName) _buildHeaderCell('الاسم', 220.w),
                          if (showPhone) _buildHeaderCell('الرقم الأساسي', 150.w),
                          if (showCity) _buildHeaderCell('المدينة', 120.w),
                          if (showListing) _buildHeaderCell('نوع الإعلان', 130.w),
                          if (showProperty) _buildHeaderCell('نوع العقار', 130.w),
                          if (showStatus) _buildHeaderCell('الحالة', 140.w),
                          if (showAssigned) _buildHeaderCell('المسند إليه', 150.w),
                          if (showAction) _buildHeaderCell('آخر إجراء', 120.w),
                          ...dynamicColumns.map((f) => _buildHeaderCell(f.titleAr, 140.w)),
                          if (showDelete) _buildHeaderCell('إجراءات', 120.w),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                    // List of Rows
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: widget.leads.length + (widget.isLoadingMore ? 1 : 0),
                        separatorBuilder: (ctx, i) => Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          if (index == widget.leads.length) {
                            return _buildLoadingRow(showName, showPhone, showCity, showListing, showProperty, showStatus, showAssigned, showAction, dynamicColumns, showDelete);
                          }
                          final lead = widget.leads[index];
                          return LeadTableRowWidget(
                            key: ValueKey(lead.id),
                            lead: lead,
                            isFlashing: widget.flashingIds.contains(lead.id),
                            onTap: () => widget.onTap(lead),
                            showName: showName,
                            showPhone: showPhone,
                            showCity: showCity,
                            showListing: showListing,
                            showProperty: showProperty,
                            showStatus: showStatus,
                            showAssigned: showAssigned,
                            showAction: showAction,
                            showDelete: showDelete,
                            dynamicColumns: dynamicColumns,
                            canSoftDelete: canSoftDelete,
                            canRestore: canRestore,
                            canHardDelete: canHardDelete,
                            dataManager: dataManager,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.hasMore && !widget.isLoadingMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: TextButton(
                onPressed: widget.onLoadMore,
                child: const Text('تحميل المزيد من العملاء', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14.sp,
          color: Colors.grey.shade700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLoadingRow(bool showName, bool showPhone, bool showCity, bool showListing, bool showProperty, bool showStatus, bool showAssigned, bool showAction, List<FormFieldModel> dynamicColumns, bool showDelete) {
    Widget sCell(double w) => Container(
      width: w, padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerRight,
      child: Skeletonizer(enabled: true, child: Container(width: w*0.7, height: 16.h, color: Colors.grey.shade300)),
    );
    return SizedBox(
      height: 70.h,
      child: Row(
        children: [
          if (showName) sCell(220.w),
          if (showPhone) sCell(150.w),
          if (showCity) sCell(120.w),
          if (showListing) sCell(130.w),
          if (showProperty) sCell(130.w),
          if (showStatus) sCell(140.w),
          if (showAssigned) sCell(150.w),
          if (showAction) sCell(120.w),
          ...dynamicColumns.map((f) => sCell(140.w)),
          if (showDelete) sCell(120.w),
        ],
      ),
    );
  }
}

class LeadTableRowWidget extends StatefulWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final bool showName, showPhone, showCity, showListing, showProperty, showStatus, showAssigned, showAction, showDelete;
  final List<FormFieldModel> dynamicColumns;
  final bool canSoftDelete, canRestore, canHardDelete;
  final StaticDataManager dataManager;
  /// لو true يعني إن هذا الصف تحدّث للتو عبر realtime
  final bool isFlashing;

  const LeadTableRowWidget({
    super.key, required this.lead, required this.onTap, required this.showName, required this.showPhone, required this.showCity, required this.showListing, required this.showProperty, required this.showStatus, required this.showAssigned, required this.showAction, required this.showDelete, required this.dynamicColumns, required this.canSoftDelete, required this.canRestore, required this.canHardDelete, required this.dataManager, this.isFlashing = false,
  });

  @override
  State<LeadTableRowWidget> createState() => _LeadTableRowWidgetState();
}

class _LeadTableRowWidgetState extends State<LeadTableRowWidget> {
  bool _isHovering = false;
  bool _isUpdating = false;

  @override
  void didUpdateWidget(covariant LeadTableRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لو تغيّرت بيانات العميل أو جاء فلاش من realtime
    if (oldWidget.lead != widget.lead || (!oldWidget.isFlashing && widget.isFlashing)) {
      setState(() => _isUpdating = true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _isUpdating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: _isHovering ? AppColors.brandPrimary.withOpacity(0.03) : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (h) => setState(() => _isHovering = h),
        child: SizedBox(
          height: 75.h,
          child: Row(
            children: [
              if (widget.showName) _buildCell(220.w, _buildName()),
              if (widget.showPhone) _buildCell(150.w, Text(widget.lead.primaryPhone ?? '-', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 14.sp))),
              if (widget.showCity) _buildCell(120.w, Text(widget.lead.city ?? '-', style: TextStyle(color: Colors.grey.shade700, fontSize: 14.sp))),
              if (widget.showListing) _buildCell(130.w, _buildBadge(widget.lead.listingType, isDark: true)),
              if (widget.showProperty) _buildCell(130.w, Text(widget.lead.propertyType ?? '-', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500, fontSize: 13.sp))),
              if (widget.showStatus) _buildCell(140.w, _buildBadge(widget.lead.leadStatus, isBrand: true, colorHex: widget.lead.statusColorHex)),
              if (widget.showAssigned) _buildCell(150.w, Text(widget.lead.assignedToName ?? '-', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (widget.showAction) _buildCell(120.w, Text(widget.lead.lastActionAt != null ? "${widget.lead.lastActionAt!.year}/${widget.lead.lastActionAt!.month}/${widget.lead.lastActionAt!.day}" : '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp))),
              ...widget.dynamicColumns.map((f) => _buildCell(140.w, _buildDynamicCell(f))),
              if (widget.showDelete) _buildCell(120.w, _buildActions()),
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        content,
        if (_isUpdating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2.h,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(double width, Widget child) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.centerRight,
      child: child,
    );
  }

  Widget _buildName() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: AppColors.brandPrimary.withOpacity(0.1),
          child: Icon(Icons.person, size: 20.sp, color: AppColors.brandPrimary),
        ),
        SizedBox(width: 10.w),
        Expanded(child: Text(widget.lead.clientName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildBadge(String? text, {bool isDark = false, bool isBrand = false, String? colorHex}) {
    if (text == null || text.isEmpty) return const Text('-');
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade800;
    
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        bgColor = color.withOpacity(0.1);
        textColor = color;
      } catch (_) {
        if (isBrand) { bgColor = AppColors.brandPrimary.withOpacity(0.1); textColor = AppColors.brandPrimary; }
        else if (isDark) { bgColor = Colors.grey.shade800; textColor = Colors.white; }
      }
    } else if (isBrand) {
      bgColor = AppColors.brandPrimary.withOpacity(0.1); textColor = AppColors.brandPrimary;
    } else if (isDark) {
      bgColor = Colors.grey.shade800; textColor = Colors.white;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.r)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildDynamicCell(FormFieldModel f) {
    dynamic val;
    if (f.fieldKey == 'rate_id') val = widget.lead.rateId;
    else if (f.fieldKey == 'last_activity_type_id') val = widget.lead.lastActivityTypeId;
    else if (f.fieldKey == 'assigned_to_at') val = widget.lead.assignedToAt?.toIso8601String();
    else if (f.fieldKey == 'scheduled_deadline_at') val = widget.lead.scheduledDeadlineAt?.toIso8601String();
    else if (f.fieldKey == 'last_comment') val = widget.lead.lastComment;
    else if (f.fieldKey == 'transferred_by') val = widget.lead.transferredBy;
    else if (f.fieldKey == 'transferred_from') val = widget.lead.transferredFrom;
    else val = widget.lead.customFields?[f.fieldKey];

    if (val == null || val.toString().isEmpty) return const Text('-');
    
    String displayValue = val.toString();
    if (f.inputType == FormFieldInputType.checkbox) {
      displayValue = (val == true || val == 'true' || val == 1) ? 'نعم ✓' : 'لا ✗';
    } else if (f.inputType == FormFieldInputType.selectStatic) {
      try { displayValue = f.options.firstWhere((o) => o.value == val.toString()).label; } catch (_) {}
    } else if (f.inputType == FormFieldInputType.selectRef && f.refTable != null) {
      try { displayValue = widget.dataManager.getRefTableOptions(f.refTable!).firstWhere((o) => o.id == val.toString()).nameAr; } catch (_) {}
    }

    return Text(displayValue, style: TextStyle(color: Colors.grey.shade800, fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.lead.deletedAt == null && widget.canSoftDelete)
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20.sp),
            onPressed: () => _confirmDelete(isHard: false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (widget.lead.deletedAt != null && widget.canRestore)
          IconButton(
            icon: Icon(Icons.restore, color: Colors.green.shade600, size: 20.sp),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<LeadCubit>(),
                  child: LeadRestoreDialog(lead: widget.lead, dataManager: widget.dataManager),
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (widget.lead.deletedAt != null && widget.canHardDelete)
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20.sp),
            onPressed: () => _confirmDelete(isHard: true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  void _confirmDelete({required bool isHard}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHard ? 'تأكيد الحذف النهائي' : 'تأكيد الحذف المؤقت'),
        content: Text(isHard ? 'هل أنت متأكد من حذف العميل ${widget.lead.clientName} نهائياً؟ هذا الإجراء لا يمكن التراجع عنه!' : 'هل تريد نقل العميل ${widget.lead.clientName} إلى المهملات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isHard ? Colors.red.shade700 : Colors.red.shade400),
            onPressed: () {
              Navigator.pop(ctx);
              if (isHard) context.read<LeadCubit>().hardDeleteLead(widget.lead.id!);
              else context.read<LeadCubit>().softDeleteLead(widget.lead.id!);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isHard ? 'تم الحذف النهائي للعميل' : 'تم نقل العميل إلى المهملات'), backgroundColor: isHard ? Colors.red.shade700 : Colors.orange.shade700));
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
