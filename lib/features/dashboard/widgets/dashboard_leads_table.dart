import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

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

  // Controllers for synchronized scrollbars
  final ScrollController _topScrollController = ScrollController();
  final ScrollController _bottomScrollController = ScrollController();

  // Expanded states for notes and logs
  final Set<int> _expandedNotes = {};
  final Set<int> _expandedLogs = {};

  final TextStyle headerStyle = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Cairo',
  );

  final TextStyle cellStyle = TextStyle(
    fontSize: 18.sp,
    color: AppColors.textPrimary,
    fontFamily: 'Cairo',
  );

  @override
  void initState() {
    super.initState();
    _loadLeads();

    _topScrollController.addListener(() {
      if (_topScrollController.offset != _bottomScrollController.offset) {
        _bottomScrollController.jumpTo(_topScrollController.offset);
      }
    });

    _bottomScrollController.addListener(() {
      if (_bottomScrollController.offset != _topScrollController.offset) {
        _topScrollController.jumpTo(_topScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _topScrollController.dispose();
    _bottomScrollController.dispose();
    super.dispose();
  }

  Widget _cell(
    String text,
    double width, {
    bool isHeader = false,
    bool isBold = false,
    Color? color,
    TextDirection? textDirection,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: isHeader
            ? headerStyle
            : cellStyle.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
        overflow: TextOverflow.ellipsis,
        maxLines: isHeader ? 2 : 3,
        textDirection: textDirection,
        textAlign: textDirection == TextDirection.rtl ? TextAlign.right : null,
      ),
    );
  }

  Widget _customCell(Widget child, double width) {
    return SizedBox(width: width, child: child);
  }

  Widget _buildNotesCell(LeadModel lead, int idx) {
    if (lead.notes.isEmpty) {
      return SizedBox(
        width: 300.w,
        child: Text(
          '—',
          style: cellStyle,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      );
    }

    final isExpanded = _expandedNotes.contains(idx);
    final List<String> notesList = lead.notes
        .map((n) => '• ${n.noteText}')
        .toList();

    final bool hasMore =
        notesList.length > 3 || notesList.any((note) => note.length > 100);
    final List<String> displayedNotes = isExpanded
        ? notesList
        : notesList
              .take(3)
              .map(
                (note) =>
                    note.length > 100 ? '${note.substring(0, 97)}...' : note,
              )
              .toList();

    return SizedBox(
      width: 300.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...displayedNotes.map(
            (note) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                note,
                style: cellStyle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          if (hasMore) ...[
            SizedBox(height: 4.h),
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedNotes.remove(idx);
                  } else {
                    _expandedNotes.add(idx);
                  }
                });
              },
              child: Text(
                isExpanded ? 'عرض أقل' : 'المزيد...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsCell(LeadModel lead, int idx) {
    final statusLogs = lead.logs
        .where((log) => log.action == 'status_changed')
        .map((log) {
          final dateStr = DateFormat("dd/MM/yyyy HH:mm").format(log.createdAt);
          final changerStr = log.createdByName != null
              ? ' بواسطة (${log.createdByName})'
              : '';
          return '• $dateStr$changerStr: تم تحويل العميل من (${log.oldStatusName ?? "—"}) الي (${log.newStatusName ?? "—"})';
        })
        .toList();

    if (statusLogs.isEmpty) {
      return SizedBox(
        width: 350.w,
        child: Text(
          '—',
          style: cellStyle,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      );
    }

    final isExpanded = _expandedLogs.contains(idx);
    final bool hasMore = statusLogs.length > 3;
    final List<String> displayedLogs = isExpanded
        ? statusLogs
        : statusLogs.take(3).toList();

    return SizedBox(
      width: 350.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...displayedLogs.map(
            (log) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                log,
                style: cellStyle,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          if (hasMore) ...[
            SizedBox(height: 4.h),
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedLogs.remove(idx);
                  } else {
                    _expandedLogs.add(idx);
                  }
                });
              },
              child: Text(
                isExpanded ? 'عرض أقل' : 'المزيد...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhonesCell(LeadModel lead) {
    if (lead.phones.isEmpty) {
      return Text('—', style: cellStyle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: lead.phones
          .map((p) => Text(p.phoneNumber, style: cellStyle))
          .toList(),
    );
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
        filtered = filtered
            .where((l) => l.statusId == _selectedStatusId)
            .toList();
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
    } catch (e, s) {
      print("============== LEADS INVENTORY ERROR DETECTED ==============");
      print("Error loading dashboard leads table: $e");
      print("Stack trace: $s");
      print("==========================================================");
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

    final isManager =
        widget.role == 'manager' ||
        widget.role == 'admin' ||
        widget.role == 'ceo';

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
          ),
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
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                    label: Text(
                      'تصدير PDF',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  OutlinedButton.icon(
                    onPressed: () =>
                        DashboardExportHelper.exportToExcel(_leads),
                    icon: const Icon(
                      Icons.grid_on_outlined,
                      color: Colors.green,
                    ),
                    label: Text(
                      'تصدير Excel',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'تقرير تفاصيل ومتابعة العملاء',
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 22.sp,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.table_chart_rounded,
                    color: AppColors.brandPrimary,
                    size: 24.sp,
                  ),
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
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: _clearFilters,
                icon: Icon(
                  Icons.filter_alt_off,
                  color: Colors.red,
                  size: 26.sp,
                ),
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
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'خطأ أثناء تحميل الجدول: $_errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15.sp,
                  fontFamily: 'Cairo',
                ),
              ),
            )
          else if (_leads.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Center(
                child: Text(
                  'لا توجد نتائج مطابقة للفلاتر المعيّنة',
                  style: TextStyle(fontSize: 16.sp, fontFamily: 'Cairo'),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEAEAF0)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // المؤشر العلوي للتمرير الأفقي (Top Scrollbar)
                  Scrollbar(
                    controller: _topScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _topScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: 2880.w, height: 12.h),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // جدول البيانات الأساسي مع التمرير المتزامن
                  Scrollbar(
                    controller: _bottomScrollController,
                    child: SingleChildScrollView(
                      controller: _bottomScrollController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16.w,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        dataRowMinHeight: 65.h,
                        dataRowMaxHeight: double.infinity,
                        headingRowHeight: 65.h,
                        columns: [
                          DataColumn(label: _cell('#', 50.w, isHeader: true)),
                          DataColumn(
                            label: _cell('اسم العميل', 180.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('أرقام الهاتف', 150.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('المسؤول', 150.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell(
                              'تاريخ الإضافة',
                              160.w,
                              isHeader: true,
                            ),
                          ),
                          DataColumn(
                            label: _cell('كود العقار', 120.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('طلب العميل', 250.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('المنصة', 130.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell(
                              'الحالة الحالية',
                              150.w,
                              isHeader: true,
                            ),
                          ),
                          DataColumn(
                            label: _cell(
                              'سبب الاستبعاد',
                              160.w,
                              isHeader: true,
                            ),
                          ),
                          DataColumn(
                            label: _cell('نوع الإعلان', 130.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('نوع العقار', 130.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('المدينة', 130.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell('الملاحظات', 300.w, isHeader: true),
                          ),
                          DataColumn(
                            label: _cell(
                              'سجل تغيير الحالات',
                              350.w,
                              isHeader: true,
                            ),
                          ),
                        ],
                        rows: _leads.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final lead = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(_cell('${idx + 1}', 50.w, isBold: true)),
                              DataCell(
                                _cell(lead.clientName, 180.w, isBold: true),
                              ),
                              DataCell(
                                _customCell(_buildPhonesCell(lead), 150.w),
                              ),
                              DataCell(
                                _cell(lead.assignedToName ?? '—', 150.w),
                              ),
                              DataCell(
                                _cell(
                                  lead.createdAt != null
                                      ? DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                          'en',
                                        ).format(lead.createdAt!)
                                      : '—',
                                  160.w,
                                ),
                              ),
                              DataCell(_cell(lead.propertyCode ?? '—', 120.w)),
                              DataCell(
                                _cell(
                                  lead.descLeadNeed ?? '—',
                                  250.w,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              DataCell(_cell(lead.platform ?? '—', 130.w)),
                              DataCell(
                                _customCell(
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      lead.leadStatus ?? '—',
                                      style: cellStyle.copyWith(
                                        color: AppColors.brandPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  150.w,
                                ),
                              ),
                              DataCell(
                                _cell(lead.exclusionReasonName ?? '—', 160.w),
                              ),
                              DataCell(_cell(lead.listingType ?? '—', 130.w)),
                              DataCell(_cell(lead.propertyType ?? '—', 130.w)),
                              DataCell(_cell(lead.city ?? '—', 130.w)),
                              DataCell(
                                _customCell(_buildNotesCell(lead, idx), 300.w),
                              ),
                              DataCell(
                                _customCell(_buildLogsCell(lead, idx), 350.w),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
