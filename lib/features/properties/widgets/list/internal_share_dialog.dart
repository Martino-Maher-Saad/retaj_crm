import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/services/lead_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../cubit/properties_cubit.dart';

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
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final service = di.sl<LeadService>();
      final emps = await service.fetchAllEmployees();
      setState(() {
        _employees = emps.where((e) => e.id != widget.currentUserId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        width: 400.w,
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    hint: const Text("اختر الزميل..."),
                    value: _selectedEmployeeId,
                    items: _employees.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text("${e.firstName} ${e.lastName}"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedEmployeeId = val;
                      });
                    },
                  ),
            SizedBox(height: 20.h),
            
            Text("ملاحظة (اختياري)", style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "اكتب ملاحظتك هنا...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                filled: true,
                fillColor: Colors.grey[50],
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
