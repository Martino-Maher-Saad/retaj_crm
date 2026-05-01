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

class LayoutScreen extends StatefulWidget {
  final ProfileModel user;
  const LayoutScreen({super.key, required this.user});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  late PageController _pageController;

  List<Widget> _getPagesByRole(ProfileModel user) {
    return [
      DashboardScreen(key: const PageStorageKey('dashboard_page')),
      PropertiesListScreen(userId: user.id, role: user.role, key: const PageStorageKey('properties_page')),
      LeadsManagementScreen(user: user, key: const PageStorageKey('leads_page')),
      const DesignsListScreen(key: PageStorageKey('designs_page')),
      if (user.role == 'admin')
        BlocProvider(
          key: const PageStorageKey('accounts_page'),
          create: (_) => di.sl<AdminUsersCubit>(),
          child: const AdminUsersScreen(),
        ),
      if (user.role == 'manager' || user.role == 'admin')
        const DropdownManagementScreen(key: PageStorageKey('dropdown_page')),
    ];
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
        body: BlocListener<LayoutCubit, LayoutState>(
          listener: (context, state) {
            if (state is LayoutNavigationChanged) {
              _pageController.animateToPage(
                state.selectedIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          child: ResponsiveDebouncerWrapper(
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
                    // المحتوى الرئيسي بدون TopHeader
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _getPagesByRole(widget.user),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveSidebarRole(String role) {
    switch (role) {
      case 'admin':
        return 'مسؤول النظام';
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
                  children: [
                    _CustomNavItem(icon: Icons.dashboard_outlined,            label: "لوحة القيادة",       index: 0, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.home_work_outlined,             label: "العقارات",           index: 1, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.people_outline_rounded,         label: "العملاء المحتملين",  index: 2, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.format_paint_outlined,          label: "مكتبة التصاميم",     index: 3, currentIndex: currentIndex),
                    if (widget.user.role == 'admin')
                      _CustomNavItem(icon: Icons.admin_panel_settings_outlined, label: "إدارة الحسابات",   index: 4, currentIndex: currentIndex),
                    if (widget.user.role == 'manager' || widget.user.role == 'admin')
                      _CustomNavItem(icon: Icons.list_alt_rounded,             label: "إدارة القوائم",      index: widget.user.role == 'admin' ? 5 : 4, currentIndex: currentIndex),
                  ],
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