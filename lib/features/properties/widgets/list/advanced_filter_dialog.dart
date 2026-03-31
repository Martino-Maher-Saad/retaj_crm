import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/static_data_manager.dart';
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
  final dataManager = StaticDataManager();

  String? _selectedCityId;
  String? _selectedPropertyType;
  String? _selectedListingType;
  String? _selectedGovId;
  String? _selectedEmployee; // For manager

  double _minPrice = 0;
  double _maxPrice = 100000000;

  // هذه القوائم يمكن تبديلها لاحقاً لتقرأ من ملفات הـ JSON لديك
  final List<String> _propertyTypes = ['شقة', 'فيلا', 'محل تجاري', 'مكتب', 'شاليه'];
  final List<String> _listingTypes = ['للبيع', 'للإيجار'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
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
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(height: 20.h),
              
              _buildDropdown("نوع الإعلان (بيع/إيجار)", _listingTypes, _selectedListingType, (v) => setState(() => _selectedListingType = v)),
              SizedBox(height: 10.h),
              _buildDropdown("نوع العقار", _propertyTypes, _selectedPropertyType, (v) => setState(() => _selectedPropertyType = v)),
              SizedBox(height: 10.h),
              
              // قائمة المحافظات المنسدلة
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                ),
                hint: const Text("المحافظة"),
                value: _selectedGovId,
                items: dataManager.governorates.map((g) => DropdownMenuItem(value: g.id, child: Text(g.nameAr))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedGovId = v;
                    _selectedCityId = null; // تفريغ المدينة عند تغيير المحافظة
                  });
                },
              ),
              SizedBox(height: 10.h),

              // قائمة المدن المنسدلة
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                ),
                hint: const Text("المدينة"),
                value: _selectedCityId,
                items: _selectedGovId == null 
                  ? [] 
                  : dataManager.getCitiesByGov(_selectedGovId!).map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr))).toList(),
                onChanged: _selectedGovId == null 
                  ? null 
                  : (v) => setState(() => _selectedCityId = v),
              ),

              
              SizedBox(height: 20.h),
              Text("اختر نطاق السعر:"),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 100000000,
                divisions: 100,
                labels: RangeLabels(_minPrice.toStringAsFixed(0), _maxPrice.toStringAsFixed(0)),
                activeColor: AppColors.primaryBlue,
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              
              // خاصية المدير للبحث برقم الموظف
              if (widget.role == 'manager') ...[
                SizedBox(height: 20.h),
                Text("الموظف (للمدير فقط):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                SizedBox(height: 5.h),
                TextField(
                  decoration: InputDecoration(
                    hintText: "أدخل ID الموظف أو اتركه فارغاً للكل",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => _selectedEmployee = v,
                ),
              ],
              
              SizedBox(height: 30.h),
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () {
                        String? govName;
                        if (_selectedGovId != null) {
                          govName = dataManager.governorates.firstWhere((g) => g.id == _selectedGovId).nameAr;
                        }
                        String? cityName;
                        if (_selectedCityId != null && _selectedGovId != null) {
                          cityName = dataManager.getCitiesByGov(_selectedGovId!).firstWhere((c) => c.id == _selectedCityId).nameAr;
                        }

                        context.read<PropertiesCubit>().applyAdvancedFilters(
                          role: widget.role,
                          currentUserId: widget.currentUserId,
                          listingType: _selectedListingType,
                          type: _selectedPropertyType,
                          city: cityName,
                          governorate: govName,
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                          selectedEmployee: _selectedEmployee,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("تطبيق الفلتر", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
