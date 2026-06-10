import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import 'package:retaj_crm/features/layout/cubit/layout_cubit.dart';
import 'package:retaj_crm/features/layout/cubit/layout_state.dart';
import 'package:retaj_crm/features/layout/widgets/logout_button.dart';
import 'package:retaj_crm/features/layout/widgets/side_bar_logo.dart';
import 'package:retaj_crm/core/utils/responsive_debouncer_wrapper.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../admin_users/screens/admin_users_screen.dart';
import '../../admin_users/screens/dropdown_management_screen.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../designs/screens/designs_list_screen.dart';
import '../../leads/screens/leads_management_screen.dart';
import '../../properties/screens/properties_list_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../tasks/screens/manager_approvals_screen.dart';
import '../../archive/screens/archive_screen.dart';
import '../../duplicates/screens/duplicates_screen.dart';
import '../../properties/screens/property_shares_screen.dart';

class LayoutScreen extends StatefulWidget {
  final ProfileModel user;
  const LayoutScreen({super.key, required this.user});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _NavItemData {
  final String label;
  final IconData icon;
  final Widget page;
  _NavItemData(this.label, this.icon, this.page);
}

class _LayoutScreenState extends State<LayoutScreen> {
  late PageController _pageController;

  List<_NavItemData> _getNavItems(ProfileModel user) {
    final dashboard = _NavItemData("لوحة القيادة", Icons.dashboard_outlined, DashboardScreen(key: const PageStorageKey('dashboard_page'), user: user));
    final tasks = _NavItemData("المهام", Icons.assignment_late_rounded, TasksScreen(user: user, key: const PageStorageKey('tasks_page')));
    final properties = _NavItemData("مخزون العقارات", Icons.home_work_outlined, PropertiesListScreen(userId: user.id, role: user.role, key: const PageStorageKey('properties_page')));
    final shares = _NavItemData("مشاركات العقارات", Icons.share_rounded, PropertySharesScreen(user: user, key: const PageStorageKey('shares_page')));
    final leads = _NavItemData("مخزون العملاء", Icons.people_outline_rounded, LeadsManagementScreen(user: user, key: const PageStorageKey('leads_page')));
    final designs = _NavItemData("مكتبة التصاميم", Icons.format_paint_outlined, const DesignsListScreen(key: PageStorageKey('designs_page')));
    final archive = _NavItemData("الأرشيف", Icons.archive_outlined, ArchiveScreen(user: user, key: const PageStorageKey('archive_page')));
    final duplicates = _NavItemData("سجل التكرارات", Icons.control_point_duplicate, DuplicatesScreen(user: user, key: const PageStorageKey('duplicates_page')));
    final approvals = _NavItemData("موافقات الإدارة", Icons.admin_panel_settings_outlined, ManagerApprovalsScreen(user: user, key: const PageStorageKey('approvals_page')));
    final accounts = _NavItemData("إدارة الحسابات", Icons.manage_accounts_outlined, BlocProvider(key: const PageStorageKey('accounts_page'), create: (_) => di.sl<AdminUsersCubit>(), child: const AdminUsersScreen()));
    final dropdowns = _NavItemData("إدارة القوائم", Icons.list_alt_rounded, const DropdownManagementScreen(key: PageStorageKey('dropdown_page')));

    if (user.role == 'sales') {
      return [dashboard, properties, leads, tasks, archive, shares];
    } else if (user.role == 'manager') {
      return [dashboard, properties, leads, tasks, archive, shares, duplicates];
    } else if (user.role == 'ceo') {
      return [dashboard, approvals, properties, leads, tasks, archive, shares, duplicates, designs];
    } else { // admin
      return [dashboard, tasks, properties, shares, leads, designs, archive, duplicates, approvals, accounts, dropdowns];
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<LayoutCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        body: BlocBuilder<LayoutCubit, LayoutState>(
          builder: (context, state) {
            int selectedIndex = 0;
            if (state is LayoutNavigationChanged) {
              selectedIndex = state.selectedIndex;
            }
            return ResponsiveDebouncerWrapper(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: AppConstants.minDesktopWidth,
                    maxWidth: MediaQuery.of(context).size.width > AppConstants.minDesktopWidth
                        ? MediaQuery.of(context).size.width
                        : AppConstants.minDesktopWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RepaintBoundary(
                        child: _buildCustomSidebar(widget.user),
                      ),
                      // المحتوى الرئيسي
                      Expanded(
                        child: IndexedStack(
                          index: selectedIndex,
                          children: _getNavItems(widget.user).map((e) => e.page).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _resolveSidebarRole(String role) {
    switch (role) {
      case 'admin':
        return 'مسؤول النظام';
      case 'ceo':
        return 'المدير التنفيذي';
      case 'manager':
        return 'مدير';
      case 'sales':
        return 'موظف مبيعات';
      default:
        return role;
    }
  }

  String _getInitials(ProfileModel user) {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    final combined = (first + last).toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }

  Widget _buildCustomSidebar(ProfileModel user) {
    return BlocBuilder<LayoutCubit, LayoutState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is LayoutNavigationChanged) currentIndex = state.selectedIndex;

        return Container(
          width: 260.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Color(0xFFEEEEF5), width: 1),
            ),
          ),
          child: Column(
            children: [
              // ─── Logo ───
              const SideBarLogo(),

              // ─── بطاقة المستخدم ─── (قابلة للضغط → فتح صفحة البروفايل)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => di.sl<ProfileCubit>(),
                        child: UserProfileScreen(currentUser: widget.user),
                      ),
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar كبير
                        Container(
                          width: 68.r,
                          height: 68.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.brandPrimary.withValues(alpha: 0.3),
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: widget.user.imageUrl != null
                                ? Image.network(widget.user.imageUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _initialsWidget())
                                : _initialsWidget(),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}".trim(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF1A1A2E),
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  _resolveSidebarRole(widget.user.role),
                                  style: TextStyle(
                                    color: AppColors.brandPrimary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded,
                            size: 20.sp, color: AppColors.brandPrimary.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(color: const Color(0xFFEEEEF5), height: 1.h),
              SizedBox(height: 6.h),

              // ─── قائمة التنقل ───
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  children: _getNavItems(widget.user).asMap().entries.map((entry) {
                    return _CustomNavItem(
                      icon: entry.value.icon,
                      label: entry.value.label,
                      index: entry.key,
                      currentIndex: currentIndex,
                    );
                  }).toList(),
                ),
              ),

              const LogoutButton(),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        _getInitials(widget.user),
        style: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.brandPrimary,
        ),
      ),
    );
  }
}

// ─── Nav Item Widget ───
class _CustomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;

  const _CustomNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
  });

  @override
  State<_CustomNavItem> createState() => _CustomNavItemState();
}

class _CustomNavItemState extends State<_CustomNavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.index == widget.currentIndex;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: () => context.read<LayoutCubit>().changeNavigation(widget.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 54.h,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brandPrimary.withValues(alpha: 0.08)
                  : _isHovering
                      ? const Color(0xFFF3F2FF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                // Purple left indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 5.w,
                  height: isSelected ? 36.h : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(5.r),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  widget.icon,
                  size: 34.sp,
                  color: isSelected
                      ? AppColors.brandPrimary
                      : const Color(0xFF888899),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : const Color(0xFF555566),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}