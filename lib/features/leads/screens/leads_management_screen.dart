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
import '../widgets/list/leads_status_filter_bar.dart';
import 'lead_details_screen.dart';
import 'lead_form_screen.dart';
import 'bulk_add_leads_screen.dart';
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
  bool _isAddingNewLead = false;

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
                      onAdd: () {
                        setState(() {
                          _isAddingNewLead = true;
                          // سكرول لأعلى القائمة لرؤية الكارت الجديد
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      },
                      totalCount: total,
                      onFilter: () => _openFilterDialog(context),
                      filterLabel: 'فلاتر متقدمة',
                      filterBar: LeadsStatusFilterBar(
                        filters: _filters,
                        currentFilter: currentFilter,
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
                      extraAction: (widget.user.role.toLowerCase() == 'manager' || widget.user.role.toLowerCase() == 'admin' || widget.user.role.toLowerCase() == 'ceo')
                          ? OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BulkAddLeadsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.grid_on, color: Colors.green),
                              label: const Text('إضافة متعددة / إكسيل', style: TextStyle(color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          : null,
                    ),

                    // شريط بحث ذكي
                    LeadSearchBar(
                      onSearch: (query, type) {
                        if (type == 'general') {
                          _cubit.smartSearch(query, role: widget.user.role, userId: widget.user.id);
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
                            (state.isLoadingMore ? 1 : 0) +
                            (_isAddingNewLead ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isAddingNewLead && index == 0) {
                            return LeadCard(
                              key: const ValueKey('new_lead_inline'),
                              lead: LeadModel(
                                id: '',
                                clientName: '',
                                phones: const [],
                                propertyCode: '',
                                leadStatus: 'جديد',
                                createdBy: widget.user.id,
                                assignedTo: widget.user.id,
                                isActive: true,
                              ),
                              role: widget.user.role,
                              initialEditMode: true,
                              isAddingMode: true,
                              onCancelAdd: () {
                                setState(() => _isAddingNewLead = false);
                              },
                              onTap: () {},
                              onEdit: () {},
                              onDelete: () {},
                            );
                          }

                          final actualIndex = _isAddingNewLead ? index - 1 : index;

                          if (actualIndex >= state.filteredLeads.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final lead = state.filteredLeads[actualIndex];
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
          child: LeadDetailsScreen(
            leadId: lead.id!,
            currentUser: widget.user,
          ),
        ),
      ),
    );
  }
}
