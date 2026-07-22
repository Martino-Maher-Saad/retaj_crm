import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/core/constants/app_roles.dart';
import 'package:retaj_crm/core/utils/responsive_debouncer_wrapper.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import 'package:retaj_crm/features/layout/cubit/layout_cubit.dart';
import 'package:retaj_crm/features/layout/cubit/layout_state.dart';
import 'package:retaj_crm/features/layout/widgets/logout_button.dart';
import 'package:retaj_crm/features/layout/widgets/side_bar_logo.dart';
import 'package:retaj_crm/features/layout/widgets/top_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/lead_sync_notifier.dart';
import '../../../core/utils/property_sync_notifier.dart';
import '../../../data/services/realtime_sync_service.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../admin_users/cubit/form_field_cubit.dart';
import '../../admin_users/screens/admin_users_screen.dart';
import '../../admin_users/screens/dropdown_management_screen.dart';
import '../../admin_users/screens/form_fields_management_screen.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../designs/screens/designs_list_screen.dart';
import '../../duplicates/screens/duplicates_screen.dart';
import '../../leads/cubit/leads_cubit.dart';
import '../../leads/screens/lead_form_screen.dart';
import '../../leads/screens/leads_management_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/screens/properties_list_screen.dart';
import '../../properties/screens/property_form_screen.dart';
import '../../properties/screens/property_shares_screen.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../tasks/widgets/task_form_dialog.dart';

// ─────────────────────────────────────────────────────────
// بيانات عنصر التنقل في الـ Sidebar
// ─────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final Widget page;

  const _NavItem({required this.label, required this.icon, required this.page});
}

// ─────────────────────────────────────────────────────────
// تجميع عناصر التنقل في مجموعة (مثل EngazCRM)
// ─────────────────────────────────────────────────────────
class _NavGroup {
  final String? groupLabel; // عنوان المجموعة (اختياري)
  final List<_NavItem> items;

  const _NavGroup({this.groupLabel, required this.items});
}

// ─────────────────────────────────────────────────────────
// الشاشة الرئيسية للـ Layout
// ─────────────────────────────────────────────────────────
class LayoutScreen extends StatefulWidget {
  final ProfileModel user;
  const LayoutScreen({super.key, required this.user});

  @override
  State<LayoutScreen> createState() => _LayoutScreenState();
}

class _LayoutScreenState extends State<LayoutScreen> {
  late PageController _pageController;

  // ─── بناء عناصر التنقل حسب الدور ───
  List<_NavGroup> _buildNavGroups(ProfileModel user) {
    final role = user.appRole;

    // ─── الصفحات المشتركة ───
    final dashboard = _NavItem(
      label: 'لوحة القيادة',
      icon: Icons.dashboard_outlined,
      page: DashboardScreen(
        key: const PageStorageKey('dashboard_page'),
        user: user,
      ),
    );

    final leads = _NavItem(
      label: 'العملاء',
      icon: Icons.group_outlined,
      page: LeadsManagementScreen(
        key: const PageStorageKey('leads_page'),
        user: user,
      ),
    );

    final properties = _NavItem(
      label: 'مخزون العقارات',
      icon: Icons.inventory_2_outlined,
      page: PropertiesListScreen(
        key: const PageStorageKey('properties_page'),
        userId: user.id,
        role: user.role,
      ),
    );

    final tasks = _NavItem(
      label: 'المهام',
      icon: Icons.task_outlined,
      page: TasksScreen(key: const PageStorageKey('tasks_page'), user: user),
    );

    final shares = _NavItem(
      label: 'مشاركات العقارات',
      icon: Icons.share_outlined,
      page: PropertySharesScreen(
        key: const PageStorageKey('shares_page'),
        user: user,
      ),
    );

    final duplicates = _NavItem(
      label: 'التكرارات',
      icon: Icons.content_copy_rounded,
      page: DuplicatesScreen(
        key: const PageStorageKey('duplicates_page'),
        user: user,
      ),
    );

    final designs = _NavItem(
      label: 'مكتبة التصاميم',
      icon: Icons.collections_rounded,
      page: const DesignsListScreen(key: PageStorageKey('designs_page')),
    );

    final accounts = _NavItem(
      label: 'المستخدمين',
      icon: Icons.manage_accounts_rounded,
      page: BlocProvider(
        key: const PageStorageKey('accounts_page'),
        create: (_) => di.sl<AdminUsersCubit>(),
        child: AdminUsersScreen(currentUser: user),
      ),
    );

    final dropdowns = _NavItem(
      label: 'إدارة القوائم',
      icon: Icons.list_alt_rounded,
      page: const DropdownManagementScreen(
        key: PageStorageKey('dropdown_page'),
      ),
    );

    final formFields = _NavItem(
      label: 'حقول العملاء (Inputs)',
      icon: Icons.edit_note_rounded,
      page: BlocProvider(
        key: const PageStorageKey('form_fields_page'),
        create: (_) => di.sl<FormFieldCubit>(),
        child: const FormFieldsManagementScreen(),
      ),
    );

    // ─── تجميع حسب الدور ───

    if (role == AppRole.sales) {
      return [
        _NavGroup(items: [dashboard, leads, properties, tasks, shares]),
      ];
    }

    if (role == AppRole.leader) {
      return [
        _NavGroup(
          items: [dashboard, leads, properties, tasks, duplicates, shares],
        ),
      ];
    }

    if (role == AppRole.manager) {
      return [
        _NavGroup(
          items: [
            dashboard,
            leads,
            properties,
            tasks,
            duplicates,
            shares,
            accounts,
          ],
        ),
      ];
    }

    // admin & super_admin
    return [
      _NavGroup(
        items: [
          dashboard,
          leads,
          properties,
          tasks,
          duplicates,
          shares,
          accounts,
          dropdowns,
          formFields,
          designs,
        ],
      ),
    ];
  }

  // ─── قائمة مسطّحة من كل العناصر (للـ IndexedStack) ───
  List<_NavItem> _flatItems(ProfileModel user) {
    return _buildNavGroups(user).expand((g) => g.items).toList();
  }

  // ─── عناوين الصفحات (للـ TopHeader) ───
  List<String> _navTitles(ProfileModel user) {
    return _flatItems(user).map((e) => e.label).toList();
  }

  RealtimeChannel? _profileChannel;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _broadcastSubscription;
  bool _showTransferNotification = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setupRealtime();
  }

  void _setupRealtime() {
    final userId = widget.user.id;

    // Listen to Central RealtimeService for Broadcasts (Bulk Transfers)
    _broadcastSubscription = di
        .sl<RealtimeSyncService>()
        .broadcastEvents
        .listen((event) {
          if (!mounted) return;
          if (event['event'] == 'bulk_transfer' &&
              event['payload']['receiver_id'] == userId) {
            setState(() => _showTransferNotification = true);
          }
        });

    // Listen to Central RealtimeService for Snackbars
    _syncSubscription = di.sl<RealtimeSyncService>().events.listen((payload) {
      if (!mounted) return;

      // New Lead assigned to me
      if (payload.table == 'leads' && payload.type == RealtimeOpType.insert) {
        if (payload.newRecord['assigned_to'] == userId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'تم تعيين عميل جديد لك!',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
              backgroundColor: AppColors.brandPrimary,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // New property share
      if (payload.table == 'property_shares' &&
          payload.type == RealtimeOpType.insert) {
        if (payload.newRecord['shared_with'] == userId ||
            payload.newRecord['receiver_id'] == userId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت مشاركة عقار جديد معك!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });

    // Profile Realtime Kickout (Auth Guard)
    _profileChannel = Supabase.instance.client
        .channel('profile_kickout_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) {
              final isActive = payload.newRecord['is_active'] as bool?;
              if (isActive == false) {
                // الموظف تم إيقافه، نطرده فوراً
                context.read<AuthCubit>().logout();
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    _syncSubscription?.cancel();
    _broadcastSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// يعمل refresh للـ cubits الفعلية بدون إعادة بناء الـ Layout
  void _refreshAfterBulkTransfer() {
    // إشعار الـ LeadCubits بإعادة التحميل
    di.sl<LeadSyncNotifier>().notifyRefresh();
    // إشعار الـ PropertiesListScreen بإعادة التحميل
    di.sl<PropertySyncNotifier>().notifyRefresh();
  }

  void _navigateToLeads(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<LeadCubit>(),
          child: LeadFormScreen(user: widget.user),
        ),
      ),
    );
  }

  void _navigateToProperties(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<PropertiesCubit>(),
          child: PropertyFormScreen(
            userId: widget.user.id,
            userRole: widget.user.role,
          ),
        ),
      ),
    );
  }

  void _navigateToTasks(BuildContext context) {
    TaskFormDialog.show(context, currentUser: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final items = _flatItems(widget.user);
    final groups = _buildNavGroups(widget.user);

    return BlocProvider(
      create: (context) => di.sl<LayoutCubit>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.brandPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              builder: (bottomSheetContext) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          "إضافة عميل",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _navigateToLeads(context);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_work,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          "إضافة عقار",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _navigateToProperties(context);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.task, color: Colors.green),
                        ),
                        title: Text(
                          "إضافة مهمة",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _navigateToTasks(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Icon(Icons.add, color: Colors.white, size: 28.sp),
        ),
        body: BlocBuilder<LayoutCubit, LayoutState>(
          builder: (context, state) {
            int selectedIndex = 0;
            if (state is LayoutNavigationChanged) {
              selectedIndex = state.selectedIndex;
            }

            return Stack(
              children: [
                ResponsiveDebouncerWrapper(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: AppConstants.minDesktopWidth,
                        maxWidth:
                            MediaQuery.of(context).size.width >
                                AppConstants.minDesktopWidth
                            ? MediaQuery.of(context).size.width
                            : AppConstants.minDesktopWidth,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Sidebar ───
                          SelectionContainer.disabled(
                            child: RepaintBoundary(
                              child: _buildSidebar(
                                context,
                                groups,
                                selectedIndex,
                              ),
                            ),
                          ),

                          // ─── المحتوى الرئيسي ───
                          Expanded(
                            child: SelectionArea(
                              child: Column(
                                children: [
                                  // الـ Top Header الثابت
                                  TopHeader(
                                    user: widget.user,
                                    navTitles: _navTitles(widget.user),
                                    onAddLead: () => _navigateToLeads(context),
                                    onAddProperty: () =>
                                        _navigateToProperties(context),
                                    onAddTask: () => _navigateToTasks(context),
                                  ),
                                  // محتوى الصفحات
                                  Expanded(
                                    child: IndexedStack(
                                      index: selectedIndex,
                                      children: items
                                          .map((e) => e.page)
                                          .toList(),
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
                if (_showTransferNotification)
                  Positioned(
                    bottom: 24.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'تم نقل مسؤوليات موظف آخر إليك',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            ElevatedButton(
                              onPressed: () {
                                setState(
                                  () => _showTransferNotification = false,
                                );
                                // بدل pushReplacement اللي بيدمر كل الـ layout:
                                // بنعمل refresh للـ cubits مباشرة
                                _refreshAfterBulkTransfer();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                              ),
                              child: const Text('تحديث البيانات'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── بناء الـ Sidebar ───
  Widget _buildSidebar(
    BuildContext context,
    List<_NavGroup> groups,
    int currentIndex,
  ) {
    return Container(
      width: 280.w,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E), // داكن مثل EngazCRM
        border: Border(left: BorderSide(color: Color(0xFF252B3B), width: 1)),
      ),
      child: Column(
        children: [
          // ─── اللوجو ───
          const SideBarLogo(),

          // ─── بطاقة المستخدم ───
          _buildUserCard(context),

          SizedBox(height: 8.h),

          // ─── قائمة التنقل بالمجموعات ───
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              children: _buildGroupedNavItems(context, groups, currentIndex),
            ),
          ),

          // ─── زر تسجيل الخروج ───
          const LogoutButton(),
        ],
      ),
    );
  }

  // ─── بناء عناصر التنقل مع عناوين المجموعات ───
  List<Widget> _buildGroupedNavItems(
    BuildContext context,
    List<_NavGroup> groups,
    int currentIndex,
  ) {
    final List<Widget> widgets = [];
    int flatIndex = 0;

    for (final group in groups) {
      // عنوان المجموعة
      if (group.groupLabel != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: 16.h,
              bottom: 4.h,
              right: 14.w,
              left: 8.w,
            ),
            child: Text(
              group.groupLabel!,
              style: TextStyle(
                color: const Color(0xFF6B7A99),
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }

      // عناصر المجموعة
      for (final item in group.items) {
        final index = flatIndex;
        widgets.add(
          _SidebarNavItem(
            icon: item.icon,
            label: item.label,
            index: index,
            currentIndex: currentIndex,
          ),
        );
        flatIndex++;
      }
    }

    return widgets;
  }

  // ─── بطاقة المستخدم في الـ Sidebar ───
  Widget _buildUserCard(BuildContext context) {
    return MouseRegion(
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
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFF252B3B),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.brandPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: widget.user.imageUrl != null
                      ? Image.network(
                          widget.user.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsWidget(),
                        )
                      : _initialsWidget(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        widget.user.roleNameAr,
                        style: TextStyle(
                          color: const Color(0xFF8B9FCC),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16.sp,
                color: const Color(0xFF6B7A99),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsWidget() {
    final initials = [
      widget.user.firstName?.isNotEmpty == true
          ? widget.user.firstName![0]
          : '',
      widget.user.lastName?.isNotEmpty == true ? widget.user.lastName![0] : '',
    ].join().toUpperCase();

    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.brandPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// عنصر التنقل في الـ Sidebar (مثل EngazCRM)
// ─────────────────────────────────────────────────────────
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.index == widget.currentIndex;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: () =>
              context.read<LayoutCubit>().changeNavigation(widget.index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 54.h, // Increased from 42
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.brandPrimary.withValues(alpha: 0.15)
                  : _isHovering
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                // المؤشر الجانبي الأيسر (مثل EngazCRM)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4.w,
                  height: isSelected ? 36.h : 0,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  widget.icon,
                  size: 24.sp, // Increased from 20
                  color: isSelected
                      ? AppColors.brandPrimaryLight
                      : const Color(0xFF8892AA),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16.sp, // Increased from 13
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF8892AA),
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
