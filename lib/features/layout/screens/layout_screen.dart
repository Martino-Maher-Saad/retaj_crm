import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import 'package:retaj_crm/features/layout/cubit/layout_cubit.dart';
import 'package:retaj_crm/features/layout/cubit/layout_state.dart';
import 'package:retaj_crm/features/layout/widgets/logout_button.dart';
import 'package:retaj_crm/features/layout/widgets/side_bar_logo.dart';
import '../../../core/constants/app_colors.dart';
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

              _buildCustomSidebar(widget.user),

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



  Widget _buildCustomSidebar(ProfileModel user) {
    return BlocBuilder<LayoutCubit, LayoutState>(
      builder: (context, state) {
        int currentIndex = 0;
        if (state is LayoutNavigationChanged) currentIndex = state.selectedIndex;

        return Container(
          width: 260,
          color: AppColors.sidebarBackground,
          child: Column(
            children: [
              SideBarLogo(),

              const SizedBox(height: 10),

              UserAvatar(user: widget.user,),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Divider(
                  color: AppColors.greyLight,
                ),
              ),

              Expanded(
                child: ListView(
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

              LogoutButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _customNavItem(BuildContext context, IconData icon, String label, int index, int currentIndex) {
    bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => context.read<LayoutCubit>().changeNavigation(index),

      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

        decoration: BoxDecoration(
          color: isSelected ? AppColors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              Icon(icon, color: AppColors.white),

              const SizedBox(width: 16),

              Text(
                label,
                style: TextStyle(
                  color:Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}