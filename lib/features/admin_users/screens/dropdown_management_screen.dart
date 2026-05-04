import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/repositories/dropdown_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/retaj_shared_fields.dart';

class DropdownManagementScreen extends StatefulWidget {
  const DropdownManagementScreen({super.key});

  @override
  State<DropdownManagementScreen> createState() => _DropdownManagementScreenState();
}

class _DropdownManagementScreenState extends State<DropdownManagementScreen> {
  final _dataManager = di.sl<StaticDataManager>();
  final _repository = di.sl<DropdownRepository>();
  
  bool _isLoading = false;
  String _selectedType = 'property_type';
  final TextEditingController _addController = TextEditingController();

  final Map<String, String> _dropdownTypes = {
    'property_type': 'أنواع العقارات',
    'listing_type': 'أنواع الإعلانات',
    'property_source': 'مصدر العقار',
    'property_platform': 'منصات الإعلان (عقارات)',
    'platform': 'منصة العميل (Leads)',
    'lead_status': 'حالات العملاء',
    'communication_channel': 'قنوات التواصل',
  };

  void _loadData() async {
    setState(() => _isLoading = true);
    await _dataManager.initialize();
    setState(() => _isLoading = false);
  }

  void _addOption() async {
    final value = _addController.text.trim();
    if (value.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _repository.addOption(_selectedType, value);
      _addController.clear();
      await _dataManager.initialize(); // Refresh static data
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت الإضافة بنجاح", style: TextStyle(fontFamily: 'Cairo'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e", style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  void _deleteOption(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", style: TextStyle(fontFamily: 'Cairo')),
        content: const Text("هل أنت متأكد من حذف هذا الخيار؟ لا يمكن التراجع.", style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _repository.deleteOption(id);
      await _dataManager.initialize(); // Refresh static data
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف بنجاح", style: TextStyle(fontFamily: 'Cairo'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e", style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text("إدارة الخيارات (Dropdowns)", style: AppTextStyles.h2),
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("اختر القائمة للتعديل:", style: AppTextStyles.h3),
                        SizedBox(height: 16.h),
                        RetajDropdown<String>(
                          label: "اختر القائمة",
                          value: _selectedType,
                          items: _dropdownTypes.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontFamily: 'Cairo')),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addController,
                            decoration: InputDecoration(
                              hintText: "اكتب خيار جديد...",
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add),
                          label: const Text("إضافة", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _dataManager.getOptionModels(_selectedType).length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final option = _dataManager.getOptionModels(_selectedType)[index];
                          return ListTile(
                            title: Text(option.valueAr, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteOption(option.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
