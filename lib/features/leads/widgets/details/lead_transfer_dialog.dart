import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../data/models/lead_model.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../auth/cubit/auth_states.dart';
import '../../cubit/leads_cubit.dart';

class LeadTransferDialog extends StatefulWidget {
  final LeadModel lead;
  final StaticDataManager dataManager;

  const LeadTransferDialog({
    super.key,
    required this.lead,
    required this.dataManager,
  });

  @override
  State<LeadTransferDialog> createState() => _LeadTransferDialogState();
}

class _LeadTransferDialogState extends State<LeadTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  final _notesController = TextEditingController();
  bool _isTransferring = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    setState(() => _isTransferring = true);

    try {
      await context.read<LeadCubit>().transferLead(
        leadId: widget.lead.id!,
        fromEmployeeId: widget.lead.assignedTo ?? authState.user.id!,
        toEmployeeId: _selectedEmployeeId!,
        changedBy: authState.user.id!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحويل العميل بنجاح'),
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
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var employees = widget.dataManager.employees
        .where((e) => e.isActive)
        .toList();
    employees = employees.where((e) => e.id != widget.lead.assignedTo).toList();

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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إعادة تعيين العميل',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'تحويل ${widget.lead.clientName} إلى موظف آخر',
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

              if (widget.lead.assignedToName != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 20.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'الموظف الحالي:',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.lead.assignedToName!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],

              RetajDropdown<String>(
                label: 'اختر الموظف الجديد *',
                value: _selectedEmployeeId,
                items: employees
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
                validator: (v) => v == null ? 'يرجى اختيار موظف' : null,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات التحويل (اختياري)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isTransferring ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isTransferring
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'تحويل العميل',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
