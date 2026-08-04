import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../cubit/properties_cubit.dart';
import '../../../../core/utils/static_data_manager.dart';

class InternalShareDialog extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;

  const InternalShareDialog({
    super.key,
    required this.property,
    required this.currentUserId,
  });

  static void show(BuildContext context, PropertyModel property, String currentUserId, PropertiesCubit cubit) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: InternalShareDialog(
          property: property,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  @override
  State<InternalShareDialog> createState() => _InternalShareDialogState();
}

class _InternalShareDialogState extends State<InternalShareDialog> {
  final TextEditingController _noteController = TextEditingController();
  List<ProfileModel> _employees = [];
  String? _selectedEmployeeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _fetchEmployees() {
    final staticData = di.sl<StaticDataManager>();
    setState(() {
      _employees = staticData.employees.where((e) => e.id != widget.currentUserId).toList();
    });
  }

  Future<void> _submit() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الموظف أولاً')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    
    try {
      final cubit = context.read<PropertiesCubit>();
      await cubit.sharePropertyInternal(
        propertyId: widget.property.id,
        receiverId: _selectedEmployeeId!,
        note: _noteController.text,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مشاركة العقار بنجاح!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNotesEditorDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              "ملاحظات المشاركة",
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 0.6.sw,
              height: 0.6.sh,
              child: TextFormField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "اكتب ملاحظتك هنا...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.all(16.w),
                ),
                style: TextStyle(
                  fontSize: 20.sp,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "تم",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        width: 450.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.ios_share_rounded, color: AppColors.brandPrimary, size: 28.sp),
                SizedBox(width: 12.w),
                Text(
                  "مشاركة داخلية",
                  style: AppTextStyles.h2.copyWith(fontSize: 22.sp),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            Text("اختر الموظف", style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              menuHeight: 250,
              enableFilter: true,
              enableSearch: false,
              hintText: "اختر الزميل...",
              initialSelection: _selectedEmployeeId,
              onSelected: (val) {
                setState(() {
                  _selectedEmployeeId = val;
                });
              },
              dropdownMenuEntries: _employees
                  .map((e) => DropdownMenuEntry<String>(
                        value: e.id,
                        label: "${e.firstName} ${e.lastName}".trim(),
                      ))
                  .toList(),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 20.h),
            
            Text("ملاحظة (اختياري)", style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextFormField(
                controller: _noteController,
                maxLines: 4,
                textAlign: TextAlign.right,
                scrollPhysics: const NeverScrollableScrollPhysics(),
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "اكتب ملاحظتك هنا...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: AppColors.brandPrimary,
                      size: 24.sp,
                    ),
                    onPressed: _showNotesEditorDialog,
                    tooltip: "فتح الملاحظات في نافذة مكبرة",
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: const Text("إلغاء"),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: _isSubmitting
                        ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("مشاركة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
