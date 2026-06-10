import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/property_tasks_cubit.dart';
import '../cubit/property_tasks_state.dart';
import '../widgets/admin_property_task_card.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../core/constants/app_colors.dart';

class ManagerApprovalsScreen extends StatefulWidget {
  final ProfileModel user;
  const ManagerApprovalsScreen({super.key, required this.user});

  @override
  State<ManagerApprovalsScreen> createState() => _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<ManagerApprovalsScreen> {
  late PropertyTasksCubit _cubit;
  final dataManager = di.sl<StaticDataManager>();
  late String pendingStatusId;
  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<PropertyTasksCubit>();
    pendingStatusId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
    _fetchEmployees();
    _fetchData();
  }

  Future<void> _fetchEmployees() async {
    try {
      final repo = di.sl<PropertyRepository>();
      final emps = await repo.fetchAllEmployees();
      if (mounted) {
        setState(() {
          _employees = emps;
        });
      }
    } catch (_) {}
  }

  void _fetchData({bool isRefresh = false}) {
    _cubit.fetchPendingApprovals(
      pendingStatusId: pendingStatusId,
      filteredEmployeeId: _selectedEmployeeId,
      isRefresh: isRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'موافقات الإدارة',
            style: TextStyle(
              color: const Color(0xFF1A1A2E),
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          children: [
            // شريط الفلتر والعداد
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandPrimary, size: 24.sp),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          hint: Row(
                            children: [
                              Icon(Icons.person_outline, size: 20.sp, color: Colors.grey.shade600),
                              SizedBox(width: 8.w),
                              Text("تصفية بالموظف...", style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          value: _selectedEmployeeId,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                            fontFamily: 'Cairo', // Assuming Cairo or similar is default, or just let default font apply
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.group, size: 20.sp, color: AppColors.brandPrimary),
                                  SizedBox(width: 8.w),
                                  Text("جميع الموظفين", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ..._employees.map((e) {
                              return DropdownMenuItem<String>(
                                value: e['id'].toString(),
                                child: Text('${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim()),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedEmployeeId = val;
                            });
                            _fetchData(isRefresh: true);
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  BlocBuilder<PropertyTasksCubit, PropertyTasksState>(
                    builder: (context, state) {
                      int count = 0;
                      if (state is PropertyTasksSuccess) {
                        count = state.pendingApprovals.length;
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "العدد: $count",
                          style: TextStyle(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<PropertyTasksCubit, PropertyTasksState>(
                builder: (context, state) {
                  if (state is PropertyTasksInitial ||
                (state is PropertyTasksLoading &&
                    _cubit.state is! PropertyTasksSuccess)) {
              return Skeletonizer(
                enabled: true,
                child: ListView.separated(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                  itemCount: 4,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, __) => Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r)),
                    child: Container(height: 180.h),
                  ),
                ),
              );
            }

            if (state is PropertyTasksSuccess) {
              if (!state.hasFetchedApprovals && !state.isLoadingApprovals) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fetchData();
                });
              }
              if (state.isLoadingApprovals &&
                  state.pendingApprovals.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final pendingList = state.pendingApprovals;

              if (pendingList.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => _fetchData(isRefresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Text(
                          "لا توجد عقارات قيد المراجعة حالياً",
                          style:
                              TextStyle(fontSize: 18.sp, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _fetchData(isRefresh: true),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  itemCount: pendingList.length,
                  itemBuilder: (context, index) {
                    final property = pendingList[index];
                    return AdminPropertyTaskCard(property: property, role: widget.user.role, currentUserId: widget.user.id);
                  },
                ),
              );
            }

            if (state is PropertyTasksError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Colors.red, fontSize: 14.sp),
                ),
              );
            }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
