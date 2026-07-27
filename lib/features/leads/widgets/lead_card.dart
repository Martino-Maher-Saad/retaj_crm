import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lead_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_states.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../screens/smart_match_screen.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';

class LeadCard extends StatefulWidget {
  final LeadModel lead;
  final String role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  
  // ─── Inline Edit/Add ───
  final bool initialEditMode;
  final bool isAddingMode;
  final VoidCallback? onCancelAdd;

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
    this.initialEditMode = false,
    this.isAddingMode = false,
    this.onCancelAdd,
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

  // ─── Inline Edit State ───
  late bool _isEditing;
  bool _isSavingInline = false;
  final TextEditingController _inlineNameController = TextEditingController();
  final TextEditingController _inlinePropertyCodeController = TextEditingController();
  final TextEditingController _inlinePhoneController = TextEditingController();
  int? _inlineSelectedCityId;
  final TextEditingController _inlineNeedsController = TextEditingController();
  String? _inlineSelectedStatus;
  String? _inlineSelectedPropertyType;
  String? _inlineSelectedListingType;
  String? _inlineSelectedPlatform;
  String? _inlineSelectedEmployeeId;
  num? _inlineBudgetFrom;
  num? _inlineBudgetTo;

  // قياس ارتفاع الكارت لجعل الفواصل مرنة
  final GlobalKey _mainRowKey = GlobalKey();
  double _dividerHeight = 120.0;

  /// لكسر حلقة: divider يحدد Row، وRow يحدد divider
  /// نعيّن الارتفاع إلى 1 أولاً حتى يتحدد الارتفاع بالمحتوى، ثم نقيس
  void _scheduleDividerUpdate({bool resetFirst = false}) {
    if (resetFirst) {
      // أعد التعيين داخل setState حتى يُعاد بناء Frame بارتفاع محتوى حقيقي
      setState(() => _dividerHeight = 1.0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box = _mainRowKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final newH = box.size.height;
        if ((newH - _dividerHeight).abs() > 0.5) {
          setState(() => _dividerHeight = newH);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
    if (_isEditing) {
      _initInlineEditData();
    }
    _checkDuplicates();
    _scheduleDividerUpdate();
  }

  void _initInlineEditData() {
    _inlineNameController.text = widget.lead.clientName;
    _inlinePhoneController.text = _primaryPhone?.phoneNumber ?? '';
    _inlinePropertyCodeController.text = widget.lead.propertyCode ?? '';
    _inlineSelectedCityId = widget.lead.cityId;
    _inlineNeedsController.text = widget.lead.descLeadNeed ?? '';
    _inlineBudgetFrom = widget.lead.budgetFrom;
    _inlineBudgetTo = widget.lead.budgetTo;
    
    final dataManager = di.sl<StaticDataManager>();

    final statusOptions = dataManager.getOptions('lead_status').toSet().toList();
    if (widget.isAddingMode) {
      _inlineSelectedStatus = null;
    } else {
      _inlineSelectedStatus = widget.lead.leadStatus;
      if (_inlineSelectedStatus == null || !statusOptions.contains(_inlineSelectedStatus)) {
        _inlineSelectedStatus = statusOptions.isNotEmpty ? statusOptions.first : null;
      }
    }

    final propertyTypeOptions = dataManager.getOptions('property_type').toSet().toList();
    _inlineSelectedPropertyType = widget.lead.propertyType;
    if (_inlineSelectedPropertyType != null && !propertyTypeOptions.contains(_inlineSelectedPropertyType)) {
      _inlineSelectedPropertyType = null;
    }

    final listingTypeOptions = dataManager.getOptions('listing_type').toSet().toList();
    _inlineSelectedListingType = widget.lead.listingType;
    if (_inlineSelectedListingType != null && !listingTypeOptions.contains(_inlineSelectedListingType)) {
      _inlineSelectedListingType = null;
    }

    final platformOptions = dataManager.getOptions('platform').toSet().toList();
    _inlineSelectedPlatform = widget.lead.platform;
    if (_inlineSelectedPlatform != null && !platformOptions.contains(_inlineSelectedPlatform)) {
      _inlineSelectedPlatform = null;
    }
    
    _inlineSelectedEmployeeId = widget.lead.assignedTo;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inlinePropertyCodeController.dispose();
    _inlineNameController.dispose();
    _inlinePhoneController.dispose();
    _inlineNeedsController.dispose();
    super.dispose();
  }

  void _checkDuplicates() async {
    final bool isAllowed =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo' ||
        widget.role == 'sales';
    if (!isAllowed || widget.lead.phones.isEmpty) return;

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
    if (widget.isAddingMode && !_isEditing) return const SizedBox.shrink();
    final bool isManagerOrAdmin =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo';
    final Color sColor = _statusColor(widget.lead.leadStatus);
    final bool hasPlatform = widget.lead.platformId != null;

    return Container(
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
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

            // المحتوى الرئيسي مع Row مقيس الارتفاع
            Row(
              key: _mainRowKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عمود الاسم والرقم
                Expanded(
                  flex: 3,
                  child: _buildFirstColumn(context, sColor, hasPlatform),
                ),

                Container(
                  width: 1.w,
                  height: _dividerHeight,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  color: Colors.grey[300],
                ),

                Expanded(
                  flex: 4,
                  child: _buildSecondColumn(context),
                ),

                Container(
                  width: 1.w,
                  height: _dividerHeight,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  color: Colors.grey[300],
                ),

                Expanded(
                  flex: 3,
                  child: _buildThirdColumn(context),
                ),

                SizedBox(width: 16.w),
                _buildActions(isManagerOrAdmin),
              ],
            ),
          ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    Container(
                      margin: EdgeInsets.only(bottom: 12.h, top: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _inlineNameController,
                        style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: 'اسم العميل (اختياري)',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                        ),
                      ),
                    )
                  else ...[
                    SelectableText(
                      widget.lead.clientName,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                        height: 1.1,
                      ),
                      maxLines: _isNameExpanded ? null : 1,
                    ),
                    if (isNameLong)
                      SelectionContainer.disabled(
                        child: TextButton(
                          onPressed: () {
                            final willCollapse = _isNameExpanded;
                            setState(() {
                              _isNameExpanded = !_isNameExpanded;
                            });
                            _scheduleDividerUpdate(resetFirst: willCollapse);
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
                ],
              ),
            ),
            if (widget.lead.createdAt != null) ...[
              SizedBox(width: 24.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تاريخ الإنشاء',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy', 'ar').format(widget.lead.createdAt!),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (_isEditing)
          Container(
            margin: EdgeInsets.only(bottom: 12.h, top: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: _inlinePhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
              decoration: InputDecoration(
                hintText: 'رقم الهاتف *',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              ),
            ),
          )
        else if (_primaryPhone != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    SelectableText(
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
              ),
              SizedBox(width: 12.w),
              InkWell(
                onTap: () => _launchWhatsAppWeb(_primaryPhone!.phoneNumber),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat, color: Colors.green, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text("واتساب ويب", style: TextStyle(color: Colors.green, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
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
            Expanded(
              child: _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المنصة *:', style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        SizedBox(height: 4.h),
                        _buildInlineDropdownMenu<String>(
                          'المنصة',
                          _inlineSelectedPlatform,
                          di.sl<StaticDataManager>().getOptions('platform').toSet().map((s) => DropdownMenuEntry(value: s, label: s)).toList(),
                          (val) => setState(() => _inlineSelectedPlatform = val),
                        ),
                      ],
                    )
                  : _infoRowSmall('المنصة:', widget.lead.platform ?? 'غير محدد'),
            ),
            Container(width: 1.w, height: 35.h, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 16.w)),
            Expanded(
              child: _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('حالة العميل:', style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        SizedBox(height: 4.h),
                        _buildInlineDropdownMenu<String>(
                          'الحالة',
                          _inlineSelectedStatus,
                          di.sl<StaticDataManager>().getOptions('lead_status').toSet().map((s) => DropdownMenuEntry(value: s, label: s)).toList(),
                          (val) => setState(() => _inlineSelectedStatus = val),
                        ),
                      ],
                    )
                  : _infoRowSmall('حالة العميل:', widget.lead.leadStatus ?? 'غير محدد', valueColor: sColor),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing && isManagerOrAdmin)
              Expanded(
                child: BlocBuilder<LeadCubit, LeadState>(
                  builder: (context, state) {
                    if (state is LeadLoaded && state.employees.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المسؤول *:', style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          SizedBox(height: 4.h),
                          _buildInlineDropdownMenu<String>(
                            'المسؤول',
                            state.employees.any((e) => e.id == _inlineSelectedEmployeeId) ? _inlineSelectedEmployeeId : null,
                            state.employees.map((e) => DropdownMenuEntry(value: e.id, label: e.firstName != null ? "${e.firstName} ${e.lastName}" : e.email)).toList(),
                            (val) => setState(() => _inlineSelectedEmployeeId = val),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              )
            else if (!_isEditing) ...[
              if (widget.lead.assignedTo == widget.lead.createdBy)
                Expanded(child: _infoRowSmall('المسؤول والمُنشئ:', widget.lead.assignedToName ?? 'غير محدد'))
              else ...[
                Expanded(child: _infoRowSmall('المُنشئ:', widget.lead.createdByName ?? 'غير محدد')),
                Container(width: 1.w, height: 35.h, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 16.w)),
                Expanded(child: _infoRowSmall('المسؤول:', widget.lead.assignedToName ?? 'غير محدد')),
              ]
            ]
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
          SelectableText(
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

    Widget? editFields;
    List<Widget> metaItems = [];

    if (_isEditing) {
      editFields = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المدينة *:', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    _buildInlineDropdownMenu<int>(
                      'المدينة',
                      _inlineSelectedCityId,
                      di.sl<StaticDataManager>().allCities.map((c) => DropdownMenuEntry(value: c.id, label: c.name)).toList(),
                      (val) => setState(() => _inlineSelectedCityId = val),
                    ),
                  ]
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نوع العقار *:', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    _buildInlineDropdownMenu<String>(
                      'نوع العقار',
                      _inlineSelectedPropertyType,
                      di.sl<StaticDataManager>().getOptions('property_type').toSet().map((s) => DropdownMenuEntry(value: s, label: s)).toList(),
                      (val) => setState(() => _inlineSelectedPropertyType = val),
                    ),
                  ]
                ),
              ),
            ]
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نوع الإعلان *:', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    _buildInlineDropdownMenu<String>(
                      'نوع الإعلان',
                      _inlineSelectedListingType,
                      di.sl<StaticDataManager>().getOptions('listing_type').toSet().map((s) => DropdownMenuEntry(value: s, label: s)).toList(),
                      (val) => setState(() => _inlineSelectedListingType = val),
                    ),
                  ]
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كود العقار (اختياري):', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    _buildInlineTextField(_inlinePropertyCodeController, 'كود العقار'),
                  ]
                ),
              ),
            ]
          )
        ]
      );
    } else {
      if (widget.lead.city != null && widget.lead.city!.isNotEmpty) {
        metaItems.add(
          SelectableText(
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
          SelectableText(
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
          SelectableText(
            widget.lead.listingType!,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (editFields != null)
          editFields
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metaItems.isNotEmpty)
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: metaItems,
                  ),
                ),
              if (widget.lead.propertyCode != null && widget.lead.propertyCode!.isNotEmpty) ...[
                if (metaItems.isNotEmpty) SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
                  ),
                  child: SelectableText(
                    'كود: ${widget.lead.propertyCode!}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),

        if (editFields != null || metaItems.isNotEmpty || (widget.lead.propertyCode != null && widget.lead.propertyCode!.isNotEmpty)) SizedBox(height: 6.h),

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
          child: _isEditing
              ? Row(
                  children: [
                    ElevatedButton.icon(
                      icon: _isSavingInline
                          ? SizedBox(width: 16.sp, height: 16.sp, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.save, size: 28.sp),
                      label: Text(
                        'حفظ',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                        minimumSize: Size.zero,
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      onPressed: _isSavingInline ? null : _saveInlineLead,
                    ),
                    SizedBox(width: 8.w),
                    OutlinedButton(
                      onPressed: () {
                        if (widget.isAddingMode) {
                          if (widget.onCancelAdd != null) widget.onCancelAdd!();
                        } else {
                          setState(() => _isEditing = false);
                          _scheduleDividerUpdate(resetFirst: true);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                        minimumSize: Size.zero,
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      child: Text('إلغاء', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              : ElevatedButton.icon(
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
                    final willCollapse = _isCommenting;
                    setState(() {
                      _isCommenting = !_isCommenting;
                    });
                    _scheduleDividerUpdate(resetFirst: willCollapse);
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
            if (_isEditing)
              TextFormField(
                controller: _inlineNeedsController,
                maxLines: 4,
                minLines: 1,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
                decoration: const InputDecoration(
                  hintText: 'وصف احتياجات العميل',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            else ...[
              SelectableText(
                need,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: _isNeedExpanded ? null : 2,
              ),
              if (isLong)
                SelectionContainer.disabled(
                  child: TextButton(
                    onPressed: () {
                      final willCollapse = _isNeedExpanded;
                      setState(() {
                        _isNeedExpanded = !_isNeedExpanded;
                      });
                      _scheduleDividerUpdate(resetFirst: willCollapse);
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
          ],
        );
      },
    );
  }

  void _editNeedsDialog() {
    final TextEditingController needController = TextEditingController(
      text: _isEditing ? _inlineNeedsController.text : (widget.lead.descLeadNeed ?? ''),
    );
    final num? currentBudgetFrom = _isEditing ? _inlineBudgetFrom : widget.lead.budgetFrom;
    final num? currentBudgetTo = _isEditing ? _inlineBudgetTo : widget.lead.budgetTo;

    final TextEditingController budgetFromController = TextEditingController(
      text: currentBudgetFrom != null
          ? NumberFormat.decimalPattern().format(currentBudgetFrom)
          : '',
    );
    final TextEditingController budgetToController = TextEditingController(
      text: currentBudgetTo != null
          ? NumberFormat.decimalPattern().format(currentBudgetTo)
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
                      if (_isEditing) {
                        setState(() {
                          _inlineNeedsController.text = needController.text.trim();
                          _inlineBudgetFrom = int.tryParse(budgetFromController.text.replaceAll(',', '').trim());
                          _inlineBudgetTo = int.tryParse(budgetToController.text.replaceAll(',', '').trim());
                        });
                        Navigator.pop(ctx);
                        return;
                      }

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
              final textWidget = SelectableText(
                comment,
                textDirection: ui.TextDirection.rtl,
                style: TextStyle(
                  fontSize: 24.sp,
                  color: hasComment ? Colors.black87 : Colors.grey[500],
                  fontWeight: hasComment ? FontWeight.w800 : FontWeight.normal,
                  height: 1.3,
                ),
                maxLines: _isCommentExpanded ? null : 3,
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
                          final willCollapse = _isCommentExpanded;
                          setState(() {
                            _isCommentExpanded = !_isCommentExpanded;
                          });
                          _scheduleDividerUpdate(resetFirst: willCollapse);
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
            () {
              setState(() {
                _isEditing = true;
                _initInlineEditData();
              });
            },
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

  Future<void> _saveInlineLead() async {
    final name = _inlineNameController.text.trim();
    final finalName = name;
    
    final phoneStr = _inlinePhoneController.text.trim();
    if (phoneStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف الأساسي مطلوب')));
      return;
    }
    
    if (_inlineSelectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المدينة مطلوبة')));
      return;
    }
    
    if (_inlineSelectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حالة العميل مطلوبة')));
      return;
    }
    
    if (_inlineSelectedListingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع الإعلان مطلوب')));
      return;
    }
    
    if (_inlineSelectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع العقار مطلوب')));
      return;
    }
    
    if (_inlineSelectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المنصة مطلوبة')));
      return;
    }

    final bool isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';
    if (isManagerOrAdmin && _inlineSelectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الموظف المسؤول مطلوب')));
      return;
    }
    
    setState(() => _isSavingInline = true);
    final dataManager = di.sl<StaticDataManager>();
    
    final statusId = _inlineSelectedStatus != null
        ? dataManager.getIdByName('lead_status', _inlineSelectedStatus!)
        : null;
    final propertyTypeId = _inlineSelectedPropertyType != null
        ? dataManager.getIdByName('property_type', _inlineSelectedPropertyType!)
        : null;
    final listingTypeId = _inlineSelectedListingType != null
        ? dataManager.getIdByName('listing_type', _inlineSelectedListingType!)
        : null;
    final platformId = _inlineSelectedPlatform != null
        ? dataManager.getIdByName('platform', _inlineSelectedPlatform!)
        : null;

    List<LeadPhoneModel> phones = widget.lead.phones.toList();
    if (phoneStr.isNotEmpty) {
      // Clean phone
      String rawPhone = phoneStr;
      const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      for (int i = 0; i < 10; i++) {
        rawPhone = rawPhone.replaceAll(arabicDigits[i], englishDigits[i]);
      }
      rawPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (phones.isNotEmpty) {
        phones[0] = LeadPhoneModel(
          phoneNumber: rawPhone,
          isPrimary: phones[0].isPrimary,
        );
      } else {
        phones.add(LeadPhoneModel(phoneNumber: rawPhone, isPrimary: true));
      }
    }

    final newLead = widget.lead.copyWith(
      clientName: finalName,
      leadStatus: _inlineSelectedStatus,
      statusId: statusId,
      propertyType: _inlineSelectedPropertyType,
      propertyTypeId: propertyTypeId,
      listingType: _inlineSelectedListingType,
      listingTypeId: listingTypeId,
      platform: _inlineSelectedPlatform,
      platformId: platformId,
      assignedTo: _inlineSelectedEmployeeId,
      cityId: _inlineSelectedCityId,
      governorate: widget.lead.governorate,
      city: di.sl<StaticDataManager>().allCities.where((c) => c.id == _inlineSelectedCityId).firstOrNull?.name ?? widget.lead.city,
      propertyCode: _inlinePropertyCodeController.text.trim(),
      descLeadNeed: _inlineNeedsController.text.trim(),
      budgetFrom: _inlineBudgetFrom,
      budgetTo: _inlineBudgetTo,
      phones: phones,
    );

    try {
      // ─── Duplicate Check ───
      final duplicates = await context.read<LeadCubit>().checkDuplicates(phones.map((p) => p.phoneNumber).toList());
      if (duplicates.isNotEmpty) {
        // Exclude the current lead if we are editing
        final otherDuplicates = duplicates.where((d) => d.id != widget.lead.id).toList();
        if (otherDuplicates.isNotEmpty) {
          final isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';
          final authState = context.read<AuthCubit>().state;
          final currentUserId = (authState is AuthSuccess) ? authState.user.id : null;

          bool shouldWarn = false;
          String warningMsg = '';

          if (isManagerOrAdmin) {
            shouldWarn = true;
            warningMsg = 'هذا الرقم مسجل بالفعل في النظام.';
          } else {
            // Sales
            final hasOwnDuplicate = otherDuplicates.any((d) => d.assignedTo == currentUserId);
            if (hasOwnDuplicate) {
              shouldWarn = true;
              warningMsg = 'هذا الرقم مسجل بالفعل لديك.';
            }
          }

          if (shouldWarn) {
            if (mounted) setState(() => _isSavingInline = false);
            
            final bool? proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('رقم مكرر ⚠️'),
                content: Text('$warningMsg\n\nالرقم المكرر:\n${phones.map((p) => p.phoneNumber).join('، ')}\n\nهل تريد المتابعة والحفظ على أي حال؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حفظ رغم التكرار', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (proceed != true) return;
            if (mounted) setState(() => _isSavingInline = true);
          }
        }
      }

      if (widget.isAddingMode) {
        await context.read<LeadCubit>().addLead(newLead, phones);
        if (mounted && widget.onCancelAdd != null) widget.onCancelAdd!();
      } else {
        await context.read<LeadCubit>().updateFullLead(newLead, phones);
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSavingInline = false;
          });
          _scheduleDividerUpdate(resetFirst: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingInline = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
      }
    }
  }
  Widget _buildInlineDropdownMenu<T>(String hint, T? value, List<DropdownMenuEntry<T>> entries, Function(T?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownMenu<T>(
        initialSelection: value,
        enableFilter: true,
        requestFocusOnTap: true,
        expandedInsets: EdgeInsets.zero,
        menuHeight: 200, 
        hintText: hint,
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        dropdownMenuEntries: entries,
        onSelected: onChanged,
      ),
    );
  }

  Widget _buildInlineTextField(TextEditingController controller, String hint, {List<TextInputFormatter>? formatters, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }

  Future<void> _launchWhatsAppWeb(String phone) async {
    // تنسيق الرقم ليكون دولياً إذا لم يكن كذلك (افتراض مصر إذا لم يبدأ بـ +)
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (formattedPhone.startsWith('01')) {
      formattedPhone = '+2$formattedPhone';
    } else if (formattedPhone.startsWith('1')) {
      formattedPhone = '+20$formattedPhone';
    }
    final url = Uri.parse('https://web.whatsapp.com/send?phone=$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب ويب')),
        );
      }
    }
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
