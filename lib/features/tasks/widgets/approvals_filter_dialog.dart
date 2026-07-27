import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;

class ApprovalsFilterDialog extends StatefulWidget {
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

  const ApprovalsFilterDialog({
    super.key,
    required this.onApply,
    this.initialEmployeeId,
    this.initialListingTypeId,
    this.initialPropertyTypeId,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<ApprovalsFilterDialog> createState() => _ApprovalsFilterDialogState();
}

class _ApprovalsFilterDialogState extends State<ApprovalsFilterDialog> {
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

  Future<void> _pickDateTime({required bool isFrom}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        final finalDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          if (isFrom) {
            _fromDate = finalDateTime;
          } else {
            _toDate = finalDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = dataManager.employees;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500.w),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تصفية الموافقات",
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  _buildDropdown(
                    "نوع الإعلان",
                    dataManager.getOptions('listing_type'),
                    _selectedListingType,
                    (v) => setState(() => _selectedListingType = v),
                  ),
                  SizedBox(height: 14.h),
                  _buildDropdown(
                    "نوع العقار",
                    dataManager.getOptions('property_type'),
                    _selectedPropertyType,
                    (v) => setState(() => _selectedPropertyType = v),
                  ),
                  SizedBox(height: 14.h),
                  
                  RetajDropdown<String>(
                    label: "الموظف المسؤول",
                    value: _selectedEmployee == null ? null : (() {
                      try {
                        final emp = employees.firstWhere((e) => e.id == _selectedEmployee);
                        return '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                      } catch (_) { return null; }
                    })(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("الكل")),
                      ...employees.map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim()).toList()
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    ],
                    onChanged: (displayName) {
                      if (displayName == null) {
                        setState(() => _selectedEmployee = null);
                        return;
                      }
                      final emp = employees.firstWhere(
                        (e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim() == displayName,
                        orElse: () => employees.first,
                      );
                      setState(() => _selectedEmployee = emp.id);
                    },
                  ),

                  SizedBox(height: 24.h),
                  Text("نطاق التاريخ (تاريخ الإضافة):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(isFrom: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: "من تاريخ", border: OutlineInputBorder()),
                            child: Text(_fromDate == null ? "اختر..." : DateFormat('yyyy/MM/dd hh:mm a').format(_fromDate!)),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(isFrom: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: "إلى تاريخ", border: OutlineInputBorder()),
                            child: Text(_toDate == null ? "اختر..." : DateFormat('yyyy/MM/dd hh:mm a').format(_toDate!)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fromDate != null || _toDate != null) ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() { _fromDate = null; _toDate = null; }),
                        icon: const Icon(Icons.clear, color: Colors.red),
                        label: const Text("مسح التاريخ", style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],

                  SizedBox(height: 40.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("إلغاء", style: TextStyle(color: Colors.red, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () {
                            final propertyTypeId = _selectedPropertyType != null
                                ? dataManager.getIdByName('property_type', _selectedPropertyType!)
                                : null;
                            final listingTypeId = _selectedListingType != null
                                ? dataManager.getIdByName('listing_type', _selectedListingType!)
                                : null;

                            widget.onApply(
                              _selectedEmployee,
                              listingTypeId,
                              propertyTypeId,
                              _fromDate,
                              _toDate,
                            );
                          },
                          child: Text("تطبيق", style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return RetajDropdown<String>(
      label: hint,
      value: value,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text("الكل")),
        ...items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))),
      ],
      onChanged: onChanged,
    );
  }
}
