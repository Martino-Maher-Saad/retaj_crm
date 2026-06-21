import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../data/models/lead_model.dart';
import '../../../../data/repositories/lead_repository.dart';
import 'export_helper.dart';

class DashboardLeadsTable extends StatefulWidget {
  final String role;
  final String userId;

  const DashboardLeadsTable({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  State<DashboardLeadsTable> createState() => _DashboardLeadsTableState();
}

class _DashboardLeadsTableState extends State<DashboardLeadsTable> {
  final _leadRepo = di.sl<LeadRepository>();
  final _dataManager = di.sl<StaticDataManager>();

  // Filter States
  final _searchController = TextEditingController();
  String? _selectedListingTypeId;
  String? _selectedPropertyTypeId;
  String? _selectedStatusId;
  int? _selectedCityId;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedEmployeeId;

  List<LeadModel> _leads = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardLeadsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.role != widget.role) {
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedLeads = await _leadRepo.fetchDashboardExcelLeads(
        role: widget.role,
        userId: widget.userId,
        filterByEmployeeId: _selectedEmployeeId,
        listingTypeId: _selectedListingTypeId,
        propertyTypeId: _selectedPropertyTypeId,
        cityId: _selectedCityId,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      // تصفية العملاء بناءً على الحالة محلياً
      var filtered = fetchedLeads;
      if (_selectedStatusId != null) {
        filtered = filtered.where((l) => l.statusId == _selectedStatusId).toList();
      }

      // تصفية العملاء بناءً على حقل البحث بالاسم أو الهاتف
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        _leads = filtered.where((l) {
          final matchName = l.clientName.toLowerCase().contains(query);
          final matchPhone = l.phones.any((p) => p.phoneNumber.contains(query));
          return matchName || matchPhone;
        }).toList();
      } else {
        _leads = filtered;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadLeads();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedListingTypeId = null;
      _selectedPropertyTypeId = null;
      _selectedStatusId = null;
      _selectedCityId = null;
      _fromDate = null;
      _toDate = null;
      _selectedEmployeeId = null;
    });
    _loadLeads();
  }

  @override
  Widget build(BuildContext context) {
    final listingTypes = _dataManager.getOptionModels('listing_type');
    final propertyTypes = _dataManager.getOptionModels('property_type');
    final statuses = _dataManager.getOptionModels('lead_status');
    final cities = _dataManager.allCities;
    final employees = _dataManager.employees;

    final isManager = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';

    return Container(
      margin: EdgeInsets.only(top: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => DashboardExportHelper.exportToPdf(_leads),
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                    label: Text('تصدير PDF', style: TextStyle(color: Colors.red, fontSize: 14.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  OutlinedButton.icon(
                    onPressed: () => DashboardExportHelper.exportToExcel(_leads),
                    icon: const Icon(Icons.grid_on_outlined, color: Colors.green),
                    label: Text('تصدير Excel', style: TextStyle(color: Colors.green, fontSize: 14.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('تقرير تفاصيل ومتابعة العملاء', style: AppTextStyles.h2.copyWith(fontSize: 22.sp, fontFamily: 'Cairo')),
                  SizedBox(width: 8.w),
                  Icon(Icons.table_chart_rounded, color: AppColors.brandPrimary, size: 24.sp),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Filters Row 1
          Row(
            children: [
              Expanded(
                flex: 2,
                child: RetajTextField(
                  controller: _searchController,
                  label: 'بحث باسم العميل أو الهاتف...',
                  prefixIcon: Icons.search,
                  onChanged: (val) {
                    // Debounce is handled natively by user typing submit
                  },
                  onSubmitted: (_) => _loadLeads(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: RetajDropdown<String?>(
                  value: _selectedStatusId,
                  label: 'حالة العميل',
                  prefixIcon: Icons.star_border_rounded,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    ...statuses.map((t) {
                      return DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.nameAr),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedStatusId = val);
                    _loadLeads();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: RetajDropdown<String?>(
                  value: _selectedListingTypeId,
                  label: 'نوع الإعلان',
                  prefixIcon: Icons.sell_outlined,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    ...listingTypes.map((t) {
                      return DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.nameAr),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedListingTypeId = val);
                    _loadLeads();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: RetajDropdown<String?>(
                  value: _selectedPropertyTypeId,
                  label: 'نوع العقار',
                  prefixIcon: Icons.home_work_outlined,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    ...propertyTypes.map((t) {
                      return DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.nameAr),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedPropertyTypeId = val);
                    _loadLeads();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Filters Row 2
          Row(
            children: [
              Expanded(
                child: RetajDropdown<int?>(
                  value: _selectedCityId,
                  label: 'المدينة',
                  prefixIcon: Icons.location_city_outlined,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    ...cities.map((c) {
                      return DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCityId = val);
                    _loadLeads();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              if (isManager) ...[
                Expanded(
                  child: RetajDropdown<String?>(
                    value: _selectedEmployeeId,
                    label: 'الموظف المسؤول',
                    prefixIcon: Icons.people_outline,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('الكل'),
                      ),
                      ...employees.map((e) {
                        return DropdownMenuItem<String?>(
                          value: e.id,
                          child: Text(e.fullName),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedEmployeeId = val);
                      _loadLeads();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range_rounded, size: 20.sp),
                  label: Text(
                    _fromDate == null
                        ? 'تاريخ الإضافة'
                        : '${DateFormat("MM/dd").format(_fromDate!)} - ${DateFormat("MM/dd").format(_toDate!)}',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: _clearFilters,
                icon: Icon(Icons.filter_alt_off, color: Colors.red, size: 26.sp),
                tooltip: 'تفريغ الفلاتر',
                padding: EdgeInsets.all(12.r),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // كارت العدد الكلي للعملاء (تم نقله إلى أول الجدول)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFC0DFFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_leads.length} عملاء',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E3A8A),
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'العدد الكلي للعملاء المعروضين بالجدول وفقاً للفلاتر:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // Main Table Area
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
            )
          else if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'خطأ أثناء تحميل الجدول: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 15.sp, fontFamily: 'Cairo'),
              ),
            )
          else if (_leads.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Center(child: Text('لا توجد نتائج مطابقة للفلاتر المعيّنة', style: TextStyle(fontSize: 16.sp, fontFamily: 'Cairo'))),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEAEAF0)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  dataRowMinHeight: 85.h,
                  dataRowMaxHeight: 120.h,
                  headingRowHeight: 65.h,
                  columns: [
                    DataColumn(label: Text('#', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('اسم العميل', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('أرقام الهاتف', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('المسؤول', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('الحالة الحالية', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('نوع الإعلان', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('نوع العقار', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('المدينة', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('الملاحظات', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                    DataColumn(label: Text('سجل تغيير الحالات', style: AppTextStyles.tableHeader.copyWith(fontSize: 19.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                  ],
                  rows: _leads.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final lead = entry.value;

                    final phones = lead.phones.map((p) => p.phoneNumber).join('\n');
                    final notes = lead.notes
                        .map((n) => '• ${n.userName ?? "موظف"}: ${n.noteText}')
                        .join('\n');

                    final logs = lead.logs
                        .where((log) => log.action == 'status_changed')
                        .map((log) =>
                            '${log.oldStatusName ?? "—"} ➔ ${log.newStatusName ?? "—"} (${DateFormat("MM/dd").format(log.createdAt)})')
                        .join('\n');

                    return DataRow(
                      cells: [
                        DataCell(Text('${idx + 1}', style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
                        DataCell(Text(lead.clientName, style: AppTextStyles.tableCellMain.copyWith(fontWeight: FontWeight.w900, fontSize: 20.sp, fontFamily: 'Cairo'))),
                        DataCell(Text(phones, style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontFamily: 'Cairo'), textAlign: TextAlign.left)),
                        DataCell(Text(lead.assignedToName ?? '—', style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontFamily: 'Cairo'))),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(lead.leadStatus ?? '—', style: AppTextStyles.tableCellSub.copyWith(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 18.sp, fontFamily: 'Cairo')),
                          ),
                        ),
                        DataCell(Text(lead.listingType ?? '—', style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontFamily: 'Cairo'))),
                        DataCell(Text(lead.propertyType ?? '—', style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontFamily: 'Cairo'))),
                        DataCell(Text(lead.city ?? '—', style: AppTextStyles.tableCellSub.copyWith(fontSize: 18.sp, fontFamily: 'Cairo'))),
                        DataCell(
                          SizedBox(
                            width: 300.w,
                            child: Text(
                              notes.isEmpty ? '—' : notes,
                              style: AppTextStyles.tableCellSub.copyWith(fontSize: 17.sp, fontFamily: 'Cairo'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 320.w,
                            child: Text(
                              logs.isEmpty ? '—' : logs,
                              style: AppTextStyles.tableCellSub.copyWith(fontSize: 17.sp, fontFamily: 'Cairo'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
