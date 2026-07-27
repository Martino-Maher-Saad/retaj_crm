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
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../widgets/approvals_inline_filters.dart';

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
  String? _selectedEmployeeId;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedListingTypeId;
  String? _selectedPropertyTypeId;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<PropertyTasksCubit>();
    pendingStatusId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
    _fetchData();
  }

  void _fetchData({bool isRefresh = false}) {
    _cubit.fetchPendingApprovals(
      pendingStatusId: pendingStatusId,
      filteredEmployeeId: _selectedEmployeeId,
      fromDate: _fromDate,
      toDate: _toDate,
      listingTypeId: _selectedListingTypeId,
      propertyTypeId: _selectedPropertyTypeId,
      isRefresh: isRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<PropertyTasksCubit, PropertyTasksState>(
                builder: (context, state) {
                  int count = 0;
                  if (state is PropertyTasksSuccess) {
                    count = state.pendingApprovals.length;
                  }
                  return RetajPageHeader(
                    title: 'موافقات الإدارة',
                    subtitle: 'إدارة الموافقات وعقارات الموظفين',
                    totalCount: count,
                    filterBar: ApprovalsInlineFilters(
                      initialEmployeeId: _selectedEmployeeId,
                      initialFromDate: _fromDate,
                      initialToDate: _toDate,
                      initialListingTypeId: _selectedListingTypeId,
                      initialPropertyTypeId: _selectedPropertyTypeId,
                      onApply: (empId, listId, propId, from, to) {
                        setState(() {
                          _selectedEmployeeId = empId;
                          _selectedListingTypeId = listId;
                          _selectedPropertyTypeId = propId;
                          _fromDate = from;
                          _toDate = to;
                        });
                        _fetchData(isRefresh: true);
                      },
                    ),
                  );
                },
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
    ),
  );
}
}
