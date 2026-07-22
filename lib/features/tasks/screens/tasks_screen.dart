import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/task_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/tasks_cubit.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/task_form_dialog.dart';
import 'leads_tasks_view.dart';
import 'property_tasks_view.dart';

class TasksScreen extends StatefulWidget {
  final ProfileModel user;

  const TasksScreen({super.key, required this.user});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TasksCubit _tasksCubit;
  final _dataManager = di.sl<StaticDataManager>();
  
  List<ProfileModel> _employees = [];
  String? _selectedEmployeeId;
  String? _selectedStatusId;

  late TabController _tabController;

  bool get _isManager => widget.user.appRole.isAtLeast(AppRole.manager);

  @override
  void initState() {
    super.initState();
    _tasksCubit = di.sl<TasksCubit>()..init(widget.user.appRole.name, widget.user.id);
    _tabController = TabController(length: 3, vsync: this);
    if (_isManager) {
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _employees = _dataManager.employees;
    });
  }

  void _applyFilter() {
    _tasksCubit.fetchTasks(
      filterEmployeeId: _selectedEmployeeId,
      statusId: _selectedStatusId,
    );
  }

  void _openTaskDetails(TaskModel? task) {
    TaskFormDialog.show(
      context,
      currentUser: widget.user,
      task: task,
      cubit: _tasksCubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tasksCubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Column(
          children: [
            _buildHeader(),
            if (_isManager) _buildFilters(),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.brandPrimary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.brandPrimary,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                tabs: const [
                  Tab(text: "المهام العامة"),
                  Tab(text: "مهام العملاء"),
                  Tab(text: "مهام العقارات"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTasksTab(),
                  LeadsTasksView(user: widget.user, filteredEmployeeId: _selectedEmployeeId),
                  PropertyTasksView(user: widget.user, filteredEmployeeId: _selectedEmployeeId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTasksTab() {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TasksError) {
          return Center(child: Text(state.message, style: TextStyle(color: Colors.red)));
        } else if (state is TasksLoaded) {
          if (state.tasks.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: state.tasks.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              return _buildTaskCard(task);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "إدارة المهام",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.brandPrimary,
            ),
          ),
          CustomButton(
            isCenter: true,
            title: "إضافة مهمة عامة",
            onTap: () => _openTaskDetails(null),
            icon: Icon(Icons.add, color: Colors.white),
            buttonWidth: 160.w,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: RetajDropdown<String>(
              label: "الموظف",
              value: _selectedEmployeeId,
              items: _employees
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text("${e.firstName} ${e.lastName}"),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedEmployeeId = v);
                _applyFilter();
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RetajDropdown<String>(
              label: "الحالة",
              value: _selectedStatusId,
              items: _dataManager.getOptionModels('task_status')
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nameAr),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedStatusId = v);
                _applyFilter();
              },
            ),
          ),
          SizedBox(width: 12.w),
          IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              setState(() {
                _selectedEmployeeId = null;
                _selectedStatusId = null;
              });
              _applyFilter();
            },
            tooltip: "مسح الفلاتر",
          )
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return InkWell(
      onTap: () => _openTaskDetails(task),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                _buildTag(task.statusName ?? 'غير محدد', Colors.blue),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              task.description ?? 'لا يوجد وصف',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16.sp, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(task.assignedToName ?? 'غير محدد', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700])),
                Spacer(),
                Icon(Icons.calendar_today, size: 16.sp, color: Colors.red[300]),
                SizedBox(width: 4.w),
                Text(
                  DateFormat('dd/MM/yyyy').format(task.endDate),
                  style: TextStyle(fontSize: 12.sp, color: Colors.red[400], fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_outlined, size: 80.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            "لا توجد مهام حالياً",
            style: TextStyle(fontSize: 20.sp, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
