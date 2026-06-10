import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../properties/cubit/properties_cubit.dart';
import '../../leads/cubit/leads_cubit.dart';
import 'property_archive_view.dart';
import 'lead_archive_view.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../admin_users/cubit/admin_users_state.dart';

class ArchiveScreen extends StatefulWidget {
  final ProfileModel user;
  const ArchiveScreen({super.key, required this.user});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String? _selectedEmployeeId;
  late AdminUsersCubit _adminCubit;

  @override
  void initState() {
    super.initState();
    _adminCubit = di.sl<AdminUsersCubit>();
    final role = widget.user.role;
    if (role == 'admin' || role == 'manager' || role == 'ceo') {
      _adminCubit.fetchAllUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canFilter = widget.user.role == 'admin' || widget.user.role == 'manager' || widget.user.role == 'ceo';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'الأرشيف',
            style: TextStyle(
              color: const Color(0xFF1A1A2E),
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            if (canFilter)
              BlocBuilder<AdminUsersCubit, AdminUsersState>(
                bloc: _adminCubit,
                builder: (context, adminState) {
                  if (adminState is AdminUsersLoaded) {
                    final employees = adminState.users;
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Container(
                          height: 40.h,
                          constraints: BoxConstraints(maxWidth: 180.w),
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.bgMain,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedEmployeeId,
                              hint: const Text("الكل"),
                              isExpanded: true,
                              icon: const Icon(Icons.filter_list_rounded, color: AppColors.brandPrimary),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text("الكل (جميع الموظفين)"),
                                ),
                                ...employees.map((e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(
                                        "${e.firstName ?? ''} ${e.lastName ?? ''}".trim(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedEmployeeId = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  if (adminState is AdminUsersLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator())),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.brandPrimary,
            labelColor: AppColors.brandPrimary,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'أرشيف العقارات', icon: Icon(Icons.home_work_outlined)),
              Tab(text: 'أرشيف العملاء', icon: Icon(Icons.people_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (_) => di.sl<PropertiesCubit>(),
              child: PropertyArchiveView(user: widget.user, filteredEmployeeId: _selectedEmployeeId),
            ),
            BlocProvider(
              create: (_) => di.sl<LeadCubit>(),
              child: LeadArchiveView(user: widget.user, filteredEmployeeId: _selectedEmployeeId),
            ),
          ],
        ),
      ),
    );
  }
}
