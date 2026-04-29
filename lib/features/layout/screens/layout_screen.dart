import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import 'package:retaj_crm/features/layout/cubit/layout_cubit.dart';
import 'package:retaj_crm/features/layout/cubit/layout_state.dart';
import 'package:retaj_crm/features/layout/widgets/logout_button.dart';
import 'package:retaj_crm/features/layout/widgets/side_bar_logo.dart';
import 'package:retaj_crm/core/utils/responsive_debouncer_wrapper.dart'; // استيراد الـ Wrapper

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../admin_users/screens/admin_users_screen.dart';
import '../../admin_users/screens/dropdown_management_screen.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../designs/screens/designs_list_screen.dart';
import '../../leads/screens/leads_management_screen.dart';
import '../../properties/screens/properties_list_screen.dart';
import '../widgets/top_header.dart';
import '../widgets/user_avatar.dart';

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
        backgroundColor: Colors.white,
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
          // 1. المحرك الذي يمنع الـ Lag أثناء تغيير الحجم
          child: ResponsiveDebouncerWrapper(
            // 2. السكرول الأفقي (يمين وشمال) في حالة الشاشات الصغيرة فقط
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // نحدد هنا "أقل" عرض مسموح به
                  minWidth: AppConstants.minDesktopWidth, // 1100
                  maxWidth: MediaQuery.of(context).size.width > AppConstants.minDesktopWidth
                      ? MediaQuery.of(context).size.width
                      : AppConstants.minDesktopWidth,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الـ Sidebar ثابت الطول
                    RepaintBoundary(
                      child: _buildCustomSidebar(widget.user),
                    ),
                    // المحتوى الرئيسي يأخذ باقي المساحة
                    Expanded(
                      child: Column(
                        children: [
                          RepaintBoundary(
                            child: TopHeader(user: widget.user),
                          ),
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

  Widget _buildCustomSidebar(ProfileModel user) {
    return BlocBuilder<LayoutCubit, LayoutState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is LayoutNavigationChanged) currentIndex = state.selectedIndex;

        return Container(
          width: 280.w,
          color: AppColors.bgSideBar,
          child: Column(
            children: [
              const SideBarLogo(),
              const SizedBox(height: 10),
              // ─── بطاقة المستخدم في الـ Sidebar ───
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    UserAvatar(user: widget.user),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}".trim(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _resolveSidebarRole(widget.user.role),
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  color: AppColors.borderSubtle.withOpacity(0.3),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  children: [
                    _CustomNavItem(icon: Icons.analytics_outlined, label: "Dashboard", index: 0, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.home_work_outlined, label: "Properties", index: 1, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.person_search_outlined, label: "Leads", index: 2, currentIndex: currentIndex),
                    _CustomNavItem(icon: Icons.format_paint_outlined, label: "Designs", index: 3, currentIndex: currentIndex),
                    if (widget.user.role == 'admin')
                      _CustomNavItem(icon: Icons.admin_panel_settings_outlined, label: "Accounts", index: 4, currentIndex: currentIndex),
                    if (widget.user.role == 'manager' || widget.user.role == 'admin')
                      _CustomNavItem(icon: Icons.list_alt, label: "Dropdowns", index: widget.user.role == 'admin' ? 5 : 4, currentIndex: currentIndex),
                  ],
                ),
              ),
              const LogoutButton(),
            ],
          ),
        );
      },
    );
  }

}

class _CustomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;

  const _CustomNavItem({required this.icon, required this.label, required this.index, required this.currentIndex});

  @override
  State<_CustomNavItem> createState() => _CustomNavItemState();
}

class _CustomNavItemState extends State<_CustomNavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool isSelected = widget.index == widget.currentIndex;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: InkWell(
        onTap: () => context.read<LayoutCubit>().changeNavigation(widget.index),
        onHover: (hovering) {
          setState(() => _isHovering = hovering);
        },
        borderRadius: BorderRadius.circular(8.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 55.h,
          transform: Matrix4.translationValues(_isHovering && !isSelected ? 4.w : 0, 0, 0),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : _isHovering
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Active Indicator Pillar — Neon Glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3.w,
                height: isSelected ? 36.h : 0,
                decoration: BoxDecoration(
                  color: AppColors.brandAccent,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(3.r)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.brandAccent.withValues(alpha: 0.7),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 24.sp),
                      SizedBox(width: 16.w),
                      Text(
                        widget.label,
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
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