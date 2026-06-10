import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card.dart';
import '../widgets/list/lead_delete_dialog.dart';
import '../widgets/list/lead_archive_dialog.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_top_actions_bar.dart';
import '../widgets/list/lead_filter_dialog.dart';
import '../widgets/list/lead_search_bar.dart';
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

  final _dataManager = di.sl<StaticDataManager>();

  // شريط الفلاتر السريع - الأسماء للعرض فقط، التصفية بالـ ID
  List<String> get _filters =>
      ['الكل', ...(_dataManager.getOptions('lead_status'))];

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
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
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
        backgroundColor: const Color(0xFFF5F5FB),
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
                    // ─── Header الموحّد ───
                    RetajPageHeader(
                      title: 'العملاء المحتملين',
                      subtitle: 'تتبع وإدارة وتحويل فرص الاستثمار العقاري',
                      addLabel: 'إضافة عميل',
                      onAdd: () => _openForm(context),
                      totalCount: total,
                      onFilter: () => _openFilterDialog(context),
                      filterLabel: 'فلاتر متقدمة',
                    ),

                    // شريط فلاتر الحالة
                    LeadTopActionsBar(
                      filters: _filters,
                      currentFilter: currentFilter,
                      onAddPressed: () => _openForm(context),
                      onFilterSelected: (filter) {
                        setState(() => _isFiltering = false);
                        final statusId = filter == 'الكل'
                            ? null
                            : _dataManager.getIdByName('lead_status', filter);
                        _cubit.getAllLeads(
                          role: widget.user.role,
                          userId: widget.user.id,
                          isRefresh: true,
                          leadStatusId: statusId,
                        );
                      },
                    ),

                    // شريط البحث الذكي
                    LeadSearchBar(
                      onSearch: (query, type) {
                        if (type == 'general') {
                          _cubit.smartSearch(query);
                        } else {
                          _cubit.search(query, type: type, role: widget.user.role, userId: widget.user.id);
                        }
                      },
                      onClear: () => _cubit.clearSearch(),
                      isSearching: (state is LeadLoaded) ? state.isSearching : false,
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
                              phones: const [LeadPhoneModel(phoneNumber: '010000000', isPrimary: true)],
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
                          child: Text(
                            "عدد النتائج: ${state.isSearching ? state.filteredLeads.length : state.totalCount}",
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
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
                            onArchive: widget.user.role != 'admin'
                              ? () => LeadArchiveDialog.show(
                                  context,
                                  lead,
                                  () => _cubit.archiveLead(lead.id!, true),
                                )
                              : null,
                            onPinToggle: () => _cubit.toggleLeadPin(lead),
                          );
                        },
                            ),
                          ),
                        ),
                      ],
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
          child: LeadDetailsScreen(leadId: lead.id!),
        ),
      ),
    );
  }
}
