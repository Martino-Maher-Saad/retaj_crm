import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;

class ApprovalsInlineFilters extends StatefulWidget {
  final String? initialEmployeeId;
  final String? initialListingTypeId;
  final String? initialPropertyTypeId;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  
  final Function(
    String? employeeId,
    String? listingTypeId,
    String? propertyTypeId,
    DateTime? fromDate,
    DateTime? toDate,
  ) onApply;

  const ApprovalsInlineFilters({
    super.key,
    required this.onApply,
    this.initialEmployeeId,
    this.initialListingTypeId,
    this.initialPropertyTypeId,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<ApprovalsInlineFilters> createState() => _ApprovalsInlineFiltersState();
}

class _ApprovalsInlineFiltersState extends State<ApprovalsInlineFilters> {
  final dataManager = di.sl<StaticDataManager>();

  String? _selectedEmployee;
  String? _selectedPropertyType;
  String? _selectedListingType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.initialEmployeeId;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;

    if (widget.initialPropertyTypeId != null) {
      try {
        _selectedPropertyType = dataManager.getOptionModels('property_type').firstWhere((o) => o.id == widget.initialPropertyTypeId!).nameAr;
      } catch (_) {}
    }
    
    if (widget.initialListingTypeId != null) {
      try {
        _selectedListingType = dataManager.getOptionModels('listing_type').firstWhere((o) => o.id == widget.initialListingTypeId!).nameAr;
      } catch (_) {}
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brandPrimary),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = DateTime(date.year, date.month, date.day);
        } else {
          _toDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
        }
      });
      _apply();
    }
  }

  void _apply() {
    String? propId;
    if (_selectedPropertyType != null) {
      try {
        propId = dataManager.getOptionModels('property_type').firstWhere((o) => o.nameAr == _selectedPropertyType!).id;
      } catch (_) {}
    }

    String? listId;
    if (_selectedListingType != null) {
      try {
        listId = dataManager.getOptionModels('listing_type').firstWhere((o) => o.nameAr == _selectedListingType!).id;
      } catch (_) {}
    }

    widget.onApply(_selectedEmployee, listId, propId, _fromDate, _toDate);
  }

  void _clear() {
    setState(() {
      _selectedEmployee = null;
      _selectedPropertyType = null;
      _selectedListingType = null;
      _fromDate = null;
      _toDate = null;
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final employees = dataManager.employees;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: _buildSearchableDropdown(
            label: "الإعلان",
            options: dataManager.getOptions('listing_type'),
            selectedValue: _selectedListingType,
            onChanged: (v) {
              setState(() => _selectedListingType = v);
              _apply();
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: _buildSearchableDropdown(
            label: "العقار",
            options: dataManager.getOptions('property_type'),
            selectedValue: _selectedPropertyType,
            onChanged: (v) {
              setState(() => _selectedPropertyType = v);
              _apply();
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 3,
          child: _buildSearchableDropdown(
            label: "المسؤول",
            options: employees.map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim()).toList(),
            selectedValue: _selectedEmployee == null ? null : (() {
              try {
                final emp = employees.firstWhere((e) => e.id == _selectedEmployee);
                return '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
              } catch (_) { return null; }
            })(),
            onChanged: (displayName) {
              if (displayName == null) {
                setState(() => _selectedEmployee = null);
              } else {
                final emp = employees.firstWhere(
                  (e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim() == displayName,
                  orElse: () => employees.first,
                );
                setState(() => _selectedEmployee = emp.id);
              }
              _apply();
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => _pickDate(isFrom: true),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _fromDate == null ? "من" : DateFormat('yy/MM/dd').format(_fromDate!),
                      style: TextStyle(fontSize: 13.sp, color: _fromDate == null ? Colors.grey[600] : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 16.sp, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => _pickDate(isFrom: false),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _toDate == null ? "إلى" : DateFormat('yy/MM/dd').format(_toDate!),
                      style: TextStyle(fontSize: 13.sp, color: _toDate == null ? Colors.grey[600] : Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 16.sp, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),
        if (_selectedEmployee != null || _selectedPropertyType != null || _selectedListingType != null || _fromDate != null || _toDate != null) ...[
          SizedBox(width: 4.w),
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.clear, color: Colors.red),
            tooltip: "مسح الفلاتر",
          )
        ]
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          initialSelection: selectedValue,
          label: Text(label, style: TextStyle(fontSize: 13.sp)),
          enableFilter: true,
          enableSearch: true,
          menuHeight: 220, 
          width: constraints.maxWidth,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.borderSubtle)),
          ),
          dropdownMenuEntries: [
            const DropdownMenuEntry<String>(value: "", label: "الكل"),
            ...options.map((option) => DropdownMenuEntry<String>(value: option, label: option))
          ],
          onSelected: (val) => onChanged(val == "" ? null : val),
        );
      }
    );
  }
}
