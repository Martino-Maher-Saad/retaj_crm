import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card.dart';
import '../widgets/list/lead_delete_dialog.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_top_actions_bar.dart';
import '../widgets/list/lead_filter_dialog.dart';
import 'lead_details_screen.dart';
import 'lead_form_screen.dart';

/// شاشة إدارة العملاء (Leads)
class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen>
    with AutomaticKeepAliveClientMixin {
  late LeadCubit _cubit;
  bool _isFiltering = false;

  final List<String> _filters = [
    'الكل',
    'جديد',
    'تم التواصل',
    'تفاوض',
    'تم التعاقد',
    'مستبعد',
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<LeadCubit>()
      ..getAllLeads(role: widget.user.role, userId: widget.user.id);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.7) {
      _cubit.loadMoreLeads(
        role: widget.user.role,
        userId: widget.user.id,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openFilterDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: LeadFilterDialog(
          role: widget.user.role,
          currentUserId: widget.user.id,
        ),
      ),
    ).then((_) {
      // تحقق إذا الكيوبيت غيّر حالته بفلاتر جديدة
      setState(() => _isFiltering = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Column(
          children: [
            // ─── Header bar ───
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                final String currentFilter =
                    (state is LeadLoaded) ? state.currentFilter : 'الكل';
                final int total = (state is LeadLoaded) ? state.totalCount : 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AppBar بديل يحتوي على عداد + زر الفلتر
                    Container(
                      color: AppColors.bgSurface,
                      padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.p16, vertical: 12.h),
                      child: Row(
                        children: [
                          Text('إدارة العملاء', style: AppTextStyles.h2),
                          SizedBox(width: 8.w),
                          if (total > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '$total',
                                style: TextStyle(
                                  color: AppColors.brandPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // زر الفلاتر المتقدمة
                          OutlinedButton.icon(
                            onPressed: () => _openFilterDialog(context),
                            icon: Icon(Icons.filter_list_rounded,
                                size: 18.sp, color: AppColors.brandPrimary),
                            label: Text('فلاتر',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.brandPrimary)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              side: BorderSide(
                                  color: AppColors.brandPrimary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // زر الإضافة
                          ElevatedButton.icon(
                            onPressed: () => _openForm(context),
                            icon: Icon(Icons.add, size: 18.sp),
                            label: Text('إضافة',
                                style: TextStyle(fontSize: 13.sp)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // شريط فلاتر الحالة
                    LeadTopActionsBar(
                      filters: _filters,
                      currentFilter: currentFilter,
                      onAddPressed: () => _openForm(context),
                      onFilterSelected: (filter) {
                        setState(() => _isFiltering = false);
                        _cubit.getAllLeads(
                          role: widget.user.role,
                          userId: widget.user.id,
                          isRefresh: true,
                          leadStatus: filter == 'الكل' ? null : filter,
                        );
                      },
                    ),

                    // شريط "فلاتر نشطة"
                    if (_isFiltering)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.p16, vertical: 4.h),
                        color: Colors.orange.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('نتائج الفلاتر المتقدمة 🎯',
                                style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp)),
                            TextButton(
                              onPressed: () {
                                setState(() => _isFiltering = false);
                                _cubit.getAllLeads(
                                  role: widget.user.role,
                                  userId: widget.user.id,
                                  isRefresh: true,
                                );
                              },
                              child: const Text('إلغاء الفلاتر',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            // ─── قائمة العملاء ───
            Expanded(
              child: BlocConsumer<LeadCubit, LeadState>(
                listener: (context, state) {
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
                  if (state is LeadLoading) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return LeadCard(
                            lead: LeadModel(
                              id: 'dummy',
                              propertyCode: 'PROP-XXXX',
                              clientName: 'تحميل اسم العميل',
                              city: 'مدينة افتراضية',
                              leadStatus: 'جديد',
                              clientPhone: const ['010000000'],
                              createdBy: '',
                              assignedTo: '',
                            ),
                            role: widget.user.role,
                            onTap: () {},
                            onEdit: () {},
                            onDelete: () {},
                          );
                        },
                      ),
                    );
                  }

                  if (state is LeadLoaded) {
                    if (state.filteredLeads.isEmpty) {
                      return const LeadEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () => _cubit.getAllLeads(
                        role: widget.user.role,
                        userId: widget.user.id,
                        isRefresh: true,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        itemCount: state.filteredLeads.length +
                            (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.filteredLeads.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final lead = state.filteredLeads[index];
                          return LeadCard(
                            key: ValueKey(lead.id),
                            lead: lead,
                            role: widget.user.role,
                            onTap: () => _openDetails(context, lead),
                            onEdit: () => _openForm(context, lead: lead),
                            onDelete: () => LeadDeleteDialog.show(
                              context,
                              lead,
                              () => _cubit.deleteLead(lead.id!, widget.user.role),
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
