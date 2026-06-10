import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/profile_model.dart';
import '../cubit/property_tasks_cubit.dart';
import '../cubit/property_tasks_state.dart';
import '../widgets/employee_property_task_card.dart';
import '../../../core/utils/static_data_manager.dart';

class PropertyTasksView extends StatefulWidget {
  final ProfileModel user;
  final String? filteredEmployeeId;

  const PropertyTasksView({
    super.key,
    required this.user,
    this.filteredEmployeeId,
  });

  @override
  State<PropertyTasksView> createState() => _PropertyTasksViewState();
}

class _PropertyTasksViewState extends State<PropertyTasksView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _innerTabController;
  late PropertyTasksCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 3, vsync: this);
    _cubit = di.sl<PropertyTasksCubit>();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant PropertyTasksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredEmployeeId != oldWidget.filteredEmployeeId) {
      _fetchData(isRefresh: true);
    }
  }

  void _fetchData({bool isRefresh = false}) {
    _cubit.fetchTaskProperties(
      role: widget.user.role,
      userId: widget.user.id,
      filteredEmployeeId: widget.filteredEmployeeId,
      isRefresh: isRefresh,
    );
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _innerTabController,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.brandPrimary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
              tabs: const [
                Tab(text: "قيد المراجعة"),
                Tab(text: "تمت الموافقة"),
                Tab(text: "مرفوض"),
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
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 16.w,
                      ),
                      itemCount: 4,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (_, __) => Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Container(height: 180.h),
                      ),
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

                if (state is PropertyTasksSuccess) {
                  if (!state.hasFetchedTasks && !state.isLoadingTasks) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fetchData();
                    });
                  }
                  if (state.isLoadingTasks && state.taskProperties.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = state.taskProperties;
                  final pendingId = '634f7e69-6161-4535-b409-d1ea1bbbdcd3';
                  final approvedId = '74076467-124a-4142-b821-6096d9fa3f4c';
                  final rejectedId = '7345796d-1fd8-462d-b240-7eec15c87e6f';

                  final pending =
                      tasks.where((p) => p.approvalStatusId == pendingId).toList();
                  final approved =
                      tasks.where((p) => p.approvalStatusId == approvedId).toList();
                  final rejected =
                      tasks.where((p) => p.approvalStatusId == rejectedId).toList();

                  return RefreshIndicator(
                    onRefresh: () async => _fetchData(isRefresh: true),
                    child: TabBarView(
                      controller: _innerTabController,
                      children: [
                        _buildList(
                          pending,
                          emptyMessage: "لا توجد عقارات قيد المراجعة",
                          itemBuilder: (p) => EmployeePropertyTaskCard(property: p, role: widget.user.role, currentUserId: widget.user.id),
                        ),
                        _buildList(
                          approved,
                          emptyMessage: "لا توجد عقارات بانتظار النشر",
                          itemBuilder: (p) => EmployeePropertyTaskCard(property: p, role: widget.user.role, currentUserId: widget.user.id),
                        ),
                        _buildList(
                          rejected,
                          emptyMessage: "لا توجد عقارات مرفوضة",
                          itemBuilder: (p) => EmployeePropertyTaskCard(property: p, role: widget.user.role, currentUserId: widget.user.id),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List properties, {
    required String emptyMessage,
    required Widget Function(dynamic) itemBuilder,
  }) {
    if (properties.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 50.sp,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 12.h),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 15.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            "عدد المهام: ${properties.length}",
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            itemCount: properties.length,
            itemBuilder: (context, index) => itemBuilder(properties[index]),
          ),
        ),
      ],
    );
  }
}
