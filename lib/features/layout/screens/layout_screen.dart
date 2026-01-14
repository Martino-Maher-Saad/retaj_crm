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

import '../../auth/screens/accounts_management_screen.dart';
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
        const AccountsManagementScreen(key: PageStorageKey('accounts_page')),
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
      create: (context) => LayoutCubit(),
      child: Scaffold(
        backgroundColor: AppColors.white,
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
            // 2. السكرول الرأسي (فوق وتحت)
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                // 3. السكرول الأفقي (يمين وشمال)
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // نحدد هنا "أقل" أبعاد مسموح بها للتطبيق قبل أن يظهر السكرول
                    minWidth: AppConstants.minDesktopWidth, // 1100
                    minHeight: 750, // حد أدنى للطول لضمان عدم اختفاء الـ Sidebar أو الأزرار

                    // نترك الحد الأقصى مرناً ليأخذ مساحة الشاشة كاملة إذا كانت أكبر
                    maxWidth: MediaQuery.of(context).size.width > AppConstants.minDesktopWidth
                        ? MediaQuery.of(context).size.width
                        : AppConstants.minDesktopWidth,
                    maxHeight: MediaQuery.of(context).size.height > 750
                        ? MediaQuery.of(context).size.height
                        : 750,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الـ Sidebar مع ارتفاع كامل يتناسب مع الـ Constraints
                      RepaintBoundary(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height > 750
                              ? MediaQuery.of(context).size.height
                              : 750,
                          child: _buildCustomSidebar(widget.user),
                        ),
                      ),
                      // المحتوى الرئيسي
                      Expanded(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height > 750
                              ? MediaQuery.of(context).size.height
                              : 750,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSidebar(ProfileModel user) {
    return BlocBuilder<LayoutCubit, LayoutState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is LayoutNavigationChanged) currentIndex = state.selectedIndex;

        return Container(
          width: 280.w,
          color: AppColors.sidebarBackground,
          child: Column(
            children: [
              const SideBarLogo(),
              const SizedBox(height: 10),
              UserAvatar(user: widget.user),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  color: AppColors.greyLight.withOpacity(0.3),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  children: [
                    _customNavItem(context, Icons.analytics_outlined, "Dashboard", 0, currentIndex),
                    _customNavItem(context, Icons.home_work_outlined, "Properties", 1, currentIndex),
                    _customNavItem(context, Icons.person_search_outlined, "Leads", 2, currentIndex),
                    _customNavItem(context, Icons.format_paint_outlined, "Designs", 3, currentIndex),
                    if (widget.user.role == 'admin')
                      _customNavItem(context, Icons.admin_panel_settings_outlined, "Accounts", 4, currentIndex),
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

  Widget _customNavItem(BuildContext context, IconData icon, String label, int index, int currentIndex) {
    bool isSelected = index == currentIndex;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: InkWell(
        onTap: () => context.read<LayoutCubit>().changeNavigation(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 55.h,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: AppColors.white, size: 24.sp),
                SizedBox(width: 16.w),
                Text(
                  label,
                  style: AppTextStyles.blue18Medium.copyWith(
                    color: AppColors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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