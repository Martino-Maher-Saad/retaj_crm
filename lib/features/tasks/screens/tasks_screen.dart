import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/profile_model.dart';
import 'leads_tasks_view.dart';
import 'property_tasks_view.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../data/services/property_service.dart';

class TasksScreen extends StatefulWidget {
  final ProfileModel user;

  const TasksScreen({super.key, required this.user});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  List<ProfileModel> employees = [];
  String? selectedEmployeeId;
  bool isLoadingEmployees = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (_canFilterEmployees) {
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canFilterEmployees =>
      widget.user.role == 'admin' ||
      widget.user.role == 'manager' ||
      widget.user.role == 'ceo';

  Future<void> _loadEmployees() async {
    setState(() => isLoadingEmployees = true);
    try {
      // نجيب الموظفين من الداتا بيز مباشرة
      final service = di.sl<PropertyService>();
      final raw = await service.fetchAllEmployees();
      final emps = raw.map((e) => ProfileModel.fromJson(e)).toList();
      setState(() {
        employees = emps;
        isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => isLoadingEmployees = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'صفحة المهام',
          style: TextStyle(
            color: const Color(0xFF1A1A2E),
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          // ─── فيلتر الموظفين (للمدير فقط) ───
          if (_canFilterEmployees && employees.isNotEmpty) ...[
            Center(
              child: Container(
                height: 40.h,
                constraints: BoxConstraints(maxWidth: 200.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.bgMain,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedEmployeeId,
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
                      setState(() {
                        selectedEmployeeId = val;
                      });
                    },
                  ),
                ),
              ),
            ),
            if (isLoadingEmployees)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandPrimary),
                ),
              ),
            SizedBox(width: 16.w),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandPrimary,
          labelColor: AppColors.brandPrimary,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'مهام العملاء', icon: Icon(Icons.people_outline)),
            Tab(text: 'مهام العقارات', icon: Icon(Icons.home_work_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // نمرر filteredEmployeeId - لما يتغير didUpdateWidget بيشتغل في الـ children
          LeadsTasksView(
            key: const PageStorageKey('leads_tasks'),
            user: widget.user,
            filteredEmployeeId: selectedEmployeeId,
          ),
          PropertyTasksView(
            key: const PageStorageKey('property_tasks'),
            user: widget.user,
            filteredEmployeeId: selectedEmployeeId,
          ),
        ],
      ),
    );
  }
}

