import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/utils/number_formatter.dart';
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

  bool _searchAll = false;

  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PropertiesCubit>();
    _selectedGovId = cubit.filterGovernorateId;
    _searchAll = cubit.searchAll; // Sync searchAll selection
    
    // Reverse lookup for string representations
    if (cubit.filterPropertyTypeId != null) {
      try {
        _selectedPropertyType = dataManager.getOptionModels('property_type').firstWhere((o) => o.id == cubit.filterPropertyTypeId!).nameAr;
      } catch (_) {}
    }
    
    if (cubit.filterListingTypeId != null) {
      try {
        _selectedListingType = dataManager.getOptionModels('listing_type').firstWhere((o) => o.id == cubit.filterListingTypeId!).nameAr;
      } catch (_) {}
    }
    
    if (cubit.filterCityId != null) {
      try {
        final allCities = dataManager.allCities;
        final city = allCities.firstWhere((c) => c.id == cubit.filterCityId);
        _selectedCityName = city.name;
        _selectedGovId ??= city.governorateId;
      } catch (_) {}
    }

    _selectedEmployee = cubit.filterAssignedTo;
    if (cubit.filterMinPrice != null) {
      _minPrice = cubit.filterMinPrice!.toDouble();
      _minPriceCtrl.text = _minPrice.toStringAsFixed(0);
    }
    if (cubit.filterMaxPrice != null) {
      _maxPrice = cubit.filterMaxPrice!.toDouble();
      _maxPriceCtrl.text = _maxPrice.toStringAsFixed(0);
    }

    _fromDate = cubit.filterFromDate;
    _toDate = cubit.filterToDate;
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
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
              SizedBox(height: 24.h),
              Text("نطاق السعر:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [NumberFormatter()],
                      decoration: const InputDecoration(
                        labelText: "السعر من",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [NumberFormatter()],
                      decoration: const InputDecoration(
                        labelText: "السعر إلى",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),
              Text("تاريخ الإضافة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
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
              
              if (widget.role == 'sales') ...[
                SizedBox(height: 20.h),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    title: Text("البحث في كل العقارات (وليس عقاراتي فقط)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    value: _searchAll,
                    activeColor: AppColors.brandPrimary,
                    onChanged: (val) => setState(() => _searchAll = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              if (widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo') ...[
                SizedBox(height: 24.h),
                Text("الموظف (للمديرين فقط):", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary, fontSize: 18.sp)),
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
                        // تحويل الاختيارات النصية إلى IDs
                        final propertyTypeId = _selectedPropertyType != null
                            ? dataManager.getIdByName('property_type', _selectedPropertyType!)
                            : null;
                        final listingTypeId = _selectedListingType != null
                            ? dataManager.getIdByName('listing_type', _selectedListingType!)
                            : null;
                        int? cityId;
                        if (_selectedGovId != null && _selectedCityName != null) {
                          try {
                            cityId = dataManager
                                .getCitiesByGovId(_selectedGovId!)
                                .firstWhere((c) => c.name == _selectedCityName)
                                .id;
                          } catch (_) {}
                        }

                        final parsedMinPrice = double.tryParse(_minPriceCtrl.text.replaceAll(',', ''));
                        final parsedMaxPrice = double.tryParse(_maxPriceCtrl.text.replaceAll(',', ''));

                        context.read<PropertiesCubit>().applyAdvancedFilters(
                          role: widget.role,
                          currentUserId: widget.currentUserId,
                          listingTypeId: listingTypeId,
                          propertyTypeId: propertyTypeId,
                          cityId: cityId,
                          governorateId: _selectedGovId,
                          minPrice: parsedMinPrice,
                          maxPrice: parsedMaxPrice,
                          selectedEmployee: _selectedEmployee,
                          fromDate: _fromDate,
                          toDate: _toDate,
                          searchAll: _searchAll,
                        );
                        Navigator.pop(context);
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
