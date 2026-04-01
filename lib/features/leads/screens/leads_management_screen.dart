import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/services/lead_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card.dart';
import '../widgets/list/lead_delete_dialog.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_top_actions_bar.dart';
import 'lead_details_screen.dart';
import 'lead_form_screen.dart';

/// شاشة إدارة العملاء (Leads) — النقطة المركزية لعرض وفلترة وإدارة العملاء
/// تستخدم BlocProvider مع AutomaticKeepAliveClientMixin للحفاظ على الحالة عند التنقل بين الـ tabs
class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen>
    with AutomaticKeepAliveClientMixin {
  late LeadCubit _cubit;

  // قائمة فلاتر الحالة — تُمرر للـ LeadTopActionsBar
  final List<String> _filters = [
    'الكل',
    'جديد',
    'تم التواصل',
    'تفاوض',
    'تم التعاقد',
    'مستبعد',
  ];

  // ScrollController لتفعيل Infinite Scroll
  final ScrollController _scrollController = ScrollController();

  String? _selectedFilterEmployeeId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // إنشاء الـ Cubit وجلب البيانات الأولية فور فتح الشاشة
    _cubit = LeadCubit(LeadRepository(LeadService()))
      ..getAllLeads(role: widget.user.role, userId: widget.user.id);

    _scrollController.addListener(_onScroll);
  }

  /// يراقب موضع الـ Scroll — عند الاقتراب من النهاية يجلب المزيد من البيانات
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMoreLeads(
        role: widget.user.role,
        userId: widget.user.id,
        filterByEmployeeId: _selectedFilterEmployeeId,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('إدارة العملاء', style: AppTextStyles.h2),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                final String currentFilter = (state is LeadLoaded)
                    ? state.currentFilter
                    : 'الكل';
                final List<ProfileModel> employees = (state is LeadLoaded)
                    ? state.employees
                    : [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeadTopActionsBar(
                      filters: _filters,
                      currentFilter: currentFilter,
                      onAddPressed: () => _openForm(context),
                      onFilterSelected: (filter) => _cubit.filterLeads(filter),
                    ),
                    if ((widget.user.role == 'manager' ||
                            widget.user.role == 'admin') &&
                        employees.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.p16,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              hint: const Text('الموظف المكلف (للمدير)'),
                              value:
                                  employees.any(
                                    (e) => e.id == _selectedFilterEmployeeId,
                                  )
                                  ? _selectedFilterEmployeeId
                                  : null,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text("كل الموظفين (إلغاء الفلتر)"),
                                ),
                                ...employees.map(
                                  (e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(
                                      e.firstName != null
                                          ? "${e.firstName} ${e.lastName}"
                                          : e.email,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedFilterEmployeeId = val);
                                _cubit.getAllLeads(
                                  role: widget.user.role,
                                  userId: widget.user.id,
                                  isRefresh: true,
                                  filterByEmployeeId: val,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ],
                );
              },
            ),

            // ─── قائمة العملاء + Loading States ───
            Expanded(
              child: BlocConsumer<LeadCubit, LeadState>(
                listener: (context, state) {
                  // إظهار الخطأ كـ SnackBar للمستخدم
                  if (state is LeadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.brandAccent,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  // ─── حالة التحميل الأولي ───
                  if (state is LeadLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                      ),
                    );
                  }

                  // ─── حالة النجاح ───
                  if (state is LeadLoaded) {
                    if (state.filteredLeads.isEmpty)
                      return const LeadEmptyState();

                    return RefreshIndicator(
                      onRefresh: () => _cubit.getAllLeads(
                        role: widget.user.role,
                        userId: widget.user.id,
                        filterByEmployeeId: _selectedFilterEmployeeId,
                        isRefresh: true,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        // +1 للـ Loading indicator في نهاية القائمة عند التحميل
                        itemCount:
                            state.filteredLeads.length +
                            (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // مؤشر التحميل عند نهاية القائمة
                          if (index >= state.filteredLeads.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final lead = state.filteredLeads[index];
                          return LeadCard(
                            lead: lead,
                            onTap: () => _openDetails(context, lead),
                            onEdit: () => _openForm(context, lead: lead),
                            onDelete: () => LeadDeleteDialog.show(
                              context,
                              lead,
                              () => _cubit.deleteLead(lead.id!),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════
  // ─── Navigation Helpers ───
  // ═══════════════════════════════

  /// يفتح فورم الإضافة/التعديل — يمرر الـ lead للتعديل أو null للإضافة
  void _openForm(BuildContext context, {LeadModel? lead}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadFormScreen(lead: lead, user: widget.user),
        ),
      ),
    );
  }

  /// يفتح صفحة تفاصيل العميل
  void _openDetails(BuildContext context, LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadDetailsScreen(lead: lead),
        ),
      ),
    );
  }
}
