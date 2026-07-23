import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lead_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/leads_cubit.dart';
import '../screens/smart_match_screen.dart';

class LeadCard extends StatefulWidget {
  final LeadModel lead;
  final String role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;

  const LeadCard({
    super.key,
    required this.lead,
    required this.role,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onRestore,
    required this.onTap,
    this.onPinToggle,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  int _duplicateCount = 0;
  bool _isLoadingDuplicates = false;
  List<LeadModel> _duplicates = [];

  bool _isCommenting = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isCommentExpanded = false;
  bool _isNeedExpanded = false;
  bool _isNameExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkDuplicates();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _checkDuplicates() async {
    final bool isManagerOrAdmin =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo';
    if (!isManagerOrAdmin || widget.lead.phones.isEmpty) return;

    if (mounted) setState(() => _isLoadingDuplicates = true);

    try {
      final phones = widget.lead.phones.map((e) => e.phoneNumber).toList();
      final duplicates = await context.read<LeadCubit>().checkDuplicates(
        phones,
      );
      if (mounted) {
        setState(() {
          _duplicateCount = duplicates.length;
          _duplicates = duplicates;
          _isLoadingDuplicates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDuplicates = false);
    }
  }

  void _showDuplicatesModal() {
    if (_duplicates.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التكرارات لهذا العميل',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  itemCount: _duplicates.length,
                  itemBuilder: (ctx, i) {
                    final l = _duplicates[i];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10.h),
                      child: ListTile(
                        title: Text(l.clientName),
                        subtitle: Text(
                          l.phones.isNotEmpty
                              ? l.phones.first.phoneNumber
                              : 'بدون هاتف',
                        ),
                        trailing: Text(l.leadStatus ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LeadPhoneModel? get _primaryPhone {
    if (widget.lead.phones.isEmpty) return null;
    try {
      return widget.lead.phones.firstWhere((p) => p.isPrimary);
    } catch (_) {
      return widget.lead.phones.first;
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ رقم الهاتف 📋'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'جديد':
        return const Color(0xFF3B82F6);
      case 'تم التواصل':
        return const Color(0xFF8B5CF6);
      case 'تفاوض':
        return AppColors.brandPrimary;
      case 'تم التعاقد':
        return const Color(0xFF10B981);
      case 'مستبعد':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isManagerOrAdmin =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo';
    final Color sColor = _statusColor(widget.lead.leadStatus);
    final bool hasPlatform = widget.lead.platformId != null;

    return SelectionArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: !hasPlatform
                ? Colors.red.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
            width: !hasPlatform ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (widget.lead.isPinned)
                    Positioned(
                      top: -20.h,
                      right: -20.w,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          color: AppColors.brandPrimary,
                          size: 16.sp,
                        ),
                      ),
                    ),

                  if (_duplicateCount > 1)
                    Positioned(
                      top: -20.h,
                      left: -16.w,
                      child: GestureDetector(
                        onTap: _showDuplicatesModal,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "مكرر $_duplicateCount",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.only(left: 16.w),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1.w))),
                          child: _buildFirstColumn(context, sColor, hasPlatform),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: EdgeInsets.only(left: 16.w),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1.w))),
                          child: _buildSecondColumn(context),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.only(left: 16.w),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1.w))),
                          child: _buildThirdColumn(context),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      _buildActions(isManagerOrAdmin),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFirstColumn(
    BuildContext context,
    Color sColor,
    bool hasPlatform,
  ) {
    final bool isManagerOrAdmin =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo';

    DateTime? lastNoteDate;
    if (widget.lead.notes.isNotEmpty) {
      final sortedNotes = List<LeadNoteModel>.from(widget.lead.notes);
      sortedNotes.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );
      lastNoteDate = sortedNotes.first.createdAt;
    }

    final bool isNameLong = widget.lead.clientName.length > 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lead.clientName,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                      height: 1.1,
                    ),
                    maxLines: _isNameExpanded ? null : 1,
                    overflow: _isNameExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (isNameLong)
                    SelectionContainer.disabled(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isNameExpanded = !_isNameExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isNameExpanded ? 'إخفاء' : 'عرض المزيد...',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.lead.createdAt != null) ...[
              SizedBox(width: 16.w),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تاريخ الإنشاء',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy', 'ar').format(widget.lead.createdAt!),
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (_primaryPhone != null)
          GestureDetector(
            onTap: () => _copyPhone(_primaryPhone!.phoneNumber),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18.sp,
                  color: AppColors.brandPrimary,
                ),
                SizedBox(width: 4.w),
                Text(
                  _primaryPhone!.phoneNumber,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'لا يوجد رقم هاتف',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[400]),
          ),

        SizedBox(height: 12.h),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _infoRowSmall('المنصة:', widget.lead.platform ?? 'غير محدد')),
            Container(width: 1.w, height: 35.h, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 16.w)),
            Expanded(
              child: _infoRowSmall(
                'حالة العميل:',
                widget.lead.leadStatus ?? 'غير محدد',
                valueColor: sColor,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        if (isManagerOrAdmin)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.lead.assignedToName != null)
                Expanded(child: _infoRowSmall('المسؤول:', widget.lead.assignedToName!)),
              if (widget.lead.createdByName != null && widget.lead.createdBy != widget.lead.assignedTo) ...[
                if (widget.lead.assignedToName != null)
                  Container(width: 1.w, height: 35.h, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 16.w)),
                Expanded(child: _infoRowSmall('المُسند:', widget.lead.transferredFromName ?? widget.lead.createdByName!)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _infoRowSmall(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Icon(Icons.circle, size: 5.sp, color: Colors.grey[400]),
    );
  }

  Widget _buildSecondColumn(BuildContext context) {
    final bool hasNeed =
        widget.lead.descLeadNeed != null &&
        widget.lead.descLeadNeed!.trim().isNotEmpty;

    List<Widget> metaItems = [];
    if (widget.lead.city != null && widget.lead.city!.isNotEmpty) {
      metaItems.add(
        Text(
          widget.lead.city!,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
    }
    if (widget.lead.propertyType != null &&
        widget.lead.propertyType!.isNotEmpty) {
      if (metaItems.isNotEmpty) metaItems.add(_bulletSeparator());
      metaItems.add(
        Text(
          widget.lead.propertyType!,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
    }
    if (widget.lead.listingType != null &&
        widget.lead.listingType!.isNotEmpty) {
      if (metaItems.isNotEmpty) metaItems.add(_bulletSeparator());
      metaItems.add(
        Text(
          widget.lead.listingType!,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metaItems.isNotEmpty)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: metaItems,
          ),

        if (metaItems.isNotEmpty) SizedBox(height: 6.h),

        Row(
          children: [
            Text(
              'الميزانية: ',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.lead.budgetFrom != null ? NumberFormat.decimalPattern().format(widget.lead.budgetFrom) : '0'} - ${widget.lead.budgetTo != null ? NumberFormat.decimalPattern().format(widget.lead.budgetTo) : 'غير محدد'}',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        if (hasNeed)
          _buildNeedsDescBox()
        else
          Text(
            'لا يوجد وصف للاحتياجات',
            style: TextStyle(fontSize: 24.sp, color: Colors.grey[400]),
          ),

        SizedBox(height: 8.h),
        SelectionContainer.disabled(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              OutlinedButton.icon(
              icon: Icon(Icons.edit_note, size: 28.sp),
              label: Text(
                'تعديل الوصف والميزانية',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                minimumSize: Size.zero,
                foregroundColor: AppColors.brandPrimary,
                side: BorderSide(
                  color: AppColors.brandPrimary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              onPressed: _editNeedsDialog,
            ),
            if (hasNeed)
              ElevatedButton.icon(
                icon: Icon(Icons.auto_awesome, size: 28.sp),
                label: Text(
                  'المطابقة الذكية',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  minimumSize: Size.zero,
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                onPressed: () {
                  final authState = context.read<AuthCubit>().state;
                  final currentUser = (authState as dynamic).user;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartMatchScreen(
                        lead: widget.lead,
                        currentUser: currentUser,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThirdColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLastComment(),
        SizedBox(height: 8.h),
        SelectionContainer.disabled(
          child: ElevatedButton.icon(
            icon: Icon(Icons.add_comment, size: 28.sp),
            label: Text(
              'إضافة تعليق',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              minimumSize: Size.zero,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brandPrimary,
              elevation: 0,
              side: BorderSide(
                color: AppColors.brandPrimary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onPressed: () {
              setState(() {
                _isCommenting = !_isCommenting;
              });
            },
          ),
        ),
        if (_isCommenting) ...[
          SizedBox(height: 6.h),
          _buildCommentInputField(),
        ],
      ],
    );
  }

  Widget _buildNeedsDescBox() {
    final need = widget.lead.descLeadNeed!.trim();
    final bool isLong = need.length > 80;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              need,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: _isNeedExpanded ? null : 2,
              overflow: _isNeedExpanded ? null : TextOverflow.ellipsis,
            ),
            if (isLong)
              SelectionContainer.disabled(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isNeedExpanded = !_isNeedExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isNeedExpanded ? 'إخفاء' : 'عرض المزيد...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _editNeedsDialog() {
    final TextEditingController needController = TextEditingController(
      text: widget.lead.descLeadNeed,
    );
    final TextEditingController budgetFromController = TextEditingController(
      text: widget.lead.budgetFrom != null
          ? NumberFormat.decimalPattern().format(widget.lead.budgetFrom)
          : '',
    );
    final TextEditingController budgetToController = TextEditingController(
      text: widget.lead.budgetTo != null
          ? NumberFormat.decimalPattern().format(widget.lead.budgetTo)
          : '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.brandPrimary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'تعديل الوصف والميزانية',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 500.w,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الميزانية',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: budgetFromController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18.sp),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'من',
                            labelStyle: TextStyle(fontSize: 16.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: budgetToController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18.sp),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'إلى',
                            labelStyle: TextStyle(fontSize: 16.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'وصف الاحتياج',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: needController,
                    maxLines: 5,
                    textDirection: ui.TextDirection.rtl,
                    style: TextStyle(fontSize: 20.sp),
                    decoration: InputDecoration(
                      hintText: 'اكتب وصف احتياجات العميل هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final updatedLead = LeadModel(
                          id: widget.lead.id,
                          clientName: widget.lead.clientName,
                          phones: widget.lead.phones,
                          createdBy: widget.lead.createdBy,
                          createdByName: widget.lead.createdByName,
                          assignedTo: widget.lead.assignedTo,
                          assignedToName: widget.lead.assignedToName,
                          transferredFrom: widget.lead.transferredFrom,
                          transferredFromName: widget.lead.transferredFromName,
                          createdAt: widget.lead.createdAt,
                          updatedAt: widget.lead.updatedAt,
                          listingType: widget.lead.listingType,
                          propertyType: widget.lead.propertyType,
                          governorate: widget.lead.governorate,
                          city: widget.lead.city,
                          platform: widget.lead.platform,
                          leadStatus: widget.lead.leadStatus,
                          communicationChannel:
                              widget.lead.communicationChannel,
                          exclusionReasonName: widget.lead.exclusionReasonName,
                          descLeadNeed: needController.text.trim(),
                          lastComment: widget.lead.lastComment,
                          propertyCode: widget.lead.propertyCode,
                          notes: widget.lead.notes,
                          logs: widget.lead.logs,
                          budgetFrom: int.tryParse(
                            budgetFromController.text.replaceAll(',', '').trim(),
                          ),
                          budgetTo: int.tryParse(
                            budgetToController.text.replaceAll(',', '').trim(),
                          ),
                          statusId: widget.lead.statusId,
                          platformId: widget.lead.platformId,
                          propertyTypeId: widget.lead.propertyTypeId,
                          listingTypeId: widget.lead.listingTypeId,
                          channelId: widget.lead.channelId,
                          cityId: widget.lead.cityId,
                          governorateId: widget.lead.governorateId,
                          exclusionReasonId: widget.lead.exclusionReasonId,
                          isActive: widget.lead.isActive,
                          isArchived: widget.lead.isArchived,
                          isPinned: widget.lead.isPinned,
                        );

                        await context.read<LeadCubit>().updateFullLead(
                          updatedLead,
                          widget.lead.phones,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم التحديث بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'حفظ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textDirection: ui.TextDirection.rtl,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا...',
                hintStyle: TextStyle(fontSize: 24.sp, color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 8.h,
                ),
              ),
            ),
          ),
          _isSubmittingComment
              ? SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.brandPrimary,
                  iconSize: 28.sp,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) return;
                    setState(() => _isSubmittingComment = true);
                    try {
                      await context.read<LeadCubit>().addNote(
                        widget.lead.id!,
                        text,
                      );
                      if (mounted) {
                        setState(() {
                          _isSubmittingComment = false;
                          _isCommenting = false;
                          _commentController.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إضافة التعليق بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSubmittingComment = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
    required double iconSize,
    bool isOutlined = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: color.withValues(alpha: isOutlined ? 0.5 : 0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastComment() {
    String? latestNoteText;
    DateTime? latestNoteDate;
    if (widget.lead.notes.isNotEmpty) {
      final sortedNotes = List<LeadNoteModel>.from(widget.lead.notes);
      sortedNotes.sort((a, b) {
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      latestNoteText = sortedNotes.first.noteText;
      latestNoteDate = sortedNotes.first.createdAt;
    }

    latestNoteDate ??= widget.lead.lastCommentDate;

    String? rawComment = latestNoteText ?? widget.lead.lastComment?.trim();
    if (rawComment == 'تم إنشاء العميل في النظام') {
      rawComment = null;
    }

    final comment = rawComment ?? 'لم يتم إضافة أي تعليق أو إجراء بعد';
    final bool hasComment = rawComment != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 16.sp,
                color: AppColors.brandPrimary,
              ),
              SizedBox(width: 6.w),
              Text(
                'آخر تعليق',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (latestNoteDate != null && hasComment) ...[
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy - hh:mm a', 'ar').format(latestNoteDate),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: ui.TextDirection.ltr,
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final textWidget = Text(
                comment,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontSize: 24.sp,
                  color: hasComment ? Colors.black87 : Colors.grey[500],
                  fontWeight: hasComment ? FontWeight.w800 : FontWeight.normal,
                  height: 1.3,
                ),
                maxLines: _isCommentExpanded ? null : 3,
                overflow: _isCommentExpanded ? null : TextOverflow.ellipsis,
              );

              final bool isLong = comment.length > 80;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget,
                  if (isLong)
                    SelectionContainer.disabled(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isCommentExpanded = !_isCommentExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isCommentExpanded
                              ? 'إخفاء التعليق'
                              : 'عرض المزيد...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isManagerOrAdmin) {
    return SelectionContainer.disabled(
      child: Column(
      children: [
        _actionBtn(
          Icons.open_in_new_rounded,
          AppColors.brandPrimary,
          widget.onTap,
          'فتح التفاصيل',
        ),
        SizedBox(height: 8.h),
        if (widget.onPinToggle != null) ...[
          _actionBtn(
            widget.lead.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            widget.lead.isPinned ? AppColors.brandPrimary : Colors.grey,
            widget.onPinToggle!,
            widget.lead.isPinned ? 'إلغاء التثبيت' : 'تثبيت',
          ),
          SizedBox(height: 8.h),
        ],
        if (widget.onEdit != null)
          _actionBtn(
            Icons.edit_rounded,
            AppColors.info,
            widget.onEdit!,
            'تعديل',
          ),

        if (widget.onRestore != null) ...[
          SizedBox(height: 8.h),
          _actionBtn(
            Icons.restore_page_outlined,
            Colors.green,
            widget.onRestore!,
            'استعادة',
          ),
        ],
        if (widget.onDelete != null) ...[
          SizedBox(height: 8.h),
          _actionBtn(
            Icons.delete_outline_rounded,
            AppColors.brandAccent,
            widget.onDelete!,
            'حذف',
          ),
        ],
      ],
    ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 24.sp, color: color),
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final int selectionIndexFromRight =
        newValue.text.length - newValue.selection.end;
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String newString = NumberFormat.decimalPattern().format(
      digits.isEmpty ? 0 : int.parse(digits),
    );
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: newString.length - selectionIndexFromRight,
      ),
    );
  }
}
