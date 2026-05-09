import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
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
  int? _selectedGovId;
  String? _selectedCityName;
  String? _selectedEmployee;
  DateTime? _fromDate;
  DateTime? _toDate;

  // حالة الـ leads تُجلب من dataManager (لا hardcode)
  List<String> get _statuses => dataManager.getOptions('lead_status');

  Future<void> _pickDate({required bool isFrom}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = date;
        } else {
          _toDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = dataManager.employees;
    final isManager = widget.role == 'manager' || widget.role == 'admin';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Header ───
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: Colors.white, size: 22.sp),
                      SizedBox(width: 10.w),
                      Text(
                        'فلترة العملاء',
                        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.white70, size: 22.sp),
                      ),
                    ],
                  ),
                ),

                // ─── Body ───
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Row 1: حالة العميل + المنصة ───
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                'حالة العميل',
                                Icons.flag_outlined,
                                _statuses,
                                _selectedLeadStatus,
                                (v) => setState(() => _selectedLeadStatus = v),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildDropdown(
                                'المنصة',
                                Icons.source_outlined,
                                dataManager.getOptions('platform'),
                                _selectedPlatform,
                                (v) => setState(() => _selectedPlatform = v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // ─── Row 2: نوع العقار + نوع الإعلان ───
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                'نوع العقار',
                                Icons.home_work_outlined,
                                dataManager.getOptions('property_type'),
                                _selectedPropertyType,
                                (v) => setState(() => _selectedPropertyType = v),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildDropdown(
                                'نوع الإعلان',
                                Icons.sell_outlined,
                                dataManager.getOptions('listing_type'),
                                _selectedListingType,
                                (v) => setState(() => _selectedListingType = v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // ─── Row 3: المحافظة + المدينة ───
                        Row(
                          children: [
                            Expanded(
                              child: _buildGovDropdown(),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildCityDropdown(),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // ─── تاريخ الإضافة ───
                        _sectionLabel('تاريخ الإضافة', Icons.calendar_month_outlined),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                label: _fromDate == null ? 'من تاريخ' : DateFormat('dd/MM/yyyy').format(_fromDate!),
                                onTap: () => _pickDate(isFrom: true),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildDateButton(
                                label: _toDate == null ? 'إلى تاريخ' : DateFormat('dd/MM/yyyy').format(_toDate!),
                                onTap: () => _pickDate(isFrom: false),
                              ),
                            ),
                          ],
                        ),

                        // ─── الموظف (للمدير فقط) ───
                        if (isManager && employees.isNotEmpty) ...[
                          SizedBox(height: 14.h),
                          _sectionLabel('الموظف المكلف', Icons.person_search_outlined),
                          SizedBox(height: 8.h),
                          _buildDropdown(
                            'كل الموظفين',
                            Icons.people_outline,
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
                      ],
                    ),
                  ),
                ),

                // ─── Footer Buttons ───
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedLeadStatus = null;
                              _selectedPlatform = null;
                              _selectedPropertyType = null;
                              _selectedListingType = null;
                              _selectedGovId = null;
                              _selectedCityName = null;
                              _selectedEmployee = null;
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                          icon: Icon(Icons.clear_all, size: 18.sp),
                          label: Text('مسح الكل', style: TextStyle(fontSize: 14.sp)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // تحويل الاختيارات النصية إلى IDs
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
                            int? cityId;
                            if (_selectedGovId != null && _selectedCityName != null) {
                              try {
                                final cityObj = dataManager
                                    .getCitiesByGovId(_selectedGovId!)
                                    .firstWhere((c) => c.name == _selectedCityName);
                                cityId = cityObj.id;
                              } catch (_) {}
                            }
                            context.read<LeadCubit>().getAllLeads(
                              role: widget.role,
                              userId: widget.currentUserId,
                              isRefresh: true,
                              leadStatusId: leadStatusId,
                              platformId: platformId,
                              propertyTypeId: propertyTypeId,
                              listingTypeId: listingTypeId,
                              governorateId: _selectedGovId,
                              cityId: cityId,
                              filterByEmployeeId: _selectedEmployee,
                              fromDate: _fromDate,
                              toDate: _toDate,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.search, size: 18.sp),
                          label: Text('تطبيق الفلاتر', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.brandPrimary),
        SizedBox(width: 6.w),
        Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildDropdown(String hint, IconData icon, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return RetajDropdown<String>(
      label: hint,
      prefixIcon: icon,
      value: value,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('الكل', style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
        ),
        ...items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, style: TextStyle(fontSize: 13.sp)),
              ),
            )
            .toList(),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildGovDropdown() {
    return RetajDropdown<int>(
      label: 'المحافظة',
      prefixIcon: Icons.location_on_outlined,
      value: _selectedGovId,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('الكل'),
        ),
        ...dataManager.governorates.map(
          (g) => DropdownMenuItem<int>(
            value: g.id,
            child: Text(g.name),
          ),
        ),
      ],
      onChanged: (v) => setState(() {
        _selectedGovId = v;
        _selectedCityName = null;
      }),
    );
  }

  Widget _buildCityDropdown() {
    final cities = _selectedGovId == null
        ? <String>[]
        : dataManager.getCitiesByGovId(_selectedGovId!).map((c) => c.name).toSet().toList();

    return RetajDropdown<String>(
      label: 'المدينة',
      prefixIcon: Icons.location_city_outlined,
      value: _selectedCityName,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('الكل'),
        ),
        ...cities
            .map(
              (name) => DropdownMenuItem<String>(
                value: name,
                child: Text(name),
              ),
            )
            .toList(),
      ],
      onChanged: _selectedGovId == null ? null : (v) => setState(() => _selectedCityName = v),
    );
  }

  Widget _buildDateButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.calendar_today, size: 15.sp, color: AppColors.brandPrimary),
      label: Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: const Color(0xFFF8FAFC),
      ),
    );
  }
}
