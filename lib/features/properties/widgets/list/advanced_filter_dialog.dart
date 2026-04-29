import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../cubit/properties_cubit.dart';

class AdvancedFilterDialog extends StatefulWidget {
  final String role;
  final String currentUserId;

  const AdvancedFilterDialog({
    super.key,
    required this.role,
    required this.currentUserId,
  });

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  final dataManager = di.sl<StaticDataManager>();

  int? _selectedGovId;
  String? _selectedCityName;
  String? _selectedPropertyType;
  String? _selectedListingType;
  String? _selectedEmployee; // For manager

  double _minPrice = 0;
  double _maxPrice = 100000000;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
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
    // استخدام الموظفين المحملين مسبقاً من الـ StaticDataManager
    final employees = dataManager.employees;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w),
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
                "الفلاتر المتقدمة",
                style: TextStyle(
                  fontSize: 22.sp,
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
              
              // قائمة المحافظات المنسدلة
              RetajDropdown<int>(
                label: "المحافظة",
                value: _selectedGovId,
                items: dataManager.governorates
                    .map(
                      (g) => DropdownMenuItem<int>(
                        value: g.id,
                        child: Text(g.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedGovId = v;
                    _selectedCityName = null; // تفريغ المدينة عند تغيير المحافظة
                  });
                },
              ),
              SizedBox(height: 14.h),

              // قائمة المدن المنسدلة
              RetajDropdown<String>(
                label: "المدينة",
                value: _selectedCityName,
                items: _selectedGovId == null
                    ? []
                    : dataManager
                        .getCitiesByGovId(_selectedGovId!)
                        .map((c) => c.name)
                        .toSet()
                        .map(
                          (name) => DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          ),
                        )
                        .toList(),
                onChanged: _selectedGovId == null
                    ? null
                    : (v) => setState(() => _selectedCityName = v),
              ),

              SizedBox(height: 24.h),
              Text("اختر نطاق السعر:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 100000000,
                divisions: 100,
                labels: RangeLabels(_minPrice.toStringAsFixed(0), _maxPrice.toStringAsFixed(0)),
                activeColor: AppColors.brandPrimary,
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),

              SizedBox(height: 24.h),
              Text("تاريخ الإضافة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isFrom: true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_fromDate == null 
                          ? "من تاريخ" 
                          : DateFormat('dd/MM/yyyy HH:mm').format(_fromDate!)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isFrom: false),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_toDate == null 
                          ? "إلى تاريخ" 
                          : DateFormat('dd/MM/yyyy HH:mm').format(_toDate!)),
                    ),
                  ),
                ],
              ),
              
              // خاصية المدير للبحث باسم الموظف
              if (widget.role == 'manager' || widget.role == 'admin') ...[
                SizedBox(height: 24.h),
                Text("الموظف (للمديرين فقط):", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary, fontSize: 16.sp)),
                SizedBox(height: 10.h),
                _buildDropdown(
                  "كل الموظفين",
                  employees.map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim()).toList(),
                  _selectedEmployee == null ? null : (() {
                    try {
                      final emp = employees.firstWhere((e) => e.id == _selectedEmployee);
                      return '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                    } catch (_) { return null; }
                  })(),
                  (displayName) {
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
                      child: Text("إلغاء", style: TextStyle(color: Colors.red, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
                        String? govName;
                        if (_selectedGovId != null) {
                          govName = dataManager.governorates.firstWhere((g) => g.id == _selectedGovId).name;
                        }

                        context.read<PropertiesCubit>().applyAdvancedFilters(
                          role: widget.role,
                          currentUserId: widget.currentUserId,
                          listingType: _selectedListingType,
                          type: _selectedPropertyType,
                          city: _selectedCityName,
                          governorate: govName,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          selectedEmployee: _selectedEmployee,
                          fromDate: _fromDate,
                          toDate: _toDate,
                        );
                        Navigator.pop(context);
                      },
                      child: Text("تطبيق", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
