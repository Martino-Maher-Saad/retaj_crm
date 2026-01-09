import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import 'package:retaj_crm/features/layout/cubit/layout_cubit.dart';
import 'package:retaj_crm/features/layout/cubit/layout_state.dart';
import 'package:retaj_crm/features/layout/widgets/logout_button.dart';
import 'package:retaj_crm/features/layout/widgets/side_bar_logo.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/screens/accounts_management_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../designs/screens/designs_list_screen.dart';
import '../../leads/screens/leads_management_screen.dart';
import '../../properties/screens/properties_list_screen.dart';
import '../widgets/top_header.dart';




class LayoutScreen extends StatefulWidget {
  final ProfileModel user;
  const LayoutScreen({super.key, required this.user});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  late PageController _pageController;

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

          child: Row(
            children: [

              _buildSidebar(context),

              Expanded(
                child: Column(
                  children: [

                    TopHeader(user: widget.user,),

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
    );
  }

  List<Widget> _getPagesByRole(ProfileModel user) {
    return [
      DashboardScreen(key: const PageStorageKey('dashboard_page')),

      // نمرر بيانات المستخدم (user) لكل صفحة لتحديد نوع جلب البيانات (Admin vs Sales)
      PropertiesListScreen(userId: user.id, role: user.role, key: const PageStorageKey('properties_page')),

      LeadsManagementScreen(user: user, key: const PageStorageKey('leads_page')),

      const DesignsListScreen(key: PageStorageKey('designs_page')),

      if (user.role == 'admin')
        const AccountsManagementScreen(key: PageStorageKey('accounts_page')),
    ];
  }

  // ... (نفس دوال السايد بار والهيدر السابقة مع التأكد من الربط مع الـ Cubit)
  Widget _buildSidebar(BuildContext context) {
    return BlocBuilder<LayoutCubit, LayoutState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is LayoutNavigationChanged) currentIndex = state.selectedIndex;

        return NavigationRail(
          extended: true,
          minExtendedWidth: 260,
          backgroundColor: AppColors.sidebarBackground,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            context.read<LayoutCubit>().changeNavigation(index, widget.user.role);
          },
          leading: SideBarLogo(),
          destinations: _buildDestinations(widget.user.role),
          trailing: LogoutButton(),
          selectedIconTheme: const IconThemeData(color: AppColors.primaryRed, size: 30),
          unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 26),
        );
      },
    );
  }


  List<NavigationRailDestination> _buildDestinations(String role) {
    return [
      _navItem(Icons.analytics_outlined, "Dashboard"),
      _navItem(Icons.home_work_outlined, "Properties"),
      _navItem(Icons.person_search_outlined, "Leads"),
      _navItem(Icons.format_paint_outlined, "Designs"),
      if (role == 'admin') _navItem(Icons.admin_panel_settings_outlined, "Accounts"),
    ];
  }

  NavigationRailDestination _navItem(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon),
      label: Text(label, style: AppTextStyles.white18SemiBold),
    );
  }

}