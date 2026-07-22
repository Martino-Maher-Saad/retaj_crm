import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/models/lead_model.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../auth/cubit/auth_states.dart';
import '../../cubit/leads_cubit.dart';

class LeadRestoreDialog extends StatefulWidget {
  final LeadModel lead;
  final StaticDataManager dataManager;

  const LeadRestoreDialog({
    super.key,
    required this.lead,
    required this.dataManager,
  });

  @override
  State<LeadRestoreDialog> createState() => _LeadRestoreDialogState();
}

class _LeadRestoreDialogState extends State<LeadRestoreDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.lead.assignedTo;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    setState(() => _isRestoring = true);

    try {
      // 1. استعادة العميل
      await context.read<LeadCubit>().restoreLeadFromArchive(widget.lead.id!);

      // 2. إذا تم تغيير الموظف، يتم عمل تحويل للعميل لنفس الموظف الجديد
      if (_selectedEmployeeId != widget.lead.assignedTo) {
        await context.read<LeadCubit>().transferLead(
          leadId: widget.lead.id!,
          fromEmployeeId: widget.lead.assignedTo ?? authState.user.id!,
          toEmployeeId: _selectedEmployeeId!,
          changedBy: authState.user.id!,
          notes: 'تم استعادة العميل وتحويله',
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة العميل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var employees = widget.dataManager.employees
        .where((e) => e.isActive)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.restore,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استعادة العميل',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'استعادة ${widget.lead.clientName} من المهملات',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              Text(
                'إلى من تريد استعادة العميل؟',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                hint: const Text('اختر الموظف'),
                items: employees.map((e) {
                  return DropdownMenuItem(
                    value: e.id,
                    child: Text('${e.firstName} ${e.lastName} ${e.id == widget.lead.assignedTo ? "(الموظف الأصلي)" : ""}'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
                validator: (v) => v == null ? 'يجب اختيار موظف' : null,
              ),

              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isRestoring ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isRestoring
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'استعادة العميل',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
