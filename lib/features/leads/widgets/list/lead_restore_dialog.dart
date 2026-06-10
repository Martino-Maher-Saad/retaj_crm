import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/lead_model.dart';
import '../../../../../data/models/profile_model.dart';
import '../../cubit/leads_cubit.dart';
import '../../../admin_users/cubit/admin_users_cubit.dart';
import '../../../admin_users/cubit/admin_users_state.dart';
import '../../../../../core/di/injection_container.dart' as di;

class LeadRestoreDialog extends StatefulWidget {
  final LeadModel lead;
  final ProfileModel user;

  const LeadRestoreDialog({super.key, required this.lead, required this.user});

  static void show(BuildContext context, LeadModel lead, ProfileModel user) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LeadCubit>(),
        child: LeadRestoreDialog(lead: lead, user: user),
      ),
    );
  }

  @override
  State<LeadRestoreDialog> createState() => _LeadRestoreDialogState();
}

class _LeadRestoreDialogState extends State<LeadRestoreDialog> {
  String? _selectedEmployeeId;
  String _selectedStatusId = '460be748-7685-49ef-abcf-c4dd49511ab7'; // Default: First Contact
  late AdminUsersCubit _adminCubit;

  final List<Map<String, String>> _statusOptions = [
    {'id': '460be748-7685-49ef-abcf-c4dd49511ab7', 'name': 'تم التواصل اول مرة'},
    {'id': 'e8d1b11b-789a-4c91-9de3-ec06d0a797af', 'name': 'قيد الانتظار'},
    {'id': '6e214151-5fb5-4a67-8ddb-2ec32c4e20b0', 'name': 'متابعة'},
    {'id': '266c1b34-8c85-4f46-9d33-40a23e98629f', 'name': 'مهتم'},
    {'id': 'c8eebf99-bfb7-4a1d-a3df-a1f73663a8a3', 'name': 'جاري التنفيذ'},
    {'id': '19b489a2-71c1-4b13-9ecf-dbccb01ba0dc', 'name': 'اغلاق مبدئي'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.lead.assignedTo;
    _adminCubit = di.sl<AdminUsersCubit>();
    _adminCubit.fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استعادة العميل', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('قم باختيار الموظف المسؤول والحالة الجديدة للعميل:'),
            SizedBox(height: 16.h),
            const Text('حالة العميل:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStatusId,
                  items: _statusOptions.map((e) => DropdownMenuItem(
                    value: e['id'],
                    child: Text(e['name']!),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatusId = val);
                  },
                ),
              ),
            ),
            SizedBox(height: 16.h),
            const Text('الموظف المسؤول:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            BlocBuilder<AdminUsersCubit, AdminUsersState>(
              bloc: _adminCubit,
              builder: (context, state) {
                if (state is AdminUsersLoaded) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        hint: const Text('اختر الموظف'),
                        value: _selectedEmployeeId,
                        items: state.users.map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text("${e.firstName ?? ''} ${e.lastName ?? ''}".trim()),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedEmployeeId = val);
                        },
                      ),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
          onPressed: () {
            context.read<LeadCubit>().restoreLeadFromArchive(
              widget.lead.id!,
              _selectedStatusId,
              employeeId: _selectedEmployeeId,
            );
            Navigator.pop(context);
          },
          child: const Text('استعادة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
