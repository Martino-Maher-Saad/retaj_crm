import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../cubit/leads_cubit.dart';

class LeadFilterDialog extends StatefulWidget {
  final String role;
  final String currentUserId;

  const LeadFilterDialog({
    super.key,
    required this.role,
    required this.currentUserId,
  });

  @override
  State<LeadFilterDialog> createState() => _LeadFilterDialogState();
}

class _LeadFilterDialogState extends State<LeadFilterDialog> {
  final dataManager = di.sl<StaticDataManager>();

  String? _selectedLeadStatus;
  String? _selectedPlatform;
  String? _selectedPropertyType;
  String? _selectedListingType;
  String? _selectedGovName;
  String? _selectedCityName;
  String? _selectedEmployee;

  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _lastCommentFromDate;
  DateTime? _lastCommentToDate;
  
  Future<void> _pickDateTime({required bool isFrom, required bool isComment}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        if (isComment) {
          if (isFrom) {
            _lastCommentFromDate = date;
          } else {
            _lastCommentToDate = date;
          }
        } else {
          if (isFrom) {
            _fromDate = date;
          } else {
            _toDate = date;
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final cubit = context.read<LeadCubit>();
    _selectedEmployee = cubit.currentFilterByEmployeeId;
    _fromDate = cubit.currentFromDate;
    _toDate = cubit.currentToDate;
    _lastCommentFromDate = cubit.currentLastCommentFromDate;
    _lastCommentToDate = cubit.currentLastCommentToDate;

    if (cubit.currentLeadStatusId != null) {
      try {
        _selectedLeadStatus = dataManager.getOptionModels('lead_status').firstWhere((o) => o.id == cubit.currentLeadStatusId!).nameAr;
      } catch (_) {}
    }
    if (cubit.currentPlatformId != null) {
      try {
        _selectedPlatform = dataManager.getOptionModels('platform').firstWhere((o) => o.id == cubit.currentPlatformId!).nameAr;
      } catch (_) {}
    }
    if (cubit.currentPropertyTypeId != null) {
      try {
        _selectedPropertyType = dataManager.getOptionModels('property_type').firstWhere((o) => o.id == cubit.currentPropertyTypeId!).nameAr;
      } catch (_) {}
    }
    if (cubit.currentListingTypeId != null) {
      try {
        _selectedListingType = dataManager.getOptionModels('listing_type').firstWhere((o) => o.id == cubit.currentListingTypeId!).nameAr;
      } catch (_) {}
    }
    
    if (cubit.currentGovernorateId != null) {
      try {
        final gov = dataManager.governorates.firstWhere((g) => g.id == cubit.currentGovernorateId);
        _selectedGovName = gov.name;
      } catch (_) {}
    }

    if (cubit.currentCityId != null) {
      try {
        final allCities = dataManager.allCities;
        final city = allCities.firstWhere((c) => c.id == cubit.currentCityId);
        _selectedCityName = city.name;
        if (_selectedGovName == null) {
          final gov = dataManager.governorates.firstWhere((g) => g.id == city.governorateId);
          _selectedGovName = gov.name;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = dataManager.employees;
    final isManager = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';

    List<String> cityList = dataManager.allCities.map((c) => c.name).toSet().toList();
    if (_selectedGovName != null) {
      try {
        final govId = dataManager.governorates.firstWhere((g) => g.name == _selectedGovName).id;
        cityList = dataManager.getCitiesByGovId(govId).map((c) => c.name).toSet().toList();
      } catch (_) {}
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540.w),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "الفلاتر المتقدمة",
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 24.sp, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  _buildDropdown(
                    "حالة العميل",
                    dataManager.getOptions('lead_status'),
                    _selectedLeadStatus,
                    (v) => setState(() => _selectedLeadStatus = v),
                  ),
                  SizedBox(height: 14.h),
                  _buildDropdown(
                    "المنصة",
                    dataManager.getOptions('platform'),
                    _selectedPlatform,
                    (v) => setState(() => _selectedPlatform = v),
                  ),
                  SizedBox(height: 14.h),
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
                  
                  // المحافظة
                  _buildDropdown(
                    "المحافظة",
                    dataManager.governorates.map((g) => g.name).toList(),
                    _selectedGovName,
                    (v) => setState(() {
                      _selectedGovName = v;
                      _selectedCityName = null;
                    }),
                  ),
                  SizedBox(height: 14.h),
                  
                  // المدينة
                  _buildDropdown(
                    "المدينة",
                    cityList,
                    _selectedCityName,
                    (v) => setState(() => _selectedCityName = v),
                  ),

                  SizedBox(height: 24.h),
                  Text("تاريخ الإضافة:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(isFrom: true, isComment: false),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_fromDate == null 
                              ? "من تاريخ" 
                              : DateFormat('dd/MM/yyyy').format(_fromDate!)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(isFrom: false, isComment: false),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_toDate == null 
                              ? "إلى تاريخ" 
                              : DateFormat('dd/MM/yyyy').format(_toDate!)),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24.h),
                  Text("تاريخ آخر تعليق:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(isFrom: true, isComment: true),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_lastCommentFromDate == null 
                              ? "من تاريخ" 
                              : DateFormat('dd/MM/yyyy').format(_lastCommentFromDate!)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(isFrom: false, isComment: true),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_lastCommentToDate == null 
                              ? "إلى تاريخ" 
                              : DateFormat('dd/MM/yyyy').format(_lastCommentToDate!)),
                        ),
                      ),
                    ],
                  ),

                  if (isManager && employees.isNotEmpty) ...[
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
                          onPressed: () {
                             setState(() {
                              _selectedLeadStatus = null;
                              _selectedPlatform = null;
                              _selectedPropertyType = null;
                              _selectedListingType = null;
                              _selectedGovName = null;
                              _selectedCityName = null;
                              _selectedEmployee = null;
                              _fromDate = null;
                              _toDate = null;
                              _lastCommentFromDate = null;
                              _lastCommentToDate = null;
                            });
                          },
                          child: Text("مسح الكل", style: TextStyle(color: Colors.red, fontSize: 20.sp, fontWeight: FontWeight.bold)),
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
                            final leadStatusId = _selectedLeadStatus != null
                                ? dataManager.getIdByName('lead_status', _selectedLeadStatus!)
                                : null;
                            final platformId = _selectedPlatform != null
                                ? dataManager.getIdByName('platform', _selectedPlatform!)
                                : null;
                            final propertyTypeId = _selectedPropertyType != null
                                ? dataManager.getIdByName('property_type', _selectedPropertyType!)
                                : null;
                            final listingTypeId = _selectedListingType != null
                                ? dataManager.getIdByName('listing_type', _selectedListingType!)
                                : null;
                            
                            int? govId;
                            if (_selectedGovName != null) {
                                try {
                                  govId = dataManager.governorates.firstWhere((g) => g.name == _selectedGovName).id;
                                } catch (_) {}
                            }

                            int? cityId;
                            if (_selectedCityName != null) {
                              try {
                                cityId = dataManager.allCities
                                    .firstWhere((c) => c.name == _selectedCityName)
                                    .id;
                              } catch (_) {}
                            }

                            final hasFilters = leadStatusId != null ||
                                platformId != null ||
                                propertyTypeId != null ||
                                listingTypeId != null ||
                                govId != null ||
                                cityId != null ||
                                _selectedEmployee != null ||
                                _fromDate != null ||
                                _toDate != null ||
                                _lastCommentFromDate != null ||
                                _lastCommentToDate != null;

                            if (!hasFilters) {
                              context.read<LeadCubit>().cancelFilters();
                            } else {
                              context.read<LeadCubit>().getAllLeads(
                                role: widget.role,
                                userId: widget.currentUserId,
                                isRefresh: true,
                                leadStatusId: leadStatusId,
                                platformId: platformId,
                                propertyTypeId: propertyTypeId,
                                listingTypeId: listingTypeId,
                                governorateId: govId,
                                cityId: cityId,
                                filterByEmployeeId: _selectedEmployee,
                                fromDate: _fromDate,
                                toDate: _toDate,
                                lastCommentFromDate: _lastCommentFromDate,
                                lastCommentToDate: _lastCommentToDate,
                              );
                            }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          initialSelection: value,
          onSelected: onChanged,
          enableSearch: true,
          enableFilter: true,
          menuHeight: 220.h,
          label: Text(
            hint,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          textStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black45, width: 1.5.w),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black45, width: 1.5.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.brandPrimary, width: 2.0.w),
            ),
          ),
          dropdownMenuEntries: items.map<DropdownMenuEntry<String>>((String item) {
            return DropdownMenuEntry<String>(
              value: item,
              label: item,
              style: MenuItemButton.styleFrom(
                textStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
