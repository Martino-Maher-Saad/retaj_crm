import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/services/dropdown_service.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/widgets/property_card.dart';
import '../../properties/widgets/list/property_shimmer_list.dart';
import '../cubit/marketing_cubit.dart';
import '../cubit/marketing_state.dart';

class MarketingScreen extends StatefulWidget {
  final ProfileModel user;

  const MarketingScreen({super.key, required this.user});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen>
    with AutomaticKeepAliveClientMixin {
  late MarketingCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  // فلاتر
  final TextEditingController _codeController = TextEditingController();
  String? _selectedEmployeeId;
  String? _selectedStatusId;
  DateTime? _fromDate;
  DateTime? _toDate;

  List<Map<String, dynamic>> _employees = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // موظف الماركيتينج يشوف بس عقارات الموظفين المخصصين له
    final assignedIds = widget.user.isMarketing && widget.user.assignedEmployees.isNotEmpty
        ? widget.user.assignedEmployees
        : null;
    _cubit = context.read<MarketingCubit>()
      ..fetchProperties(
        excludeUserId: widget.user.id,
        isRefresh: true,
        assignedEmployeeIds: assignedIds,
      );
    _scrollController.addListener(_onScroll);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final dataManager = di.sl<StaticDataManager>();
      List<ProfileModel> emps;
      // لو موظف ماركيتينج وعنده موظفين مخصصين، يعرض بس هما
      if (widget.user.isMarketing && widget.user.assignedEmployees.isNotEmpty) {
        emps = dataManager.employees
            .where((e) => widget.user.assignedEmployees.contains(e.id))
            .toList();
      } else {
        emps = dataManager.employees
            .where((e) => e.id != widget.user.id)
            .toList();
      }
      final data = emps
          .map((e) => <String, dynamic>{
                'id': e.id,
                'first_name': e.firstName,
                'last_name': e.lastName,
              })
          .toList();
      if (mounted) setState(() => _employees = data);
    } catch (_) {}
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
      _cubit.loadMore(widget.user.id);
    }
  }

  void _applyFilters() {
    final assignedIds = widget.user.isMarketing && widget.user.assignedEmployees.isNotEmpty
        ? widget.user.assignedEmployees
        : null;
    _cubit.fetchProperties(
      excludeUserId: widget.user.id,
      isRefresh: true,
      filterEmployeeId: _selectedEmployeeId,
      filterApprovalStatusId: _selectedStatusId,
      filterFromDate: _fromDate,
      filterToDate: _toDate,
      filterPropertyCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      overwriteFilters: true,
      assignedEmployeeIds: assignedIds,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedEmployeeId = null;
      _selectedStatusId = null;
      _fromDate = null;
      _toDate = null;
      _codeController.clear();
    });
    _cubit.clearFilters(widget.user.id);
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A), // AppColors.brandPrimary
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
            _buildCombinedHeaderAndFilters(),
            Expanded(
              child: BlocBuilder<MarketingCubit, MarketingState>(
                builder: (context, state) {
                  if (state is MarketingLoading) return const PropertyShimmerList();
                  if (state is MarketingError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  }
                  if (state is MarketingSuccess) {
                    return _buildList(state);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildCombinedHeaderAndFilters() {
    final dataManager = di.sl<StaticDataManager>();
    final statuses = dataManager.getOptionModels('property_approval_statuses');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          children: [
            // 1. Icon and Title
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.campaign_rounded, color: AppColors.brandPrimary, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الإعلانات',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
                ),
                BlocBuilder<MarketingCubit, MarketingState>(
                  builder: (context, state) {
                    final count = state is MarketingSuccess ? state.properties.length : 0;
                    return Text(
                      'عقارات الشركة • $count نتيجة',
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                    );
                  },
                ),
              ],
            ),
            SizedBox(width: 24.w),
            
            // 2. Filters
            Expanded(
              child: Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // بحث بكود العقار
                  SizedBox(
                    width: 280.w, // كبرنا خانة البحث
                    height: 55.h, // كبرنا الارتفاع
                    child: TextField(
                      controller: _codeController,
                      onSubmitted: (_) => _applyFilters(),
                      textDirection: ui.TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'ابحث بكود العقار...',
                        hintStyle: TextStyle(fontSize: 16.sp), // كبرنا الخط
                        prefixIcon: Icon(Icons.search, size: 24.sp), // كبرنا الأيقونة
                        suffixIcon: _codeController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  _codeController.clear();
                                  _applyFilters();
                                },
                              ) 
                            : null,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: TextStyle(fontSize: 16.sp),
                      onChanged: (val) {
                        setState(() {}); // to show/hide the suffix close icon
                      },
                    ),
                  ),

                  // فلتر الموظف
                  _buildDropdownMenuFilter<String>(
                    hint: 'الموظف',
                    icon: Icons.person_outline,
                    value: _selectedEmployeeId,
                    options: {
                      for (var e in _employees)
                        e['id'] as String: '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim()
                    },
                    onChanged: (v) {
                      setState(() => _selectedEmployeeId = v);
                      _applyFilters();
                    },
                  ),

                  // فلتر حالة العقار
                  _buildDropdownMenuFilter<String>(
                    hint: 'حالة العقار',
                    icon: Icons.flag_outlined,
                    value: _selectedStatusId,
                    options: {
                      for (var s in statuses)
                        s.id: s.nameAr
                    },
                    onChanged: (v) {
                      setState(() => _selectedStatusId = v);
                      _applyFilters();
                    },
                  ),

                  // فلتر من تاريخ
                  _buildDateChip(
                    label: _fromDate != null ? 'من: ${DateFormat('dd/MM/yy').format(_fromDate!)}' : 'من تاريخ',
                    onTap: () => _pickDate(true),
                    onClear: _fromDate != null ? () {
                      setState(() => _fromDate = null);
                      _applyFilters();
                    } : null,
                  ),

                  // فلتر إلى تاريخ
                  _buildDateChip(
                    label: _toDate != null ? 'إلى: ${DateFormat('dd/MM/yy').format(_toDate!)}' : 'إلى تاريخ',
                    onTap: () => _pickDate(false),
                    onClear: _toDate != null ? () {
                      setState(() => _toDate = null);
                      _applyFilters();
                    } : null,
                  ),
                ],
              ),
            ),
            
            // 3. Actions
            BlocBuilder<MarketingCubit, MarketingState>(
              builder: (context, state) {
                final hasFilter = state is MarketingSuccess && state.hasActiveFilter;
                if (!hasFilter) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all_rounded, color: Colors.red, size: 24),
                    label: Text('إلغاء الفلاتر', style: TextStyle(color: Colors.red, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 8.w),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppColors.brandPrimary, size: 24.sp),
              tooltip: 'تحديث',
              onPressed: () => _cubit.fetchProperties(excludeUserId: widget.user.id, isRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownMenuFilter<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required Map<T, String> options,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownMenu<T?>(
      initialSelection: value,
      onSelected: onChanged,
      enableFilter: true,
      enableSearch: false,
      menuHeight: 250.h,
      width: 220.w, // كبرنا العرض
      textStyle: TextStyle(fontSize: 16.sp), // كبرنا الخط
      hintText: hint,
      leadingIcon: Icon(icon, size: 22.sp, color: Colors.grey.shade600), // كبرنا الأيقونة
      dropdownMenuEntries: [
        DropdownMenuEntry<T?>(value: null, label: 'الكل'),
        ...options.entries.map((e) => DropdownMenuEntry<T?>(value: e.key, label: e.value)),
      ],
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0.h),
        constraints: BoxConstraints(maxHeight: 55.h), // كبرنا الارتفاع
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.brandPrimary)),
      ),
    );
  }

  Widget _buildDateChip({required String label, required VoidCallback onTap, VoidCallback? onClear}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 55.h, // كبرنا الارتفاع
        padding: EdgeInsets.symmetric(horizontal: 16.w), // زيادة الحواف
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10.r),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 22.sp, color: Colors.grey.shade600), // كبرنا الأيقونة
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700)), // كبرنا الخط
            if (onClear != null) ...[
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 20.sp, color: Colors.red), // كبرنا أيقونة الإغلاق
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(MarketingSuccess state) {
    if (state.properties.isEmpty && state.pendingProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text('لا توجد عقارات', style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                'إجمالي العقارات: ${state.totalCount}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
        if (state.hasNewUpdates && state.pendingProperties.isNotEmpty)
          _buildUpdateBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _cubit.fetchProperties(excludeUserId: widget.user.id, isRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              itemCount: state.properties.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.properties.length) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ));
                }
                final property = state.properties[index];
                return BlocProvider(
                  create: (_) => di.sl<PropertiesCubit>(),
                  child: PropertyCard(
                    key: ValueKey(property.id),
                    property: property,
                    currentUserId: widget.user.id,
                    role: widget.user.role,
                    hideOwnerPhone: widget.user.isMarketing,
                    platformOnlyMode: true,
                    onTap: () {},
                    onEdit: widget.user.isMarketing ? null : () {},
                    onPlatformSaved: (updated) => _cubit.patchProperty(updated),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateBanner() {
    return GestureDetector(
      onTap: () => _cubit.applyPendingUpdates(),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, color: AppColors.brandPrimary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'يوجد عقارات جديدة، انقر للتحديث',
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
