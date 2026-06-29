import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/profile_model.dart';
import '../../../data/models/lead_model.dart';
import '../cubit/lead_tasks_cubit.dart';
import '../cubit/lead_tasks_state.dart';
import '../../leads/widgets/lead_card.dart';
import '../../leads/widgets/list/lead_empty_state.dart';
import '../../leads/screens/lead_details_screen.dart';
import '../../leads/screens/lead_form_screen.dart';
import '../../leads/cubit/leads_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/utils/lead_sync_notifier.dart';

class LeadsTasksView extends StatefulWidget {
  final ProfileModel user;
  final String? filteredEmployeeId;

  const LeadsTasksView(
      {super.key, required this.user, this.filteredEmployeeId});

  @override
  State<LeadsTasksView> createState() => _LeadsTasksViewState();
}

class _LeadsTasksViewState extends State<LeadsTasksView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late LeadTasksCubit _cubit;
  late LeadSyncNotifier _sync;
  late TabController _innerTabController;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
    _cubit = di.sl<LeadTasksCubit>();
    _sync = di.sl<LeadSyncNotifier>()..addListener(_onLeadSync);
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  void _onLeadSync() {
    final updated = _sync.consumeUpdate();
    if (updated != null) {
      _cubit.patchLead(updated);
    }
    final deletedId = _sync.consumeDeletion();
    if (deletedId != null) {
      _cubit.removeLead(deletedId);
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onLeadSync);
    _scrollController.dispose();
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LeadsTasksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredEmployeeId != oldWidget.filteredEmployeeId) {
      _fetchData(isRefresh: true);
    }
  }

  void _fetchData({bool isRefresh = false}) {
    _cubit.fetchTasks(
      role: widget.user.role,
      userId: widget.user.id,
      filterByEmployeeId: widget.filteredEmployeeId,
      isRefresh: isRefresh,
    );
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
      _cubit.loadMore();
    }
  }

  void _openDetails(LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<LeadCubit>()..loadSingleLeadAndEmployees(lead, widget.user.role),
          child: LeadDetailsScreen(
            leadId: lead.id!,
            currentUser: widget.user,
          ),
        ),
      ),
    );
  }

  void _openEdit(LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<LeadCubit>()..loadSingleLeadAndEmployees(lead, widget.user.role),
          child: LeadFormScreen(user: widget.user, lead: lead),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _innerTabController,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.brandPrimary,
              labelStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              tabs: const [
                Tab(text: "عملاء متأخرين"),
                Tab(text: "عملاء محولين"),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchData(isRefresh: true),
              child: BlocBuilder<LeadTasksCubit, LeadTasksState>(
                builder: (context, state) {
                  if (state is LeadTasksInitial ||
                      (state is LeadTasksLoading &&
                          _cubit.state is! LeadTasksLoaded)) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.separated(
                        padding: EdgeInsets.all(20.w),
                        itemCount: 5,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (_, __) => Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                          child: Container(height: 140.h),
                        ),
                      ),
                    );
                  }

                  if (state is LeadTasksError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Text(
                            'حدث خطأ: ${state.message}',
                            style:
                                TextStyle(color: Colors.red, fontSize: 16.sp),
                          ),
                        ),
                      ],
                    );
                  }

                  if (state is LeadTasksLoaded) {
                    final delayedLeads = state.leads.where((l) => l.transferredFrom == null).toList();
                    final transferredLeads = state.leads.where((l) => l.transferredFrom != null).toList();

                    return TabBarView(
                      controller: _innerTabController,
                      children: [
                        _buildList(delayedLeads, state.isLoadingMore),
                        _buildList(transferredLeads, state.isLoadingMore),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LeadModel> tasks, bool isLoadingMore) {
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Center(
            child: LeadEmptyState(
              message: "رائع! لا توجد لديك مهام.",
              icon: Icons.task_alt,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            "عدد المهام: ${tasks.length}",
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
            itemCount: tasks.length + (isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              if (index >= tasks.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final lead = tasks[index];
              return LeadCard(
                lead: lead,
                role: widget.user.role,
                onTap: () => _openDetails(lead),
                onEdit: () => _openEdit(lead),
                onDelete: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
